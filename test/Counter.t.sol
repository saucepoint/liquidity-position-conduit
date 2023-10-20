// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "forge-std/Test.sol";
import {HookTest} from "./utils/HookTest.sol";
import {Counter} from "../src/Counter.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {Constants} from "@uniswap/v4-core/test/foundry-tests/utils/Constants.sol";
import {LiquidityPositionManager} from "bungi/LiquidityPositionManager.sol";
import {Position, PositionId, PositionIdLibrary} from "bungi/types/PositionId.sol";
import {LiquidityAmounts} from "v4-periphery/libraries/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";

contract CounterTest is HookTest {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using PositionIdLibrary for Position;

    LiquidityPositionManager lpm;
    Counter counter;
    PoolKey poolKey;
    PoolId poolId;
    IERC20 DAI;

    bytes32 allocDAO = bytes32("allocDAO");
    address alice = makeAddr("alice");
    bytes constant ZERO_BYTES = new bytes(0);

    function setUp() public {
        HookTest.initHookTestEnv();
        lpm = new LiquidityPositionManager(IPoolManager(address(manager)));
        counter = new Counter(lpm);
        counter.approvePair(address(token0), address(token1));

        DAI = IERC20(address(token0));

        // Create a hookless pool
        poolKey =
            PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(address(0x0)));
        poolId = poolKey.toId();
        manager.initialize(poolKey, Constants.SQRT_RATIO_1_1, ZERO_BYTES);

        // mint alice from token1
        token1.transfer(address(alice), 1_000_000e18);
    }

    function test_lpCreate() public {
        // supply DAI to the conduit
        DAI.approve(address(counter), 10_000e18);
        counter.deposit(allocDAO, address(DAI), 10_000e18);

        // alice creates a position by using the DAI in the conduit
        vm.startPrank(alice);
        token1.approve(address(counter), 1_000_000e18);

        Position memory position = Position({poolKey: poolKey, tickLower: -600, tickUpper: 600});
        (, int24 currentTick,,) = manager.getSlot0(poolId);
        uint256 liq = LiquidityAmounts.getLiquidityForAmounts(
            TickMath.getSqrtRatioAtTick(currentTick),
            TickMath.getSqrtRatioAtTick(position.tickLower),
            TickMath.getSqrtRatioAtTick(position.tickUpper),
            DAI.balanceOf(address(counter)),
            token1.balanceOf(address(alice))
        );
        counter.createPosition(position, token1.balanceOf(address(alice)), uint256(liq), ZERO_BYTES);

        // all of the DAI was used
        assertEq(DAI.balanceOf(address(counter)), 0);

        vm.stopPrank();
    }

    // Test withdrawals work when LPs are forcibly closed
    function test_withdraw_lpClose() public {
        // supply DAI to the conduit
        uint256 DAI_SUPPLIED = 10_000e18;
        DAI.approve(address(counter), DAI_SUPPLIED);
        counter.deposit(allocDAO, address(DAI), DAI_SUPPLIED);

        // alice creates a position by using the DAI in the conduit
        vm.startPrank(alice);
        token1.approve(address(counter), 1_000_000e18);

        Position memory position = Position({poolKey: poolKey, tickLower: -600, tickUpper: 600});
        (, int24 currentTick,,) = manager.getSlot0(poolId);
        uint256 liq = LiquidityAmounts.getLiquidityForAmounts(
            TickMath.getSqrtRatioAtTick(currentTick),
            TickMath.getSqrtRatioAtTick(position.tickLower),
            TickMath.getSqrtRatioAtTick(position.tickUpper),
            DAI.balanceOf(address(counter)),
            token1.balanceOf(address(alice))
        );
        counter.createPosition(position, token1.balanceOf(address(alice)), uint256(liq), ZERO_BYTES);
        vm.stopPrank();

        // cant withdraw without closing the LPs
        vm.expectRevert();
        counter.withdraw(allocDAO, address(DAI), DAI_SUPPLIED);

        // close the LP
        counter.closeAll(position, ZERO_BYTES);

        // DAI is withdrawable, TODO: look into the off-by-1-wei error
        counter.withdraw(allocDAO, address(DAI), DAI_SUPPLIED - 1);
        assertEq(DAI.balanceOf(address(counter)), 0);
    }
}

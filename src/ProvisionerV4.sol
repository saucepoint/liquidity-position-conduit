// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {LiquidityPositionManager} from "bungi/LiquidityPositionManager.sol";
import {Position, PositionId, PositionIdLibrary} from "bungi/types/PositionId.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract ProvisionerV4 {
    LiquidityPositionManager public immutable lpm;

    constructor(LiquidityPositionManager _lpm) {
        lpm = _lpm;
    }

    function createPosition(Position calldata position, uint256 tokenAmount, uint256 liquidity, bytes calldata hookData)
        external
    {
        // TODO: do not assume that token0 is Maker allocated, and token1 is user provided
        // for now, we'll assume that token0 is from Maker, and token 1 is from the user
        IERC20(Currency.unwrap(position.poolKey.currency1)).transferFrom(msg.sender, address(this), tokenAmount);
        lpm.modifyPosition(
            address(this),
            position.poolKey,
            IPoolManager.ModifyPositionParams({
                tickLower: position.tickLower,
                tickUpper: position.tickUpper,
                liquidityDelta: int256(liquidity)
            }),
            hookData
        );
    }

    function approvePair(address token0, address token1) external {
        IERC20(token0).approve(address(lpm), type(uint256).max);
        IERC20(token1).approve(address(lpm), type(uint256).max);
    }
}

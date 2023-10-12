// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {LiquidityPositionManager} from "bungi/LiquidityPositionManager.sol";

contract ProvisionerV4 {
    LiquidityPositionManager public immutable lpm;

    constructor(LiquidityPositionManager _lpm) {
        lpm = _lpm;
    }

    function _modifyPosition(PoolKey calldata key, int24 tickLower, int24 tickUpper, int256 liquidityDelta) external {
        lpm.modifyPosition(
            address(this),
            key,
            IPoolManager.ModifyPositionParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: liquidityDelta
            }),
            new bytes(0)
        );
    }
}

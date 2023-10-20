// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IAllocatorConduit} from "dss-allocator/src/IAllocatorConduit.sol";
import {ProvisionerV4} from "./ProvisionerV4.sol";
import {LiquidityPositionManager} from "bungi/LiquidityPositionManager.sol";

contract LPConduit is IAllocatorConduit, ProvisionerV4 {
    constructor(LiquidityPositionManager _lpm) ProvisionerV4(_lpm) {}

    function deposit(bytes32 ilk, address asset, uint256 amount) external override {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        emit Deposit(ilk, asset, msg.sender, amount);
    }

    function withdraw(bytes32 ilk, address asset, uint256 maxAmount) external override returns (uint256 amount) {
        // TODO: assume all assets are recoverable
        amount = maxAmount;
        IERC20(asset).transfer(msg.sender, maxAmount);
        emit Withdraw(ilk, asset, msg.sender, maxAmount);
    }

    function maxDeposit(bytes32 ilk, address asset) external view override returns (uint256 maxDeposit_) {
        // TODO: enforce limits
        return type(uint256).max;
    }

    function maxWithdraw(bytes32 ilk, address asset) external view override returns (uint256 maxWithdraw_) {
        // TODO: enforce limits, based on LP holdings
        return type(uint256).max;
    }
}

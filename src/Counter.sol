// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IAllocatorConduit} from "dss-allocator/src/IAllocatorConduit.sol";

contract Counter is IAllocatorConduit {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function deposit(bytes32 ilk, address asset, uint256 amount) external override {
        // limit to DAI only
        emit Deposit(ilk, asset, msg.sender, amount);
    }

    function withdraw(bytes32 ilk, address asset, uint256 maxAmount) external override returns (uint256 amount) {
        // limit to DAI only
        emit Withdraw(ilk, asset, msg.sender, maxAmount);
        return maxAmount;
    }

    function maxDeposit(bytes32 ilk, address asset) external view override returns (uint256 maxDeposit_) {
        // limit to DAI only
        return IERC20(asset).balanceOf(address(this));
    }

    function maxWithdraw(bytes32 ilk, address asset) external view override returns (uint256 maxWithdraw_) {
        // limit to DAI only
        return IERC20(asset).balanceOf(address(this));
    }
}

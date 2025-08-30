// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInterestRateModel {
    function getBorrowRatePerSecond(
        uint256 utilization
    ) external view returns (uint256);
}

/// @notice Minimal single-asset lending pool with super-simplified accounting.
/// Users:
/// - deposit(asset)
/// - withdraw(asset)
/// - borrow(asset) up to 66.66% of their deposits (150% collateral requirement)
/// - repay(asset)
/// Interest:
/// - Linear simple interest on each borrower since their last action.
contract LendingPool {
    IERC20 public immutable asset; // single ERC20 asset
    IInterestRateModel public immutable irm; // interest rate model

    uint256 public totalDeposits; // pool total deposits
    uint256 public totalBorrows; // pool total borrows (principal only)

    mapping(address => uint256) public deposits; // user deposit balance

    struct Borrow {
        uint256 principal; // what user currently owes as principal
        uint256 timestamp; // last time we updated their loan
    }
    mapping(address => Borrow) public borrows;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount, uint256 interestPaid);

    constructor(IERC20 _asset, IInterestRateModel _irm) {
        asset = _asset;
        irm = _irm;
    }

    // ===== View helpers =====

    function utilization() public view returns (uint256) {
        if (totalDeposits == 0) return 0;
        if (totalBorrows > totalDeposits) return 1e18;
        return (totalBorrows * 1e18) / totalDeposits; // 1e18 scale
    }

    function availableLiquidity() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /// max a user can newly borrow now (ignores interest until next action)
}

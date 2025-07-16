// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IRewardsDistributor.sol";

abstract contract RewardsDistributorStorage is IRewardsDistributor {
    //=========================================================================
    //                                CONSTANT
    //=========================================================================
    // The ERC20 token used for rewards
    IERC20 public immutable cToken;

    //=========================================================================
    //                                STORAGE
    //=========================================================================
    // Address authorized to update rewards
    address public rewardsUpdater;
    
    // Current distribution root
    bytes32 public distributionRoot;

    // Mapping of address and role to total claimed rewards
    mapping(address => mapping(Role => uint256)) public rewardClaimed;
}

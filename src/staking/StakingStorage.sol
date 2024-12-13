// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStaking.sol";

abstract contract StakingStorage is IStaking {
    //=========================================================================
    //                                CONSTANT
    //=========================================================================
    IERC20 public immutable cToken;
    uint256 public constant UNLOCK_PERIOD = 7 days;

    //=========================================================================
    //                                STORAGE
    //=========================================================================
    uint256 public minOperatorStake;
    mapping(address => bool) public operatorWhitelist;
    mapping(address => uint256) public operatorStakes;
    mapping(address => mapping(address => uint256)) public delegations;
}

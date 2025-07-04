// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStaking.sol";

abstract contract StakingStorage is IStaking {
    //=========================================================================
    //                                CONSTANT
    //=========================================================================
    // The ERC20 C token used for staking
    IERC20 public immutable cToken;
    // Time period required to wait before withdrawing unstaked tokens (7 days)
    uint256 public constant UNLOCK_PERIOD = 7 days;

    //=========================================================================
    //                                STORAGE
    //=========================================================================
    // The counter for the NFT token IDs
    Counters.Counter internal _tokenIdCounter;
    // The address of the airdrop contract
    address public airdropContract;
    // Minimum amount of tokens required for an operator to stake
    uint256 public minOperatorStake;
    // Mapping to track whitelisted operators
    mapping(address => bool) public operatorWhitelist;
    // Mapping of operator addresses to their staked amounts
    mapping(address => uint256) public operatorStakes;
    // Mapping of operator addresses to their unstake requests
    mapping(address => UnstakeRequest) public unstakeRequests;
    // Mapping from NFT token ID to delegation amount
    mapping(uint256 => uint256) public delegations;
    // Mapping of NFT token ID to Undelegate request
    mapping(uint256 => UndelegateRequest) public undelegateRequests;
}

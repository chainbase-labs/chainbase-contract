// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IStaking {
    //=========================================================================
    //                                STRUCTS
    //=========================================================================
    // Structure to track unstake requests with amount and unlock time
    struct UnstakeRequest {
        uint256 amount; // Amount of tokens requested to unstake
        uint256 unlockTime; // Timestamp when tokens can be withdrawn
    }

    // Structure to track undelegate requests with amount and unlock time
    struct UndelegateRequest {
        uint256 amount;
        uint256 unlockTime;
    }

    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event AirdropContractUpdated(address indexed oldAirdropContract, address indexed newAirdropContract);
    event MinOperatorStakeUpdated(uint256 oldAmount, uint256 newAmount);
    event WhitelistAdded(address indexed operator);
    event WhitelistRemoved(address indexed operator);
    event StakeDeposited(address indexed operator, uint256 amount);
    event UnstakeRequested(address indexed operator, uint256 amount, uint256 unlockTime);
    event StakeWithdrawn(address indexed operator, uint256 amount);
    event DelegationDeposited(address indexed delegator, uint256 amount);
    event UndelegateRequested(address indexed delegator, uint256 amount, uint256 unlockTime);
    event DelegationWithdrawn(address indexed delegator, uint256 amount);

    //=========================================================================
    //                                FUNCTIONS
    //=========================================================================
    function addWhitelist(address[] calldata operators) external;
    function removeWhitelist(address[] calldata operators) external;
    function stake(uint256 amount) external;
    function unstake() external;
    function withdrawStake() external;
    function delegate(uint256 amount) external;
    function delegateFromAirdrop(address delegator, uint256 amount) external;
    function undelegate(uint256 amount) external;
    function withdrawDelegation() external;
}

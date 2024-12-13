// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IStaking {
    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event WhitelistAdded(address indexed operator);
    event WhitelistRemoved(address indexed operator);
    event StakeDeposited(address indexed operator, uint256 amount);
    event StakeWithdrawn(address indexed operator, uint256 amount);
    event DelegationDeposited(address indexed delegator, address indexed operator, uint256 amount);
    event DelegationWithdrawn(address indexed delegator, address indexed operator, uint256 amount);

    //=========================================================================
    //                                FUNCTIONS
    //=========================================================================
    function addWhitelist(address[] calldata _operators) external;
    function removeWhitelist(address[] calldata _operators) external;
    function stake(uint256 _amount) external;
    function withdrawStake() external;
    function delegate(address _operator, uint256 _amount) external;
    function withdrawDelegation(address operator, uint256 amount) external;
}

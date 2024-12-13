// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "./StakingStorage.sol";

contract Staking is OwnableUpgradeable, PausableUpgradeable, StakingStorage {
    //=========================================================================
    //                                MODIFIERS
    //=========================================================================
    modifier onlyWhitelisted() {
        require(operatorWhitelist[msg.sender], "Staking: Not a whitelisted operator");
        _;
    }

    //=========================================================================
    //                                CONSTRUCTOR
    //=========================================================================
    constructor(address _cToken) {
        cToken = IERC20(_cToken);
        _disableInitializers();
    }

    //=========================================================================
    //                                INITIALIZE
    //=========================================================================
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __Pausable_init();
        minOperatorStake = 500000 * 10 ** 18;
    }

    //=========================================================================
    //                                 MANAGE
    //=========================================================================
    function setMinOperatorStake(uint256 _minOperatorStake) external onlyOwner {
        minOperatorStake = _minOperatorStake;
    }

    function addWhitelist(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            operatorWhitelist[operators[i]] = true;
            emit WhitelistAdded(operators[i]);
        }
    }

    function removeWhitelist(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            delete operatorWhitelist[operators[i]];
            emit WhitelistRemoved(operators[i]);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    function stake(uint256 amount) external onlyWhitelisted whenNotPaused {
        address operator = msg.sender;

        require(operatorStakes[operator] + amount >= minOperatorStake, "Staking: Insufficient stake amount");

        require(cToken.transferFrom(operator, address(this), amount), "Staking: Transfer failed");
        operatorStakes[operator] += amount;

        emit StakeDeposited(operator, amount);
    }

    function withdrawStake() external onlyWhitelisted whenNotPaused {
        address operator = msg.sender;
        uint256 amount = operatorStakes[operator];

        require(amount > 0, "Staking: No stake to withdraw");

        delete operatorStakes[operator];
        require(cToken.transfer(operator, amount), "Staking: Transfer failed");

        emit StakeWithdrawn(operator, amount);
    }

    function delegate(address operator, uint256 amount) external whenNotPaused {
        address delegator = msg.sender;

        require(operatorWhitelist[operator], "Staking: Operator not whitelisted");

        require(cToken.transferFrom(delegator, address(this), amount), "Staking: Transfer failed");
        delegations[delegator][operator] += amount;

        emit DelegationDeposited(delegator, operator, amount);
    }

    function withdrawDelegation(address operator, uint256 amount) external whenNotPaused {
        address delegator = msg.sender;

        require(operatorWhitelist[operator], "Staking: Operator not whitelisted");
        require(delegations[delegator][operator] >= amount, "Staking: Insufficient delegation amount");

        delegations[delegator][operator] -= amount;
        require(cToken.transfer(delegator, amount), "Staking: Transfer failed");

        emit DelegationWithdrawn(delegator, operator, amount);
    }
}

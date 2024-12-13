// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./StakingStorage.sol";

contract Staking is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, StakingStorage {
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
        require(_cToken != address(0), "Staking: Invalid cToken address");
        cToken = IERC20(_cToken);
        _disableInitializers();
    }

    //=========================================================================
    //                                INITIALIZE
    //=========================================================================
    function initialize(address initialOwner) public initializer {
        require(initialOwner != address(0), "Staking: Invalid initial owner address");
        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();
        minOperatorStake = 500000 * 10 ** 18;
    }

    //=========================================================================
    //                                 MANAGE
    //=========================================================================
    function setMinOperatorStake(uint256 _minOperatorStake) external onlyOwner {
        require(_minOperatorStake > 0, "Staking: minimum operator stake amount must be greater than 0");
        uint256 oldAmount = minOperatorStake;
        minOperatorStake = _minOperatorStake;
        emit MinOperatorStakeUpdated(oldAmount, _minOperatorStake);
    }

    function addWhitelist(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            address operator = operators[i];
            require(operator != address(0), "Staking: Invalid operator address");
            operatorWhitelist[operator] = true;
            emit WhitelistAdded(operator);
        }
    }

    function removeWhitelist(address[] calldata operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            address operator = operators[i];
            delete operatorWhitelist[operator];
            emit WhitelistRemoved(operator);
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
    function stake(uint256 amount) external onlyWhitelisted whenNotPaused nonReentrant {
        address operator = msg.sender;

        require(amount > 0, "Staking: Amount must be greater than 0");
        require(operatorStakes[operator] + amount >= minOperatorStake, "Staking: Insufficient stake amount");

        require(cToken.transferFrom(operator, address(this), amount), "Staking: Transfer failed");
        operatorStakes[operator] += amount;

        emit StakeDeposited(operator, amount);
    }

    function unstake() external onlyWhitelisted whenNotPaused nonReentrant {
        address operator = msg.sender;
        uint256 amount = operatorStakes[operator];

        require(amount > 0, "Staking: No stake to withdraw");
        require(unstakeRequests[operator].amount == 0, "Staking: Existing unstake request");

        delete operatorStakes[operator];
        uint256 unlockTime = block.timestamp + UNLOCK_PERIOD;
        unstakeRequests[operator] = UnstakeRequest({amount: amount, unlockTime: unlockTime});

        emit UnstakeRequested(operator, amount, unlockTime);
    }

    function withdrawStake() external onlyWhitelisted whenNotPaused nonReentrant {
        address operator = msg.sender;
        UnstakeRequest memory request = unstakeRequests[operator];

        require(request.amount > 0, "Staking: No pending unstake request");
        require(block.timestamp >= request.unlockTime, "Staking: Tokens still locked");

        uint256 amount = request.amount;
        delete unstakeRequests[operator];

        require(cToken.transfer(operator, amount), "Staking: Transfer failed");

        emit StakeWithdrawn(operator, amount);
    }

    function delegate(address operator, uint256 amount) external whenNotPaused nonReentrant {
        address delegator = msg.sender;

        require(amount > 0, "Staking: Amount must be greater than 0");
        require(operatorWhitelist[operator], "Staking: Operator not whitelisted");

        require(cToken.transferFrom(delegator, address(this), amount), "Staking: Transfer failed");
        delegations[delegator][operator] += amount;

        emit DelegationDeposited(delegator, operator, amount);
    }

    function withdrawDelegation(address operator, uint256 amount) external whenNotPaused nonReentrant {
        address delegator = msg.sender;

        require(amount > 0, "Staking: Amount must be greater than 0");
        require(delegations[delegator][operator] >= amount, "Staking: Insufficient delegation amount");

        delegations[delegator][operator] -= amount;
        require(cToken.transfer(delegator, amount), "Staking: Transfer failed");

        emit DelegationWithdrawn(delegator, operator, amount);
    }
}

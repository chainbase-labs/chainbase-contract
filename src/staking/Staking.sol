// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./StakingStorage.sol";

contract Staking is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, StakingStorage {
    using SafeERC20 for IERC20;

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
    /**
     * @notice Allows whitelisted operators to stake tokens
     * @param amount The amount of tokens to stake
     */
    function stake(uint256 amount) external onlyWhitelisted whenNotPaused nonReentrant {
        address operator = msg.sender;

        require(amount > 0, "Staking: Amount must be greater than 0");
        require(operatorStakes[operator] + amount >= minOperatorStake, "Staking: Insufficient stake amount");

        cToken.safeTransferFrom(operator, address(this), amount);
        operatorStakes[operator] += amount;

        emit StakeDeposited(operator, amount);
    }

    /**
     * @notice Initiates the unstake process for an operator
     * @dev Starts the unlock period before tokens can be withdrawn
     */
    function unstake() external onlyWhitelisted whenNotPaused nonReentrant {
        address operator = msg.sender;
        uint256 amount = operatorStakes[operator];

        require(amount > 0, "Staking: No staking to unstake");
        require(unstakeRequests[operator].amount == 0, "Staking: Existing unstake request");

        delete operatorStakes[operator];
        uint256 unlockTime = block.timestamp + UNLOCK_PERIOD;
        unstakeRequests[operator] = UnstakeRequest({amount: amount, unlockTime: unlockTime});

        emit UnstakeRequested(operator, amount, unlockTime);
    }

    /**
     * @notice Allows operators to withdraw their unstaked tokens after the unlock period
     */
    function withdrawStake() external onlyWhitelisted whenNotPaused nonReentrant {
        address operator = msg.sender;
        UnstakeRequest memory request = unstakeRequests[operator];

        require(request.amount > 0, "Staking: No pending unstake request");
        require(block.timestamp >= request.unlockTime, "Staking: Tokens still locked");

        uint256 amount = request.amount;
        delete unstakeRequests[operator];

        cToken.safeTransfer(operator, amount);

        emit StakeWithdrawn(operator, amount);
    }

    /**
     * @notice Allows users to delegate tokens
     * @param amount The amount of tokens to delegate
     */
    function delegate(uint256 amount) external whenNotPaused nonReentrant {
        address delegator = msg.sender;

        require(amount > 0, "Staking: Amount must be greater than 0");

        cToken.safeTransferFrom(delegator, address(this), amount);
        delegations[delegator] += amount;

        emit DelegationDeposited(delegator, amount);
    }

    /**
     * @notice Allows delegators to initiate the undelegate process
     * @param amount The amount of tokens to undelegate
     */
    function undelegate(uint256 amount) external whenNotPaused nonReentrant {
        address delegator = msg.sender;

        require(amount > 0, "Staking: Amount must be greater than 0");
        require(delegations[delegator] >= amount, "Staking: Insufficient delegation amount");
        require(undelegateRequests[delegator].amount == 0, "Staking: Existing undelegate request");

        delegations[delegator] -= amount;
        uint256 unlockTime = block.timestamp + UNLOCK_PERIOD;
        undelegateRequests[delegator] = UndelegateRequest({amount: amount, unlockTime: unlockTime});

        emit UndelegateRequested(delegator, amount, unlockTime);
    }

    /**
     * @notice Allows delegators to withdraw their undelegated tokens after the unlock period
     * @dev Transfers tokens back to the delegator after the unlock period has passed
     */
    function withdrawDelegation() external whenNotPaused nonReentrant {
        address delegator = msg.sender;
        UndelegateRequest memory request = undelegateRequests[delegator];

        require(request.amount > 0, "Staking: No pending undelegate request");
        require(block.timestamp >= request.unlockTime, "Staking: Tokens still locked");

        uint256 amount = request.amount;
        delete undelegateRequests[delegator];

        cToken.safeTransfer(delegator, amount);

        emit DelegationWithdrawn(delegator, amount);
    }
}

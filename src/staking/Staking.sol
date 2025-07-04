// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./StakingStorage.sol";

contract Staking is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, ERC721EnumerableUpgradeable, StakingStorage {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

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
    function initialize(
        address _airdropContract
    ) public initializer {
        require(_airdropContract != address(0), "Staking: Invalid airdrop contract address");
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        airdropContract = _airdropContract;
        minOperatorStake = 500000 * 10 ** 18;
    }

    //=========================================================================
    //                                 MANAGE
    //=========================================================================
    function setAirdropContract(address _airdropContract) external onlyOwner {
        require(_airdropContract != address(0), "Staking: Invalid airdrop contract address");
        address oldAirdropContract = airdropContract;
        airdropContract = _airdropContract;
        emit AirdropContractUpdated(oldAirdropContract, _airdropContract);
    }

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

        _delegate(delegator, amount);
    }

    /**
     * @notice Allows the airdrop contract to delegate tokens on behalf of a delegator
     * @param delegator The address of the delegator
     * @param amount The amount of tokens to delegate
     */
    function delegateFromAirdrop(address delegator, uint256 amount) external whenNotPaused nonReentrant {
        require(msg.sender == airdropContract, "Staking: Only airdrop contract");
        require(delegator != address(0), "Staking: Invalid delegator address");
        require(amount > 0, "Staking: Amount must be greater than 0");

        _delegate(delegator, amount);
    }

    /**
     * @notice Internal function to delegate tokens
     * @param delegator The address of the delegator
     * @param amount The amount of tokens to delegate
     */
    function _delegate(address delegator, uint256 amount) internal {
        // Mint NFT
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(delegator, tokenId);

        delegations[tokenId] = amount;

        emit DelegationDeposited(tokenId, delegator, amount);
    }

    /**
     * @notice Allows delegators to increase their delegation amount
     * @param tokenId The ID of the NFT representing the delegation
     * @param amount The amount of tokens to increase the delegation by
     */
    function increaseDelegation(uint256 tokenId, uint256 amount) external whenNotPaused nonReentrant {
        address delegator = msg.sender;
        require(ownerOf(tokenId) == delegator, "Staking: Not token owner");
        require(amount > 0, "Staking: Amount must be greater than 0");

        uint256 oldAmount = delegations[tokenId];
        delegations[tokenId] += amount;

        emit DelegationIncreased(tokenId, oldAmount, delegations[tokenId]);
    }

    /**
     * @notice Allows delegators to initiate the undelegate process
     * @param tokenId The ID of the NFT representing the delegation
     */
    function undelegate(uint256 tokenId) external whenNotPaused nonReentrant {
        address delegator = msg.sender;
        require(ownerOf(tokenId) == delegator, "Staking: Not token owner");
        require(undelegateRequests[tokenId].amount == 0, "Staking: Existing undelegate request");

        uint256 amount = delegations[tokenId];
        require(amount > 0, "Staking: No delegation for this token");

        uint256 unlockTime = block.timestamp + UNLOCK_PERIOD;
        undelegateRequests[tokenId] = UndelegateRequest({
            amount: amount,
            unlockTime: unlockTime
        });

        emit UndelegateRequested(tokenId, delegator, amount, unlockTime);
    }

    /**
     * @notice Allows delegators to cancel their undelegate request
     * @param tokenId The ID of the NFT representing the delegation
     */
    function cancelUndelegate(uint256 tokenId) external whenNotPaused nonReentrant {
        address delegator = msg.sender;
        require(ownerOf(tokenId) == delegator, "Staking: Not token owner");
        require(undelegateRequests[tokenId].amount > 0, "Staking: No pending undelegate request");

        // Clean up state
        delete undelegateRequests[tokenId];

        emit UndelegateCanceled(tokenId, delegator);
    }

    /**
     * @notice Allows delegators to withdraw their undelegated tokens after the unlock period
     * @dev Transfers tokens back to the delegator after the unlock period has passed
     */
    function withdrawDelegation(uint256 tokenId) external whenNotPaused nonReentrant {
        address delegator = msg.sender;
        UndelegateRequest memory request = undelegateRequests[tokenId];
        uint256 amount = request.amount;

        require(ownerOf(tokenId) == delegator, "Staking: Not token owner");
        require(amount > 0, "Staking: No pending undelegate request");
        require(block.timestamp >= request.unlockTime, "Staking: Tokens still locked");

        // Clean up state
        delete delegations[tokenId];
        delete undelegateRequests[tokenId];

        // Burn NFT
        _burn(tokenId);

        // Transfer tokens
        cToken.safeTransfer(delegator, amount);

        emit DelegationWithdrawn(tokenId, delegator, amount);
    }

    /**
     * @notice Get total delegation amount for an address
     * @param delegator The address to check
     * @return total The total delegation amount
     */
    function getDelegationAmount(address delegator) public view returns (uint256 total) {
        uint256 balance = balanceOf(delegator);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(delegator, i);
            total += delegations[tokenId];
        }
        return total;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./RewardsDistributorStorage.sol";

contract RewardsDistributor is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    RewardsDistributorStorage
{
    using SafeERC20 for IERC20;

    //=========================================================================
    //                                MODIFIERS
    //=========================================================================
    /// @notice Ensures the caller is the authorized rewards updater
    modifier onlyRewardsUpdater() {
        require(msg.sender == rewardsUpdater, "RewardsDistributor: caller is not the rewardsUpdater");
        _;
    }

    //=========================================================================
    //                                CONSTRUCTOR
    //=========================================================================
    /// @notice Constructor sets the reward token address
    /// @param _cToken Address of the ERC20 token used for rewards
    constructor(address _cToken) {
        require(_cToken != address(0), "RewardsDistributor: Invalid cToken address");
        cToken = IERC20(_cToken);
        _disableInitializers();
    }

    //=========================================================================
    //                                INITIALIZE
    //=========================================================================
    /// @notice Initializes the contract with required parameters
    /// @param _rewardsUpdater Address authorized to update rewards
    function initialize(address _rewardsUpdater) public initializer {
        require(_rewardsUpdater != address(0), "RewardsDistributor: Invalid rewards updater address");

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        rewardsUpdater = _rewardsUpdater;
    }

    //=========================================================================
    //                               MANAGE-owner
    //=========================================================================
    /// @notice Updates the rewards updater address
    /// @param _rewardsUpdater New rewards updater address
    function setRewardsUpdater(address _rewardsUpdater) external onlyOwner {
        require(_rewardsUpdater != address(0), "RewardsDistributor: Invalid rewards updater address");

        address oldUpdater = rewardsUpdater;
        rewardsUpdater = _rewardsUpdater;

        emit RewardsUpdaterUpdated(oldUpdater, _rewardsUpdater);
    }

    /// @notice Transfers all tokens to the owner
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = cToken.balanceOf(address(this));
        cToken.safeTransfer(owner(), balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //=========================================================================
    //                               MANAGE-rewardsUpdater
    //=========================================================================
    /// @notice Updates the merkle root for rewards distribution
    /// @param newRoot New merkle root of the distribution
    /// @param amount Total amount of tokens to be distributed
    function updateRoot(bytes32 newRoot, uint256 amount) external onlyRewardsUpdater {
        require(newRoot != bytes32(0), "RewardsDistributor: Invalid root");

        bytes32 oldRoot = distributionRoot;
        distributionRoot = newRoot;

        require(cToken.transferFrom(msg.sender, address(this), amount), "RewardsDistributor: Transfer failed");

        emit RootUpdated(oldRoot, newRoot, amount);
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    /// @notice Claims rewards for the caller
    /// @param role Role of the claimer (developer, operator, or delegator)
    /// @param amount Total cumulative amount of rewards claimable by the user
    /// @param proof Merkle proof to verify the claim
    function claimRewards(Role role, uint256 amount, bytes32[] calldata proof) external nonReentrant whenNotPaused {
        require(distributionRoot != bytes32(0), "RewardsDistributor: No active distribution");

        // Verify merkle proof - validates user address, role and amount
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, role, amount));
        require(MerkleProof.verify(proof, distributionRoot, leaf), "RewardsDistributor: Invalid proof");

        // Update claim record for specific role
        uint256 claimable = amount - rewardClaimed[msg.sender][role];
        require(claimable > 0, "RewardsDistributor: No rewards to claim");
        rewardClaimed[msg.sender][role] = amount;

        // Safe transfer rewards
        cToken.safeTransfer(msg.sender, claimable);

        emit RewardsClaimed(msg.sender, claimable);
    }
}

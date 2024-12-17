// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

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
    /// @param initialOwner Address of the contract owner
    /// @param _rewardsUpdater Address authorized to update rewards
    /// @param _activationDelay Time delay before rewards become active
    function initialize(address initialOwner, address _rewardsUpdater, uint32 _activationDelay) public initializer {
        require(initialOwner != address(0), "RewardsDistributor: Invalid initial owner address");
        require(_rewardsUpdater != address(0), "RewardsDistributor: Invalid rewards updater address");
        require(_activationDelay > 0, "RewardsDistributor: Invalid activation delay");

        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();

        rewardsUpdater = _rewardsUpdater;
        activationDelay = _activationDelay;
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

    /// @notice Updates the activation delay
    /// @param _activationDelay New activation delay
    function setActivationDelay(uint32 _activationDelay) external onlyOwner {
        require(_activationDelay > 0, "RewardsDistributor: Invalid activation delay");

        uint32 oldDelay = activationDelay;
        activationDelay = _activationDelay;

        emit ActivationDelayUpdated(oldDelay, _activationDelay);
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
    /// @notice Submits a new merkle root for rewards distribution
    /// @param root Merkle root of the distribution
    /// @param totalAmount Total amount of tokens to be distributed
    function submitRoot(bytes32 root, uint256 totalAmount) external onlyRewardsUpdater whenNotPaused {
        uint32 activateTime = uint32(block.timestamp) + activationDelay;

        require(cToken.transferFrom(msg.sender, address(this), totalAmount), "RewardsDistributor: Transfer failed");

        _distributionRoots.push(DistributionRoot({root: root, activatedAt: activateTime, disabled: false}));

        emit RootSubmitted(_distributionRoots.length - 1, root, totalAmount);
    }

    /// @notice Disables a distribution root
    /// @param rootIndex Index of the distribution root
    function disableRoot(uint32 rootIndex) external onlyRewardsUpdater whenNotPaused {
        require(rootIndex < _distributionRoots.length, "RewardsDistributor: invalid rootIndex");

        DistributionRoot storage root = _distributionRoots[rootIndex];

        require(!root.disabled, "RewardsDistributor: root already disabled");
        require(block.timestamp < root.activatedAt, "RewardsDistributor: root already activated");

        root.disabled = true;

        emit RootDisabled(rootIndex);
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    /// @notice Claims rewards for the caller
    /// @param rootIndex Index of the distribution root
    /// @param amount Total cumulative amount of rewards claimable by the user
    /// @param proof Merkle proof to verify the claim
    function claimRewards(uint256 rootIndex, uint256 amount, bytes32[] calldata proof)
        external
        nonReentrant
        whenNotPaused
    {
        require(rootIndex < _distributionRoots.length, "RewardsDistributor: Invalid root");
        DistributionRoot storage root = _distributionRoots[rootIndex];

        require(!root.disabled, "RewardsDistributor: Root already disabled");
        require(block.timestamp >= root.activatedAt, "RewardsDistributor: Not activated");

        // Verify merkle proof - validates user address and amount
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, root.root, leaf), "RewardsDistributor: Invalid proof");

        // Update claim record
        uint256 claimable = amount - rewardClaimed[msg.sender];
        require(claimable > 0, "RewardsDistributor: No rewards to claim");
        rewardClaimed[msg.sender] = amount;

        // Safe transfer rewards
        cToken.safeTransfer(msg.sender, claimable);

        emit RewardsClaimed(msg.sender, claimable);
    }

    //=========================================================================
    //                                VIEW
    //=========================================================================
    function getDistributionRoot(uint256 rootIndex) external view returns (DistributionRoot memory) {
        require(rootIndex < _distributionRoots.length, "RewardsDistributor: Invalid index");
        return _distributionRoots[rootIndex];
    }

    function getRootIndexFromHash(bytes32 rootHash) public view returns (uint32) {
        for (uint32 i = uint32(_distributionRoots.length); i > 0; i--) {
            if (_distributionRoots[i - 1].root == rootHash) {
                return i - 1;
            }
        }
        revert("RewardsDistributor: Root not found");
    }

    function getDistributionRootsLength() external view returns (uint256) {
        return _distributionRoots.length;
    }
}

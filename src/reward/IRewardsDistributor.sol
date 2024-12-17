// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IRewardsDistributor {
    //=========================================================================
    //                                STRUCTS
    //=========================================================================
    // Structure for storing merkle root distribution data
    struct DistributionRoot {
        bytes32 root; // Merkle root of the distribution
        uint32 activatedAt; // Timestamp when the distribution becomes active
        bool disabled; // Flag to disable the distribution
    }
    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event RootSubmitted(uint256 indexed index, bytes32 root, uint256 totalAmount);
    event RootDisabled(uint256 indexed index);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsUpdaterUpdated(address oldUpdater, address newUpdater);
    event ActivationDelayUpdated(uint32 oldDelay, uint32 newDelay);
}

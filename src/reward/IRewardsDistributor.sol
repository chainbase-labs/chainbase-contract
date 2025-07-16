// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IRewardsDistributor {
    //=========================================================================
    //                                ENUM
    //=========================================================================
    enum Role {
        DEVELOPER,
        OPERATOR,
        DELEGATOR
    }

    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event RootUpdated(bytes32 oldRoot, bytes32 newRoot, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsUpdaterUpdated(address oldUpdater, address newUpdater);

    //=========================================================================
    //                                FUNCTIONS
    //=========================================================================
    function updateRoot(bytes32 root, uint256 amount) external;
    function claimRewards(Role role, uint256 amount, bytes32[] calldata proof) external;
}

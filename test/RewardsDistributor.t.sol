// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {ChainbaseToken} from "../src/ChainbaseToken.sol";
import {RewardsDistributor} from "../src/reward/RewardsDistributor.sol";

contract RewardsDistributorTest is Test {
    RewardsDistributor public distributor;
    ChainbaseToken public cToken;

    address public owner;
    address public rewardsUpdater;
    address public user1;
    address public user2;

    uint32 public constant ACTIVATION_DELAY = 1 weeks;

    bytes32 public merkleRoot;
    uint256 public totalAmount = 1000e18;
    bytes32[] public mockProof;

    bytes32[] public leaves;
    bytes32[][] public proofs;
    uint256 public user1Amount = 600e18;
    uint256 public user2Amount = 400e18;

    function setUp() public {
        owner = makeAddr("owner");
        rewardsUpdater = makeAddr("rewardsUpdater");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy C Token
        cToken = new ChainbaseToken();

        // Deploy RewardsDistributor contract
        vm.prank(owner);
        ProxyAdmin distributorProxyAdmin = new ProxyAdmin();

        address distributorImplementation = address(new RewardsDistributor(address(cToken)));
        TransparentUpgradeableProxy distributorProxy = new TransparentUpgradeableProxy(
            distributorImplementation,
            address(distributorProxyAdmin),
            abi.encodeWithSelector(RewardsDistributor.initialize.selector, owner, rewardsUpdater, ACTIVATION_DELAY)
        );
        distributor = RewardsDistributor(address(distributorProxy));

        leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encodePacked(user1, user1Amount)); // user1's leaf
        leaves[1] = keccak256(abi.encodePacked(user2, user2Amount)); // user2's leaf

        // calculate merkle root
        merkleRoot = keccak256(abi.encodePacked(leaves[0], leaves[1]));

        // build user proofs
        proofs = new bytes32[][](2);
        // user1's proofs is leaves[1]
        proofs[0] = new bytes32[](1);
        proofs[0][0] = leaves[1];
        // user2's proofs is leaves[0]
        proofs[1] = new bytes32[](1);
        proofs[1][0] = leaves[0];

        // Verify the constructed merkle tree is correct
        require(MerkleProof.verify(proofs[0], merkleRoot, leaves[0]), "User1 proof verification failed");
        require(MerkleProof.verify(proofs[1], merkleRoot, leaves[1]), "User2 proof verification failed");

        // mint cToken to rewardsUpdater and approve distributor
        cToken.mint(rewardsUpdater, totalAmount);
        vm.prank(rewardsUpdater);
        cToken.approve(address(distributor), type(uint256).max);
    }

    function test_Initialize() public view {
        assertEq(distributor.owner(), owner);
        assertEq(distributor.rewardsUpdater(), rewardsUpdater);
        assertEq(distributor.activationDelay(), ACTIVATION_DELAY);
    }

    function testFail_InitializeZeroOwner() public {
        distributor = new RewardsDistributor(address(cToken));
        distributor.initialize(address(0), rewardsUpdater, ACTIVATION_DELAY);
    }

    function testFail_InitializeZeroUpdater() public {
        distributor = new RewardsDistributor(address(cToken));
        distributor.initialize(owner, address(0), ACTIVATION_DELAY);
    }

    function test_SetRewardsUpdater() public {
        address newUpdater = makeAddr("newUpdater");
        vm.prank(owner);
        distributor.setRewardsUpdater(newUpdater);
        assertEq(distributor.rewardsUpdater(), newUpdater);
    }

    function test_SetActivationDelay() public {
        uint32 newDelay = 2 days;
        vm.prank(owner);
        distributor.setActivationDelay(newDelay);
        assertEq(distributor.activationDelay(), newDelay);
    }

    function test_EmergencyWithdraw() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        uint256 balanceBefore = cToken.balanceOf(owner);
        vm.prank(owner);
        distributor.emergencyWithdraw();
        assertEq(cToken.balanceOf(owner) - balanceBefore, totalAmount);
    }

    function test_SubmitRoot() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        RewardsDistributor.DistributionRoot memory root = distributor.getDistributionRoot(0);
        assertEq(root.root, merkleRoot);
        assertEq(root.activatedAt, block.timestamp + ACTIVATION_DELAY);
        assertEq(root.disabled, false);
    }

    function test_DisableRoot() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        vm.prank(rewardsUpdater);
        distributor.disableRoot(0);

        RewardsDistributor.DistributionRoot memory root = distributor.getDistributionRoot(0);
        assertTrue(root.disabled);
    }

    function test_ClaimRewards() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        vm.warp(block.timestamp + ACTIVATION_DELAY + 1);

        // User1 claims
        vm.prank(user1);
        distributor.claimRewards(0, user1Amount, proofs[0]);
        assertEq(cToken.balanceOf(user1), user1Amount);

        // User2 claims
        vm.prank(user2);
        distributor.claimRewards(0, user2Amount, proofs[1]);
        assertEq(cToken.balanceOf(user2), user2Amount);
    }

    function testFail_ClaimRewardsWithWrongProof() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        vm.warp(block.timestamp + ACTIVATION_DELAY + 1);

        // User1 try use user2's proof
        vm.prank(user1);
        distributor.claimRewards(0, user1Amount, proofs[1]);
    }

    function testFail_ClaimRewardsWithWrongAmount() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        vm.warp(block.timestamp + ACTIVATION_DELAY + 1);

        // User1 try use wrong amount
        vm.prank(user1);
        distributor.claimRewards(0, user2Amount, proofs[0]);
    }

    function test_GetDistributionRoot() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        RewardsDistributor.DistributionRoot memory root = distributor.getDistributionRoot(0);
        assertEq(root.root, merkleRoot);
    }

    function test_GetRootIndexFromHash() public {
        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        uint32 index = distributor.getRootIndexFromHash(merkleRoot);
        assertEq(index, 0);
    }

    function test_GetDistributionRootsLength() public {
        assertEq(distributor.getDistributionRootsLength(), 0);

        vm.prank(rewardsUpdater);
        distributor.submitRoot(merkleRoot, totalAmount);

        assertEq(distributor.getDistributionRootsLength(), 1);
    }
}

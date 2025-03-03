// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {ChainbaseToken} from "../src/ChainbaseToken.sol";
import {ChainbaseAirdrop} from "../src/ChainbaseAirdrop.sol";

contract ChainbaseAirdropTest is Test {
    ChainbaseToken public token;
    ChainbaseAirdrop public airdrop;

    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    bytes32 public merkleRoot;
    bytes32[] public merkleProof;

    // Add new storage variables for merkle tree testing
    bytes32[] public leaves;
    mapping(address => uint256) public airdropAmounts;

    function setUp() public {
        vm.startPrank(owner);
        token = new ChainbaseToken();

        // Setup airdrop amounts
        airdropAmounts[user1] = 100 ether;
        airdropAmounts[user2] = 200 ether;

        // Generate merkle tree leaves
        leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encodePacked(user1, airdropAmounts[user1]));
        leaves[1] = keccak256(abi.encodePacked(user2, airdropAmounts[user2]));

        // Generate merkle root
        merkleRoot = _generateRoot(leaves);

        airdrop = new ChainbaseAirdrop(address(token), merkleRoot);
        token.mint(owner, 1000 ether);
        token.transfer(address(airdrop), 1000 ether);
        vm.stopPrank();

        // Generate merkle proof for user1
        merkleProof = _generateProof(leaves, 0);
    }

    function test_Constructor() public view {
        assertEq(address(airdrop.cToken()), address(token));
        assertEq(airdrop.merkleRoot(), merkleRoot);
        assertEq(airdrop.owner(), owner);
    }

    function test_SetAirdropState() public {
        vm.prank(owner);
        airdrop.setAirdropState(true);
        assertTrue(airdrop.isEnabled());

        vm.prank(owner);
        airdrop.setAirdropState(false);
        assertFalse(airdrop.isEnabled());
    }

    function test_SetAirdropState_RevertIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        airdrop.setAirdropState(true);
    }

    function test_UpdateMerkleRoot() public {
        bytes32 newRoot = keccak256(abi.encodePacked("new_root"));

        vm.prank(owner);
        airdrop.updateMerkleRoot(newRoot);

        assertEq(airdrop.merkleRoot(), newRoot);
    }

    function test_UpdateMerkleRoot_RevertIfNotOwner() public {
        bytes32 newRoot = keccak256(abi.encodePacked("new_root"));

        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        airdrop.updateMerkleRoot(newRoot);
    }

    function test_EmergencyWithdraw() public {
        uint256 initialBalance = token.balanceOf(address(airdrop));

        vm.prank(owner);
        airdrop.emergencyWithdraw();

        assertEq(token.balanceOf(owner), initialBalance);
        assertEq(token.balanceOf(address(airdrop)), 0);
    }

    function test_EmergencyWithdraw_RevertIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        airdrop.emergencyWithdraw();
    }

    function test_ClaimAirdrop_RevertWhenDisabled() public {
        vm.prank(user1);
        vm.expectRevert("ChainbaseAirdrop: Airdrop is not enabled");
        airdrop.claimAirdrop(airdropAmounts[user1], merkleProof);
    }

    function test_ClaimAirdrop_RevertWhenInsufficientBalance() public {
        vm.prank(owner);
        airdrop.setAirdropState(true);

        // Withdraw all tokens to make contract balance insufficient
        vm.prank(owner);
        airdrop.emergencyWithdraw();

        vm.prank(user1);
        vm.expectRevert("ChainbaseAirdrop: Insufficient balance");
        airdrop.claimAirdrop(airdropAmounts[user1], merkleProof);
    }

    function test_ClaimAirdrop_Success() public {
        // Enable airdrop
        vm.prank(owner);
        airdrop.setAirdropState(true);

        uint256 userBalanceBefore = token.balanceOf(user1);
        uint256 contractBalanceBefore = token.balanceOf(address(airdrop));

        vm.prank(user1);
        airdrop.claimAirdrop(airdropAmounts[user1], merkleProof);

        // Verify balances after claim
        assertEq(token.balanceOf(user1), userBalanceBefore + airdropAmounts[user1]);
        assertEq(token.balanceOf(address(airdrop)), contractBalanceBefore - airdropAmounts[user1]);
        assertTrue(airdrop.claimed(user1));
    }

    function test_ClaimAirdrop_RevertWhenAlreadyClaimed() public {
        vm.prank(owner);
        airdrop.setAirdropState(true);

        // First claim
        vm.prank(user1);
        airdrop.claimAirdrop(airdropAmounts[user1], merkleProof);

        // Try to claim again
        vm.prank(user1);
        vm.expectRevert("ChainbaseAirdrop: Airdrop already claimed");
        airdrop.claimAirdrop(airdropAmounts[user1], merkleProof);
    }

    function test_ClaimAirdrop_RevertWhenInvalidAmount() public {
        vm.prank(owner);
        airdrop.setAirdropState(true);

        vm.prank(user1);
        vm.expectRevert("ChainbaseAirdrop: Invalid merkle proof");
        airdrop.claimAirdrop(150 ether, merkleProof); // Wrong amount
    }

    function test_ClaimAirdrop_RevertWhenWrongUser() public {
        vm.prank(owner);
        airdrop.setAirdropState(true);

        vm.prank(user2); // Wrong user trying to use user1's proof
        vm.expectRevert("ChainbaseAirdrop: Invalid merkle proof");
        airdrop.claimAirdrop(airdropAmounts[user1], merkleProof);
    }

    // Helper function to generate merkle root
    function _generateRoot(bytes32[] memory _leaves) internal pure returns (bytes32) {
        require(_leaves.length > 0, "Empty leaves");

        bytes32[] memory currentLevel = _leaves;

        while (currentLevel.length > 1) {
            bytes32[] memory nextLevel = new bytes32[]((currentLevel.length + 1) / 2);

            for (uint256 i = 0; i < nextLevel.length; i++) {
                uint256 leftIndex = i * 2;
                uint256 rightIndex = leftIndex + 1;
                bytes32 left = currentLevel[leftIndex];
                bytes32 right = rightIndex < currentLevel.length ? currentLevel[rightIndex] : left;
                nextLevel[i] = keccak256(abi.encodePacked(left, right));
            }

            currentLevel = nextLevel;
        }

        return currentLevel[0];
    }

    // Helper function to generate merkle proof
    function _generateProof(bytes32[] memory _leaves, uint256 index) internal pure returns (bytes32[] memory) {
        require(index < _leaves.length, "Index out of bounds");

        uint256 numLevels = 0;
        uint256 levelCount = _leaves.length;
        while (levelCount > 1) {
            levelCount = (levelCount + 1) / 2;
            numLevels++;
        }

        bytes32[] memory proof = new bytes32[](numLevels);
        uint256 currentIndex = index;
        bytes32[] memory currentLevel = _leaves;

        for (uint256 i = 0; i < numLevels; i++) {
            uint256 levelSize = currentLevel.length;
            bytes32[] memory nextLevel = new bytes32[]((levelSize + 1) / 2);

            for (uint256 j = 0; j < levelSize; j += 2) {
                uint256 k = j / 2;
                if (j + 1 < levelSize) {
                    nextLevel[k] = keccak256(abi.encodePacked(currentLevel[j], currentLevel[j + 1]));
                } else {
                    nextLevel[k] = keccak256(abi.encodePacked(currentLevel[j], currentLevel[j]));
                }
            }

            uint256 pairIndex = currentIndex % 2 == 0 ? currentIndex + 1 : currentIndex - 1;
            if (pairIndex < levelSize) {
                proof[i] = currentLevel[pairIndex];
            } else {
                proof[i] = currentLevel[currentIndex];
            }

            currentIndex /= 2;
            currentLevel = nextLevel;
        }

        return proof;
    }
}

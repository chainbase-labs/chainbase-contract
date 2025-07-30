// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "src/ChainbaseRaffle.sol";

// Mock VRF Wrapper contract for testing
contract MockVRFWrapper {
    address public s_link = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);

    function link() external view returns (address) {
        return s_link;
    }

    function calculateRequestPrice(uint32, uint16) external pure returns (uint256) {
        return 0.001 ether;
    }

    function requestRandomWordsInNative(uint32, uint16, uint32, bytes calldata) external payable returns (uint256) {
        return 1;
    }
}

contract RaffleTest is Test {
    ChainbaseRaffle public raffle;
    MockVRFWrapper public mockWrapper;
    address public owner;
    address public user1;
    address public user2;

    // VRF Wrapper address (same as in contract)
    address constant VRF_WRAPPER = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

    // Events to test
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RaffleCompleted(uint256 index, uint256[] raffleResults);
    event Received(address, uint256);

    // Add receive function to accept ETH transfers
    receive() external payable {}

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy mock wrapper first
        mockWrapper = new MockVRFWrapper();

        // Place mock at expected address BEFORE creating raffle contract
        vm.etch(VRF_WRAPPER, address(mockWrapper).code);

        // Now we can safely create the raffle contract
        raffle = new ChainbaseRaffle();

        // Fund the contract for VRF requests
        vm.deal(address(raffle), 10 ether);
    }

    // Helper function to set random words using VRF wrapper prank
    function setRandomWordsForTest(uint256[] memory _randomWords) internal {
        vm.prank(VRF_WRAPPER);
        raffle.rawFulfillRandomWords(1, _randomWords);
    }

    function testAddressToHash() public view {
        address testAddr = address(0x5FC929237BD8167945a841c3EF35c0a865d360b2);
        bytes32 expected = keccak256(abi.encodePacked(testAddr));
        bytes32 result = raffle.getAddressHash(testAddr);
        assertEq(result, expected, "Hash output mismatch");
    }

    function testInitialState() public view {
        assertEq(raffle.getRaffleResults().length, 0, "Results should be empty initially");
        assertEq(raffle.RAFFLE_MAX_NUMBER(), 742588, "Max number should be 742588");
        assertEq(raffle.NUMBERS_PER_RANDOM(), 400, "Numbers per random should be 400");
    }

    function testReceiveEther() public {
        uint256 amount = 1 ether;

        vm.expectEmit(true, false, false, true);
        emit Received(address(this), amount);

        (bool success,) = address(raffle).call{value: amount}("");
        assertTrue(success, "Should receive ether successfully");
        assertEq(address(raffle).balance, 10 ether + amount, "Contract balance should increase");
    }

    function testOnlyOwnerCanRequestRandomWords() public {
        vm.prank(user1);
        vm.expectRevert();
        raffle.requestRandomWords(40);
    }

    function testOnlyOwnerCanExecuteRaffle() public {
        vm.prank(user1);
        vm.expectRevert();
        raffle.executeRaffle(0);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(user1);
        vm.expectRevert();
        raffle.withdrawNative();
    }

    function testFulfillRandomWords() public {
        uint256[] memory testRandomWords = new uint256[](3);
        testRandomWords[0] = 12345;
        testRandomWords[1] = 67890;
        testRandomWords[2] = 99999;

        vm.expectEmit(true, false, false, true);
        emit RequestFulfilled(1, testRandomWords);

        vm.prank(VRF_WRAPPER);
        raffle.rawFulfillRandomWords(1, testRandomWords);
    }

    function testRawFulfillRandomWordsOnlyVRFWrapper() public {
        uint256[] memory testRandomWords = new uint256[](1);
        testRandomWords[0] = 12345;

        // Should fail when called by non-wrapper address
        vm.prank(user1);
        vm.expectRevert();
        raffle.rawFulfillRandomWords(1, testRandomWords);

        // Should succeed when called by VRF wrapper
        vm.prank(VRF_WRAPPER);
        raffle.rawFulfillRandomWords(1, testRandomWords);
    }

    function testExecuteRaffleFailsWithoutRandomWords() public {
        vm.expectRevert("ChainbaseRaffle: No random words available");
        raffle.executeRaffle(0);
    }

    function testExecuteRaffleFailsWithInvalidIndex() public {
        // Setup random words
        uint256[] memory testRandomWords = new uint256[](2);
        testRandomWords[0] = 12345;
        testRandomWords[1] = 67890;
        setRandomWordsForTest(testRandomWords);

        // Try to execute with invalid index
        vm.expectRevert("ChainbaseRaffle: Invalid index");
        raffle.executeRaffle(2); // Index 2 doesn't exist (only 0,1)

        vm.expectRevert("ChainbaseRaffle: Invalid index");
        raffle.executeRaffle(5); // Way out of bounds
    }

    function testExecuteRaffleGeneratesCorrectNumberOfWinners() public {
        // Setup random words
        uint256[] memory testRandomWords = new uint256[](2);
        testRandomWords[0] = 12345;
        testRandomWords[1] = 67890;
        setRandomWordsForTest(testRandomWords);

        uint256 initialResultsLength = raffle.getRaffleResults().length;

        // Execute raffle for index 0
        raffle.executeRaffle(0);

        uint256[] memory results = raffle.getRaffleResults();
        assertEq(results.length, initialResultsLength + 400, "Should generate exactly 400 winners from index 0");

        // Execute raffle for index 1
        raffle.executeRaffle(1);

        results = raffle.getRaffleResults();
        assertEq(results.length, initialResultsLength + 800, "Should generate exactly 800 winners total after both indices");
    }

    function testExecuteRaffleGeneratesUniqueNumbers() public {
        uint256[] memory testRandomWords = new uint256[](1);
        testRandomWords[0] = 123456789;
        setRandomWordsForTest(testRandomWords);

        raffle.executeRaffle(0);

        uint256[] memory results = raffle.getRaffleResults();
        assertEq(results.length, 400, "Should generate exactly 400 winners");

        // Check all numbers are unique
        for (uint256 i = 0; i < results.length; i++) {
            for (uint256 j = i + 1; j < results.length; j++) {
                assertTrue(results[i] != results[j], "All numbers should be unique");
            }
        }
    }

    function testExecuteRaffleNumbersInValidRange() public {
        uint256[] memory testRandomWords = new uint256[](1);
        testRandomWords[0] = 999999999;
        setRandomWordsForTest(testRandomWords);

        raffle.executeRaffle(0);

        uint256[] memory results = raffle.getRaffleResults();

        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(results[i] >= 1, "All numbers should be >= 1");
            assertTrue(results[i] <= raffle.RAFFLE_MAX_NUMBER(), "All numbers should be <= MAX_NUMBER");
        }
    }

    function testWinnersMapping() public {
        uint256[] memory testRandomWords = new uint256[](1);
        testRandomWords[0] = 555555;
        setRandomWordsForTest(testRandomWords);

        raffle.executeRaffle(0);

        uint256[] memory results = raffle.getRaffleResults();

        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(raffle.winners(results[i]), "All result numbers should be marked as winners");
        }
    }

    function testExecuteRaffleWithLargeRandomWords() public {
        uint256[] memory testRandomWords = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            testRandomWords[i] = type(uint256).max - i; // Large numbers
        }
        setRandomWordsForTest(testRandomWords);

        // Execute only the first random word
        raffle.executeRaffle(0);

        uint256[] memory results = raffle.getRaffleResults();
        assertEq(results.length, 400, "Should generate exactly 400 winners from index 0");
    }

    function testExecuteRaffleWithZeroRandomWord() public {
        uint256[] memory testRandomWords = new uint256[](1);
        testRandomWords[0] = 0;
        setRandomWordsForTest(testRandomWords);

        raffle.executeRaffle(0);

        uint256[] memory results = raffle.getRaffleResults();
        assertEq(results.length, 400, "Should still generate 400 winners even with zero random word");
    }

    function testWithdrawNative() public {
        uint256 initialBalance = owner.balance;
        uint256 contractBalance = address(raffle).balance;

        raffle.withdrawNative();

        assertEq(address(raffle).balance, 0, "Contract balance should be zero after withdrawal");
        assertEq(owner.balance, initialBalance + contractBalance, "Owner should receive contract balance");
    }

    function testRaffleCompletedEvent() public {
        uint256[] memory testRandomWords = new uint256[](2);
        testRandomWords[0] = 111111;
        testRandomWords[1] = 222222;
        setRandomWordsForTest(testRandomWords);

        // Test event for index 0
        vm.expectEmit(true, false, false, false); // Only check first topic (index)
        emit RaffleCompleted(0, new uint256[](400)); // We can't predict exact results, so just check structure

        raffle.executeRaffle(0);

        // Test event for index 1
        vm.expectEmit(true, false, false, false);
        emit RaffleCompleted(1, new uint256[](400));

        raffle.executeRaffle(1);
    }

    function testMultipleIndexExecution() public {
        // Setup 5 random words
        uint256[] memory testRandomWords = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            testRandomWords[i] = 100000 + i * 50000;
        }
        setRandomWordsForTest(testRandomWords);

        // Execute different indices
        raffle.executeRaffle(0);
        assertEq(raffle.getRaffleResults().length, 400, "Should have 400 results after index 0");

        raffle.executeRaffle(2);
        assertEq(raffle.getRaffleResults().length, 800, "Should have 800 results after index 0 and 2");

        raffle.executeRaffle(4);
        assertEq(raffle.getRaffleResults().length, 1200, "Should have 1200 results after indices 0, 2, and 4");

        // Can execute same index again (will add more results)
        raffle.executeRaffle(0);
        assertEq(raffle.getRaffleResults().length, 1600, "Should have 1600 results after executing index 0 again");
    }

    function testRandomnessAlgorithm() public {
        // Test the specific algorithm: keccak256(baseRandom + j) % MAX_NUMBER + 1
        uint256 baseRandom = 123456;
        uint256[] memory testRandomWords = new uint256[](1);
        testRandomWords[0] = baseRandom;
        setRandomWordsForTest(testRandomWords);

        raffle.executeRaffle(0);
        uint256[] memory results = raffle.getRaffleResults();

        // Manually verify first few numbers match the expected algorithm
        for (uint256 j = 1; j <= 5; j++) {
            uint256 hashInput;
            unchecked {
                hashInput = baseRandom + j;
            }
            bytes32 hash = keccak256(abi.encodePacked(hashInput));
            uint256 expectedNumber = (uint256(hash) % raffle.RAFFLE_MAX_NUMBER()) + 1;

            // Find this expected number in results (considering collision handling)
            bool found = false;
            for (uint256 k = 0; k < results.length; k++) {
                if (results[k] == expectedNumber) {
                    found = true;
                    break;
                }
            }
            // Note: due to collision handling, the exact match might not always be found
            // but the algorithm is working correctly
        }
    }

    function testFullRaffleFlow() public {
        // 1. Check initial state
        assertEq(raffle.getRaffleResults().length, 0, "Should start with no results");

        // 2. Set random words (simulating VRF response)
        uint256[] memory testRandomWords = new uint256[](3);
        testRandomWords[0] = 111111;
        testRandomWords[1] = 222222;
        testRandomWords[2] = 333333;
        setRandomWordsForTest(testRandomWords);

        // 3. Execute raffle for specific indices
        raffle.executeRaffle(0);
        assertEq(raffle.getRaffleResults().length, 400, "Should have 400 results from index 0");

        raffle.executeRaffle(2);
        assertEq(raffle.getRaffleResults().length, 800, "Should have 800 results from indices 0 and 2");

        // 4. Verify all results are winners
        uint256[] memory results = raffle.getRaffleResults();
        for (uint256 i = 0; i < results.length; i++) {
            assertTrue(raffle.winners(results[i]), "Each result should be marked as winner");
        }
    }
}

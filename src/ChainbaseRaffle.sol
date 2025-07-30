// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";

contract ChainbaseRaffle is VRFV2PlusWrapperConsumerBase, Ownable {
    //=========================================================================
    //                                CONSTANT
    //=========================================================================
    // You can download raffle participant address Keccak-256 hash list file from IPFS and verify hash at https://emn178.github.io/online-tools/sha256_checksum.html
    string public constant RAFFLE_PARTICIPANTS_IPFS_LINK =
        "https://gateway.pinata.cloud/ipfs/QmZafRU3Xf6KLJg7fw9jHpcfv3GBT7dBgQ79QYuEeGxerh";
    bytes32 public constant RAFFLE_PARTICIPANTS_FILE_HASH =
        0xb8eb100af08bc79a9b4a280cd1ac577f276c47cfd4a91058bbaad12de12d821e;
    uint256 public constant RAFFLE_MAX_NUMBER = 742588;
    uint256 public constant NUMBERS_PER_RANDOM = 400;
    // Chainlink VRF constants
    uint32 public constant CALLBACK_GAS_LIMIT = 1000000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    address public constant WRAPPER_ADDRESS = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

    //=========================================================================
    //                                STORAGE
    //=========================================================================
    uint256[] public randomWords;
    uint256[] public raffleResults;
    mapping(uint256 => bool) public winners;

    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event Received(address, uint256);
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RaffleCompleted(uint256 index, uint256[] raffleResults);

    //=========================================================================
    //                                CONSTRUCTOR
    //=========================================================================
    constructor() VRFV2PlusWrapperConsumerBase(WRAPPER_ADDRESS) {}

    //=========================================================================
    //                                 MANAGE
    //=========================================================================
    function withdrawNative() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = payable(owner()).call{value: amount}("");
        require(success, "ChainbaseRaffle: WithdrawNative failed");
    }

    function requestRandomWords(uint32 numWords) external onlyOwner returns (uint256) {
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}));
        uint256 requestId;
        uint256 reqPrice;
        (requestId, reqPrice) =
            requestRandomnessPayInNative(CALLBACK_GAS_LIMIT, REQUEST_CONFIRMATIONS, numWords, extraArgs);
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function executeRaffle(uint256 index) external onlyOwner {
        require(randomWords.length > 0, "ChainbaseRaffle: No random words available");
        require(index < randomWords.length, "ChainbaseRaffle: Invalid index");

        uint256 baseRandom = randomWords[index];
        uint256[] memory currentResults = new uint256[](NUMBERS_PER_RANDOM);

        // Generate numbers from the specified random word
        for (uint256 j = 1; j <= NUMBERS_PER_RANDOM; j++) {
            bytes32 hash;
            unchecked {
                // Allow overflow for randomness, it's actually beneficial for entropy
                hash = keccak256(abi.encodePacked(baseRandom + j));
            }
            uint256 number = (uint256(hash) % RAFFLE_MAX_NUMBER) + 1;

            // If number is already selected, find next available number
            while (winners[number]) {
                number = (number % RAFFLE_MAX_NUMBER) + 1;
            }

            // Mark number as winner and add to results
            winners[number] = true;
            raffleResults.push(number);
            currentResults[j - 1] = number;
        }

        emit RaffleCompleted(index, currentResults);
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    function getAddressHash(address addr) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(addr));
    }

    function getRaffleResults() external view returns (uint256[] memory) {
        return raffleResults;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

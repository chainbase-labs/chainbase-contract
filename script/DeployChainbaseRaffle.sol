// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/ChainbaseRaffle.sol";

contract DeployChainbaseRaffle is Script {
    // forge script script/DeployChainbaseRaffle.sol:DeployChainbaseRaffle --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy contract
        ChainbaseRaffle raffle = new ChainbaseRaffle();
        console.log("ChainbaseRaffle deployed to:", address(raffle));

        // Transfer 0.01 ETH to contract for chainlink VRF request
        uint256 fundAmount = 0.01 ether;
        (bool success,) = payable(address(raffle)).call{value: fundAmount}("");
        require(success, "Failed to transfer ETH to contract");
        console.log("Contract balance:", address(raffle).balance);

        // Request 10 random words
        console.log("Requesting 10 random words...");
        uint256 requestId = raffle.requestRandomWords(10);
        console.log("VRF request sent with ID:", requestId);

        vm.stopBroadcast();
    }
}

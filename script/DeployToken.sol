// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ChainbaseToken.sol";

contract DeployToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        require(deployerPrivateKey != 0, "Private key is not set in the environment");

        vm.startBroadcast(deployerPrivateKey);

        ChainbaseToken chainbaseToken = new ChainbaseToken();
        require(address(chainbaseToken) != address(0), "Deployment failed");
        console.log("Chainbase Token deployed to:", address(chainbaseToken));

        vm.stopBroadcast();
    }
}

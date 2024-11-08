// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/ChainbaseToken.sol";

contract DeployToken is Script {
    //forge script script/DeployToken.sol:DeployToken --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        ChainbaseToken C = new ChainbaseToken();
        console.log("Chainbase Token deployed to:", address(C));

        vm.stopBroadcast();
    }
}

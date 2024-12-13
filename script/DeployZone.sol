// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/Zone.sol";

contract DeployZone is Script {
    //forge script script/DeployZone.sol:DeployZone --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Zone zone = new Zone("TestZone", "TZ", "");
        console.log("Zone deployed to:", address(zone));

        vm.stopBroadcast();
    }
}

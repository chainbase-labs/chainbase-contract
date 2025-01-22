// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/Zone.sol";

contract DeployZone is Script {
    //forge script script/DeployZone.sol:DeployZone --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Zone zone1 = new Zone("StableCoin", "SC", "https://images.chainbase.online/zones/Stablecoin.json");
        console.log("Zone deployed to:", address(zone1));

        Zone zone2 = new Zone("Balance", "B", "https://images.chainbase.online/zones/Balance.json");
        console.log("Zone deployed to:", address(zone2));

        Zone zone3 = new Zone("Transfer", "T", "https://images.chainbase.online/zones/Transfer.json");
        console.log("Zone deployed to:", address(zone3));

        vm.stopBroadcast();
    }
}

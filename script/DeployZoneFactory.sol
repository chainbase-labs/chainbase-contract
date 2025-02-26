// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/zone/ZoneFactory.sol";

contract DeployZoneFactory is Script {
    //forge script script/DeployZoneFactory.sol:DeployZoneFactory --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address zoneFactoryImplementation = address(new ZoneFactory());

        ProxyAdmin zoneFactoryProxyAdmin = new ProxyAdmin();
        console.log("ZoneFactory proxy admin deployed to:", address(zoneFactoryProxyAdmin));

        // Deploy the proxy contract
        TransparentUpgradeableProxy zoneFactoryProxy = new TransparentUpgradeableProxy(
            zoneFactoryImplementation,
            address(zoneFactoryProxyAdmin),
            abi.encodeWithSelector(ZoneFactory.initialize.selector, vm.addr(deployerPrivateKey))
        );

        console.log("ZoneFactory proxy deployed to:", address(zoneFactoryProxy));

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/staking/Staking.sol";

contract DeployStaking is Script {
    //forge script script/DeployStaking.sol:DeployStaking --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address cTokenAddress = address(0x21b09d2a0baC5B55AfCE96A7d0f3711e59711Feb);
        address stakingImplementation = address(new Staking(cTokenAddress));

        ProxyAdmin stakingProxyAdmin = new ProxyAdmin();
        console.log("Staking proxy admin deployed to:", address(stakingProxyAdmin));

        // Deploy the proxy contract
        TransparentUpgradeableProxy stakingProxy = new TransparentUpgradeableProxy(
            stakingImplementation,
            address(stakingProxyAdmin),
            abi.encodeWithSelector(Staking.initialize.selector, msg.sender)
        );

        console.log("Staking proxy deployed to:", address(stakingProxy));

        vm.stopBroadcast();
    }
}
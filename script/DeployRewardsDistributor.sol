// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/reward/RewardsDistributor.sol";

contract DeployRewardsDistributor is Script {
    // forge script script/DeployRewardsDistributor.sol:DeployRewardsDistributor --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // address cTokenAddress = address(0x21b09d2a0baC5B55AfCE96A7d0f3711e59711Feb); // mainnet
        // address cTokenAddress = address(0x911bb6Fee00AE3ca3943Ea8AE7f571151BC78f67); // holesky
        // address cTokenAddress = address(0xe30a02dF61b661140938b8e0B910CD81b466A46b); // chainbase testnet
        address cTokenAddress = address(0xA1f8B99b010c72201d149EFBDC38b88b342E7C18); //  base_sepolia
        address rewardsDistributorImplementation = address(new RewardsDistributor(cTokenAddress));

        ProxyAdmin rewardsDistributorProxyAdmin = new ProxyAdmin();
        console.log("RewardsDistributor proxy admin deployed to:", address(rewardsDistributorProxyAdmin));

        // Deploy the proxy contract
        TransparentUpgradeableProxy rewardsDistributorProxy = new TransparentUpgradeableProxy(
            rewardsDistributorImplementation,
            address(rewardsDistributorProxyAdmin),
            abi.encodeWithSelector(
                RewardsDistributor.initialize.selector,
                vm.addr(deployerPrivateKey)
            )
        );

        console.log("RewardsDistributor proxy deployed to:", address(rewardsDistributorProxy));

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/reward/RewardsDistributor.sol";

contract UpgradeRewardDistributor is Script {
    // forge script script/UpgradeRewardDistributor.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
    // forge script script/UpgradeRewardDistributor.sol --rpc-url $RPC_URL --broadcast --verify --verifier blockscout --verifier-url https://testnet.explorer.chainbase.com/api/ -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // chainbase testnet
        address proxyAdmin = address(0x00Ea5021c00040D0d01fd574a9dCc5a3063C9F48);
        address rewardDistributorProxy = address(0x6F9100EdF5DE1E35E775E61F40335721A2Eaf79A);
        address cTokenAddress = address(0xe30a02dF61b661140938b8e0B910CD81b466A46b);
        RewardsDistributor newImplementation = new RewardsDistributor(cTokenAddress);

        ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(rewardDistributorProxy), address(newImplementation));

        vm.stopBroadcast();
    }
}

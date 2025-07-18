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
        address proxyAdmin = address(0x6a9e75a741277199E27c93d544a32a6650638c85);
        address rewardDistributorProxy = address(0xe1186578D2fDc5Ed16f25840562cF9F3395c1ddC);
        address cTokenAddress = address(0xA1f8B99b010c72201d149EFBDC38b88b342E7C18);
        RewardsDistributor newImplementation = new RewardsDistributor(cTokenAddress);

        ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(rewardDistributorProxy), address(newImplementation));

        vm.stopBroadcast();
    }
}

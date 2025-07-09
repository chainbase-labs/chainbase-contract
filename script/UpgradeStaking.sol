// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/staking/Staking.sol";

contract UpgradeStaking is Script {
    // forge script script/UpgradeStaking.sol --rpc-url $RPC_URL --broadcast --verify -vvvv
    // forge script script/UpgradeStaking.sol --rpc-url $RPC_URL --broadcast --verify --verifier blockscout --verifier-url https://testnet.explorer.chainbase.com/api/ -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // chainbase testnet
        address proxyAdmin = address(0xBf3A61fC96EDcd86AF764C117dcB55465110886a);
        address stakingProxy = address(0x0035F5dfC849d95732E0F5be5d2c354e3772f4d0);
        address cTokenAddress = address(0xA1f8B99b010c72201d149EFBDC38b88b342E7C18);
        Staking newImplementation = new Staking(cTokenAddress);

        ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(stakingProxy), address(newImplementation));

        vm.stopBroadcast();
    }
}

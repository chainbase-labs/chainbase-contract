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
        address proxyAdmin = address(0x0AA732Db3691b59881D6f1d1A86E65F3a44aaF8c);
        address stakingProxy = address(0x721b03DF571aFd7CE5702176cF5979d1d863B815);
        address cTokenAddress = address(0xe30a02dF61b661140938b8e0B910CD81b466A46b);
        Staking newImplementation = new Staking(cTokenAddress);

        ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(stakingProxy), address(newImplementation));

        vm.stopBroadcast();
    }
}

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
        address proxyAdmin = address(0xB1398C69F02B9550D02033D217A05A64E1412124);
        address stakingProxy = address(0x957c914E71179215672635B435162F1e582b9Df0);
        address cTokenAddress = address(0xF494b1883F029D8172d192D8074e5e82F1F9dAe7);
        Staking newImplementation = new Staking(cTokenAddress);

        ProxyAdmin(proxyAdmin).upgrade(ITransparentUpgradeableProxy(stakingProxy), address(newImplementation));

        vm.stopBroadcast();
    }
}

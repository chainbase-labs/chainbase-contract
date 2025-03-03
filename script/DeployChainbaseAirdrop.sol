// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/ChainbaseAirdrop.sol";

contract DeployChainbaseAirdrop is Script {
    //forge script script/DeployChainbaseAirdrop.sol:DeployChainbaseAirdrop --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address cTokenAddress = address(0xF494b1883F029D8172d192D8074e5e82F1F9dAe7); //  base_sepolia
        ChainbaseAirdrop airdrop = new ChainbaseAirdrop(cTokenAddress, "");
        console.log("ChainbaseAirdrop deployed to:", address(airdrop));

        vm.stopBroadcast();
    }
}

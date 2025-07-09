// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/ChainbaseAirdrop.sol";
import "../src/staking/Staking.sol";

contract DeployAirdropStaking is Script {
    //forge script script/DeployAirdropStaking.sol:DeployAirdropStaking --rpc-url $RPC_URL --broadcast --verify -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address cTokenAddress = address(0xA1f8B99b010c72201d149EFBDC38b88b342E7C18); //  base_sepolia
        ChainbaseAirdrop airdrop = new ChainbaseAirdrop(cTokenAddress, "");
//        ChainbaseAirdrop airdrop = ChainbaseAirdrop(address(0x6E6664d74F1180926Ac2DEe0d3e71B3c684cb4d3));
        console.log("ChainbaseAirdrop deployed to:", address(airdrop));

        address stakingImplementation = address(new Staking(cTokenAddress));

        ProxyAdmin stakingProxyAdmin = new ProxyAdmin();
        console.log("Staking proxy admin deployed to:", address(stakingProxyAdmin));

        // Deploy the proxy contract
        TransparentUpgradeableProxy stakingProxy = new TransparentUpgradeableProxy(
            stakingImplementation,
            address(stakingProxyAdmin),
            abi.encodeWithSelector(Staking.initialize.selector, address(airdrop))
        );

        Staking staking = Staking(address(stakingProxy));
        staking.transferOwnership(vm.addr(deployerPrivateKey));

        console.log("Staking proxy deployed to:", address(stakingProxy));

        airdrop.setStakingContract(address(stakingProxy));

        vm.stopBroadcast();
    }
}

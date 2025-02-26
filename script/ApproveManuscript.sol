// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/zone/Zone.sol";

contract ApproveManuscript is Script {
    //forge script script/ApproveManuscript.sol:ApproveManuscript --rpc-url $RPC_URL --broadcast -vvvv
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Zone stableCoinZone = Zone(address(0x0AA732Db3691b59881D6f1d1A86E65F3a44aaF8c));
        Zone balanceZone = Zone(address(0x721b03DF571aFd7CE5702176cF5979d1d863B815));
        Zone transferZone = Zone(address(0xD985763b49d1C4Ec75acD6179F2FA377D4a709fC));

        bytes32[] memory manuscriptHashes = new bytes32[](2);
        manuscriptHashes[0] = bytes32(0xBDBBF0929F4AE78C4ABC5DC541B11742E5F99858CC575FA60F5E6BD0222C66CC);
        manuscriptHashes[1] = bytes32(0x505242F79B1243202C43482F082FC24B2D3F304216ACB409C2778A2AA72064DD);

        bool[] memory approvals = new bool[](2);
        approvals[0] = true;
        approvals[1] = true;

        stableCoinZone.approveManuscripts(manuscriptHashes, approvals);

        manuscriptHashes = new bytes32[](14);
        manuscriptHashes[0] = bytes32(0x7f4efc7e746361ae3b04e18461da608687d4267543799462d560a80178e547be);
        manuscriptHashes[1] = bytes32(0x1b3868624012615882fe5975dd9e651aaa2cdd17e60dbf517ab14f6b5614672d);
        manuscriptHashes[2] = bytes32(0x2ddad0a5c81c7423b005be8d4c5f6dba7cf6f43a9614adcf3a52a0dadc38d6ec);
        manuscriptHashes[3] = bytes32(0xbf8217f91ce66a38dbba5cbde168ae0ee6bdb487afdb0c4290bbe899ba07aa85);
        manuscriptHashes[4] = bytes32(0xb70a48f4b1c76665bc5b6350fe87025d2f5a49f0baba12dbb7a148c0bbfd234c);
        manuscriptHashes[5] = bytes32(0x554d42838425b3f3f9df2b0a6febb64063de2b54c39e151af0d3780efa5c8e22);
        manuscriptHashes[6] = bytes32(0x6deadd1cd6beda0edfc743c67f1c3599f0962d39a4b87d49a46e53c546a2f539);
        manuscriptHashes[7] = bytes32(0x5bf5c082e259b3f6904a756833bc937c280faa11b660fc9a48bca7476d9ab050);
        manuscriptHashes[8] = bytes32(0xa9b4d38ebf76a6dd0b756051c45f3807aff08f28970c06c05252c5827db325e8);
        manuscriptHashes[9] = bytes32(0x089ac0e47ca2d1ec6d6e393416bda29ce452c87e259c4f7617794fa774aef64d);
        manuscriptHashes[10] = bytes32(0xbc4f6b576ddcaf721f4a412e4efc77cc4117a04eb7e31c8e41de6246b44c0f2e);
        manuscriptHashes[11] = bytes32(0x5e98422f837ca71c3ec648e401ad27a658b19b354f881cfe46eccdbcd417ea4a);
        manuscriptHashes[12] = bytes32(0x1590c3dc995a2cdd0ed3cc3d2b0852cb7f1f233728228eab7e313b32693eca40);
        manuscriptHashes[13] = bytes32(0x2bddce760e5ff300e0d187a46643ed41a8082dab5ac84e68e6c69bee793362ca);

        approvals = new bool[](14);
        approvals[0] = true;
        approvals[1] = true;
        approvals[2] = true;
        approvals[3] = true;
        approvals[4] = true;
        approvals[5] = true;
        approvals[6] = true;
        approvals[7] = true;
        approvals[8] = true;
        approvals[9] = true;
        approvals[10] = true;
        approvals[11] = true;
        approvals[12] = true;
        approvals[13] = true;

        balanceZone.approveManuscripts(manuscriptHashes, approvals);

        manuscriptHashes = new bytes32[](25);
        manuscriptHashes[0] = bytes32(0x82af40283257c1811e1251ee44746b4042f6dba7bccfc8fce10bc88c777a93dd);
        manuscriptHashes[1] = bytes32(0xd383c2c1e7b1fdfc4f40ab9ed16a64742551d97a44d9558e5ba264dbc24c2f49);
        manuscriptHashes[2] = bytes32(0xaa02b9fb56464aebb72e3affc8c0cf0098f21b71a16edbe5dfdba585ca235a1f);
        manuscriptHashes[3] = bytes32(0xe6a9229d54ef21cdf3883710e0471b7172b1aec0d900c450047286f9e71a797e);
        manuscriptHashes[4] = bytes32(0x5e43e4a0b006edffffa7aa271003406af5b88813883581e7c6ce646df43fae1c);
        manuscriptHashes[5] = bytes32(0x3f238782e2d1fe530275be7a0117362f72060a5203357411a0e9e5370f64e5c0);
        manuscriptHashes[6] = bytes32(0x1c76043499a0f085c41e899c07542bb29e00ca847f57f6fb2cfe8c0ece1fb75f);
        manuscriptHashes[7] = bytes32(0x8117940139ecd759bcd1d46dd32450cdca74401a9786a549378d9a358402c940);
        manuscriptHashes[8] = bytes32(0x06180bc8597f6bddf9face146778f27ed6b42f0e2ad0af65f3ec772479f0f274);
        manuscriptHashes[9] = bytes32(0x54bb61685cae8dcb6c82d9ac14bcea30133ef56b778691be9cb0cc562fe4298e);
        manuscriptHashes[10] = bytes32(0xa781ed8dcf9065526d7882a9db3854c1061dc955f538eeff122a9f171d2cd8b2);
        manuscriptHashes[11] = bytes32(0xf121d49233a44a600cc06f74f65ec224e3910baa345ad5ae3ed52391f0a5f2fe);
        manuscriptHashes[12] = bytes32(0x7511c2d4b9a4bfdd6b7d8da7675fe27ba9ec29c4437406d3f5633c945b294d9a);
        manuscriptHashes[13] = bytes32(0x77999ef0b8579302b62702162aba2665922d38a2f86bd4f86fc5dd3284b17294);
        manuscriptHashes[14] = bytes32(0x59cec783959861891222b72e3a5ce0a86a5f36ec2e96ca625b4a687bbb2dc087);
        manuscriptHashes[15] = bytes32(0x1354f7ba09c8932ca38f301aac041dbbd880e4262d105e1f238677892fdd1ead);
        manuscriptHashes[16] = bytes32(0x94e6e9913fa143a53572fa75f0382989b655dba3bf02b358d335e9749dffb81e);
        manuscriptHashes[17] = bytes32(0x23f5df632201ca9afeda70a0b402b5d5c50c70a6bdf5d2f03fce57ea3ade4b77);
        manuscriptHashes[18] = bytes32(0xea32055c2db3c1bd0f8d787fcbd5e1e74f62770606451d2030db656f7d7e111f);
        manuscriptHashes[19] = bytes32(0xef42369ff546d38e261f30cd13dabe840fb3c8260fd8d03040838e8e6cb04ba3);
        manuscriptHashes[20] = bytes32(0xe53789c2fc12c11eb80173432a49dc557c4ce33e7273f4bd817e58b82d99c7da);
        manuscriptHashes[21] = bytes32(0x6ef977eb801c8883a978e90baed15b8cc70dd3cb6120aed744f8cf7d2956ff22);
        manuscriptHashes[22] = bytes32(0x4acb370b05dd6e8edb51c03a2dcb373606454a0a3db175ef488b6d46c90843aa);
        manuscriptHashes[23] = bytes32(0x5d3eb6c6e6729fdd68bed8f9562ced036c36f65d79d82eee4c8c02acdbe8e9e4);
        manuscriptHashes[24] = bytes32(0xab5208296f4ead6cad174d12c0bf21d44395bd060d55109d0f8774fd23706f69);


        approvals = new bool[](25);
        approvals[0] = true;
        approvals[1] = true;
        approvals[2] = true;
        approvals[3] = true;
        approvals[4] = true;
        approvals[5] = true;
        approvals[6] = true;
        approvals[7] = true;
        approvals[8] = true;
        approvals[9] = true;
        approvals[10] = true;
        approvals[11] = true;
        approvals[12] = true;
        approvals[13] = true;
        approvals[14] = true;
        approvals[15] = true;
        approvals[16] = true;
        approvals[17] = true;
        approvals[18] = true;
        approvals[19] = true;
        approvals[20] = true;
        approvals[21] = true;
        approvals[22] = true;
        approvals[23] = true;
        approvals[24] = true;

        transferZone.approveManuscripts(manuscriptHashes, approvals);

        vm.stopBroadcast();
    }
}

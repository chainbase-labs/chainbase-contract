// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "../src/zone/ZoneFactory.sol";
import "../src/zone/Zone.sol";

contract ZoneFactoryTest is Test {
    ZoneFactory public factory;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        // Setup test accounts
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy factory contract
        vm.prank(owner);
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        address factoryImplementation = address(new ZoneFactory());
        TransparentUpgradeableProxy factoryProxy = new TransparentUpgradeableProxy(
            factoryImplementation, address(proxyAdmin), abi.encodeWithSelector(ZoneFactory.initialize.selector, owner)
        );
        factory = ZoneFactory(address(factoryProxy));
    }

    function test_Initialize() public view {
        assertEq(factory.owner(), owner);
        assertTrue(factory.whitelistEnabled());
    }

    function testFail_InitializeZeroAddress() public {
        factory = new ZoneFactory();
        factory.initialize(address(0));
    }

    function test_SetWhitelistEnabled() public {
        vm.prank(owner);
        factory.setWhitelistEnabled(false);
        assertFalse(factory.whitelistEnabled());
    }

    function testFail_SetWhitelistEnabled_NotOwner() public {
        vm.prank(user1);
        factory.setWhitelistEnabled(false);
    }

    function test_AddWhitelist() public {
        address[] memory creators = new address[](2);
        creators[0] = user1;
        creators[1] = user2;

        vm.prank(owner);
        factory.addWhitelist(creators);

        assertTrue(factory.creatorWhitelist(user1));
        assertTrue(factory.creatorWhitelist(user2));
    }

    function testFail_AddWhitelist_ZeroAddress() public {
        address[] memory creators = new address[](1);
        creators[0] = address(0);

        vm.prank(owner);
        factory.addWhitelist(creators);
    }

    function test_RemoveWhitelist() public {
        // First add to whitelist
        address[] memory creators = new address[](1);
        creators[0] = user1;

        vm.prank(owner);
        factory.addWhitelist(creators);
        assertTrue(factory.creatorWhitelist(user1));

        // Then remove from whitelist
        vm.prank(owner);
        factory.removeWhitelist(creators);
        assertFalse(factory.creatorWhitelist(user1));
    }

    function test_CreateZone() public {
        // Add user to whitelist
        address[] memory creators = new address[](1);
        creators[0] = user1;
        vm.prank(owner);
        factory.addWhitelist(creators);

        // Create Zone
        vm.prank(user1);
        address zoneAddr = factory.createZone("TestZone", "TZ", "ipfs://test");

        // Verify Zone creation
        Zone zone = Zone(zoneAddr);
        assertEq(zone.name(), "TestZone");
        assertEq(zone.symbol(), "TZ");
        assertEq(zone.owner(), user1);

        // Verify zones array update
        address[] memory allZones = factory.getAllZones();
        assertEq(allZones.length, 1);
        assertEq(allZones[0], zoneAddr);
    }

    function testFail_CreateZone_NotWhitelisted() public {
        vm.prank(user1);
        factory.createZone("TestZone", "TZ", "ipfs://test");
    }

    function test_CreateZone_WhitelistDisabled() public {
        // Disable whitelist
        vm.prank(owner);
        factory.setWhitelistEnabled(false);

        // Any user should be able to create Zone
        vm.prank(user1);
        address zoneAddr = factory.createZone("TestZone", "TZ", "ipfs://test");

        assertTrue(zoneAddr != address(0));
    }

    function test_PauseAndUnpause() public {
        vm.prank(owner);
        factory.pause();
        assertTrue(factory.paused());

        vm.prank(owner);
        factory.unpause();
        assertFalse(factory.paused());
    }

    function testFail_CreateZone_WhenPaused() public {
        // Add user to whitelist
        address[] memory creators = new address[](1);
        creators[0] = user1;
        vm.prank(owner);
        factory.addWhitelist(creators);

        // Pause contract
        vm.prank(owner);
        factory.pause();

        // Try to create Zone (should fail)
        vm.prank(user1);
        factory.createZone("TestZone", "TZ", "ipfs://test");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/Zone.sol";

contract ZoneTest is Test {
    Zone public zone;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    string constant ZONE_NAME = "TestZone";
    string constant ZONE_SYMBOL = "TZ";
    string constant ZONE_METADATA = "ipfs://zone-metadata";
    string constant MANUSCRIPT_METADATA = "ipfs://manuscript-metadata";
    string constant NEW_METADATA = "ipfs://new-metadata";

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        zone = new Zone(ZONE_NAME, ZONE_SYMBOL, ZONE_METADATA);

        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testInitialization() public view {
        assertEq(zone.name(), ZONE_NAME);
        assertEq(zone.symbol(), ZONE_SYMBOL);
        assertEq(zone.zoneMetadataURI(), ZONE_METADATA);
        assertEq(zone.nextTokenId(), 1);
        assertEq(zone.transfersEnabled(), false);
    }

    function testSetZoneMetadata() public {
        zone.setZoneMetadata(NEW_METADATA);
        assertEq(zone.zoneMetadataURI(), NEW_METADATA);
    }

    function testSetZoneMetadataByNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        zone.setZoneMetadata(NEW_METADATA);
    }

    function testSetTransfersEnabled() public {
        zone.setTransfersEnabled(true);
        assertTrue(zone.transfersEnabled());

        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        zone.setTransfersEnabled(false);

        zone.setTransfersEnabled(false);
        assertFalse(zone.transfersEnabled());
    }

    function testManuscriptSubmission() public {
        bytes32 manuscriptHash = keccak256("manuscript1");

        vm.prank(user1);
        zone.submitManuscript(manuscriptHash, MANUSCRIPT_METADATA);

        (address developer, string memory uri, Zone.ManuscriptStatus status) = zone.manuscripts(manuscriptHash);

        assertEq(developer, user1);
        assertEq(uri, MANUSCRIPT_METADATA);
        assertEq(uint256(status), uint256(Zone.ManuscriptStatus.Pending));
    }

    function testSubmitEmptyMetadata() public {
        bytes32 manuscriptHash = keccak256("manuscript1");

        vm.prank(user1);
        vm.expectRevert("Zone: Empty metadataURI");
        zone.submitManuscript(manuscriptHash, "");
    }

    function testDuplicateSubmission() public {
        bytes32 manuscriptHash = keccak256("manuscript1");

        vm.startPrank(user1);
        zone.submitManuscript(manuscriptHash, MANUSCRIPT_METADATA);

        vm.expectRevert("Zone: Manuscript already exists or was approved");
        zone.submitManuscript(manuscriptHash, MANUSCRIPT_METADATA);
        vm.stopPrank();
    }

    function testApproveManuscripts() public {
        bytes32 manuscriptHash1 = keccak256("manuscript1");
        bytes32 manuscriptHash2 = keccak256("manuscript2");
        bytes32 manuscriptHash3 = keccak256("manuscript3");

        vm.prank(user1);
        zone.submitManuscript(manuscriptHash1, MANUSCRIPT_METADATA);

        vm.prank(user2);
        zone.submitManuscript(manuscriptHash2, MANUSCRIPT_METADATA);

        vm.prank(user3);
        zone.submitManuscript(manuscriptHash3, MANUSCRIPT_METADATA);

        bytes32[] memory hashes = new bytes32[](3);
        bool[] memory approvals = new bool[](2);
        hashes[0] = manuscriptHash1;
        hashes[1] = manuscriptHash2;
        hashes[2] = manuscriptHash3;
        approvals[0] = true;
        approvals[1] = false;

        vm.expectRevert("Zone: Arrays length mismatch");
        zone.approveManuscripts(hashes, approvals);

        approvals = new bool[](3);
        approvals[0] = true;
        approvals[1] = false;
        approvals[2] = true;
        zone.approveManuscripts(hashes, approvals);

        assertEq(zone.ownerOf(1), user1);
        assertEq(zone.tokenToManuscriptHash(1), manuscriptHash1);
        assertEq(zone.manuscriptHashToTokenId(manuscriptHash1), 1);

        (,, Zone.ManuscriptStatus status) = zone.manuscripts(manuscriptHash2);
        assertEq(uint256(status), uint256(Zone.ManuscriptStatus.Rejected));

        assertEq(zone.ownerOf(2), user3);
        assertEq(zone.tokenToManuscriptHash(2), manuscriptHash3);
        assertEq(zone.manuscriptHashToTokenId(manuscriptHash3), 2);
    }

    function testSetManuscriptMetadata() public {
        bytes32 manuscriptHash = keccak256("manuscript1");

        vm.prank(user1);
        zone.submitManuscript(manuscriptHash, MANUSCRIPT_METADATA);

        vm.prank(user1);
        vm.expectRevert("Zone: Token does not exist");
        zone.setManuscriptMetadata(manuscriptHash, NEW_METADATA);

        bytes32[] memory hashes = new bytes32[](1);
        bool[] memory approvals = new bool[](1);
        hashes[0] = manuscriptHash;
        approvals[0] = true;

        zone.approveManuscripts(hashes, approvals);
        assertEq(zone.tokenURI(1), MANUSCRIPT_METADATA);

        vm.prank(user1);
        zone.setManuscriptMetadata(manuscriptHash, NEW_METADATA);

        assertEq(zone.tokenURI(1), NEW_METADATA);

        vm.prank(user2);
        vm.expectRevert("Zone: Not the owner of this NFT");
        zone.setManuscriptMetadata(manuscriptHash, NEW_METADATA);
    }

    function testGetManuscriptStatuses() public {
        bytes32 manuscriptHash1 = keccak256("manuscript1");
        bytes32 manuscriptHash2 = keccak256("manuscript2");
        bytes32 manuscriptHash3 = keccak256("manuscript3");

        vm.prank(user1);
        zone.submitManuscript(manuscriptHash1, MANUSCRIPT_METADATA);
        vm.prank(user2);
        zone.submitManuscript(manuscriptHash2, MANUSCRIPT_METADATA);

        bytes32[] memory hashes = new bytes32[](3);
        hashes[0] = manuscriptHash1;
        hashes[1] = manuscriptHash2;
        hashes[2] = manuscriptHash3;

        Zone.ManuscriptStatus[] memory statuses = zone.getManuscriptStatuses(hashes);
        assertEq(uint256(statuses[0]), uint256(Zone.ManuscriptStatus.Pending));
        assertEq(uint256(statuses[1]), uint256(Zone.ManuscriptStatus.Pending));
        assertEq(uint256(statuses[2]), uint256(Zone.ManuscriptStatus.None));

        bytes32[] memory approveHashes = new bytes32[](2);
        approveHashes[0] = manuscriptHash1;
        approveHashes[1] = manuscriptHash2;
        bool[] memory approvals = new bool[](2);
        approvals[0] = true;
        approvals[1] = false;
        zone.approveManuscripts(approveHashes, approvals);

        statuses = zone.getManuscriptStatuses(hashes);
        assertEq(uint256(statuses[0]), uint256(Zone.ManuscriptStatus.Approved));
        assertEq(uint256(statuses[1]), uint256(Zone.ManuscriptStatus.Rejected));
        assertEq(uint256(statuses[2]), uint256(Zone.ManuscriptStatus.None));
    }

    function testTransferRestriction() public {
        bytes32 manuscriptHash = keccak256("manuscript1");

        vm.prank(user1);
        zone.submitManuscript(manuscriptHash, MANUSCRIPT_METADATA);

        bytes32[] memory hashes = new bytes32[](1);
        bool[] memory approvals = new bool[](1);
        hashes[0] = manuscriptHash;
        approvals[0] = true;

        zone.approveManuscripts(hashes, approvals);

        vm.prank(user1);
        vm.expectRevert("Zone: Transfers are currently disabled");
        zone.transferFrom(user1, user2, 1);

        zone.setTransfersEnabled(true);
        vm.prank(user1);
        zone.transferFrom(user1, user2, 1);

        assertEq(zone.ownerOf(1), user2);
    }
}

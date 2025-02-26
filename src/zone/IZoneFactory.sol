// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IZoneFactory {
    //=========================================================================
    //                                 EVENT
    //=========================================================================
    event WhitelistEnabledUpdated(bool enabled);
    event WhitelistAdded(address indexed operator);
    event WhitelistRemoved(address indexed operator);
    event ZoneCreated(address indexed zone, address indexed creator);

    //=========================================================================
    //                                FUNCTIONS
    //=========================================================================
    function setWhitelistEnabled(bool enabled) external;
    function addWhitelist(address[] calldata creators) external;
    function removeWhitelist(address[] calldata creators) external;
    function createZone(string memory zoneName, string memory zoneSymbol, string memory zoneMetadataURI) external returns (address);
}

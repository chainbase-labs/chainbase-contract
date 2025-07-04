// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./Zone.sol";
import "./ZoneFactoryStorage.sol";

contract ZoneFactory is OwnableUpgradeable, PausableUpgradeable, ZoneFactoryStorage {
    //=========================================================================
    //                                INITIALIZE
    //=========================================================================
    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        whitelistEnabled = true; // Enable whitelist by default
    }

    //=========================================================================
    //                                 MANAGE
    //=========================================================================
    /**
     * @notice Set whitelist status
     * @param enabled Whether to enable whitelist
     */
    function setWhitelistEnabled(bool enabled) external onlyOwner {
        whitelistEnabled = enabled;
        emit WhitelistEnabledUpdated(enabled);
    }

    /**
     * @notice Add creators to whitelist
     * @param creators Array of creator addresses to add to whitelist
     */
    function addWhitelist(address[] calldata creators) external onlyOwner {
        for (uint256 i = 0; i < creators.length; i++) {
            require(creators[i] != address(0), "ZoneFactory: Invalid creator address");
            creatorWhitelist[creators[i]] = true;
            emit WhitelistAdded(creators[i]);
        }
    }

    /**
     * @notice Remove creators from whitelist
     * @param creators Array of creator addresses to remove from whitelist
     */
    function removeWhitelist(address[] calldata creators) external onlyOwner {
        for (uint256 i = 0; i < creators.length; i++) {
            require(creators[i] != address(0), "ZoneFactory: Invalid creator address");
            creatorWhitelist[creators[i]] = false;
            emit WhitelistRemoved(creators[i]);
        }
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    //=========================================================================
    //                                EXTERNAL
    //=========================================================================
    /**
     * @notice Create a new Zone contract
     * @param zoneName Name of the Zone contract
     * @param zoneSymbol Symbol of the Zone contract
     * @param zoneMetadataURI Metadata URI of the Zone contract
     */
    function createZone(string memory zoneName, string memory zoneSymbol, string memory zoneMetadataURI)
        external
        whenNotPaused
        returns (address)
    {
        // Check whitelist
        require(!whitelistEnabled || creatorWhitelist[msg.sender], "ZoneFactory: Not whitelisted creator");
        // Deploy new Zone contract
        Zone newZone = new Zone(zoneName, zoneSymbol, zoneMetadataURI);
        // Transfer ownership of Zone contract to caller
        newZone.transferOwnership(msg.sender);
        // Add new Zone to array
        zones.push(address(newZone));

        emit ZoneCreated(address(newZone), msg.sender);

        return address(newZone);
    }

    /**
     * @notice Get all created Zone contract addresses
     */
    function getAllZones() external view returns (address[] memory) {
        return zones;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IZoneFactory.sol";

abstract contract ZoneFactoryStorage is IZoneFactory {
    //=========================================================================
    //                                STORAGE
    //=========================================================================
    // Store all created Zone contract addresses
    address[] public zones;
    // Whitelist toggle
    bool public whitelistEnabled;
    // Mapping to track whitelisted zone creators
    mapping(address => bool) public creatorWhitelist;
}

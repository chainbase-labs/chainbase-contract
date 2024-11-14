// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ChainbaseToken is ERC20Capped, ERC20Burnable, Ownable {
    constructor() ERC20("Chainbase Token", "C") ERC20Capped(2100 * 10 ** 26) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20Capped, ERC20) {
        ERC20Capped._mint(account, amount);
    }
}

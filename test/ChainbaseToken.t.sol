// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/ChainbaseToken.sol";

contract ChainbaseTokenTest is Test {
    ChainbaseToken public token;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        token = new ChainbaseToken();
    }

    function testTokenInfo() public view {
        assertEq(token.name(), "Chainbase Token");
        assertEq(token.symbol(), "C");
        assertEq(token.decimals(), 18);
    }

    function testMint() public {
        uint256 amount = 1000 * 10 ** 18;
        token.mint(user, amount);
        assertEq(token.balanceOf(user), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testOnlyOwnerCanMint() public {
        uint256 amount = 1000 * 10 ** 18;
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        token.mint(user, amount);
    }

    function testBurn() public {
        uint256 amount = 1000 * 10 ** 18;
        token.mint(user, amount);

        vm.prank(user);
        token.burn(500 * 10 ** 18);

        assertEq(token.balanceOf(user), 500 * 10 ** 18);
        assertEq(token.totalSupply(), 500 * 10 ** 18);
    }

    function testBurnFrom() public {
        uint256 amount = 1000 * 10 ** 18;
        token.mint(user, amount);

        vm.prank(user);
        token.approve(owner, 600 * 10 ** 18);

        token.burnFrom(user, 500 * 10 ** 18);

        assertEq(token.balanceOf(user), 500 * 10 ** 18);
        assertEq(token.totalSupply(), 500 * 10 ** 18);

        assertEq(token.allowance(user, owner), 100 * 10 ** 18);
    }

    function testMaxSupply() public {
        uint256 maxSupply = token.cap();

        uint256 initialMint = maxSupply - (100 * 10 ** 18);
        token.mint(user, initialMint);
        assertEq(token.totalSupply(), initialMint);

        vm.expectRevert("ERC20Capped: cap exceeded");
        token.mint(user, 200 * 10 ** 18);

        token.mint(user, 50 * 10 ** 18);
        assertEq(token.totalSupply(), initialMint + (50 * 10 ** 18));
    }
}

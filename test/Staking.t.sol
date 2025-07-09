// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {Staking} from "../src/staking/Staking.sol";
import {ChainbaseToken} from "../src/ChainbaseToken.sol";
import {ChainbaseAirdrop} from "../src/ChainbaseAirdrop.sol";

contract StakingTest is Test {
    Staking public staking;
    ChainbaseToken public cToken;
    ChainbaseAirdrop public airdrop;

    address public owner;
    address public operator;
    address public delegator;
    uint256 public constant INITIAL_BALANCE = 1000000 * 10 ** 18;
    uint256 public constant MIN_STAKE = 500000 * 10 ** 18;

    event MinOperatorStakeUpdated(uint256 oldAmount, uint256 newAmount);
    event WhitelistAdded(address indexed operator);
    event WhitelistRemoved(address indexed operator);
    event StakeDeposited(address indexed operator, uint256 amount);
    event UnstakeRequested(address indexed operator, uint256 amount, uint256 unlockTime);
    event StakeWithdrawn(address indexed operator, uint256 amount);
    event DelegationDeposited(uint256 indexed tokenId, address indexed delegator, uint256 amount);
    event DelegationWithdrawn(uint256 indexed tokenId, address indexed delegator, uint256 amount);
    event UndelegateRequested(uint256 indexed tokenId, address indexed delegator, uint256 amount, uint256 unlockTime);
    event UndelegateCanceled(uint256 indexed tokenId, address indexed delegator);
    event DelegationIncreased(uint256 indexed tokenId, address indexed delegator, uint256 oldAmount, uint256 newAmount);

    function setUp() public {
        owner = makeAddr("owner");
        operator = makeAddr("operator");
        delegator = makeAddr("delegator");

        // Deploy C Token
        cToken = new ChainbaseToken();

        // Deploy Chainbase Airdrop contract
        airdrop = new ChainbaseAirdrop(address(cToken), "merkleRoot");

        // Deploy Staking contract
        vm.prank(owner);
        ProxyAdmin stakingProxyAdmin = new ProxyAdmin();

        address stakingImplementation = address(new Staking(address(cToken)));
        TransparentUpgradeableProxy stakingProxy = new TransparentUpgradeableProxy(
            stakingImplementation,
            address(stakingProxyAdmin),
            abi.encodeWithSelector(Staking.initialize.selector, address(airdrop))
        );
        staking = Staking(address(stakingProxy));

        staking.transferOwnership(owner);

        // Mint tokens to operator and delegator
        cToken.mint(operator, INITIAL_BALANCE);
        cToken.mint(delegator, INITIAL_BALANCE);
    }

    // Test initialization
    function test_Initialize() public view {
        assertEq(staking.owner(), owner);
        assertEq(staking.minOperatorStake(), MIN_STAKE);
    }

    // Test setMinOperatorStake
    function test_SetMinOperatorStake() public {
        uint256 newMinStake = 600000 * 10 ** 18;

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit MinOperatorStakeUpdated(MIN_STAKE, newMinStake);
        staking.setMinOperatorStake(newMinStake);

        assertEq(staking.minOperatorStake(), newMinStake);
    }

    // Test addWhitelist
    function test_AddWhitelist() public {
        address[] memory operators = new address[](1);
        operators[0] = operator;

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit WhitelistAdded(operator);
        staking.addWhitelist(operators);

        assertTrue(staking.operatorWhitelist(operator));
    }

    // Test removeWhitelist
    function test_RemoveWhitelist() public {
        // First add to whitelist
        address[] memory operators = new address[](1);
        operators[0] = operator;
        vm.prank(owner);
        staking.addWhitelist(operators);

        // Then remove from whitelist
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit WhitelistRemoved(operator);
        staking.removeWhitelist(operators);

        assertFalse(staking.operatorWhitelist(operator));
    }

    // Test stake
    function test_Stake() public {
        uint256 stakeAmount = MIN_STAKE;

        // Add operator to whitelist
        address[] memory operators = new address[](1);
        operators[0] = operator;
        vm.prank(owner);
        staking.addWhitelist(operators);

        // Approve tokens
        vm.prank(operator);
        cToken.approve(address(staking), stakeAmount);

        // Stake tokens
        vm.prank(operator);
        vm.expectEmit(true, true, true, true);
        emit StakeDeposited(operator, stakeAmount);
        staking.stake(stakeAmount);

        assertEq(staking.operatorStakes(operator), stakeAmount);
    }

    // Test unstake
    function test_Unstake() public {
        // First stake some tokens
        uint256 stakeAmount = MIN_STAKE;
        address[] memory operators = new address[](1);
        operators[0] = operator;

        vm.prank(owner);
        staking.addWhitelist(operators);

        vm.prank(operator);
        cToken.approve(address(staking), stakeAmount);

        vm.prank(operator);
        staking.stake(stakeAmount);

        // Now unstake
        vm.prank(operator);
        vm.expectEmit(true, true, true, true);
        emit UnstakeRequested(operator, stakeAmount, block.timestamp + 7 days);
        staking.unstake();

        assertEq(staking.operatorStakes(operator), 0);
        (uint256 amount, uint256 unlockTime) = staking.unstakeRequests(operator);
        assertEq(amount, stakeAmount);
        assertEq(unlockTime, block.timestamp + 7 days);
    }

    // Test withdrawStake
    function test_WithdrawStake() public {
        // First stake and unstake
        uint256 stakeAmount = MIN_STAKE;
        address[] memory operators = new address[](1);
        operators[0] = operator;

        vm.prank(owner);
        staking.addWhitelist(operators);

        vm.prank(operator);
        cToken.approve(address(staking), stakeAmount);

        vm.prank(operator);
        staking.stake(stakeAmount);

        vm.prank(operator);
        staking.unstake();

        // Wait for unlock period
        vm.warp(block.timestamp + 7 days);

        // Withdraw stake
        vm.prank(operator);
        vm.expectEmit(true, true, true, true);
        emit StakeWithdrawn(operator, stakeAmount);
        staking.withdrawStake();

        (uint256 amount, uint256 unlockTime) = staking.unstakeRequests(operator);
        assertEq(amount, 0);
        assertEq(unlockTime, 0);
        assertEq(cToken.balanceOf(operator), INITIAL_BALANCE);
    }

    // Test delegate
    function test_Delegate() public {
        uint256 delegateAmount = 1000 * 10 ** 18;

        // Approve tokens
        vm.prank(delegator);
        cToken.approve(address(staking), delegateAmount);

        // Delegate tokens and expect NFT mint
        vm.prank(delegator);
        vm.expectEmit(true, true, true, true);
        emit DelegationDeposited(1, delegator, delegateAmount); // tokenId starts from 1
        staking.delegate(delegateAmount);

        // Verify NFT ownership and delegation amount
        assertEq(staking.ownerOf(1), delegator);
        assertEq(staking.delegations(1), delegateAmount);
        assertEq(staking.balanceOf(delegator), 1);
    }

    // Test increase delegation
    function test_IncreaseDelegation() public {
        uint256 initialAmount = 1000 * 10 ** 18;
        uint256 additionalAmount = 500 * 10 ** 18;

        // First make initial delegation
        vm.startPrank(delegator);
        cToken.approve(address(staking), initialAmount + additionalAmount);
        staking.delegate(initialAmount);

        // Increase delegation amount
        vm.expectEmit(true, true, true, true);
        emit DelegationIncreased(1, delegator, initialAmount, initialAmount + additionalAmount);
        staking.increaseDelegation(1, additionalAmount);
        vm.stopPrank();

        assertEq(staking.delegations(1), initialAmount + additionalAmount);
    }

    // Test undelegate
    function test_Undelegate() public {
        uint256 delegateAmount = 1000 * 10 ** 18;

        // Setup: delegate first
        vm.startPrank(delegator);
        cToken.approve(address(staking), delegateAmount);
        staking.delegate(delegateAmount);

        // Execute undelegate
        vm.expectEmit(true, true, true, true);
        emit UndelegateRequested(1, delegator, delegateAmount, block.timestamp + 7 days);
        staking.undelegate(1);
        vm.stopPrank();

        // Verify state changes
        (uint256 amount, uint256 unlockTime) = staking.undelegateRequests(1);
        assertEq(amount, delegateAmount);
        assertEq(unlockTime, block.timestamp + 7 days);
    }

    // Test cancel undelegate
    function test_CancelUndelegate() public {
        uint256 delegateAmount = 1000 * 10 ** 18;

        // Setup: delegate and undelegate
        vm.startPrank(delegator);
        cToken.approve(address(staking), delegateAmount);
        staking.delegate(delegateAmount);
        staking.undelegate(1);

        // Cancel undelegate
        vm.expectEmit(true, true, true, true);
        emit UndelegateCanceled(1, delegator);
        staking.cancelUndelegate(1);
        vm.stopPrank();

        // Verify state
        (uint256 amount,) = staking.undelegateRequests(1);
        assertEq(amount, 0);
        assertEq(staking.delegations(1), delegateAmount);
    }

    // Test withdraw delegation
    function test_WithdrawDelegation() public {
        uint256 delegateAmount = 1000 * 10 ** 18;

        // Setup initial conditions
        vm.startPrank(delegator);
        cToken.approve(address(staking), delegateAmount);
        staking.delegate(delegateAmount);
        staking.undelegate(1);

        // Wait for unlock period
        vm.warp(block.timestamp + 7 days);

        // Withdraw delegation
        vm.expectEmit(true, true, true, true);
        emit DelegationWithdrawn(1, delegator, delegateAmount);
        staking.withdrawDelegation(1);
        vm.stopPrank();

        // Verify final state
        vm.expectRevert("ERC721: invalid token ID");
        staking.ownerOf(1); // NFT should be burned
        assertEq(staking.delegations(1), 0);
        (uint256 amount,) = staking.undelegateRequests(1);
        assertEq(amount, 0);
        assertEq(cToken.balanceOf(delegator), INITIAL_BALANCE);
    }

    // Test delegation transfer
    function test_DelegationTransfer() public {
        uint256 delegateAmount = 1000 * 10 ** 18;
        address newDelegator = makeAddr("newDelegator");

        // Setup: delegate
        vm.startPrank(delegator);
        cToken.approve(address(staking), delegateAmount);
        staking.delegate(delegateAmount);

        // Transfer NFT
        staking.transferFrom(delegator, newDelegator, 1);
        vm.stopPrank();

        // Verify new owner and delegation amount
        assertEq(staking.ownerOf(1), newDelegator);
        assertEq(staking.delegations(1), delegateAmount);
        assertEq(staking.getDelegationAmount(newDelegator), delegateAmount);
        assertEq(staking.getDelegationAmount(delegator), 0);
    }

    // Test get delegation amount
    function test_GetDelegationAmount() public {
        uint256 firstAmount = 1000 * 10 ** 18;
        uint256 secondAmount = 2000 * 10 ** 18;

        // Make multiple delegations
        vm.startPrank(delegator);
        cToken.approve(address(staking), firstAmount + secondAmount);
        staking.delegate(firstAmount);
        staking.delegate(secondAmount);
        vm.stopPrank();

        // Verify total delegation amount
        assertEq(staking.getDelegationAmount(delegator), firstAmount + secondAmount);
    }

    // Test pause and unpause
    function test_PauseUnpause() public {
        vm.prank(owner);
        staking.pause();
        assertTrue(staking.paused());

        address[] memory operators = new address[](1);
        operators[0] = operator;
        vm.prank(owner);
        staking.addWhitelist(operators);

        vm.prank(operator);
        vm.expectRevert("Pausable: paused");
        staking.stake(MIN_STAKE);

        vm.prank(operator);
        vm.expectRevert("Pausable: paused");
        staking.unstake();

        vm.prank(operator);
        vm.expectRevert("Pausable: paused");
        staking.withdrawStake();

        vm.prank(delegator);
        vm.expectRevert("Pausable: paused");
        staking.delegate(MIN_STAKE);

        vm.prank(delegator);
        vm.expectRevert("Pausable: paused");
        staking.withdrawDelegation(1);

        vm.prank(owner);
        staking.unpause();
        assertFalse(staking.paused());
    }
}

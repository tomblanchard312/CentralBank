// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Permissioning.sol";
import "../src/DigitalToken.sol";

contract EscrowAccountingHardeningTest is Test {
    Permissioning private permissioning;
    DigitalToken private token;

    address private admin = makeAddr("admin");
    address private ecb = makeAddr("ecb");
    address private user = makeAddr("user");

    function setUp() public {
        permissioning = new Permissioning(admin);
        token = new DigitalToken(address(permissioning));

        vm.prank(admin);
        permissioning.grantRole(permissioning.ECB_ROLE(), ecb);

        vm.prank(ecb);
        token.mint(user, 10_000, keccak256("initial-funding"));
    }

    function test_SecondActiveEscrowIsRejectedWithoutCorruptingAccounting() public {
        vm.startPrank(ecb);
        token.escrowFunds(user, 4_000, "case-a", 0);

        vm.expectRevert(DigitalToken.ActiveEscrowExists.selector);
        token.escrowFunds(user, 2_000, "case-b", 0);
        vm.stopPrank();

        (uint256 amount, string memory legalBasis, uint256 expiry) = token.escrowedBalances(user);
        assertEq(amount, 4_000);
        assertEq(legalBasis, "case-a");
        assertEq(expiry, 0);
        assertEq(token.escrowTotals(user), 4_000);
        assertEq(token.balanceOf(user), 6_000);
    }

    function test_ReleaseClearsRecordAndTotalBeforeNewEscrow() public {
        vm.startPrank(ecb);
        token.escrowFunds(user, 4_000, "case-a", 0);
        token.releaseEscrowedFunds(user, user);

        assertEq(token.escrowTotals(user), 0);
        (uint256 releasedAmount,,) = token.escrowedBalances(user);
        assertEq(releasedAmount, 0);

        token.escrowFunds(user, 2_000, "case-b", 0);
        vm.stopPrank();

        (uint256 amount, string memory legalBasis,) = token.escrowedBalances(user);
        assertEq(amount, 2_000);
        assertEq(legalBasis, "case-b");
        assertEq(token.escrowTotals(user), 2_000);
    }

    function test_BurnEscrowClearsAccountingAndSupply() public {
        vm.startPrank(ecb);
        token.escrowFunds(user, 4_000, "confiscation", 0);
        token.burnEscrowedFunds(user);
        vm.stopPrank();

        assertEq(token.escrowTotals(user), 0);
        (uint256 amount,,) = token.escrowedBalances(user);
        assertEq(amount, 0);
        assertEq(token.totalSupply(), 6_000);
    }

    function test_EscrowRejectsAlreadyExpiredRecord() public {
        vm.prank(ecb);
        vm.expectRevert(DigitalToken.EscrowExpired.selector);
        token.escrowFunds(user, 1_000, "expired", block.timestamp);
    }

    function test_BurnRejectsZeroAddress() public {
        vm.prank(ecb);
        vm.expectRevert(DigitalToken.ZeroAddress.selector);
        token.burn(address(0), 1, keccak256("zero-address-burn"));
    }

    function test_BurnRejectsZeroAmount() public {
        vm.prank(ecb);
        vm.expectRevert(DigitalToken.InvalidAmount.selector);
        token.burn(user, 0, keccak256("zero-amount-burn"));
    }
}

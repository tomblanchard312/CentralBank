// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Permissioning.sol";
import "../src/DigitalToken.sol";

contract CentralBankControlsTest is Test {
    Permissioning internal permissioning;
    DigitalToken internal token;

    address internal admin = makeAddr("admin");
    address internal issuer = makeAddr("issuer");
    address internal emergency = makeAddr("emergency");
    address internal centralBank = makeAddr("central-bank");
    address internal user = makeAddr("user");
    address internal recipient = makeAddr("recipient");

    function setUp() public {
        permissioning = new Permissioning(admin);
        token = new DigitalToken(address(permissioning));

        vm.startPrank(admin);
        permissioning.grantRole(permissioning.MINTER_ROLE(), issuer);
        permissioning.grantRole(permissioning.BURNER_ROLE(), issuer);
        permissioning.grantRole(permissioning.EMERGENCY_ROLE(), emergency);
        permissioning.grantRole(permissioning.CENTRAL_BANK_ROLE(), centralBank);
        vm.stopPrank();
    }

    function test_IssuerCannotFreezeAccount() public {
        vm.prank(issuer);
        vm.expectRevert(DigitalToken.Unauthorized.selector);
        token.freezeAccount(user, "case");
    }

    function test_CentralBankCanFreezeAndUnfreeze() public {
        vm.prank(centralBank);
        token.freezeAccount(user, "sanctions-reference");
        assertTrue(token.frozenAccounts(user));

        vm.prank(centralBank);
        token.unfreezeAccount(user);
        assertFalse(token.frozenAccounts(user));
    }

    function test_FrozenAccountCannotTransfer() public {
        vm.prank(issuer);
        token.mint(user, 1000, keccak256("fund"));
        vm.prank(centralBank);
        token.freezeAccount(user, "case");

        vm.prank(user);
        vm.expectRevert(DigitalToken.AccountIsFrozen.selector);
        token.transfer(recipient, 1);
    }

    function test_CentralBankEscrowConservesSupply() public {
        vm.prank(issuer);
        token.mint(user, 1000, keccak256("fund-escrow"));
        uint256 supply = token.totalSupply();

        vm.prank(centralBank);
        token.escrowFunds(user, 400, "legal-case-reference", 0);

        assertEq(token.balanceOf(user), 600);
        assertEq(token.escrowTotals(user), 400);
        assertEq(token.totalSupply(), supply);

        vm.prank(centralBank);
        token.releaseEscrowedFunds(user, recipient);
        assertEq(token.balanceOf(recipient), 400);
        assertEq(token.escrowTotals(user), 0);
        assertEq(token.totalSupply(), supply);
    }

    function test_BurnEscrowReducesSupply() public {
        vm.prank(issuer);
        token.mint(user, 1000, keccak256("fund-burn-escrow"));
        vm.prank(centralBank);
        token.escrowFunds(user, 400, "confiscation-reference", 0);
        vm.prank(centralBank);
        token.burnEscrowedFunds(user);

        assertEq(token.totalSupply(), 600);
        assertEq(token.escrowTotals(user), 0);
    }

    function test_EmergencyAuthorityControlsPauseOnly() public {
        vm.prank(emergency);
        token.pause();
        assertTrue(token.paused());

        vm.prank(centralBank);
        vm.expectRevert(DigitalToken.Unauthorized.selector);
        token.unpause();

        vm.prank(emergency);
        token.unpause();
        assertFalse(token.paused());
    }
}

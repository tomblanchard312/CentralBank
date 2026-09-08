// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GovernedPermissioning.sol";

contract GovernedPermissioningTest is Test {
    GovernedPermissioning internal permissioning;
    address internal admin1 = makeAddr("admin1");
    address internal admin2 = makeAddr("admin2");
    address internal admin3 = makeAddr("admin3");
    address internal centralBank = makeAddr("central-bank");
    bytes32 internal adminRole;
    bytes32 internal centralBankRole;

    function setUp() public {
        permissioning = new GovernedPermissioning(admin1, admin2);
        adminRole = permissioning.ADMIN_ROLE();
        centralBankRole = permissioning.CENTRAL_BANK_ROLE();
    }

    function test_RoleGrantRequiresDistinctSecondAdmin() public {
        vm.prank(admin1);
        bytes32 proposalId = permissioning.proposeRoleChange(centralBankRole, centralBank, true, 1 days);

        vm.prank(admin1);
        vm.expectRevert(GovernedPermissioning.SelfApproval.selector);
        permissioning.approveAndExecute(proposalId);

        vm.prank(admin2);
        permissioning.approveAndExecute(proposalId);
        assertTrue(permissioning.isCentralBank(centralBank));
    }

    function test_ExpiredProposalCannotExecute() public {
        vm.prank(admin1);
        bytes32 proposalId = permissioning.proposeRoleChange(centralBankRole, centralBank, true, 1 hours);
        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(admin2);
        vm.expectRevert(GovernedPermissioning.ProposalExpired.selector);
        permissioning.approveAndExecute(proposalId);
    }

    function test_ProposerCanCancel() public {
        vm.prank(admin1);
        bytes32 proposalId = permissioning.proposeRoleChange(centralBankRole, centralBank, true, 1 days);
        vm.prank(admin1);
        permissioning.cancelProposal(proposalId);

        vm.prank(admin2);
        vm.expectRevert(GovernedPermissioning.ProposalFinalized.selector);
        permissioning.approveAndExecute(proposalId);
    }

    function test_AdminSetCannotFallBelowTwo() public {
        vm.prank(admin1);
        bytes32 addId = permissioning.proposeRoleChange(adminRole, admin3, true, 1 days);
        vm.prank(admin2);
        permissioning.approveAndExecute(addId);
        assertEq(permissioning.adminCount(), 3);

        vm.prank(admin1);
        bytes32 revokeId = permissioning.proposeRoleChange(adminRole, admin3, false, 1 days);
        vm.prank(admin2);
        permissioning.approveAndExecute(revokeId);
        assertEq(permissioning.adminCount(), 2);

        vm.prank(admin1);
        vm.expectRevert(GovernedPermissioning.LastAdmin.selector);
        permissioning.proposeRoleChange(adminRole, admin2, false, 1 days);
    }

    function test_NonAdminCannotProposeOrApprove() public {
        vm.prank(centralBank);
        vm.expectRevert(GovernedPermissioning.Unauthorized.selector);
        permissioning.proposeRoleChange(centralBankRole, centralBank, true, 1 days);

        vm.prank(admin1);
        bytes32 proposalId = permissioning.proposeRoleChange(centralBankRole, centralBank, true, 1 days);
        vm.prank(centralBank);
        vm.expectRevert(GovernedPermissioning.Unauthorized.selector);
        permissioning.approveAndExecute(proposalId);
    }
}

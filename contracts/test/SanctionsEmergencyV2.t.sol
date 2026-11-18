// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/v2/TokenLedgerV2.sol";
import "../src/v2/MintBurnControllerV2.sol";
import "../src/v2/HoldingLimitPolicyV2.sol";
import "../src/v2/CompositeTransferPolicyV2.sol";
import "../src/v2/SanctionsPolicyV2.sol";
import "../src/v2/EmergencyPolicyV2.sol";

contract SanctionsEmergencyV2Test is Test {
    TokenLedgerV2 internal ledger;
    MintBurnControllerV2 internal mintBurn;
    HoldingLimitPolicyV2 internal holding;
    CompositeTransferPolicyV2 internal composite;
    SanctionsPolicyV2 internal sanctions;
    EmergencyPolicyV2 internal emergency;

    address internal governance = makeAddr("governance");
    address internal emergencyAuth = makeAddr("emergency");
    address internal sanctionsAuth = makeAddr("sanctions");
    address internal policyAuth = makeAddr("policy");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal outsider = makeAddr("outsider");

    function setUp() public {
        ledger = new TokenLedgerV2(governance);
        mintBurn = new MintBurnControllerV2(
            address(ledger), governance, governance, governance, 1_000_000, 100_000, 100_000
        );
        holding = new HoldingLimitPolicyV2(address(ledger), governance, policyAuth);
        sanctions = new SanctionsPolicyV2(governance, sanctionsAuth);
        emergency = new EmergencyPolicyV2(governance, emergencyAuth);
        composite = new CompositeTransferPolicyV2(governance);

        vm.startPrank(governance);
        ledger.setControllerCapabilities(address(mintBurn), ledger.CAPABILITY_MINT() | ledger.CAPABILITY_BURN());
        address[] memory policies = new address[](3);
        policies[0] = address(emergency);
        policies[1] = address(sanctions);
        policies[2] = address(holding);
        composite.replacePolicies(policies);
        ledger.setTransferPolicy(address(composite));
        vm.stopPrank();

        vm.prank(governance);
        mintBurn.mint(alice, 50_000, keccak256("fund"), keccak256("fund-key"));
    }

    function test_FrozenAccountCannotSendOrReceive() public {
        vm.prank(sanctionsAuth);
        sanctions.freezeAccount(alice, keccak256("case-opaque"));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(SanctionsPolicyV2.AccountIsFrozen.selector, alice));
        ledger.transfer(bob, 1_000);

        vm.prank(sanctionsAuth);
        sanctions.unfreezeAccount(alice);

        vm.prank(governance);
        mintBurn.mint(bob, 5_000, keccak256("bob-fund"), keccak256("bob-key"));

        vm.prank(sanctionsAuth);
        sanctions.freezeAccount(bob, keccak256("case-bob"));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(SanctionsPolicyV2.AccountIsFrozen.selector, bob));
        ledger.transfer(bob, 1_000);
    }

    function test_OnlySanctionsAuthorityCanFreeze() public {
        vm.prank(outsider);
        vm.expectRevert(SanctionsPolicyV2.Unauthorized.selector);
        sanctions.freezeAccount(alice, keccak256("case"));
    }

    function test_EmergencyPauseBlocksTransfersUntilDualUnpause() public {
        vm.prank(emergencyAuth);
        emergency.pauseTransfers();

        vm.prank(alice);
        vm.expectRevert(EmergencyPolicyV2.TransfersArePaused.selector);
        ledger.transfer(bob, 100);

        vm.prank(emergencyAuth);
        emergency.proposeUnpause();

        vm.prank(emergencyAuth);
        vm.expectRevert(EmergencyPolicyV2.SelfConfirmation.selector);
        emergency.confirmUnpause();

        vm.prank(governance);
        emergency.confirmUnpause();

        vm.prank(alice);
        ledger.transfer(bob, 100);
        assertEq(ledger.balanceOf(bob), 100);
    }

    function test_OnlyEmergencyAuthorityCanPause() public {
        vm.prank(outsider);
        vm.expectRevert(EmergencyPolicyV2.Unauthorized.selector);
        emergency.pauseTransfers();
    }

    function test_CompositeOrderKeepsHoldingLimits() public {
        vm.prank(policyAuth);
        holding.setHoldingLimit(bob, 1_000);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(HoldingLimitPolicyV2.HoldingLimitExceeded.selector, bob, 2_000, 1_000)
        );
        ledger.transfer(bob, 2_000);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Permissioning.sol";
import "../src/DigitalToken.sol";
import "../src/ConditionalPayments.sol";
import "../src/interfaces/IConditionalPayments.sol";

contract ConditionalPaymentsGenericTest is Test {
    Permissioning internal permissioning;
    DigitalToken internal token;
    ConditionalPayments internal payments;

    address internal admin = makeAddr("admin");
    address internal issuer = makeAddr("issuer");
    address internal oracle = makeAddr("oracle");
    address internal payer = makeAddr("payer");
    address internal payee = makeAddr("payee");
    address internal arbiter = makeAddr("arbiter");

    function setUp() public {
        permissioning = new Permissioning(admin);
        token = new DigitalToken(address(permissioning));
        payments = new ConditionalPayments(address(token), address(permissioning));

        vm.startPrank(admin);
        permissioning.grantRole(permissioning.MINTER_ROLE(), issuer);
        permissioning.grantRole(permissioning.ORACLE_ROLE(), oracle);
        vm.stopPrank();

        vm.prank(issuer);
        token.mint(payer, 200_000, keccak256("setup"));
        vm.prank(payer);
        token.approve(address(payments), type(uint256).max);
    }

    function test_CreateDeliveryPaymentEscrowsPayerFunds() public {
        vm.prank(payer);
        bytes32 id = payments.createConditionalPayment(
            payee,
            50_000,
            IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0),
            block.timestamp + 30 days,
            arbiter,
            keccak256("payment-1")
        );

        assertTrue(id != bytes32(0));
        assertEq(token.balanceOf(payer), 150_000);
        assertEq(token.balanceOf(address(payments)), 50_000);
    }

    function test_DeliveryCanBeConfirmedByPayer() public {
        vm.prank(payer);
        bytes32 id = payments.createConditionalPayment(
            payee, 50_000, IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0), block.timestamp + 30 days, arbiter, keccak256("delivery")
        );

        vm.prank(payer);
        payments.confirmDelivery(id, keccak256("proof"));
        assertEq(token.balanceOf(payee), 50_000);
    }

    function test_DeliveryCanBeConfirmedByOracle() public {
        vm.prank(payer);
        bytes32 id = payments.createConditionalPayment(
            payee, 50_000, IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0), block.timestamp + 30 days, arbiter, keccak256("oracle-delivery")
        );

        vm.prank(oracle);
        payments.confirmDelivery(id, keccak256("proof"));
        assertEq(token.balanceOf(payee), 50_000);
    }

    function test_UnauthorizedDeliveryConfirmationReverts() public {
        vm.prank(payer);
        bytes32 id = payments.createConditionalPayment(
            payee, 50_000, IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0), block.timestamp + 30 days, arbiter, keccak256("unauth-delivery")
        );

        vm.prank(payee);
        vm.expectRevert(ConditionalPayments.Unauthorized.selector);
        payments.confirmDelivery(id, keccak256("proof"));
    }

    function test_TimeLockReleasesOnlyAfterUnlock() public {
        uint256 unlock = block.timestamp + 7 days;
        vm.prank(payer);
        bytes32 id = payments.createConditionalPayment(
            payee, 50_000, IConditionalPayments.ConditionType.TIME_LOCK,
            bytes32(unlock), block.timestamp + 30 days, address(0), keccak256("time-lock")
        );

        vm.expectRevert(ConditionalPayments.ConditionNotMet.selector);
        payments.releasePayment(id, bytes32("proof"));

        vm.warp(unlock + 1);
        payments.releasePayment(id, bytes32("proof"));
        assertEq(token.balanceOf(payee), 50_000);
    }

    function test_PayerAndPayeeCanDisputeButOnlyArbiterResolves() public {
        vm.prank(payer);
        bytes32 id = payments.createConditionalPayment(
            payee, 50_000, IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0), block.timestamp + 30 days, arbiter, keccak256("dispute")
        );

        vm.prank(payee);
        payments.disputePayment(id, "merchant dispute");

        vm.prank(payee);
        vm.expectRevert(ConditionalPayments.NotArbiter.selector);
        payments.resolveDispute(id, true);

        vm.prank(arbiter);
        payments.resolveDispute(id, true);
        assertEq(token.balanceOf(payee), 50_000);
    }

    function test_DuplicateIdempotencyKeyReverts() public {
        bytes32 key = keccak256("duplicate");
        vm.prank(payer);
        payments.createConditionalPayment(
            payee, 10_000, IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0), block.timestamp + 30 days, arbiter, key
        );

        vm.prank(payer);
        vm.expectRevert(ConditionalPayments.IdempotencyKeyUsed.selector);
        payments.createConditionalPayment(
            payee, 10_000, IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0), block.timestamp + 30 days, arbiter, key
        );
    }
}

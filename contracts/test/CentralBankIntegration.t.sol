// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Permissioning.sol";
import "../src/WalletRegistry.sol";
import "../src/DigitalToken.sol";
import "../src/ConditionalPayments.sol";
import "../src/interfaces/IWalletRegistry.sol";
import "../src/interfaces/IConditionalPayments.sol";

contract CentralBankIntegrationTest is Test {
    Permissioning internal permissioning;
    WalletRegistry internal registry;
    DigitalToken internal token;
    ConditionalPayments internal payments;

    address internal admin = makeAddr("admin");
    address internal issuer = makeAddr("issuer");
    address internal emergency = makeAddr("emergency");
    address internal registrar = makeAddr("registrar");
    address internal waterfall = makeAddr("waterfall");
    address internal oracle = makeAddr("oracle");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal merchant = makeAddr("merchant");
    address internal bank = makeAddr("bank");

    function setUp() public {
        permissioning = new Permissioning(admin);
        registry = new WalletRegistry(address(permissioning));
        token = new DigitalToken(address(permissioning));
        payments = new ConditionalPayments(address(token), address(permissioning));

        vm.startPrank(admin);
        permissioning.grantRole(permissioning.MINTER_ROLE(), issuer);
        permissioning.grantRole(permissioning.BURNER_ROLE(), issuer);
        permissioning.grantRole(permissioning.EMERGENCY_ROLE(), emergency);
        permissioning.grantRole(permissioning.REGISTRAR_ROLE(), registrar);
        permissioning.grantRole(permissioning.WATERFALL_ROLE(), waterfall);
        permissioning.grantRole(permissioning.ORACLE_ROLE(), oracle);
        token.setWalletRegistry(address(registry));
        vm.stopPrank();

        vm.startPrank(registrar);
        registry.registerWallet(bank, IWalletRegistry.WalletType.BANK, address(0), keccak256("bank"));
        registry.registerWallet(address(payments), IWalletRegistry.WalletType.PSP, address(0), keccak256("payments"));
        registry.registerWallet(alice, IWalletRegistry.WalletType.INDIVIDUAL, bank, keccak256("alice"));
        registry.registerWallet(bob, IWalletRegistry.WalletType.INDIVIDUAL, bank, keccak256("bob"));
        registry.registerWallet(merchant, IWalletRegistry.WalletType.MERCHANT, bank, keccak256("merchant"));
        vm.stopPrank();
    }

    function test_P2PAndMerchantPayment() public {
        vm.prank(issuer);
        token.mint(alice, 20_000, keccak256("mint-alice"));

        vm.prank(alice);
        token.transfer(bob, 5000);
        vm.prank(alice);
        token.transfer(merchant, 2500);

        assertEq(token.balanceOf(alice), 12_500);
        assertEq(token.balanceOf(bob), 5000);
        assertEq(token.balanceOf(merchant), 2500);
    }

    function test_WaterfallAndReverseWaterfall() public {
        vm.prank(admin);
        token.setWaterfallEnabled(true);

        vm.prank(issuer);
        token.mint(alice, 400_000, keccak256("large-alice"));
        vm.prank(waterfall);
        token.executeWaterfall(alice);
        assertEq(token.balanceOf(alice), 300_000);
        assertEq(token.balanceOf(bank), 100_000);

        vm.prank(issuer);
        token.executeReverseWaterfall(alice, 50_000, keccak256("reverse"));
        // Alice is already at the profile limit, so the reverse waterfall remains at the bank.
        assertEq(token.balanceOf(alice), 300_000);
        assertEq(token.balanceOf(bank), 100_000);
    }

    function test_ConditionalDeliveryPaymentPreservesPayerCustody() public {
        vm.prank(issuer);
        token.mint(alice, 10_000, keccak256("conditional-funding"));

        vm.prank(alice);
        token.approve(address(payments), 4000);

        vm.prank(alice);
        bytes32 paymentId = payments.createConditionalPayment(
            merchant,
            4000,
            IConditionalPayments.ConditionType.DELIVERY,
            bytes32(0),
            block.timestamp + 1 days,
            oracle,
            keccak256("conditional-1")
        );

        assertEq(token.balanceOf(alice), 6000);
        assertEq(token.balanceOf(address(payments)), 4000);

        vm.prank(alice);
        payments.confirmDelivery(paymentId, keccak256("proof"));

        assertEq(token.balanceOf(merchant), 4000);
        assertEq(token.balanceOf(address(payments)), 0);
    }

    function test_EmergencyPauseStopsTransfersAndMinting() public {
        vm.prank(issuer);
        token.mint(alice, 10_000, keccak256("emergency-funding"));

        vm.prank(emergency);
        token.pause();

        vm.prank(alice);
        vm.expectRevert(DigitalToken.ContractPaused.selector);
        token.transfer(bob, 100);

        vm.prank(issuer);
        vm.expectRevert(DigitalToken.ContractPaused.selector);
        token.mint(bob, 100, keccak256("paused-mint"));
    }
}

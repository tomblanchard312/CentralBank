// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Permissioning.sol";
import "../src/WalletRegistry.sol";
import "../src/DigitalToken.sol";
import "../src/interfaces/IWalletRegistry.sol";

contract DigitalTokenTest is Test {
    Permissioning internal permissioning;
    WalletRegistry internal registry;
    DigitalToken internal token;

    address internal admin = makeAddr("admin");
    address internal issuer = makeAddr("issuer");
    address internal emergency = makeAddr("emergency");
    address internal centralBank = makeAddr("central-bank");
    address internal registrar = makeAddr("registrar");
    address internal waterfall = makeAddr("waterfall");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal bank = makeAddr("bank");

    function setUp() public {
        permissioning = new Permissioning(admin);
        registry = new WalletRegistry(address(permissioning));
        token = new DigitalToken(address(permissioning));

        vm.startPrank(admin);
        permissioning.grantRole(permissioning.MINTER_ROLE(), issuer);
        permissioning.grantRole(permissioning.BURNER_ROLE(), issuer);
        permissioning.grantRole(permissioning.EMERGENCY_ROLE(), emergency);
        permissioning.grantRole(permissioning.CENTRAL_BANK_ROLE(), centralBank);
        permissioning.grantRole(permissioning.REGISTRAR_ROLE(), registrar);
        permissioning.grantRole(permissioning.WATERFALL_ROLE(), waterfall);
        token.setWalletRegistry(address(registry));
        vm.stopPrank();

        vm.startPrank(registrar);
        registry.registerWallet(bank, IWalletRegistry.WalletType.BANK, address(0), keccak256("bank"));
        registry.registerWallet(alice, IWalletRegistry.WalletType.INDIVIDUAL, bank, keccak256("alice"));
        registry.registerWallet(bob, IWalletRegistry.WalletType.INDIVIDUAL, bank, keccak256("bob"));
        vm.stopPrank();
    }

    function test_IdentityIsGenericCBDT() public view {
        assertEq(token.name(), "Central Bank Digital Token");
        assertEq(token.symbol(), "CBDT");
        assertEq(token.decimals(), 2);
    }

    function test_MintAndBurnUseDedicatedAuthorities() public {
        vm.prank(issuer);
        token.mint(alice, 10_000, keccak256("mint-1"));
        assertEq(token.balanceOf(alice), 10_000);
        assertEq(token.totalSupply(), 10_000);

        vm.prank(issuer);
        token.burn(alice, 2500, keccak256("burn-1"));
        assertEq(token.balanceOf(alice), 7500);
        assertEq(token.totalSupply(), 7500);
    }

    function test_MintRejectsNonMinter() public {
        vm.prank(alice);
        vm.expectRevert(DigitalToken.Unauthorized.selector);
        token.mint(alice, 1, keccak256("unauthorized"));
    }

    function test_BurnRejectsNonBurner() public {
        vm.prank(issuer);
        token.mint(alice, 100, keccak256("fund"));

        vm.prank(alice);
        vm.expectRevert(DigitalToken.Unauthorized.selector);
        token.burn(alice, 1, keccak256("unauthorized-burn"));
    }

    function test_IdempotencyKeyCannotBeReused() public {
        bytes32 key = keccak256("same-key");
        vm.prank(issuer);
        token.mint(alice, 100, key);

        vm.prank(issuer);
        vm.expectRevert(DigitalToken.IdempotencyKeyUsed.selector);
        token.mint(bob, 100, key);
    }

    function test_TransferAndAllowance() public {
        vm.prank(issuer);
        token.mint(alice, 10_000, keccak256("fund-alice"));

        vm.prank(alice);
        token.transfer(bob, 1000);
        assertEq(token.balanceOf(bob), 1000);

        vm.prank(alice);
        token.approve(bob, 500);
        vm.prank(bob);
        token.transferFrom(alice, bob, 500);
        assertEq(token.balanceOf(bob), 1500);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_EmergencyPauseBlocksMovement() public {
        vm.prank(issuer);
        token.mint(alice, 100, keccak256("pause-funding"));

        vm.prank(emergency);
        token.pause();

        vm.prank(alice);
        vm.expectRevert(DigitalToken.ContractPaused.selector);
        token.transfer(bob, 1);

        vm.prank(emergency);
        token.unpause();
        vm.prank(alice);
        token.transfer(bob, 1);
        assertEq(token.balanceOf(bob), 1);
    }

    function test_CentralBankCanFreezeAndEscrow() public {
        vm.prank(issuer);
        token.mint(alice, 1000, keccak256("escrow-funding"));

        vm.prank(centralBank);
        token.freezeAccount(alice, "case-ref");
        assertTrue(token.frozenAccounts(alice));

        vm.prank(centralBank);
        token.unfreezeAccount(alice);

        vm.prank(centralBank);
        token.escrowFunds(alice, 400, "case-ref", 0);
        assertEq(token.balanceOf(alice), 600);
        assertEq(token.escrowTotals(alice), 400);
    }

    function test_WaterfallMovesExcessToLinkedBank() public {
        vm.prank(admin);
        token.setWaterfallEnabled(true);

        vm.prank(issuer);
        token.mint(alice, 400_000, keccak256("large-mint"));

        vm.prank(waterfall);
        token.executeWaterfall(alice);

        assertEq(token.balanceOf(alice), 300_000);
        assertEq(token.balanceOf(bank), 100_000);
    }

    function testFuzz_TransferConservesSupply(uint96 minted, uint96 moved) public {
        minted = uint96(bound(minted, 1, 250_000));
        moved = uint96(bound(moved, 1, minted));

        vm.prank(issuer);
        token.mint(alice, minted, keccak256(abi.encode("fuzz", minted, moved)));
        uint256 supplyBefore = token.totalSupply();

        vm.prank(alice);
        token.transfer(bob, moved);

        assertEq(token.totalSupply(), supplyBefore);
        assertEq(token.balanceOf(alice) + token.balanceOf(bob), minted);
    }
}

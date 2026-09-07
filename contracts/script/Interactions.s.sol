// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/WalletRegistry.sol";
import "../src/DigitalToken.sol";
import "../src/ConditionalPayments.sol";
import "../src/interfaces/IWalletRegistry.sol";
import "../src/interfaces/IConditionalPayments.sol";

/** Register a participant wallet. */
contract RegisterWallet is Script {
    function run() external {
        uint256 privateKey = vm.envUint("REGISTRAR_PRIVATE_KEY");
        address walletRegistry = vm.envAddress("WALLET_REGISTRY_ADDRESS");
        address wallet = vm.envAddress("WALLET");
        uint8 walletType = uint8(vm.envUint("WALLET_TYPE"));
        address linkedBank = vm.envAddress("BANK");
        bytes32 kycHash = vm.envBytes32("KYC_HASH");

        vm.startBroadcast(privateKey);
        WalletRegistry(walletRegistry).registerWallet(
            wallet,
            IWalletRegistry.WalletType(walletType),
            linkedBank,
            kycHash
        );
        vm.stopBroadcast();
    }
}

/** Mint generic CBDT through an authorized issuer key. */
contract MintCBDT is Script {
    function run() external {
        uint256 privateKey = vm.envUint("ISSUER_PRIVATE_KEY");
        address digitalToken = vm.envAddress("DIGITAL_TOKEN_ADDRESS");
        address to = vm.envAddress("TO");
        uint256 amount = vm.envUint("AMOUNT");
        bytes32 idempotencyKey = keccak256(abi.encodePacked(block.timestamp, to, amount, "mint"));

        vm.startBroadcast(privateKey);
        DigitalToken(digitalToken).mint(to, amount, idempotencyKey);
        vm.stopBroadcast();
    }
}

/** Create a payer-authorized conditional payment. */
contract CreateConditionalPayment is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PAYER_PRIVATE_KEY");
        address conditionalPayments = vm.envAddress("CONDITIONAL_PAYMENTS_ADDRESS");
        address digitalToken = vm.envAddress("DIGITAL_TOKEN_ADDRESS");
        address payee = vm.envAddress("PAYEE");
        uint256 amount = vm.envUint("AMOUNT");
        uint8 conditionType = uint8(vm.envOr("CONDITION_TYPE", uint256(1)));
        uint256 expiresIn = vm.envOr("EXPIRES_IN", uint256(86400));
        address arbiter = vm.envOr("ARBITER", address(0));
        bytes32 idempotencyKey = keccak256(abi.encodePacked(block.timestamp, payee, amount, "conditional"));

        vm.startBroadcast(privateKey);
        DigitalToken(digitalToken).approve(conditionalPayments, amount);
        ConditionalPayments(conditionalPayments).createConditionalPayment(
            payee,
            amount,
            IConditionalPayments.ConditionType(conditionType),
            bytes32(0),
            block.timestamp + expiresIn,
            arbiter,
            idempotencyKey
        );
        vm.stopBroadcast();
    }
}

contract ConfirmDelivery is Script {
    function run() external {
        uint256 privateKey = vm.envUint("CONFIRMER_PRIVATE_KEY");
        address conditionalPayments = vm.envAddress("CONDITIONAL_PAYMENTS_ADDRESS");
        bytes32 paymentId = vm.envBytes32("PAYMENT_ID");
        bytes32 deliveryProof = vm.envOr("DELIVERY_PROOF", keccak256("confirmed"));

        vm.startBroadcast(privateKey);
        ConditionalPayments(conditionalPayments).confirmDelivery(paymentId, deliveryProof);
        vm.stopBroadcast();
    }
}

contract CheckBalances is Script {
    function run() external view {
        address digitalToken = vm.envAddress("DIGITAL_TOKEN_ADDRESS");
        address walletRegistry = vm.envAddress("WALLET_REGISTRY_ADDRESS");
        address account = vm.envAddress("ADDRESS");

        uint256 balance = DigitalToken(digitalToken).balanceOf(account);
        console.log("CBDT Balance (minor units):", balance);

        IWalletRegistry.WalletInfo memory info = WalletRegistry(walletRegistry).getWalletInfo(account);
        if (info.registrationTime == 0) {
            console.log("Status: NOT REGISTERED");
        } else {
            console.log("Status:", info.isActive ? "ACTIVE" : "DEACTIVATED");
            console.log("Wallet Type:", uint256(info.walletType));
            console.log("Linked Bank:", info.linkedBankAccount);
            console.log("Holding Limit:", WalletRegistry(walletRegistry).getHoldingLimit(account));
        }
    }
}

contract EmergencyPause is Script {
    function run() external {
        uint256 privateKey = vm.envUint("EMERGENCY_PRIVATE_KEY");
        address digitalToken = vm.envAddress("DIGITAL_TOKEN_ADDRESS");
        vm.startBroadcast(privateKey);
        DigitalToken(digitalToken).pause();
        vm.stopBroadcast();
    }
}

contract EmergencyUnpause is Script {
    function run() external {
        uint256 privateKey = vm.envUint("EMERGENCY_PRIVATE_KEY");
        address digitalToken = vm.envAddress("DIGITAL_TOKEN_ADDRESS");
        vm.startBroadcast(privateKey);
        DigitalToken(digitalToken).unpause();
        vm.stopBroadcast();
    }
}

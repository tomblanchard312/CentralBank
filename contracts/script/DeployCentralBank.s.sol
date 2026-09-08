// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Permissioning.sol";
import "../src/WalletRegistry.sol";
import "../src/DigitalToken.sol";
import "../src/ConditionalPayments.sol";

/**
 * @title DeployCentralBank
 * @notice Deploys the CentralBank digital-token reference stack.
 * @dev Currency denomination and jurisdictional policy are selected outside the
 *      generic token contract by deployment profile and policy configuration.
 */
contract DeployCentralBank is Script {
    Permissioning public permissioning;
    WalletRegistry public walletRegistry;
    DigitalToken public digitalToken;
    ConditionalPayments public conditionalPayments;

    struct DeploymentConfig {
        address admin;
        address centralBankController;
        address issuer;
        address participantRegistrar;
        address oracleService;
        bool enableWaterfall;
    }

    function run() external {
        DeploymentConfig memory config = loadConfig();
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        permissioning = new Permissioning(deployer);
        walletRegistry = new WalletRegistry(address(permissioning));
        digitalToken = new DigitalToken(address(permissioning));
        conditionalPayments = new ConditionalPayments(address(digitalToken), address(permissioning));

        digitalToken.setWalletRegistry(address(walletRegistry));
        if (config.enableWaterfall) digitalToken.setWaterfallEnabled(true);
        _grantRoles(config, deployer);
        vm.stopBroadcast();
        _printSummary(config);
    }

    function loadConfig() internal view returns (DeploymentConfig memory) {
        address admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        address centralBank = vm.envOr("CENTRAL_BANK_ADDRESS", admin);
        address issuer = vm.envOr("ISSUER_ADDRESS", admin);
        address participant = vm.envOr("PARTICIPANT_REGISTRAR_ADDRESS", admin);
        address oracle = vm.envOr("ORACLE_ADDRESS", admin);
        bool waterfall = vm.envOr("ENABLE_WATERFALL", true);

        return DeploymentConfig({
            admin: admin,
            centralBankController: centralBank,
            issuer: issuer,
            participantRegistrar: participant,
            oracleService: oracle,
            enableWaterfall: waterfall
        });
    }

    function _grantRoles(DeploymentConfig memory config, address deployer) internal {
        if (config.admin != deployer) permissioning.grantRole(permissioning.ADMIN_ROLE(), config.admin);
        permissioning.grantRole(permissioning.EMERGENCY_ROLE(), config.centralBankController);
        permissioning.grantRole(permissioning.ECB_ROLE(), config.centralBankController);
        permissioning.grantRole(permissioning.MINTER_ROLE(), config.issuer);
        permissioning.grantRole(permissioning.BURNER_ROLE(), config.issuer);
        permissioning.grantRole(permissioning.REGISTRAR_ROLE(), config.participantRegistrar);
        permissioning.grantRole(permissioning.WATERFALL_ROLE(), config.participantRegistrar);
        permissioning.grantRole(permissioning.ORACLE_ROLE(), config.oracleService);
        if (config.admin != deployer) permissioning.revokeRole(permissioning.ADMIN_ROLE(), deployer);
    }

    function _printSummary(DeploymentConfig memory config) internal view {
        console.log("=== CentralBank Deployment Complete ===");
        console.log("  Permissioning:       ", address(permissioning));
        console.log("  WalletRegistry:      ", address(walletRegistry));
        console.log("  DigitalToken:        ", address(digitalToken));
        console.log("  ConditionalPayments: ", address(conditionalPayments));
        console.log("  Waterfall Enabled:   ", config.enableWaterfall);
    }
}

/**
 * @title DeployLabEnvironment
 * @notice Single-authority local deployment for development and integration tests only.
 * @dev Uses the unlocked sender supplied to Foundry, so CI does not need a raw
 *      private key in workflow configuration.
 */
contract DeployLabEnvironment is Script {
    function run() external {
        address deployer = msg.sender;
        vm.startBroadcast();

        Permissioning permissioning = new Permissioning(deployer);
        WalletRegistry walletRegistry = new WalletRegistry(address(permissioning));
        DigitalToken digitalToken = new DigitalToken(address(permissioning));
        ConditionalPayments conditionalPayments = new ConditionalPayments(address(digitalToken), address(permissioning));

        digitalToken.setWalletRegistry(address(walletRegistry));
        digitalToken.setWaterfallEnabled(true);

        permissioning.grantRole(permissioning.MINTER_ROLE(), deployer);
        permissioning.grantRole(permissioning.BURNER_ROLE(), deployer);
        permissioning.grantRole(permissioning.EMERGENCY_ROLE(), deployer);
        permissioning.grantRole(permissioning.ECB_ROLE(), deployer);
        permissioning.grantRole(permissioning.REGISTRAR_ROLE(), deployer);
        permissioning.grantRole(permissioning.ORACLE_ROLE(), deployer);
        permissioning.grantRole(permissioning.WATERFALL_ROLE(), deployer);

        vm.stopBroadcast();

        console.log("export PERMISSIONING_ADDRESS=", address(permissioning));
        console.log("export WALLET_REGISTRY_ADDRESS=", address(walletRegistry));
        console.log("export DIGITAL_TOKEN_ADDRESS=", address(digitalToken));
        console.log("export CONDITIONAL_PAYMENTS_ADDRESS=", address(conditionalPayments));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GovernedPermissioning.sol";
import "../src/v2/TokenLedgerV2.sol";
import "../src/v2/HoldingLimitPolicyV2.sol";
import "../src/v2/CompositeTransferPolicyV2.sol";
import "../src/v2/MintBurnControllerV2.sol";
import "../src/v2/EscrowControllerV2.sol";
import "../src/v2/WaterfallControllerV2.sol";
import "../src/v2/MigrationControllerV2.sol";

/**
 * @title DeployCentralBankV2
 * @notice Deploys and wires the modular Protocol v2 stack.
 * @dev Profile knobs (holding limits, waterfall, migration) come from env so the
 *      same script can target eurosystem-reference style lab deployments without
 *      baking denomination into the contracts. Sanctions/emergency V2 modules are
 *      not deployed here because those contracts are not yet present in src/v2.
 *
 *      TokenLedgerV2 governance is immutable. The broadcasting deployer must be
 *      the configured GOVERNANCE_ADDRESS so capability and policy wiring can run
 *      in the same transaction batch.
 */
contract DeployCentralBankV2 is Script {
    struct DeploymentConfig {
        address governance;
        address secondAdmin;
        address mintAuthority;
        address burnAuthority;
        address policyAuthority;
        address escrowAuthority;
        address waterfallOperator;
        uint256 maxSupply;
        uint256 maxMintPerOperation;
        uint256 maxBurnPerOperation;
        bool enableHoldingLimits;
        bool enableWaterfall;
        bool deployGovernedPermissioning;
        bool deployMigration;
        bytes32 migrationSnapshotId;
        bytes32 migrationManifestHash;
        bytes32 migrationBalanceRoot;
        uint256 migrationExpectedTotal;
        uint256 migrationClaimDeadline;
    }

    TokenLedgerV2 public ledger;
    HoldingLimitPolicyV2 public holdingLimitPolicy;
    CompositeTransferPolicyV2 public compositePolicy;
    MintBurnControllerV2 public mintBurnController;
    EscrowControllerV2 public escrowController;
    WaterfallControllerV2 public waterfallController;
    MigrationControllerV2 public migrationController;
    GovernedPermissioning public governedPermissioning;

    function run() external {
        DeploymentConfig memory config = loadConfig();
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        require(config.governance == deployer, "GOVERNANCE_ADDRESS must equal deployer");
        if (config.enableWaterfall) {
            require(config.enableHoldingLimits, "waterfall requires holding limits");
        }
        if (config.deployMigration) {
            require(config.migrationClaimDeadline > block.timestamp, "migration deadline must be future");
        }

        vm.startBroadcast(deployerPrivateKey);
        _deployAndWire(config);
        vm.stopBroadcast();
        _printSummary(config);
    }

    function loadConfig() public view returns (DeploymentConfig memory config) {
        address governance = vm.envOr("GOVERNANCE_ADDRESS", vm.envOr("ADMIN_ADDRESS", msg.sender));
        address secondAdmin = vm.envOr("SECOND_ADMIN_ADDRESS", address(0));

        config = DeploymentConfig({
            governance: governance,
            secondAdmin: secondAdmin,
            mintAuthority: vm.envOr("MINT_AUTHORITY_ADDRESS", vm.envOr("ISSUER_ADDRESS", governance)),
            burnAuthority: vm.envOr("BURN_AUTHORITY_ADDRESS", vm.envOr("ISSUER_ADDRESS", governance)),
            policyAuthority: vm.envOr("POLICY_AUTHORITY_ADDRESS", governance),
            escrowAuthority: vm.envOr("ESCROW_AUTHORITY_ADDRESS", vm.envOr("CENTRAL_BANK_ADDRESS", governance)),
            waterfallOperator: vm.envOr("WATERFALL_OPERATOR_ADDRESS", governance),
            maxSupply: vm.envOr("MAX_SUPPLY", uint256(1_000_000_000_00)),
            maxMintPerOperation: vm.envOr("MAX_MINT_PER_OPERATION", uint256(10_000_000_00)),
            maxBurnPerOperation: vm.envOr("MAX_BURN_PER_OPERATION", uint256(10_000_000_00)),
            enableHoldingLimits: vm.envOr("ENABLE_HOLDING_LIMITS", true),
            enableWaterfall: vm.envOr("ENABLE_WATERFALL", true),
            deployGovernedPermissioning: secondAdmin != address(0),
            deployMigration: vm.envOr("DEPLOY_MIGRATION", false),
            migrationSnapshotId: vm.envOr("MIGRATION_SNAPSHOT_ID", bytes32(0)),
            migrationManifestHash: vm.envOr("MIGRATION_MANIFEST_HASH", bytes32(0)),
            migrationBalanceRoot: vm.envOr("MIGRATION_BALANCE_ROOT", bytes32(0)),
            migrationExpectedTotal: vm.envOr("MIGRATION_EXPECTED_TOTAL", uint256(0)),
            migrationClaimDeadline: vm.envOr("MIGRATION_CLAIM_DEADLINE", uint256(0))
        });
    }

    function _deployAndWire(DeploymentConfig memory config) internal {
        if (config.deployGovernedPermissioning) {
            governedPermissioning = new GovernedPermissioning(config.governance, config.secondAdmin);
        }

        ledger = new TokenLedgerV2(config.governance);

        mintBurnController = new MintBurnControllerV2(
            address(ledger),
            config.governance,
            config.mintAuthority,
            config.burnAuthority,
            config.maxSupply,
            config.maxMintPerOperation,
            config.maxBurnPerOperation
        );
        escrowController = new EscrowControllerV2(address(ledger), config.escrowAuthority);

        ledger.setControllerCapabilities(
            address(mintBurnController), ledger.CAPABILITY_MINT() | ledger.CAPABILITY_BURN()
        );
        ledger.setControllerCapabilities(
            address(escrowController), ledger.CAPABILITY_MOVE() | ledger.CAPABILITY_BURN()
        );

        if (config.enableHoldingLimits) {
            holdingLimitPolicy =
                new HoldingLimitPolicyV2(address(ledger), config.governance, config.policyAuthority);
            compositePolicy = new CompositeTransferPolicyV2(config.governance);

            address[] memory policies = new address[](1);
            policies[0] = address(holdingLimitPolicy);
            compositePolicy.replacePolicies(policies);
            ledger.setTransferPolicy(address(compositePolicy));
        }

        if (config.enableWaterfall) {
            waterfallController = new WaterfallControllerV2(
                address(ledger), address(holdingLimitPolicy), config.governance, config.waterfallOperator
            );
            ledger.setControllerCapabilities(address(waterfallController), ledger.CAPABILITY_MOVE());
        }

        if (config.deployMigration) {
            migrationController = new MigrationControllerV2(
                address(ledger),
                config.governance,
                config.migrationSnapshotId,
                config.migrationManifestHash,
                config.migrationBalanceRoot,
                config.migrationExpectedTotal,
                config.migrationClaimDeadline
            );
            ledger.setControllerCapabilities(address(migrationController), ledger.CAPABILITY_MINT());
        }
    }

    function _printSummary(DeploymentConfig memory config) internal view {
        console.log("=== CentralBank Protocol v2 Deployment Complete ===");
        console.log("  Profile intent:       eurosystem-reference (env-driven)");
        console.log("  Governance:           ", config.governance);
        console.log("  TokenLedgerV2:        ", address(ledger));
        console.log("  MintBurnController:   ", address(mintBurnController));
        console.log("  EscrowController:     ", address(escrowController));
        if (address(holdingLimitPolicy) != address(0)) {
            console.log("  HoldingLimitPolicy:   ", address(holdingLimitPolicy));
            console.log("  CompositePolicy:      ", address(compositePolicy));
        }
        if (address(waterfallController) != address(0)) {
            console.log("  WaterfallController:  ", address(waterfallController));
        }
        if (address(migrationController) != address(0)) {
            console.log("  MigrationController:  ", address(migrationController));
        }
        if (address(governedPermissioning) != address(0)) {
            console.log("  GovernedPermissioning:", address(governedPermissioning));
        }
        console.log("  Holding limits:       ", config.enableHoldingLimits);
        console.log("  Waterfall:            ", config.enableWaterfall);
    }
}

/**
 * @title DeployLabEnvironmentV2
 * @notice Single-authority local/lab deployment for Protocol v2.
 * @dev Uses the unlocked Foundry sender. Suitable for Anvil and Kind/Besu labs.
 *      Does not deploy MigrationControllerV2; supply snapshot metadata via the
 *      keyed DeployCentralBankV2 path when rehearsing cutover.
 */
contract DeployLabEnvironmentV2 is Script {
    function run() external {
        address deployer = msg.sender;
        bool enableHoldingLimits = vm.envOr("ENABLE_HOLDING_LIMITS", true);
        bool enableWaterfall = vm.envOr("ENABLE_WATERFALL", true);
        uint256 maxSupply = vm.envOr("MAX_SUPPLY", uint256(1_000_000_000_00));
        uint256 maxMintPerOperation = vm.envOr("MAX_MINT_PER_OPERATION", uint256(10_000_000_00));
        uint256 maxBurnPerOperation = vm.envOr("MAX_BURN_PER_OPERATION", uint256(10_000_000_00));

        if (enableWaterfall) {
            require(enableHoldingLimits, "waterfall requires holding limits");
        }

        vm.startBroadcast();

        TokenLedgerV2 ledger = new TokenLedgerV2(deployer);

        MintBurnControllerV2 mintBurn = new MintBurnControllerV2(
            address(ledger),
            deployer,
            deployer,
            deployer,
            maxSupply,
            maxMintPerOperation,
            maxBurnPerOperation
        );
        EscrowControllerV2 escrow = new EscrowControllerV2(address(ledger), deployer);

        ledger.setControllerCapabilities(
            address(mintBurn), ledger.CAPABILITY_MINT() | ledger.CAPABILITY_BURN()
        );
        ledger.setControllerCapabilities(
            address(escrow), ledger.CAPABILITY_MOVE() | ledger.CAPABILITY_BURN()
        );

        HoldingLimitPolicyV2 holdingPolicy;
        CompositeTransferPolicyV2 compositePolicy;
        WaterfallControllerV2 waterfall;

        if (enableHoldingLimits) {
            holdingPolicy = new HoldingLimitPolicyV2(address(ledger), deployer, deployer);
            compositePolicy = new CompositeTransferPolicyV2(deployer);
            address[] memory policies = new address[](1);
            policies[0] = address(holdingPolicy);
            compositePolicy.replacePolicies(policies);
            ledger.setTransferPolicy(address(compositePolicy));
        }

        if (enableWaterfall) {
            waterfall = new WaterfallControllerV2(address(ledger), address(holdingPolicy), deployer, deployer);
            ledger.setControllerCapabilities(address(waterfall), ledger.CAPABILITY_MOVE());
        }

        vm.stopBroadcast();

        console.log("export TOKEN_LEDGER_V2_ADDRESS=", address(ledger));
        console.log("export MINT_BURN_CONTROLLER_V2_ADDRESS=", address(mintBurn));
        console.log("export ESCROW_CONTROLLER_V2_ADDRESS=", address(escrow));
        if (address(holdingPolicy) != address(0)) {
            console.log("export HOLDING_LIMIT_POLICY_V2_ADDRESS=", address(holdingPolicy));
            console.log("export COMPOSITE_TRANSFER_POLICY_V2_ADDRESS=", address(compositePolicy));
        }
        if (address(waterfall) != address(0)) {
            console.log("export WATERFALL_CONTROLLER_V2_ADDRESS=", address(waterfall));
        }
        console.log("export GOVERNANCE_ADDRESS=", deployer);
    }
}

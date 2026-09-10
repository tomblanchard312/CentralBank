# CentralBank Smart Contracts

Solidity smart contracts for the **CentralBank Digital Token Protocol**, including the current `DigitalToken` integration path and the newer modular ledger/controller architecture.

CentralBank is currency-agnostic. The generic protocol asset is **CBDT (Central Bank Digital Token)**. Currency denomination and jurisdiction-specific policy belong in deployment profiles such as `eurosystem-reference`.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

CI currently pins Foundry to the version defined in the repository workflows. Use the same version locally when reproducing formatter/build behavior.

## Project structure

```text
contracts/
├── src/
│   ├── interfaces/
│   ├── Permissioning.sol
│   ├── WalletRegistry.sol
│   ├── DigitalToken.sol
│   ├── ConditionalPayments.sol
│   └── ... modular ledger, policy and controller contracts
├── script/
│   ├── DeployCentralBank.s.sol
│   └── Interactions.s.sol
├── test/
├── foundry.toml
├── .env.example
└── README.md
```

## Core contracts

| Contract / component | Purpose |
| --- | --- |
| `Permissioning` | Role and institutional authorization |
| `WalletRegistry` | Wallet registration, participant metadata, linked settlement references and limits |
| `DigitalToken` | Generic CBDT token used by the current integration path |
| `ConditionalPayments` | Escrow-based conditional payment flows |
| `TokenLedgerV2` | Modular balance ledger with scoped controller capabilities |
| `MintBurnControllerV2` | Dedicated issuance/redemption controller |
| `EscrowControllerV2` | Case-based escrow lifecycle controller |
| `WaterfallControllerV2` | Holding-limit overflow and reverse-waterfall controller |
| `CompositeTransferPolicyV2` | Composable transfer-policy enforcement |
| `HoldingLimitPolicyV2` | Holding-limit policy module |

The architectural direction is that the ledger owns balances and controllers receive narrowly scoped capabilities. Controllers should not become independent balance stores.

## Token identity

Generic protocol identity:

- **Name:** Central Bank Digital Token
- **Symbol:** CBDT
- **Core contract:** `DigitalToken`
- **Denomination:** deployment/profile parameter
- **Precision:** deployment/profile parameter where applicable

For the `eurosystem-reference` profile, the denomination is EUR with two decimal places. That EUR configuration is a profile choice, not part of the generic CBDT identity.

## Quick start

### Install dependencies

```bash
cd contracts
forge install foundry-rs/forge-std --no-commit
```

### Build

```bash
forge build
```

### Format changed Solidity

```bash
forge fmt
```

### Test

```bash
forge test -vvv
```

### Run the invariant suite

```bash
FOUNDRY_PROFILE=ci forge test --match-contract DigitalTokenInvariantTest -vvv
```

## Local deployment

Start Anvil:

```bash
anvil
```

Deploy the lab environment using the CentralBank deployment script:

```bash
forge script script/DeployCentralBank.s.sol:DeployLabEnvironment \
  --rpc-url http://localhost:8545 \
  --broadcast
```

For explicit-key deployment modes, provide only the environment-specific signer inputs required by `DeployCentralBank.s.sol`. Do not commit private keys or `.env` files.

## Interacting with DigitalToken

Example balance query:

```bash
cast call $DIGITAL_TOKEN_ADDRESS \
  "balanceOf(address)(uint256)" \
  $USER_ADDRESS
```

Example wallet registration:

```bash
cast send $WALLET_REGISTRY_ADDRESS \
  "registerWallet(address,uint8,address,bytes32)" \
  $USER_ADDRESS 1 $BANK_ADDRESS 0x1234...
```

Example CBDT issuance through the current `DigitalToken` path:

```bash
cast send $DIGITAL_TOKEN_ADDRESS \
  "mint(address,uint256,bytes32)" \
  $USER_ADDRESS 10000 $(cast keccak256 "unique-key-1")
```

The caller must hold the required issuance authority. In the refactored token, mint and burn authority use dedicated `MINTER_ROLE` and `BURNER_ROLE` semantics.

## Profile-scoped holding limits

Holding limits are policy/profile values. For example, an EUR-denominated reference profile may configure different limits for individuals, merchants, PSPs, banks, or central-bank participants.

Do not treat any example EUR limit as a property of CBDT itself.

## Security principles

- never commit private keys or environment secrets
- production local-key signing is not an acceptable final custody model
- use explicit institutional authorization and least-privilege controller capabilities
- preserve payer authorization for economic-custody operations
- preserve replay/idempotency protections on privileged actions
- validate role/capability wiring after deployment
- run unit, fuzz, invariant, and integration suites before release
- conduct independent security assessment before production use

## Production status

These contracts are still **pre-MVP**. Production operation additionally requires hardened signer custody, deterministic deployment and role wiring, full-system integration validation, operational rehearsal, gas/DoS analysis, durable audit/reconciliation infrastructure, and independent security review.

## Non-affiliation

The `eurosystem-reference` profile may be informed by publicly available digital-euro and Eurosystem concepts. CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.

## License

See the repository root [`LICENSE`](../LICENSE).

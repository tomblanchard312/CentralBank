# CentralBank — Agent Instructions

This repository is the **CentralBank** reference platform for the **CentralBank Digital Token Protocol**. The generic protocol asset is **CBDT**. It is pre-MVP research and engineering infrastructure, not production sovereign money.

**Reference MVP scope:** the v1 institutional path (`DigitalToken` + API). Protocol v2 is deployable in parallel; set `PROTOCOL_STACK=v2` to cut the gateway over to V2 controllers. See [docs/mvp-plan.md](docs/mvp-plan.md).

Read this file first, then [README.md](README.md), [docs/canonical-naming.md](docs/canonical-naming.md), and [docs/smart-contracts-architecture.md](docs/smart-contracts-architecture.md). GitHub Copilot policy anchors live in [.github/copilot-instructions.md](.github/copilot-instructions.md).

## Canonical names

| Layer | Name |
| --- | --- |
| Platform | CentralBank |
| Protocol | CentralBank Digital Token Protocol |
| Token | Central Bank Digital Token (**CBDT**) |
| Core token (v1 API path) | `DigitalToken` |
| Modular ledger (v2) | `TokenLedgerV2` |
| Initial profile | `eurosystem-reference` (EUR, 2 decimals) |

Do not reintroduce `T-EUR`, `tEUR`, `TEUR`, or `TokenizedEuro` as product names. Do not claim ECB, Eurosystem, or national-central-bank issuance, endorsement, or operation.

## Current wiring (truth table)

| Area | Status |
| --- | --- |
| v1 contracts + lab/API deploy | Implemented: `DeployCentralBank.s.sol` / `DeployLabEnvironment` |
| Protocol v2 contracts | Implemented under `contracts/src/v2/` with Foundry tests |
| Protocol v2 deploy | Implemented: `DeployCentralBankV2.s.sol` / `DeployLabEnvironmentV2` (`make deploy-local-v2`) |
| Institutional API | Default **v1**; `PROTOCOL_STACK=v2` routes mint/burn/freeze/escrow/waterfall/pause to V2 |
| `profiles/eurosystem-reference.json` | Reference artifact; deploy/API still use env / `envs/` config |
| Sanctions / emergency V2 policies | Implemented; API uses them when `PROTOCOL_STACK=v2` |
| `GovernedPermissioning` | Implemented; deployed by V2 script when `SECOND_ADMIN_ADDRESS` is set |
| Migration | Balance Merkle claims in `MigrationControllerV2`; full ADR-001 state migration incomplete |
| ConditionalPayments on V2 | Not available; rejected when `PROTOCOL_STACK=v2` |
| WalletRegistry on V2 | Not available; registration rejected when `PROTOCOL_STACK=v2` |

## Repository map

```text
contracts/     Solidity (v1 + v2), Foundry scripts/tests
api/           Node 20 institutional gateway (v1 + PROTOCOL_STACK=v2 ABIs)
profiles/      Denomination / policy reference profiles
deploy/        Kubernetes, Terraform, mTLS helpers
modules/       Reusable Terraform modules
envs/          Per-zone overlays
docs/          Architecture, runbooks, specs, compliance
tools/         Reconciliation and integrity tooling
dashboard/     Operator UI
sdk/           TypeScript client (`CentralBankClient`)
```

## How to work in this repo

1. Keep generic protocol code currency-agnostic. Put EUR / Eurosystem assumptions in the profile, docs, or adapters.
2. Prefer extending Protocol v2 modules over growing the v1 `DigitalToken` monolith, unless the task is explicitly API/v1 compatibility.
3. When deploying locally: `cd contracts && make deploy-local` (API path) or `make deploy-local-v2` (Protocol v2).
4. Keyed V2 deploys require `GOVERNANCE_ADDRESS` == deployer (`TokenLedgerV2` governance is immutable).
5. Document V2 API only when `PROTOCOL_STACK=v2` and V2 addresses are configured; ConditionalPayments and WalletRegistry remain v1-only.
6. Preserve payer-signed custody for economic transfers. Shared API signers are relays, not payers.
7. Controllers mutate balances only through scoped ledger capabilities. Controllers are not independent monetary ledgers.
8. Fail closed. No silent catches, invented endpoints, or fake “done” claims for unimplemented production blockers.

## Commands

```bash
# Contracts
cd contracts && forge build && forge test -vvv
make deploy-local
make deploy-local-v2

# API
cd api && npm ci && npm run test && npm run dev

# Protocol v2 lab API env
./scripts/lab-mvp-smoke-v2.sh   # or scripts/lab-mvp-smoke-v2.ps1
```

## Production blockers (do not hide)

Still required before any production financial operation claim:

- KMS/HSM-backed signing
- Durable distributed idempotency / nonce / API-key / rate-limit state
- Append-only durable audit persistence
- Deny-by-default institutional route classification
- Hardened production manifests
- ConditionalPayments + WalletRegistry on the V2 ledger
- Runtime profile loading into deploy/API
- Non-balance migration and reconciliation
- Full-system e2e / invariant validation, gas/DoS analysis, rehearsals, independent security assessment

## Payment / terminal integrations

Acquirer-mediated only. No direct Verifone/hardware settlement-core integration, no PAN/PIN/cardholder data in this repo’s settlement path, no value storage on terminals, no assumed permanent connectivity. Refuse requests that break those boundaries.

## Key references

- [docs/architecture/adr-001-protocol-v2-contract-architecture.md](docs/architecture/adr-001-protocol-v2-contract-architecture.md)
- [docs/architecture/adr-004-centralbank-cbdt-naming.md](docs/architecture/adr-004-centralbank-cbdt-naming.md)
- [docs/smart-contracts-architecture.md](docs/smart-contracts-architecture.md)
- [profiles/README.md](profiles/README.md)
- [ECB-ALIGNMENT.md](ECB-ALIGNMENT.md) (eurosystem-reference mapping only)

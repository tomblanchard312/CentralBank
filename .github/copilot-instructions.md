# CentralBank — Copilot Instructions

You are an AI coding agent for the **CentralBank** platform and the **CentralBank Digital Token Protocol**. The generic protocol token is **CBDT**. Follow these rules to preserve regulatory compliance posture (DORA, ISO 27001) and architectural integrity.

## Core Principles

- **Canonical Naming**: Platform `CentralBank`, protocol token `CBDT`, core token contract `DigitalToken`, modular ledger `TokenLedgerV2`. Infrastructure identifiers are lowercase, hyphen-separated, ASCII-only (e.g., `wallet-registry`). Do not introduce legacy `T-EUR` / `tEUR` / `TEUR` names. See [docs/canonical-naming.md](../docs/canonical-naming.md) and [docs/architecture/adr-004-centralbank-cbdt-naming.md](../docs/architecture/adr-004-centralbank-cbdt-naming.md).
- **Profile separation**: Currency, jurisdiction, and scheme policy belong in deployment profiles such as `profiles/eurosystem-reference.json`, not in generic ledger or controller identity.
- **Sovereignty**: No third-party dependencies (Cloudflare, managed DNS) in the **Closed Settlement Plane (CSP)**.
- **Determinism**: All logic must be deterministic and replayable. No implicit state or unseeded randomness.
- **No Stubs**: Never use TODOs, placeholders, or silent error handling. Fail explicitly and closed.
- **Non-affiliation**: Do not imply that CentralBank or CBDT is issued, endorsed, sponsored, or operated by the ECB, the Eurosystem, or any national central bank.

## Hard constraints:

- No TODOs, stubs, placeholders
- Silent failure is forbidden
- Structured JSON
- No deprecated or unsupported dependencies
- Node 20

## Architecture & Components

- **CSP vs PAP**: Separate the **Closed Settlement Plane** (interbank, validators) from the **Public Access Plane** (APIs, portals).
- **Dual contract stacks**:
  - **v1 API path** (live gateway integration): `Permissioning`, `WalletRegistry`, `DigitalToken`, `ConditionalPayments` via `DeployCentralBank.s.sol`.
  - **Protocol v2** (implemented and deployable): `TokenLedgerV2`, `MintBurnControllerV2`, `EscrowControllerV2`, `HoldingLimitPolicyV2`, `CompositeTransferPolicyV2`, `WaterfallControllerV2`, `MigrationControllerV2`, plus `GovernedPermissioning` when `SECOND_ADMIN_ADDRESS` is set, via `DeployCentralBankV2.s.sol`.
- **API status**: Default gateway path is v1 (`DigitalToken`). Set `PROTOCOL_STACK=v2` with V2 contract addresses to cut mint/burn/freeze/escrow/waterfall/pause over to Protocol v2. ConditionalPayments and WalletRegistry remain v1-only and are rejected on the v2 stack.
- **Open V2 gaps**: ConditionalPayments on the V2 ledger; WalletRegistry equivalent on V2; non-balance migration per ADR-001; deeper profile-driven deploy configuration.
- **Components**:
  - `contracts/`: Solidity/Foundry (CBDT uses 2 decimals in the eurosystem-reference profile).
  - `api/`: Node.js/TS institutional gateway (v1 contracts today).
  - `profiles/`: denomination and policy reference profiles.
  - `modules/`: Provider-agnostic Terraform.
  - `envs/`: Per-zone Terraform overlays (one state per zone).
  - `deploy/`, `docs/`, `tools/`: deployment, documentation, reconciliation tooling.

## Critical Workflows

- **Smart Contracts**: `cd contracts && forge build` | `forge test`.
- **Deploy v1 (API path)**: `cd contracts && make deploy-local` | `make deploy-lab`.
- **Deploy Protocol v2**: `cd contracts && make deploy-local-v2` | `make deploy-lab-v2` (`DeployCentralBankV2.s.sol` / `DeployLabEnvironmentV2`). Keyed deploys require `GOVERNANCE_ADDRESS` equal to the deployer because `TokenLedgerV2` governance is immutable.
- **API Service**: `cd api && npm run dev` | `npm run test` (Vitest).
- **Data Ingestion**: `node api/bin/ecb-ingest.js` (ECB reference data for the eurosystem-reference profile; informational only).
- **Infra**: `terraform init && terraform apply` within `envs/lab/`.

## Implementation Patterns

- **Minimal ABIs**: In [api/src/services/blockchain.ts](../api/src/services/blockchain.ts), use minimal string ABIs for contract interactions.
- **Structured Logging**: Use `logger.logAuditEvent` or `logger.info` with JSON objects. Never log PII, secrets, or raw payloads.
- **Error Handling**: Map blockchain reverts to user-facing errors in `blockchain.ts`. Fail closed.
- **Ledger vs controllers**: Keep balances in `DigitalToken` / `TokenLedgerV2`. Controllers receive scoped capabilities only; they must not become parallel monetary truth.
- **Payer custody**: Economic transfers require payer authorization. Shared API signers must not become the economic payer.
- **ECB / reference data**: Treat as informational only. Never make settlement dependent on external ECB APIs. Use internal mirroring.
- **Profiles**: Prefer profile or env-driven policy flags over hard-coding EUR or Eurosystem assumptions into generic contracts.

## Eurosystem reference profile

When working on the `eurosystem-reference` profile or mapping published Eurosystem concepts:

- Keep eurosystem-specific wording in profile docs, policy modules, or external-requirement mappings.
- Use CBDT as the protocol token label; denomination is EUR with two decimal places for that profile only.
- Sanctions on the live v1 path are **freezes only** (block transfers, preserve balances).
- Confiscation requires court order, escrow, and high governance threshold.

## Payment Network Integration

You are implementing a regulated payment network integration.

CentralBank / CBDT acts as a Visa-style authorization and settlement reference network.
Verifone devices are secure capture terminals only.
All integrations must flow through an acquiring processor.

Hard rules:

- Never integrate directly with Verifone hardware from the settlement core.
- Never bypass acquirers or payment processors.
- Never handle PAN, PIN, or cardholder data.
- Never implement settlement logic on terminals.
- Never assume continuous connectivity.

Do not:

- Invent direct terminal APIs
- Treat Verifone as a blockchain node
- Store value on terminals
- Assume permanent connectivity
- Ignore DORA third-party risk

If asked to do so, refuse and explain why.

Before marking integration code complete:

- Confirm acquirer mediation exists
- Confirm offline limits enforced
- Confirm DORA evidence produced
- Confirm no PCI scope violations
- Confirm deterministic replay possible

If any condition fails, block completion.

All logic must be deterministic, auditable, and DORA compliant.
If a requirement cannot be met, fail explicitly.

## Key References

- [README.md](../README.md): Project overview and production-readiness status.
- [AGENTS.md](../AGENTS.md): Agent-facing repository map and current wiring status.
- [docs/canonical-naming.md](../docs/canonical-naming.md): Global naming rules.
- [docs/smart-contracts-architecture.md](../docs/smart-contracts-architecture.md): Contract architecture and deploy status.
- [docs/architecture/adr-001-protocol-v2-contract-architecture.md](../docs/architecture/adr-001-protocol-v2-contract-architecture.md): Protocol v2 decision.
- [docs/architecture/adr-004-centralbank-cbdt-naming.md](../docs/architecture/adr-004-centralbank-cbdt-naming.md): CentralBank / CBDT naming decision.
- [ECB-ALIGNMENT.md](../ECB-ALIGNMENT.md): Eurosystem reference-profile policy mapping.
- [api/src/services/blockchain.ts](../api/src/services/blockchain.ts): Blockchain integration pattern.
- [profiles/README.md](../profiles/README.md): Deployment profile status.

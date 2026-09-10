# CentralBank

**Open-source reference infrastructure for central-bank digital tokens.**

CentralBank is a modular reference platform for issuing, governing, transferring, settling, reconciling, and auditing sovereign digital money. The protocol is designed to keep the ledger currency-agnostic while allowing denomination, jurisdictional rules, institutional controls, and scheme-specific policy to be supplied through deployment profiles.

The generic reference asset is the **Central Bank Digital Token (CBDT)**. CBDT is a technical protocol asset, not a currency, stablecoin, or claim of central-bank issuance.

> **Project status:** Pre-MVP research and engineering reference implementation. CentralBank is not production financial infrastructure.

## Why CentralBank?

Central-bank digital-money systems need more than a token contract. They require controlled issuance and redemption, institutional authorization, policy enforcement, settlement controls, auditability, operational resilience, migration procedures, and clear separation between monetary policy rules and ledger accounting.

CentralBank models those concerns as independent protocol components instead of embedding one currency or jurisdiction directly into the core token.

## Architecture

```text
                         CentralBank
                              |
              CentralBank Digital Token Protocol
                              |
        +---------------------+---------------------+
        |                     |                     |
   Core Ledger           Policy Engine         Governance
        |                     |                     |
  DigitalToken          Holding limits      Role management
  TokenLedgerV2         Sanctions           Authority rotation
  Mint / Burn           Emergency controls  Dual control
  Transfers             Waterfall
        |
        +---------------------+---------------------+
                              |
                         Controllers
                              |
              Escrow / Waterfall / Migration
                              |
                    Institutional Gateway
                              |
              mTLS / HMAC / authorization
                              |
                  Reconciliation & Audit
                              |
                     Deployment Profiles
                              |
                  eurosystem-reference
                              |
                             EUR
```

The protocol separates accounting from policy and operational authority:

- **DigitalToken / TokenLedgerV2** provide token accounting and controlled ledger capabilities.
- **Mint/Burn controllers** provide authorized issuance and redemption with limits, pause controls, replay protection, and audit references.
- **Escrow controllers** provide case-based holds with explicit release, burn, cancellation, and expiry lifecycles.
- **Waterfall controllers** support holding-limit overflow and reverse-waterfall settlement flows.
- **Transfer policies** compose sanctions, emergency controls, holding limits, and future compliance modules without coupling them to ledger accounting.
- **Institutional gateway** provides API authorization, payer-custody enforcement, mTLS identity, request signing, and transaction relay.
- **Governance** provides governed permissioning, dual-control administration, and authority rotation.
- **Migration** supports snapshot-based balance migration with reconciliation and controlled finalization.
- **Reconciliation and audit** provide operational evidence, integrity checks, and release-assurance tooling.

## Reference profiles

The core protocol does not assume that CBDT represents euros, dollars, pounds, or any other denomination. Deployment profiles supply those parameters.

The initial profile is [`profiles/eurosystem-reference.json`](profiles/eurosystem-reference.json), which currently uses:

| Parameter | Reference value |
| --- | --- |
| Profile | `eurosystem-reference` |
| Denomination | EUR |
| Minor unit | cent |
| Protocol token | CBDT |
| Holding limits | Enabled |
| Waterfall controls | Enabled |
| Sanctions / emergency policy | Enabled |
| Conditional payments | Supported |

The Eurosystem profile exists to exercise the generic architecture against concepts relevant to a European central-bank digital-money deployment. Euro-specific assumptions should live in this profile or its policy modules rather than in the identity of the core protocol.

Additional profiles can use the same protocol with different denominations, limits, governance models, and policy modules.

## Protocol components

### Ledger and token

`DigitalToken` and `TokenLedgerV2` form the accounting layer. Controller capabilities are intentionally separated from balances so operational modules can be upgraded or governed without turning each controller into a separate source of monetary truth.

### Issuance and redemption

The mint/burn architecture separates issuance and redemption authorities and supports supply caps, operation limits, independent pause controls, authority rotation, opaque audit-reference hashes, and replay protection.

### Escrow and conditional settlement

Escrow uses immutable case identifiers and explicit lifecycle states. Conditional-payment flows preserve payer custody by requiring payer-authorized transactions rather than allowing a shared API signer to become the economic payer.

### Holding limits and waterfall

Holding-limit policy can restrict wallet balances while exempting authorized accounts. Waterfall flows can atomically route excess value to linked settlement destinations, while reverse-waterfall operations remain capped by available wallet capacity.

### Migration

The migration framework supports Merkle-based balance migration using immutable snapshot metadata, claim deadlines, duplicate-claim protection, governance pause/resume controls, and exact migrated-total reconciliation before finalization.

## Institutional security model

CentralBank is designed around explicit institutional and transaction-level trust boundaries. Current reference controls include:

- payer-signed custody-preserving transfers
- institutional mTLS for privileged gateway routes
- request authentication and authorization
- HMAC/request-signature support
- replay and idempotency protection
- governed role administration and authority rotation
- emergency pause and account controls
- scoped controller capabilities
- fail-closed production configuration
- unit, fuzz, invariant, and integration testing
- reconciliation and release-assurance checks

Institutional mTLS is an additional authentication factor, not a replacement for transaction authorization, API credentials, role checks, idempotency, or audit controls.

## Production-readiness status

CentralBank is intentionally marked **pre-MVP**. The repository contains substantial protocol and security engineering, but a successful build does not mean the platform is ready to operate sovereign financial infrastructure.

Major production blockers still include:

- production KMS/HSM-backed signing
- durable distributed idempotency, nonce, API-key, and rate-limit state
- append-only durable audit persistence
- deny-by-default institutional route classification
- hardened production deployment manifests
- complete Protocol v2 API wiring
- deterministic capability and permissioning deployment
- non-balance migration and reconciliation
- full-system end-to-end and invariant validation
- gas, contract-size, and denial-of-service analysis
- deployment and migration rehearsals
- independent security assessment

These items should remain explicit release gates rather than being hidden behind an MVP label.

## Repository direction

The project is moving toward the following model:

```text
CentralBank
├── contracts/          # Ledger, policies, controllers, governance
├── api/                # Institutional gateway and transaction APIs
├── profiles/           # Jurisdiction / denomination reference profiles
├── reconciliation/     # Reconciliation and integrity tooling
├── deploy/             # Deployment and gateway infrastructure
├── docs/
│   ├── architecture/   # ADRs and protocol design
│   └── runbooks/       # Operational procedures
└── tests / CI          # Unit, fuzz, invariant and integration assurance
```

The naming and abstraction decision is recorded in [`docs/architecture/adr-004-centralbank-cbdt-naming.md`](docs/architecture/adr-004-centralbank-cbdt-naming.md).

## Naming

| Layer | Name |
| --- | --- |
| Platform | **CentralBank** |
| Protocol | **CentralBank Digital Token Protocol** |
| Generic token | **Central Bank Digital Token** |
| Symbol | **CBDT** |
| Core token contract | `DigitalToken` |
| Initial reference profile | `eurosystem-reference` |
| Initial denomination | EUR |

Legacy T-EUR terminology is not the identity of the new architecture. The platform is intended to remain reusable across central-bank and currency models.

## What this project is not

CentralBank is not itself a central bank, currency, stablecoin, live payment network, or authorization to issue sovereign money. CBDT has no inherent monetary value. Deploying the software does not create central-bank money or establish a claim against any central bank or government.

## Eurosystem / ECB disclaimer

The Eurosystem reference profile is an independent technical reference informed by publicly available concepts and requirements relevant to digital central-bank money.

**CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.** References to the ECB, Eurosystem, EUR, or digital-euro concepts describe the technical reference profile and do not imply affiliation.

## Intended audience

CentralBank is intended for:

- central-bank and public-sector technology research
- financial institutions and payment-service providers
- protocol and security engineers
- regulators and policy researchers
- academic CBDC and digital-money research
- teams evaluating sovereign-cloud and institutional settlement architectures

## Contributing

Contributions should preserve the separation between the generic protocol and deployment-specific policy. New jurisdictional or currency-specific behavior should generally be introduced through profiles, policy modules, or clearly scoped adapters rather than hard-coded into `DigitalToken` or the core ledger.

Security-sensitive changes should include appropriate unit, fuzz, invariant, integration, or migration validation for the affected trust boundary.

## License

CentralBank is licensed under the MIT License. See [`LICENSE`](LICENSE) for details.

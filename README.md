# CentralBank

**CentralBank** is an open-source reference platform for issuing, governing, transferring, settling, and auditing central-bank digital tokens.

The core protocol is currency-agnostic. Its generic reference asset is the **Central Bank Digital Token (CBDT)**. Currency denomination, jurisdictional parameters, and scheme-specific policy are supplied through deployment profiles rather than encoded into the token's identity.

## Architecture

The CentralBank Digital Token Protocol separates accounting from policy and operational authority:

- **DigitalToken / TokenLedgerV2** - token accounting and ledger capabilities
- **Mint/Burn controllers** - controlled issuance and redemption
- **Escrow controllers** - case-based holds and lifecycle management
- **Waterfall controllers** - holding-limit and linked-settlement flows
- **Transfer policies** - sanctions, emergency controls, holding limits, and future compliance modules
- **Institutional gateway** - API authorization, payer custody, mTLS, request signing, and transaction relay
- **Governance** - governed permissioning and authority rotation
- **Reconciliation and audit** - operational evidence and integrity tooling
- **Migration** - snapshot-based protocol migration and reconciliation

## Reference profiles

The first profile is `profiles/eurosystem-reference.json`.

It uses:

- denomination: **EUR**
- minor unit: **cent**
- token identity: **CBDT**
- holding-limit and waterfall controls
- sanctions and emergency policy controls
- conditional-payment support

The profile is intended to explore concepts relevant to a Eurosystem-style deployment while keeping the core protocol reusable for other central-bank and currency models.

## Naming

| Layer | Name |
| --- | --- |
| Platform | CentralBank |
| Protocol | CentralBank Digital Token Protocol |
| Generic token | Central Bank Digital Token |
| Symbol | CBDT |
| Core token contract | `DigitalToken` |
| Initial policy profile | `eurosystem-reference` |
| Initial denomination | EUR |

The naming decision is recorded in `docs/architecture/adr-004-centralbank-cbdt-naming.md`.

## Security model

The reference platform includes controls for:

- payer-signed custody-preserving transfers
- institutional mTLS for privileged API routes
- request authentication and authorization
- replay and idempotency protection
- governed role management
- emergency pause and account controls
- invariant and integration testing
- fail-closed production configuration

This repository is still **pre-MVP**. Production gaps such as production KMS/HSM signing, durable distributed idempotency and rate-limit state, append-only audit persistence, deployment hardening, and independent security assessment remain explicit release blockers.

## What this project is not

CentralBank does not constitute a currency or live payment system. CBDT has no monetary value and is a generic technical reference token. The repository is not production financial infrastructure and does not provide authority to issue sovereign money.

## Eurosystem / ECB disclaimer

The Eurosystem reference profile is informed by published concepts and requirements relevant to digital central-bank money. **CentralBank and CBDT are not issued, endorsed, sponsored, or operated by the European Central Bank, the Eurosystem, or any national central bank.** This repository is an independent open-source technical reference implementation.

## Intended audience

CentralBank is intended for engineers, researchers, financial institutions, public-sector technology teams, regulators, and academic users studying central-bank digital-token architecture, settlement, governance, security, and operational resilience.

## License

This project is licensed under the MIT License. See `LICENSE` for details.

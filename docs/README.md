# CentralBank Documentation

This directory contains architecture, policy, operations, integration, compliance, and reference-profile documentation for the **CentralBank Digital Token Protocol**.

## Documentation model

CentralBank separates generic protocol documentation from jurisdiction-specific reference material.

- **Generic protocol documentation** describes CBDT, ledger/controller architecture, governance, security, settlement, migration, reconciliation, deployment, and operational controls without assuming a currency or central bank.
- **Reference-profile documentation** describes how those generic components can be parameterized for a particular policy environment. The first profile is `eurosystem-reference`, denominated in EUR.
- **External-standard and regulatory references** may discuss the ECB, Eurosystem, DORA, ISO standards, or other institutions and frameworks. Those references describe requirements or context and do not make CentralBank an official implementation of those organizations.

## Start here

| Document | Purpose |
| --- | --- |
| [`../README.md`](../README.md) | Project overview and current production-readiness status |
| [`canonical-naming.md`](canonical-naming.md) | Authoritative CentralBank/CBDT terminology and naming rules |
| [`smart-contracts-architecture.md`](smart-contracts-architecture.md) | Current and target smart-contract architecture |
| [`architecture/adr-004-centralbank-cbdt-naming.md`](architecture/adr-004-centralbank-cbdt-naming.md) | Decision record for the CentralBank/CBDT refactor |
| [`central-bank-pilot-plan.md`](central-bank-pilot-plan.md) | Pilot-planning guidance |
| [`offline-payments-architecture.md`](offline-payments-architecture.md) | Offline-payment architecture and constraints |
| [`fees-and-limits.md`](fees-and-limits.md) | Profile-scoped fee and holding-limit guidance |
| [`runbooks/`](runbooks/) | Operational and incident-response runbooks |
| [`compliance/`](compliance/) | Compliance and control mappings |
| [`specs/`](specs/) | API and protocol specifications |
| [`merchant/`](merchant/) | Merchant acceptance, receipt, and certification guidance |

## Canonical terminology

| Concept | Canonical term |
| --- | --- |
| Platform | **CentralBank** |
| Protocol | **CentralBank Digital Token Protocol** |
| Generic protocol token | **Central Bank Digital Token (CBDT)** |
| Core token contract | `DigitalToken` |
| Initial profile | `eurosystem-reference` |
| Initial profile denomination | EUR |

`T-EUR`, `tEUR`, and `TokenizedEuro` are legacy pre-MVP names and should not be used for new generic documentation.

The phrase **digital euro** may still appear where the documentation is explicitly discussing published Eurosystem concepts, external requirements, historical design context, or the `eurosystem-reference` profile. Such usage should not be used as a synonym for CentralBank or CBDT.

## Documentation rules

When adding or updating documentation:

1. Keep generic protocol behavior separate from profile-specific policy.
2. Do not embed EUR assumptions into generic token or ledger descriptions.
3. Describe current implementation separately from target architecture when they differ.
4. Do not claim an API endpoint, service, automation, or operational guarantee exists unless it is implemented or clearly labeled as a proposed/reference design.
5. Keep security and production-readiness gaps explicit.
6. Use opaque case/document references in examples rather than confidential data.
7. Preserve the non-affiliation statement in public-facing Eurosystem reference material.
8. Keep multilingual runbooks semantically aligned with the English canonical runbooks when changes affect security or operations.

## Status labels

Where useful, documents should distinguish:

- **Implemented**: present in the repository and covered by applicable tests or deployment code.
- **Reference design**: architectural direction or example not yet fully wired into runtime paths.
- **Profile-specific**: behavior or parameter supplied by a deployment/reference profile.
- **Production blocker**: required before operating the platform as production financial infrastructure.

## Non-affiliation

CentralBank is an independent open-source technical reference implementation. The `eurosystem-reference` profile may be informed by publicly available Eurosystem and digital-euro concepts, but CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.

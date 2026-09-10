# CentralBank Canonical Naming Conventions

This document defines the authoritative naming conventions for the **CentralBank** platform and the **CentralBank Digital Token Protocol**.

CentralBank is a currency-agnostic reference platform. The generic protocol token is the **Central Bank Digital Token (CBDT)**. Currency, jurisdiction, and scheme-specific terminology belong in deployment profiles such as `eurosystem-reference` rather than in the identity of the core platform.

These conventions are intended to:

- keep the protocol reusable across jurisdictions and denominations
- support sovereign and private deployment environments
- avoid vendor lock-in
- preserve clear trust boundaries
- improve regulatory and operational readability
- prevent architecture and terminology drift

## 1. Platform terminology

| Layer | Canonical name |
| --- | --- |
| Platform | `CentralBank` |
| Protocol | `CentralBank Digital Token Protocol` |
| Generic token | `Central Bank Digital Token` |
| Token symbol | `CBDT` |
| Core token contract | `DigitalToken` |
| Generic ledger | `TokenLedger` / current implementation `TokenLedgerV2` |
| Initial reference profile | `eurosystem-reference` |
| Initial profile denomination | `EUR` |

Do not use `T-EUR`, `tEUR`, `TokenizedEuro`, or `Digital Euro` as names for the generic platform, protocol, or core token.

`Digital euro`, `ECB`, `Eurosystem`, and EUR-specific language may be used when documenting the `eurosystem-reference` profile, external requirements, published policy concepts, or regulatory context. Those references must not imply that CentralBank is issued, endorsed, sponsored, or operated by the ECB, Eurosystem, or a national central bank.

## 2. General identifier rules

Infrastructure identifiers should normally be:

- lowercase
- hyphen-separated
- ASCII-only
- based on function rather than vendor or implementation

Names should remain usable across local lab, private datacenter, sovereign cloud, and other controlled infrastructure.

Avoid:

- cloud-vendor names in portable identifiers
- personal names
- unexplained region shortcuts
- jurisdiction-specific terms in generic protocol components
- denomination-specific names in generic ledger or controller components

## 3. Environment naming

| Environment | Name | Purpose |
| --- | --- | --- |
| Local Lab | `lab` | Local or isolated development |
| Integration | `int` | Shared controlled testing |
| Staging | `stg` | Pre-production validation |
| Production | `prd` | Production deployment |

Example:

```text
env = "lab"
```

## 4. Institutional zone naming

Zones represent trust and failure domains. Generic deployments should use role-oriented names.

| Zone type | Canonical prefix | Example |
| --- | --- | --- |
| Central-bank core | `cb-core` | `cb-core-01` |
| Participant central bank | `participant-cb` | `participant-cb-01` |
| Commercial bank | `bank` | `bank-a` |
| Payment service provider | `psp` | `psp-01` |

A deployment profile may define profile-specific aliases. For example, the Eurosystem reference profile may use `ecb-core` and `ncb-*` in diagrams or profile configuration where that distinction is intentional.

## 5. Kubernetes naming

### Namespaces

Namespaces should map to trust boundaries:

```text
<layer>-<zone>
```

Examples:

```text
ledger-cb-core
ledger-participant-cb
routing-bank-a
identity-psp-01
obs-global
```

### Deployments

```text
<service>-<role>
```

Examples:

```text
ledger-validator
routing-gateway
identity-bridge
dns-authoritative
dns-resolver
```

Pods should normally inherit deployment-generated names.

## 6. DNS naming

CentralBank supports split-horizon deployment models where public-access services are isolated from the closed settlement plane.

### Closed settlement plane

Use deployment-owned private DNS. Documentation examples should use reserved/example names rather than implying ownership of a production namespace.

```text
<service>.<zone>.csp.centralbank.internal
```

Examples:

```text
ledger.cb-core.csp.centralbank.internal
ledger.participant-cb.csp.centralbank.internal
gateway.bank-a.csp.centralbank.internal
```

The actual private suffix is a deployment parameter.

### Public access plane

Public DNS is also deployment-specific. Documentation examples use the reserved `.example` namespace:

```text
<service>.centralbank.example
```

Examples:

```text
api.centralbank.example
status.centralbank.example
docs.centralbank.example
```

A public-access outage must not become a dependency of settlement-plane DNS or ledger operation.

## 7. Terraform and deployment naming

### Modules

```text
modules/<functional-area>
```

Examples:

```text
modules/dns-authoritative
modules/dns-resolver
modules/ledger-node
modules/routing-gateway
modules/pki-root
modules/pki-intermediate
```

### Environment layout

```text
envs/<env>/<zone>
```

Examples:

```text
envs/lab/cb-core
envs/lab/participant-cb
envs/lab/bank-a
```

Use one independently controlled state boundary per trust/failure zone where practical. Production backend and locking requirements are deployment-specific and must be documented by the operator.

## 8. Token and currency naming

CBDT is the protocol token identity. Denomination is supplied separately.

| Item | Generic protocol | Eurosystem reference profile |
| --- | --- | --- |
| Token name | Central Bank Digital Token | Central Bank Digital Token |
| Symbol | `CBDT` | `CBDT` |
| Currency code | deployment parameter | `EUR` |
| Minor-unit precision | deployment parameter | 2 |
| Jurisdiction policy | deployment parameter | Eurosystem reference policy |

Do not encode a fiat denomination into the generic token name or Solidity contract name.

## 9. Smart-contract naming

Contract names should describe protocol responsibility rather than a specific currency.

Preferred examples:

```text
DigitalToken
TokenLedger
MintBurnController
EscrowController
WaterfallController
GovernanceController
CompositeTransferPolicy
HoldingLimitPolicy
```

Jurisdiction-specific behavior belongs in policy modules, adapters, or deployment profiles whenever possible.

## 10. Logging and metrics

Log stream names should identify service, trust zone, and severity where applicable:

```text
<service>.<zone>.<severity>
```

Examples:

```text
ledger.cb-core.info
ledger.participant-cb.error
dns.auth.warn
```

Prometheus-style metric names should use the platform prefix:

```text
centralbank_<subsystem>_<metric>
```

Examples:

```text
centralbank_ledger_finality_seconds
centralbank_dns_query_failures_total
centralbank_quorum_active_zones
```

## 11. Reference-profile terminology

Profile-specific names must be clearly scoped. Prefer constructions such as:

- `eurosystem-reference`
- `Eurosystem reference profile`
- `EUR-denominated CBDT deployment`
- `profile-specific holding limit`

Avoid describing CentralBank itself as the "ECB system" or CBDT itself as the "digital euro."

## 12. Non-affiliation rule

Documentation that discusses the Eurosystem reference profile should retain the following meaning:

> CentralBank is an independent open-source technical reference implementation. It is not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.

This rule applies to public documentation, diagrams, API descriptions, demos, sample receipts, and deployment guides.

# CentralBank Merchant Receipt Rules v1.1

## Overview

This document defines reference receipt-formatting rules for merchant transactions processed through a CentralBank-compatible acquirer integration.

The generic protocol asset is **CBDT (Central Bank Digital Token)**. Receipt currency, scheme labels, legal notices, retention periods, dispute windows, and other regulatory text are supplied by the active deployment profile and merchant/acquirer rulebook.

For the `eurosystem-reference` profile, examples in this document use EUR. Those examples are not a claim that CentralBank or CBDT is an official digital euro scheme.

## Required receipt information

A receipt should include enough information to identify and reconcile the customer transaction without exposing sensitive credentials or full wallet/token data.

Recommended fields:

- merchant name and merchant identifier
- terminal identifier where applicable
- transaction date/time
- transaction amount and currency
- transaction type
- transaction/reference identifier
- processing result/status
- human-readable response message
- payment-method/profile label
- opaque wallet/payment reference where permitted
- dispute/support reference where applicable

## Transaction types

Reference transaction types include:

- `AUTHORIZATION`
- `CAPTURE`
- `REVERSAL`
- `REFUND`
- `OFFLINE_ADVICE`

A deployment may support only a subset.

## Payment method naming

Generic receipts should use deployment-neutral language such as:

```text
Payment Method: CBDT
Profile: eurosystem-reference
Currency: EUR
```

A profile may define a customer-facing label, but it must not imply endorsement or operation by a central bank unless that statement is actually authorized by the operator.

Do **not** use legacy `tEUR` or `Tokenized Euro` labels for the generic CentralBank protocol.

## EUR reference formatting

For the `eurosystem-reference` profile:

- currency code: `EUR`
- decimal places: `2`
- example display: `EUR 12.34` or `€12.34`, according to merchant locale/rulebook

Other profiles may use different denomination and formatting rules.

## Scheme / response codes

Acquirer integrations may map ISO-style or scheme-specific response codes to customer-readable messages. The code table is profile/interface specific and should be versioned independently from the generic CBDT token.

Example mappings may include:

| Code | Example meaning |
| --- | --- |
| `00` | APPROVED |
| `05` | DO NOT HONOUR |
| `12` | INVALID TRANSACTION |
| `30` | FORMAT ERROR |
| `51` | INSUFFICIENT FUNDS |
| `61` | AMOUNT LIMIT EXCEEDED |
| `91` | ISSUER / SERVICE NOT AVAILABLE |
| `96` | SYSTEM ERROR |

Do not expose internal exception messages, signing material, account-control rationale, or confidential compliance data on customer receipts.

## Offline transaction indicators

Where offline payments are supported, receipts must clearly distinguish an offline decision from final online reconciliation.

Recommended notice:

```text
SUBJECT TO LATER VERIFICATION
```

Recommended offline fields:

- offline transaction identifier
- local transaction timestamp
- advice status
- reconciliation status/timestamp when available
- applicable profile limit indicator

Any promise such as "verified within 24 hours" must come from the active rulebook/SLA and must not be hard-coded into generic receipt rules.

## Timestamp requirements

Use unambiguous timestamps, preferably ISO 8601. Where both local terminal time and server processing time are retained, identify them separately.

Example:

```text
Processed: 2026-01-03T13:45:12Z
Terminal time: 2026-01-03T13:40:12Z
```

## Identifiers

Transaction, merchant, terminal, wallet, and dispute identifiers should be opaque where possible. Do not expose:

- private keys
- signing secrets
- full authentication tokens
- PINs
- unnecessary personally identifiable information
- confidential case/sanctions information

## Reversals and refunds

Reversal/refund receipts should identify:

- the action (`REVERSAL` or `REFUND`)
- the original transaction reference
- amount and currency
- processing date/time
- resulting status
- customer-facing reason where appropriate

Avoid claiming settlement finality until the relevant settlement/reconciliation process has actually reached its defined final state.

## Disputes

Dispute contact channels and filing windows are deployment/profile requirements. A generic receipt may display:

```text
DISPUTE INFORMATION
Transaction ID: txn_auth_001
Contact: [operator support channel]
Reference: DISPUTE-[Transaction ID]
```

Do not use a legacy T-EUR support domain as a protocol requirement.

## Digital receipt accessibility

Digital receipt implementations should support accessible rendering, text alternatives for non-text content, scalable text, and appropriate contrast. Any formal WCAG or jurisdictional accessibility claim should be validated against the actual user interface and applicable rulebook.

## Retention and compliance

Retention periods, tax requirements, consumer-protection wording, dispute windows, and mandatory legal notices differ by jurisdiction and operator. They must be supplied by the deployment profile/rulebook rather than treated as universal CentralBank requirements.

Receipt records used as audit evidence should be linked to the underlying transaction and protected against unauthorized modification.

## Versioning

Receipt rules should be versioned independently from the core protocol. A receipt footer may include the applicable receipt/rulebook version when useful for support and audit reconstruction.

Example:

```text
CentralBank receipt profile: eurosystem-reference / receipt-rules v1.1
```

## Eurosystem reference disclaimer

The Eurosystem reference profile is an independent technical reference informed by publicly available concepts. **CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.** Merchant receipts must not state or imply otherwise.

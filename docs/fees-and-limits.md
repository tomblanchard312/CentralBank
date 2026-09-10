# Fees and Limits

## Purpose

Document configurable fees, holding limits, and related monetary-policy parameters without coupling them to the generic CBDT token identity.

## Scope

Depending on the deployment profile, configurable parameters may include:

- wallet holding limits
- transfer or settlement fees
- merchant fees
- issuance/redemption limits
- waterfall and reverse-waterfall thresholds

## Eurosystem reference examples

The following values are examples for an EUR-denominated reference profile, not hard-coded properties of CentralBank or CBDT:

- `holding_limit_individual`: EUR 3,000.00 (`300000` minor units)
- `holding_limit_merchant`: EUR 30,000.00 (`3000000` minor units)
- `fee_transfer_basis_points`: `5` (0.05%)

Other deployment profiles may use different denominations, limits, participant classes, or fee models.

## Where configured

- Profile-level parameters should be defined by the selected deployment profile and associated rulebook/configuration artifacts.
- Gateway configuration is consumed through `api/src/config/index.ts` where applicable.
- On-chain enforcement currently involves components such as `WalletRegistry`, `DigitalToken`, holding-limit policy, and controller modules depending on the deployment path.

## Change control

Changes to monetary or participant limits should be explicit, governed, and auditable. A production deployment should record:

- parameter name and previous/new value
- approving authority
- effective time
- deployment/profile scope
- change or case reference
- resulting configuration or transaction identifier

Where delayed activation is supported, use an explicit `effective_at` or equivalent governed activation mechanism rather than silent configuration replacement.

## Architectural rule

Currency-specific values belong in profiles or policy configuration. Do not encode EUR limits or fee assumptions into the generic `DigitalToken` identity or other currency-agnostic protocol components.

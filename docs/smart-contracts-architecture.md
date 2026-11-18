# CentralBank Smart Contract Architecture

## Overview

CentralBank separates token accounting, policy enforcement, operational controllers, and institutional governance. The core protocol is currency-agnostic. The generic token is **CBDT (Central Bank Digital Token)** and profile-specific denomination or policy is supplied separately.

The repository contains both the `DigitalToken` implementation used by the default API path and the modular Protocol v2 stack (`TokenLedgerV2`, policy modules, and dedicated controllers). Balances stay in the ledger; controllers receive narrowly scoped capabilities. Protocol v2 deploys via `DeployCentralBankV2.s.sol`; the API selects the stack with `PROTOCOL_STACK=v1|v2`.

```text
                         Permissioning / Governance
                                   |
          +------------------------+------------------------+
          |                        |                        |
          v                        v                        v
     Wallet Registry          Policy Engine            Controllers
          |                        |                        |
          |                 Holding limits          Mint / Burn
          |                 Sanctions               Escrow
          |                 Emergency controls      Waterfall
          |                 Composite policy        Migration
          |                        |                        |
          +------------------------+------------------------+
                                   |
                                   v
                        DigitalToken / TokenLedger
                                   |
                                   v
                        Conditional Payments
```

## Core responsibilities

### Permissioning and governance

Permissioning defines which institutional identities may administer, issue, redeem, register participants, invoke emergency controls, or operate other privileged protocol functions. Governance and permission changes should be explicit, auditable, and subject to the configured control model.

### WalletRegistry

`WalletRegistry` maintains participant wallet metadata and the information required by policy and settlement flows, including wallet type, activation status, linked settlement-account references, and configured holding limits.

### DigitalToken

`DigitalToken` is the generic CBDT token implementation used by the current gateway integration path. Its name intentionally does not encode EUR or any other denomination.

Current responsibilities include:

- balances and transfers
- allowance-based transfers
- authorized mint and burn operations
- emergency pause controls
- account freeze and legal-control operations
- wallet-registry integration
- waterfall-related operations used by the current implementation

The pre-MVP refactor uses dedicated `MINTER_ROLE` and `BURNER_ROLE` authority for issuance and redemption rather than treating those operations as an implicit property of a euro-specific or ECB-specific role.

### TokenLedgerV2

`TokenLedgerV2` is the modular ledger direction for the protocol. It owns balances and exposes scoped controller capabilities. Controllers should not become parallel balance stores.

Implemented Protocol v2 modules today:

```text
TokenLedgerV2
    |
    +--> CompositeTransferPolicyV2
    |       +--> EmergencyPolicyV2      (global transfer pause; dual-control unpause)
    |       +--> SanctionsPolicyV2      (freeze-only; opaque case hashes)
    |       +--> HoldingLimitPolicyV2
    |
    +--> MintBurnControllerV2
    +--> EscrowControllerV2
    +--> WaterfallControllerV2
    +--> MigrationControllerV2          (balance claims; not full ADR-001 state migration)
```

These modules are unit-tested and deployable via `DeployCentralBankV2.s.sol` / `DeployLabEnvironmentV2`. With `PROTOCOL_STACK=v2`, the institutional API uses V2 sanctions/emergency/holding/escrow/waterfall controllers.

### ConditionalPayments

`ConditionalPayments` provides escrowed release flows without changing the fungibility of CBDT after release. Payer-custody operations are designed to require payer authorization rather than allowing a shared API operator to debit arbitrary users.

Supported/reference condition concepts include delivery confirmation, milestones, time locks, dispute resolution, and oracle-mediated release where implemented.

## Generic funding and transfer flows

### Wallet registration

```text
Participant
    |
    v
Institution / Registrar
    |
    v
WalletRegistry.registerWallet(...)
```

### Issuance

```text
Authorized issuer
    |
    v
DigitalToken.mint(...) or MintBurnController
    |
    v
CBDT wallet balance
```

Issuance authority, supply limits, pause controls, and profile-specific monetary rules are separate concerns. A deployment profile may denominate CBDT in EUR, but the token contract remains `DigitalToken`.

### Direct transfer

```text
Payer-signed authorization
    |
    v
DigitalToken.transfer(...) / ledger transfer
    |
    +--> policy checks
    |
    v
Payee
```

The institutional API gateway relays signed economic-custody operations rather than treating its shared operator signer as the payer.

### Conditional payment

```text
Payer
  |
  +--> approve escrow amount
  |
  +--> ConditionalPayments.createConditionalPayment(...)
             |
             v
        escrow custody
             |
      condition satisfied
             |
             v
        release to payee
```

Conditional logic gates settlement or release. It does not make the released CBDT non-fungible or impose post-release spending restrictions.

## Holding limits and waterfall

Holding limits are policy parameters, not properties of CBDT itself. A profile can configure limits by wallet or participant class.

A waterfall flow may split value so that a wallet remains within its permitted capacity while excess is routed to a linked settlement destination. Reverse-waterfall logic must remain constrained by the wallet's remaining capacity and configured authority.

```text
Incoming value
      |
      v
Available wallet capacity?
   /              \
 yes              excess
  |                 |
wallet        linked settlement
```

## Escrow architecture

The modular escrow design uses immutable escrow identifiers and explicit lifecycle states. Case/document references should be represented by opaque hashes or non-sensitive references where appropriate rather than placing confidential case content on-chain.

Reference lifecycle:

```text
Active
  |-- release --> Released
  |-- burn ----> Burned
  |-- expiry --> Expired
  `-- cancel --> Cancelled
```

Expired escrow should not remain indefinitely locked. The controller design permits eligible expiry processing while preventing release, burn, or cancellation after the terminal state is reached.

## Mint and burn controller

The dedicated mint/burn controller design separates issuance from redemption authority and supports:

- independent mint and burn authorities
- authority rotation
- total-supply caps
- per-operation or configured issuance/redemption limits
- independent pause switches
- replay protection
- opaque audit-reference hashes
- ledger-scoped operation digests

## Migration

The migration framework supports snapshot-based balance migration using Merkle commitments, duplicate-claim protection, deadlines, governance pause/resume, exact migrated-total reconciliation, and finalization.

Because CentralBank is still pre-MVP, the historical T-EUR to CentralBank rename is **not** being treated as a production migration. The migration framework remains useful as a future protocol capability for real deployed-version transitions.

## Reference profile: Eurosystem

The initial `eurosystem-reference` profile currently supplies EUR denomination and Eurosystem-style policy parameters for testing the generic protocol.

Profile-specific terminology such as ECB, NCB, EUR, digital-euro concepts, or Eurosystem rules belongs in that profile, its documentation, or external-requirement mappings. It should not be encoded into generic contract names.

## Deployment status

There are two deployment paths:

| Script | Status | Stack |
| --- | --- | --- |
| `DeployCentralBank.s.sol` | **Implemented** and used by the API/lab integration path | `Permissioning`, `WalletRegistry`, `DigitalToken`, `ConditionalPayments` |
| `DeployCentralBankV2.s.sol` | **Implemented** for contract deployment/wiring | `TokenLedgerV2`, `MintBurnControllerV2`, `EscrowControllerV2`, optional holding/composite policy, waterfall, migration, and `GovernedPermissioning` |

Lab shortcuts: `make deploy-local` / `make deploy-lab` (v1) and `make deploy-local-v2` / `make deploy-lab-v2` (Protocol v2).

Protocol v2 deploy wiring:

1. deploy governance address / optional `GovernedPermissioning` when `SECOND_ADMIN_ADDRESS` is set
2. deploy `TokenLedgerV2`
3. deploy mint/burn and escrow controllers; grant scoped ledger capabilities
4. deploy holding-limit and composite transfer policy when `ENABLE_HOLDING_LIMITS=true`
5. deploy waterfall controller when `ENABLE_WATERFALL=true` (requires holding limits)
6. optionally deploy migration controller when `DEPLOY_MIGRATION=true` and snapshot metadata is supplied
7. verify capability, policy, balance, and reconciliation invariants before enabling participant traffic

Still open relative to the full README/ADR target:

- API/ABI wiring onto `TokenLedgerV2`, policies, and `EscrowControllerV2`
- deeper runtime profile loading into deploy (beyond API coherence checks)
- non-balance migration (freeze, escrow cases, roles, optional allowances) per ADR-001
- ConditionalPayments on the modular V2 ledger/escrow path

## Security invariants

At minimum, the architecture should preserve these properties:

- no unauthorized issuance or redemption
- no controller-owned hidden balance source
- no economic transfer by a shared API signer on behalf of an arbitrary payer
- conservation of supply except through authorized mint/burn operations
- policy enforcement on all applicable transfer paths
- replay/idempotency protection on privileged operations
- explicit emergency and governance authority
- auditable role and controller configuration

## Non-affiliation notice

CentralBank is an independent open-source technical reference implementation. The Eurosystem reference profile may be informed by published digital-euro concepts, but CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.

# Runbook 02: Emergency Sanctions Escalation

## Objective

Rapidly propagate sanctions or equivalent legally mandated transfer restrictions across a CentralBank deployment so affected participant accounts are blocked consistently at both the policy/gateway layer and the ledger enforcement layer.

The legal authority, sanctions source, and institutional approval chain are deployment-profile decisions. The `eurosystem-reference` profile may use EU/Eurosystem-oriented examples, but the generic protocol does not assume one jurisdiction.

## Preconditions

1. A verified instruction from the deployment's recognized legal or sanctions authority.
2. Authenticated access to the closed institutional management plane.
3. An approved case/change reference and the required emergency or compliance authority.
4. A validated sanctions input set with source, timestamp, and integrity evidence.

## Scope expansion rules

A profile may define escalation at wallet/account, participant/entity, zone/institution, or system-wide level. Broader scope must not be inferred automatically from a single-account instruction.

## Execution steps

### 1. Validate sanctions input

Confirm the source, effective time, identifiers, case reference, and integrity of the sanctions data before producing ledger actions.

### 2. Apply policy and account controls

Use the deployment's approved batch or policy-update mechanism. Preserve an auditable mapping between each input record and the resulting transaction or policy update.

### 3. Update gateway-side sanctions state

Where the gateway maintains a sanctions mirror or policy cache, update it so prohibited traffic can be rejected before transaction relay. Gateway enforcement is defense in depth and must not be the only enforcement point where on-chain policy is required.

### 4. Publish signed policy state

If the deployment distributes a sanctions/policy manifest, include manifest version, effective time, source/case reference, content hash, signer identity, and previous-manifest linkage where supported.

Profile-specific ECB-oriented service names should remain confined to the relevant deployment profile.

## Propagation and enforcement

A production deployment should define and test measurable propagation objectives. Record ledger confirmation time, gateway/policy-cache update time, participant acknowledgement time, and failed or delayed updates.

Once an on-chain freeze or transfer-policy restriction is confirmed, all applicable transfer paths must enforce it consistently.

## Regulator and auditor visibility

Authorized oversight can be provided through `DigitalToken` and policy-controller events, append-only audit records, transaction receipts, signed policy manifests, reconciliation reports, and profile-specific interfaces.

Production-grade durable audit persistence remains a release-hardening requirement.

## Legal reference recording

Each action should retain enough metadata to reconstruct why it occurred without exposing unnecessary confidential information on-chain. Typical metadata includes the legal authority reference, case/change identifier, effective timestamp, source-list version/hash, and approving institutional identity.

## Validation checks

- confirm restricted accounts are rejected by applicable ledger/policy paths
- confirm gateway policy matches the authoritative policy version
- verify manifest or source-data hashes
- verify participant acknowledgements where required
- reconcile requested, successful, failed, and pending actions
- confirm audit evidence links each action to its source case/reference

## Audit artifacts

Expected artifacts may include signed policy manifests, structured sanctions-escalation events, transaction/policy receipts, source-list hash/version, participant acknowledgement evidence, and a reconciliation summary.

## Non-affiliation note

Use of EU or Eurosystem examples in the `eurosystem-reference` profile does not imply that CentralBank is issued, endorsed, sponsored, approved, or operated by the ECB, Eurosystem, or any national central bank.

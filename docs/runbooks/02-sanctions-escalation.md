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

A profile may define escalation at one or more levels:

- **Wallet/account:** freeze specific addresses.
- **Participant/entity:** block all identified wallets associated with a participant.
- **Zone or institution:** suspend a participant or trust zone when supported by governance and policy.
- **System-wide:** invoke emergency controls only when authorized and necessary.

Broader scope must not be inferred automatically from a single-account instruction.

## Execution steps

### 1. Validate sanctions input

Confirm the source, effective time, identifiers, case reference, and integrity of the sanctions data before producing ledger actions.

### 2. Apply policy and account controls

Use the deployment's approved batch or policy-update mechanism to apply the restrictions. If a batch utility is deployed, preserve an auditable mapping between every input record and resulting transaction or policy update.

### 3. Update gateway-side sanctions state

Where the gateway maintains a sanctions mirror or policy cache, update it so prohibited traffic can be rejected before transaction relay. The gateway copy is defense in depth; it must not be the only enforcement point for restrictions that are required on-chain.

### 4. Publish signed policy state

If the deployment distributes a sanctions/policy manifest to participant nodes, produce a new signed manifest with:

- manifest version
- effective time
- source/case reference
- content hash
- signer identity
- previous-manifest linkage where supported

Profile-specific service names such as an ECB-oriented mirror or manifest should remain confined to the relevant deployment profile.

## Propagation and enforcement

A production deployment should define and test measurable propagation objectives rather than relying on a hard-coded latency assumption. Record at least:

- ledger confirmation time
- gateway/policy-cache update time
- participant acknowledgement time
- any failed or delayed participant update

Once an on-chain freeze or transfer-policy restriction is confirmed, all applicable transfer paths must enforce it consistently.

## Regulator and auditor visibility

Authorized read-only oversight can be provided through:

- `DigitalToken` and policy-controller events
- append-only audit records
- transaction receipts
- signed policy manifests
- reconciliation reports
- profile-specific regulator/auditor interfaces

A production audit stream must be durable and access-controlled. The current repository's production-grade append-only audit persistence remains a release-hardening requirement.

## Legal reference recording

Each sanctions action should retain sufficient reference data to reconstruct why the action occurred without exposing unnecessary confidential information on-chain. Typical metadata includes:

- legal instrument or authority reference
- case/change identifier
- effective timestamp
- source-list version or hash
- approving institutional identity

## Validation checks

- confirm restricted accounts are rejected by applicable ledger/policy paths
- confirm gateway-side policy matches the authoritative policy version
- verify manifest or source-data hashes
- verify participant acknowledgements where the deployment requires them
- reconcile the number of requested restrictions with successful, failed, and pending actions
- confirm audit evidence links each action to its source case/reference

## Audit artifacts

Expected artifacts may include:

- signed sanctions/policy manifest
- structured sanctions-escalation audit events
- transaction receipts or policy-update receipts
- source-list hash and version
- participant acknowledgement evidence
- reconciliation summary

## Non-affiliation note

Use of EU or Eurosystem examples in the `eurosystem-reference` profile does not imply that CentralBank is issued, endorsed, sponsored, approved, or operated by the ECB, Eurosystem, or any national central bank.

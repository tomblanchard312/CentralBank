# Runbook 01: Emergency Freeze of Wallet/Account

## Objective

Immediately halt outgoing transfer operations from a specific wallet or participant account when required by an authorized legal, sanctions, fraud, or security process.

This runbook describes the CentralBank reference flow. Exact approving authorities and legal thresholds are deployment-profile decisions.

## Preconditions

1. The operator is authenticated to the institutional gateway and holds the deployment-specific emergency/legal-control permission required for account freeze operations.
2. The target wallet is a valid address recognized by the deployment.
3. The legal or operational basis for the action has been recorded outside the public chain where required.
4. The operator has confirmed that the requested action applies to the selected deployment profile and jurisdiction.

## Authorization requirements

CentralBank does not hard-code a jurisdictional approval hierarchy. A production profile should define:

- who may initiate a freeze
- whether dual control is required
- any value- or case-based escalation threshold
- required legal/case references
- authority rotation and emergency-key procedures

For the `eurosystem-reference` profile, these controls may be mapped to appropriate central-bank or delegated institutional authorities, but that mapping is profile-specific.

## Execution steps

### 1. Identify target

Confirm the target address and record the case/legal basis for the freeze. Do not place confidential case material directly on-chain when an opaque case reference or hash is sufficient.

### 2. Execute freeze through the institutional gateway

Use the configured privileged freeze route for the deployment. Example shape:

```bash
curl -X POST "https://[internal-gateway]/api/v1/transfers/freeze" \
     -H "X-API-KEY: [AUTHORIZED_KEY]" \
     -H "Content-Type: application/json" \
     -d '{
       "account": "0xTargetAddress...",
       "reason": "Emergency compliance action - Case ID: 2026-001"
     }'
```

The exact authentication mechanism may include institutional mTLS, API credentials, request signatures, and deployment-specific authorization.

### 3. Monitor confirmation

Capture the resulting transaction identifier and confirm the state transition on the configured ledger network before declaring the freeze complete.

## Validation checks

1. Query the `DigitalToken`/applicable policy state and confirm the account is frozen.
2. Attempt an authorized test transfer path from the frozen account in a safe validation environment. The transfer must be rejected.
3. Confirm the gateway and audit trail identify the acting institution and case reference.

## Failure handling

- **Authorization rejected:** verify the operator's institutional identity, role/capability assignment, and request-signature requirements.
- **Transaction reverted:** inspect the contract revert reason and current account state before retrying.
- **Network partition:** use the deployment's approved secondary settlement-plane access path. Do not route a privileged control operation through an untrusted public fallback.
- **Uncertain legal authority:** do not improvise a broader freeze. Escalate through the deployment's governance/legal process.

## Unfreeze procedure

1. Verify that the legal or incident basis for the freeze has been resolved.
2. Obtain the required authorization for reversal.
3. Execute the configured unfreeze operation, for example:

```bash
curl -X POST "https://[internal-gateway]/api/v1/transfers/unfreeze" \
     -H "X-API-KEY: [AUTHORIZED_KEY]" \
     -H "Content-Type: application/json" \
     -d '{ "account": "0xTargetAddress..." }'
```

4. Verify the on-chain state and audit record before notifying participants.

## Audit evidence

Expected evidence includes:

- gateway audit event identifying the action and actor
- transaction receipt / ledger confirmation
- `DigitalToken` account-control event where applicable
- case or legal reference
- governance/authorization evidence required by the deployment

## Non-affiliation note

References to Eurosystem-style controls in a deployment profile do not imply that CentralBank is operated or endorsed by the ECB, Eurosystem, or any national central bank.

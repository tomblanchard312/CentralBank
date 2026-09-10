# Runbook 04: Emergency Issuance Suspension

## Objective

Suspend creation of new CBDT when required to protect monetary integrity during suspected unauthorized issuance, supply reconciliation failure, signer compromise, contract vulnerability, or another severe operational event.

This is a generic CentralBank runbook. The authority that may order or approve suspension is defined by the active deployment profile and governance model.

## Preconditions

1. A confirmed or credible condition requiring issuance suspension.
2. Authenticated access to the institutional control plane.
3. The deployment-specific emergency or issuance-control authority required to pause the relevant contract/controller.
4. A case/incident identifier and recorded approval evidence.

## Execution steps

### 1. Determine suspension scope

Identify whether the incident requires a mint-only controller pause, a `DigitalToken` pause, or broader transfer suspension because ledger integrity is in doubt. Use the narrowest control that safely contains the incident.

### 2. Execute the approved pause

For deployments using the current gateway-wide system pause route:

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/pause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

The exact request may additionally require institutional mTLS and request signing.

Where the modular mint/burn controller is deployed, prefer its dedicated mint-pause control when only issuance must stop and transfers/redemptions can safely continue.

### 3. Verify on-chain state

Confirm the relevant pause state directly against the deployed contract/controller and record the transaction receipt and block height.

### 4. Notify participants

Send an authenticated operational notice stating what capability is suspended, effective time, expected participant behavior, whether transfers/redemptions remain available, the incident/change reference, and the next update channel.

Do not claim automated notification unless the deployment actually provides and verifies that mechanism.

## Impact assessment

| Control | Issuance | Redemption | Transfers | Conditional settlement |
| --- | --- | --- | --- | --- |
| Mint-only controller pause | stopped | potentially available | available subject to policy | available subject to policy |
| Full token/system pause | stopped | implementation-dependent | stopped | may be blocked |

Operators must verify actual deployed behavior before announcing service availability.

## Reconciliation during suspension

Continue reconciliation and evidence capture. Record the last known valid total supply, compare authorized issuance/redemption records with on-chain changes, identify unrecognized operation digests or transaction hashes, preserve forensic evidence, and avoid cleanup that destroys incident data.

## Resume procedure

1. Complete sufficient root-cause analysis or containment.
2. Reconcile total supply and issuance/redemption operations over the incident window.
3. Verify signer and authority integrity; rotate compromised authority before resuming mint capability.
4. Obtain deployment-profile approval for recovery.
5. Unpause only the controls that were suspended.
6. Execute a small authorized validation operation where appropriate.
7. Confirm reconciliation remains exact.
8. Notify participants that capability is restored.

For a gateway-wide unpause:

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/unpause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

## Failure handling

- **Compromised issuance authority:** revoke or rotate authority through governance before resuming mint capability.
- **Supply cannot be reconciled:** remain suspended and escalate; do not normalize unexplained supply drift as a bookkeeping correction.
- **Contract vulnerability:** keep affected paths paused until remediation and deployment/migration plans are reviewed and rehearsed.
- **Network partition:** do not issue independently into isolated partitions unless the profile explicitly supports a safe, reconciliable procedure.

## Audit artifacts

Expected evidence includes pause/unpause transaction receipts and events, incident/approval reference, acting institutional identity, supply reconciliation report, signer/authority integrity evidence, recovery validation results, and participant notifications where required.

## Eurosystem reference profile

A Eurosystem-oriented deployment may map the approval chain to ECB/NCB or delegated emergency authorities. That mapping is profile-specific and must not be represented as authority granted by CentralBank itself.

CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the ECB, Eurosystem, or any national central bank.

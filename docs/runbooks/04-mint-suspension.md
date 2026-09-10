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

Identify whether the incident requires:

- pausing only mint/issuance operations through `MintBurnControllerV2`, where independently supported
- pausing the current `DigitalToken` implementation
- pausing broader transfer functionality because the integrity of the ledger itself is in doubt

Use the narrowest control that safely contains the incident.

### 2. Execute the approved pause

For deployments using the current gateway-wide system pause route, an example request is:

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/pause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

The exact request may additionally require institutional mTLS and request signing.

Where the modular mint/burn controller is deployed, prefer its dedicated mint-pause control when only issuance must be stopped and transfers/redemptions can safely continue.

### 3. Verify on-chain state

Confirm the relevant `paused` or issuance-pause state directly against the deployed contract/controller. Record the transaction receipt and block height.

### 4. Notify participants

Send an authenticated operational notice to affected institutions stating:

- what capability is suspended
- effective time
- expected participant behavior
- whether transfers/redemptions remain available
- incident/change reference
- next update channel

Do not claim automated notification unless the deployment actually provides and verifies that mechanism.

## Impact assessment

The impact depends on pause scope:

| Control | Issuance | Redemption | Transfers | Conditional settlement |
| --- | --- | --- | --- | --- |
| Mint-only controller pause | stopped | potentially available | available subject to policy | available subject to policy |
| Full token/system pause | stopped | implementation-dependent | stopped | may be blocked |

Operators must verify actual deployed behavior before announcing service availability.

## Reconciliation during suspension

Continue reconciliation and evidence capture while issuance is disabled. At minimum:

- record last known valid total supply
- compare authorized issuance/redemption records with on-chain supply changes
- identify unrecognized operation digests or transaction hashes
- preserve logs, manifests, signer/KMS evidence, and relevant node data
- prevent incident cleanup from destroying forensic evidence

## Resume procedure

1. Complete root-cause analysis or containment sufficient for controlled recovery.
2. Reconcile total supply and all issuance/redemption operations over the incident window.
3. Verify signer and authority integrity; rotate compromised authority before resuming.
4. Obtain deployment-profile approval for recovery.
5. Unpause only the controls that were suspended.
6. Execute a small authorized validation operation where appropriate.
7. Confirm reconciliation remains exact after the validation operation.
8. Notify participants that the capability is restored.

For a gateway-wide unpause, the reference request shape is:

```bash
curl -X POST "https://[internal-gateway]/api/v1/admin/system/unpause" \
     -H "X-API-KEY: [AUTHORIZED_KEY]"
```

## Failure handling

- **Compromised issuance authority:** revoke/rotate the authority through the configured governance path before resuming mint capability.
- **Supply cannot be reconciled:** remain suspended and escalate; do not normalize unexplained supply drift as a bookkeeping correction.
- **Contract vulnerability:** keep affected paths paused until the remediation and deployment/migration plan has been reviewed and rehearsed.
- **Network partition:** do not issue independently into isolated partitions unless the protocol/profile explicitly supports a safe, reconciliable procedure.

## Audit artifacts

Expected evidence includes:

- pause/unpause transaction receipts and events
- incident and approval reference
- acting institutional identity
- supply reconciliation report
- signer/authority integrity evidence
- recovery validation results
- participant notifications and acknowledgements where required

## Eurosystem reference profile

A Eurosystem-oriented deployment may map the approval chain to ECB/NCB or delegated emergency authorities. That mapping is profile-specific and must not be represented as an authority granted by the CentralBank software itself.

CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the ECB, Eurosystem, or any national central bank.

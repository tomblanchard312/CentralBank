# CentralBank Reference MVP Plan

Status: **CI wired; first green checklist run pending**  
Scope: lab / institutional **reference MVP** on the v1 API path. Not production sovereign readiness.

## MVP definition

**MVP means:** a new engineer can run the institutional demo path end-to-end:

1. Local chain (Anvil or lab Besu)
2. `make deploy-local` (v1 contracts)
3. API against deployed v1 addresses
4. Core flows: wallet register, mint/burn, payer-signed transfer, waterfall, conditional payment, freeze/pause
5. Profile/parameters coherence for `eurosystem-reference`
6. Reconciliation lab/test path with automated tests
7. SDK client aligned to CentralBank / CBDT naming

**MVP does not mean:** production V2 ConditionalPayments/WalletRegistry, KMS/HSM, durable distributed idempotency/audit, hardened production manifests, or independent security assessment.

Protocol v2 remains a **parallel deployable track** (`make deploy-local-v2`). Lab API cutover is available via `PROTOCOL_STACK=v2` and `scripts/lab-mvp-smoke-v2`.

## Workstreams

| Phase | Work | Status |
| --- | --- | --- |
| 0 | Scope lock in README / AGENTS / this doc | Done |
| 1a | Lab smoke script (Anvil → deploy → env) | Done |
| 1b | API Helm chart required env wiring | Done |
| 1c | Profile → parameters validation bridge | Done |
| 1d | Reconciliation automated tests | Done |
| 1e | SDK package metadata cleanup | Done |
| 2 | Demo checklist + CI smoke | Done (`.github/workflows/lab-mvp-ci.yml` + recon unit tests) |
| 3a | V2 sanctions/emergency policy modules | Done |
| 3b | V2 API cutover | Done (`PROTOCOL_STACK=v2`; ConditionalPayments/WalletRegistry still v1-only) |
| 4 | Production gates | Post-MVP |

## Exit criteria (Phase 1–2)

- [x] `scripts/lab-mvp-smoke` produces a usable API env file from a v1 deploy
- [x] Helm values document and inject RPC, contracts, JWT, parameters path
- [x] API fails closed when profile policy flags disagree with parameters
- [x] `tools/reconciliation-ref` tests pass (`npm test` in that package)
- [x] SDK package metadata uses CentralBank / CBDT (not legacy Digital Euro product naming)
- [x] Documented demo checklist covers the core flows ([mvp-demo-checklist.md](mvp-demo-checklist.md))
- [x] CI job runs lab smoke + demo checklist (`lab-mvp-ci.yml`) and reconciliation-ref `npm test` (`parameters-and-recon-ci.yml`)

## Non-affiliation

CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the ECB, the Eurosystem, or any national central bank.

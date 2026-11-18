# Reference MVP demo checklist (v1 path)

Use after `scripts/lab-mvp-smoke.sh` (or `.ps1`) and `cd api && cp .env.lab .env && npm run dev`.

Automated walk: `scripts/lab-mvp-demo-checklist.sh` (requires running Anvil + API with `ALLOW_DEMO_IDENTITIES=true`).  
CI gate: `.github/workflows/lab-mvp-ci.yml` runs smoke → API → this checklist on PRs.

| # | Flow | How to verify | Pass |
| --- | --- | --- | --- |
| 1 | API live | `curl -s http://localhost:3000/api/v1/health/live` | [x] |
| 2 | Wallet register | `POST /api/v1/wallets` with registrar credentials | [x] |
| 3 | Mint | `POST /api/v1/transfers/mint` with issuer authority | [x] |
| 4 | Payer-signed transfer | `POST /api/v1/transfers` with payer signature (not shared operator as payer) | [x] |
| 5 | Waterfall | `POST /api/v1/transfers/waterfall` for over-limit wallet | [x] |
| 6 | Conditional payment | Create + confirm via conditional-payments routes | [x] |
| 7 | Freeze / pause | Emergency/central-bank controls on `DigitalToken` via governance routes | [x] |
| 8 | Profile coherence | API starts with `PROFILE_FILE` + `PARAMETERS_FILE`; bad pair fails closed | [x] |
| 9 | Reconciliation lab | `cd tools/reconciliation-ref && CENTRALBANK_ENV=test npm test` | [x] |

Checklist coverage is enforced by `scripts/lab-mvp-demo-checklist.sh` in CI (`lab-mvp-ci`). Re-run locally with that script after smoke to refresh evidence.

Protocol v2 lab cutover: `scripts/lab-mvp-smoke-v2` + `PROTOCOL_STACK=v2`. This checklist remains the v1 reference MVP path.

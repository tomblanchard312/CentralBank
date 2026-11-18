# Deployment profiles

Deployment profiles supply denomination, jurisdictional policy flags, and scheme-specific parameters without encoding them into the generic CentralBank / CBDT protocol identity.

## Current profiles

| Profile | File | Denomination | Notes |
| --- | --- | --- | --- |
| `eurosystem-reference` | [`eurosystem-reference.json`](eurosystem-reference.json) | EUR (2 decimals) | Reference profile informed by published Eurosystem concepts. Not ECB-issued or endorsed. |

## Status

`eurosystem-reference.json` is the canonical profile intent for the initial reference deployment.

- The institutional API loads it via `PROFILE_FILE` (default: repository `profiles/eurosystem-reference.json`) and **fail-closes** when policy flags disagree with `PARAMETERS_FILE` / `envs/lab/ecb-core/parameters.json` (see `api/src/config/profile.ts`).
- Numeric rulebook values still live in parameters JSON; the profile does not replace that file yet.
- Protocol v2 deploy scripts still take capability toggles from environment variables (`ENABLE_HOLDING_LIMITS`, `ENABLE_WATERFALL`, mint/burn limits, etc.).

Full profile-driven deploy/API configuration remains a post-MVP production item; the thin coherence bridge is part of the reference MVP.

## Non-affiliation

CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.

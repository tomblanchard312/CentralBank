# Deployment profiles

Deployment profiles supply denomination, jurisdictional policy flags, and scheme-specific parameters without encoding them into the generic CentralBank / CBDT protocol identity.

## Current profiles

| Profile | File | Denomination | Notes |
| --- | --- | --- | --- |
| `eurosystem-reference` | [`eurosystem-reference.json`](eurosystem-reference.json) | EUR (2 decimals) | Reference profile informed by published Eurosystem concepts. Not ECB-issued or endorsed. |

## Status

`eurosystem-reference.json` is the canonical **documentation/reference** description of the initial profile. Protocol v2 deploy scripts currently take equivalent toggles from environment variables (`ENABLE_HOLDING_LIMITS`, `ENABLE_WATERFALL`, mint/burn limits, etc.). The institutional API still reads runtime parameters from environment / `envs/` config rather than loading this JSON file directly.

Wiring profile JSON into deploy and API configuration remains an open production-readiness item.

## Non-affiliation

CentralBank and CBDT are not issued, endorsed, sponsored, approved, or operated by the European Central Bank, the Eurosystem, or any national central bank.

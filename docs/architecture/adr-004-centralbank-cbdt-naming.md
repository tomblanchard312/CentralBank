# ADR-004: CentralBank platform and generic CBDT identity

- Status: Accepted
- Date: 2026-09-07

## Context

The project began as T-EUR, an implementation centered on a tokenized euro. The architecture has since evolved into a reusable central-bank digital-token platform with modular ledger, policy, governance, settlement, escrow, migration, institutional-authentication, reconciliation, and audit components.

The repository is pre-MVP and has no production compatibility commitments. Preserving T-EUR names would therefore add unnecessary coupling between the platform and one currency profile.

## Decision

1. The platform name is **CentralBank**.
2. The protocol name is **CentralBank Digital Token Protocol**.
3. The generic token contract is **DigitalToken**.
4. The generic reference token name is **Central Bank Digital Token** with symbol **CBDT**.
5. Currency denomination is a deployment-profile concern, not part of the core token identity.
6. The first deployment profile is **eurosystem-reference**, denominated in EUR with two decimal places.
7. Eurosystem-specific policy assumptions belong in the profile or policy modules rather than in generic core names.
8. Because the project is pre-MVP, old T-EUR/tEUR/TEUR/TokenizedEuro compatibility aliases are not required.

## Consequences

- Core contracts and APIs can be reused for non-euro reference profiles.
- Documentation must distinguish the generic platform from the Eurosystem reference profile.
- Existing pre-MVP deployment scripts, tests, configuration keys, and API identifiers may change without compatibility shims.
- The project must not imply that CBDT is issued, endorsed, or operated by the ECB or a national central bank.

## Reference-profile disclaimer

The Eurosystem reference profile is an open-source technical reference informed by published Eurosystem concepts and requirements. It is not an official digital euro implementation and is not affiliated with, endorsed by, or operated by the European Central Bank or any national central bank.

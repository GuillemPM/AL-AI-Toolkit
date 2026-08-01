# ADR-008: BDFL with succession plan from day one

- Status: Accepted
- Date: 2026-08

## Decision

Succession and maintainer-scaling planning is a v0.1 concern, documented in [GOVERNANCE.md](../../GOVERNANCE.md) from the first public release, not addressed retroactively after a bus-factor crisis.

## Alternatives considered

Informal solo maintainership with governance formalized later “if the project takes off.”

## Why rejected

For an application, deferring governance is low-risk. For infrastructure other people's shipped extensions depend on, an unplanned maintainer departure is a supply-chain risk to every downstream consumer. The cost of writing this down early is small; the cost of not having it written down when it's needed is high and hits at the worst possible time.

## Cost of this decision

Upfront overhead writing governance documentation before there's a community to govern. Accepted because the alternative failure mode is worse and harder to recover from.

# Governance

AL AI Open SDK is open-source infrastructure. Governance exists so downstream AL
extensions that depend on this library are not left without a clear succession
path.

## Phase 1 — Solo maintainer (current)

- **BDFL:** Guillem holds final decision authority on architecture and roadmap.
- Day-to-day contributions are welcome via PR.
- This phase is honest about current reality rather than inventing a foundation-style structure before there is a community to staff it.

### Succession (Phase 1)

If the BDFL becomes unavailable without a handoff:

1. Open an issue titled `GOVERNANCE: succession` on the repository.
2. Active contributors with merged PRs in the prior 12 months may self-nominate.
3. After 14 days, consensus among nominators (or a simple majority vote if needed) selects an interim maintainer with commit access.
4. The interim maintainer either confirms ongoing BDFL role or starts Phase 2 early.

Document any permanent succession in this file via PR.

## Phase 2 — First external maintainers

**Trigger (guideline, revisit if usage differs):** 3+ contributors with merged PRs across at least 2 different providers/modules, sustained over 2+ releases.

- Small maintainers group with commit access
- Lazy consensus for non-architectural changes
- BDFL-arbitrated decisions for anything touching `"AIOS Provider"` / core contracts

## Phase 3 — Maturity

If adoption justifies it, move toward a more formal steering structure. Do **not** over-specify Phase 3 in advance; revisit when approaching the need.

## Contribution asymmetry

- **High bar:** provider abstraction, structured-output contract, client result shapes
- **Lower bar:** additional provider adapters
- **Mandatory:** mock-provider test coverage for provider logic; no live API key required for core CI

## Deprecation (from v1.0)

Semver commitments begin at v1.0. Post-v1.0 breaking changes require:

- A major version bump
- A migration guide
- A minimum deprecation window of one full BC major release cycle before removal

## License

[MIT](LICENSE). Chosen to minimize friction for ISVs shipping proprietary AppSource apps that depend on this library.

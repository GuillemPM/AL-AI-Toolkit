# Contributing to AL AI Open SDK

Thanks for contributing. This project is a **client library** for AL — not a Copilot platform or hosted AI service. Keep PRs focused and testable without live API keys.

## Development setup

1. Clone the repo and open it in VS Code / Cursor with the AL Language extension.
2. Place Business Central 28 Application symbols under `.alpackages`.
3. Compile with ALC or the AL extension. Core tests must pass with the **mock provider only** — no provider API key required.

## What to contribute

| Change type | Bar |
|---|---|
| Bug fix | PR + mock-provider regression test when applicable |
| New provider adapter | Implement `"AIOS Provider"` + `"AIOS Language Model"` (and `"AIOS Image Model"` if applicable), docs, mock-covered tests |
| Core interface / structured-output / request-response contract | Discuss in the PR; keep changes focused |
| Docs, examples | PR welcome |

## Pull request checklist

- [ ] Mock-provider tests cover any provider or client logic you touch
- [ ] No secrets, API keys, or live endpoint credentials in the repo
- [ ] No new default network egress from the library
- [ ] Object IDs stay within the project's `idRanges` in `app.json` (see [docs/OBJECT_IDS.md](docs/OBJECT_IDS.md))
- [ ] Breaking public API changes are called out explicitly (semver starts at v1.0)

## Code of conduct

Participants are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).

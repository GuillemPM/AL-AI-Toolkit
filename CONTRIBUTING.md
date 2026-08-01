# Contributing to AL AI Toolkit

Thanks for contributing. This project is a **client library** for AL (see [ADR-001](docs/adr/001-library-not-platform.md) and [ADR-002](docs/adr/002-client-library-not-orchestration.md)). Keep PRs focused and testable without live API keys.

## Development setup

1. Clone the repo and open it in VS Code / Cursor with the AL Language extension.
2. Place Business Central 28 Application symbols under `.alpackages`.
3. Compile with ALC or the AL extension. Core tests must pass with the **mock provider only** — no provider API key required.

## What to contribute

| Change type | Bar |
|---|---|
| Bug fix | PR + mock-provider regression test when applicable |
| New Tier 2/3 provider adapter | Implement `"AI Provider"` + `"AI Language Model"`, docs, mock-covered mapping tests ([ADR-004](docs/adr/004-tiered-provider-support.md)) |
| Core interface / structured-output / telemetry schema | **RFC required** before implementation ([docs/rfc/](docs/rfc/)) |
| Docs, examples | PR welcome |

## Pull request checklist

- [ ] Mock-provider tests cover any provider or client logic you touch
- [ ] No secrets, API keys, or live endpoint credentials in the repo
- [ ] No new default network egress (telemetry stays local unless the consumer configures an exporter — [ADR-005](docs/adr/005-otel-genai-telemetry.md))
- [ ] Object IDs stay within the project's `idRanges` in `app.json`
- [ ] Breaking public API changes are called out explicitly (semver starts at v1.0)

## RFC process

Open an RFC (copy [docs/rfc/0000-template.md](docs/rfc/0000-template.md)) for:

- Changes to `"AI Provider"` / `"AI Language Model"` or the request/response contract
- Structured-output binding contract
- Telemetry / GenAI attribute schema

Discuss and land the RFC before merging implementation PRs for those surfaces.

## Code of conduct

Participants are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).

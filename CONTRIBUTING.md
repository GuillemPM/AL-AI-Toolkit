# Contributing to AL AI Open SDK

Thanks for contributing. This project is a **client library** for AL — not a Copilot platform or hosted AI service. Keep PRs focused and testable without live API keys.

**Day-to-day workflows** (Core-only, provider-only, new provider, consumers): see **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**.

## Quick start

1. Clone the repo. Each `apps/*` folder is an independent AL extension; they share **repo-root** `.alpackages/`.
2. Open `apps/AIOpenSDK.Core`, set `launch.json` for your BC, run **AL: Download Symbols** once.
3. From the repo root, prepare dependency packages for provider work:

   ```powershell
   # Windows (typical for BC)
   .\scripts\prepare-deps.ps1
   ```

   ```bash
   # Linux / macOS
   ./scripts/prepare-deps.sh
   ```

   That packages **Core** and **ProviderUtils** into `.alpackages` so you can open a single provider app and compile it.
4. Optional: open [`AL-AI-Toolkit.code-workspace`](AL-AI-Toolkit.code-workspace) for the full stack.
5. Full compile order when needed: **Core → ProviderUtils → providers → Examples → Test**.
6. Tests must pass with the **mock provider** — no live API key required.

## Package layout (AI SDK shape)

| App | Depends on |
|-----|------------|
| Core | BC Application |
| ProviderUtils | Core |
| OpenAI / OpenAICompatible / OpenCodeZen | Core + ProviderUtils |
| Anthropic | Core |
| Examples | Core + provider apps used by demos |
| Test | Core + ProviderUtils + Anthropic + Examples (for sample tools) |

**Rule:** no provider app depends on another provider. Share Chat Completions logic via ProviderUtils.

New provider: follow [docs/DEVELOPMENT.md — Path C](docs/DEVELOPMENT.md#path-c--work-only-on-a-provider-or-add-a-new-one).

## What to contribute

| Change type | Bar |
|---|---|
| Bug fix | PR + mock-provider regression test when applicable |
| New provider adapter | New app folder, Core (+ Utils if Completions), docs, mock-covered tests where possible |
| Core interface / structured-output / request-response contract | Discuss in the PR; keep changes focused |
| Docs, examples | PR welcome |

## Pull request checklist

- [ ] Mock-provider tests cover any provider or client logic you touch
- [ ] No secrets, API keys, or live endpoint credentials in the repo
- [ ] No new default network egress from the library
- [ ] Object IDs stay within the owning app’s `idRanges` (see [docs/OBJECT_IDS.md](docs/OBJECT_IDS.md))
- [ ] No new provider→provider dependencies
- [ ] Breaking public API changes are called out explicitly (see [docs/PUBLIC_API.md](docs/PUBLIC_API.md); semver starts at v1.0)

## Code of conduct

Participants are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).

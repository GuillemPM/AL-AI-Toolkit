# ADR-004: Provider support is tiered, not flat

- Status: Accepted
- Date: 2026-08

## Decision

Providers are classified as:

| Tier | Providers (initial) | Commitment |
|---|---|---|
| 1 | Azure OpenAI, OpenAI, Anthropic | Full support, CI-tested against live APIs when credentials available, core-team maintained |
| 2 | Gemini, Ollama | Community-maintained, best-effort |
| 3 | Generic OpenAI-compatible endpoint | Thin adapter, no vendor guarantees |

Core CI for library logic always runs against the **mock provider** without live keys.

## Alternatives considered

Flat support — every listed provider gets equal maintenance commitment.

## Why rejected

Equal commitment across many providers from a small maintainer base quietly erodes — either quality drops uniformly, or a few providers get real attention while the rest bit-rot while still listed as “supported,” which is worse than honest tiering upfront.

## Cost of this decision

Less impressive-looking provider list in marketing terms; some users unhappy their preferred provider is Tier 2/3. Accepted — an honest, sustainable tier list beats an equally-promised list that erodes silently.

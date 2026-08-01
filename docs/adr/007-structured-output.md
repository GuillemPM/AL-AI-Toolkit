# ADR-007: Structured output — native JSON mode first, validation-retry as fallback

- Status: Accepted
- Date: 2026-08

## Decision

Where a provider supports native structured/JSON-constrained output, the toolkit uses it directly. Where it doesn't, the toolkit falls back to prompt-injected schema instructions plus response validation and automatic retry-with-correction on parse failure.

Roadmap: native JSON path ships first (M5); full fallback/retry path is a later milestone (M9).

## Alternatives considered

- Always prompt-based, ignoring native structured output
- Refuse to support providers without native structured output

## Why rejected (prompt-only)

Ignoring native structured output where it exists means worse reliability on providers that already solved this well, purely for implementation simplicity.

## Why rejected (provider refusal)

Would eliminate Tier 2/3 providers (Ollama, self-hosted OpenAI-compatible endpoints) from ever supporting structured output — disproportionately valuable for self-hosted and cost-sensitive use cases.

## Cost of this decision

More internal complexity — two code paths per provider instead of one — and reliability that genuinely varies by provider/tier, documented per-provider rather than promised uniformly.

# ADR-003: Provider abstraction — lowest common denominator with escape hatches

- Status: Accepted
- Date: 2026-08

## Decision

The core `"AI Provider"` / `"AI Language Model"` interfaces cover only what every provider can do reliably. Provider-specific capabilities (Anthropic's tool_use blocks, OpenAI's function-calling shape, Gemini's grounding) are accessed through typed provider extensions, not flattened into the common interfaces.

## Alternatives considered

A fully unified interface that normalizes every provider's capabilities into one shape.

## Why rejected

Full normalization is the classic multi-provider abstraction trap — clean for the 80% case, then either silently drops capability for the 20% case or grows increasingly leaky special-case parameters. Naming the trade-off explicitly (typed extensions) rather than hiding it behind a false-clean interface is more honest and avoids subtle bugs from assumed cross-provider parity that doesn't exist.

## Cost of this decision

Provider-swap-with-zero-code-changes is only true for the common subset. Anyone using an escape hatch takes on manual migration work when switching providers — honest, since that work is real and not eliminable by better API design.

# ADR-006: Cost-safety primitives are opt-in

- Status: Accepted
- Date: 2026-08

## Decision

Circuit breakers, hard spend caps, and per-call token limits are composable, optional wrappers around the base client, not baked into every call path by default. Documentation must recommend enabling them loudly.

## Alternatives considered

Mandatory cost caps on every provider call, enforced unless explicitly disabled.

## Why rejected

A hard default cap that's wrong for a given workload (e.g. legitimate long-document summarization) becomes a silent failure mode worse than no cap at all if developers don't understand why calls are rejected. Defaults that fail loudly and configurably are safer than defaults that fail silently and correctly-in-most-cases.

## Cost of this decision

A developer who doesn't opt in gets no protection against runaway cost from a bug. Real risk, accepted in favor of not overriding developer intent silently.

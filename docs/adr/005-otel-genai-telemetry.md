# ADR-005: Telemetry uses OpenTelemetry GenAI conventions, emitted locally

- Status: Accepted
- Date: 2026-08

## Decision

Every AI call emits an OTel span following GenAI/LLM semantic conventions (`gen_ai.system`, `gen_ai.request.model`, `gen_ai.usage.input_tokens`, …) with custom `bc.*` attributes for tenant/company/environment. Nothing is sent anywhere unless the developer configures an exporter destination themselves.

## Alternatives considered

- A bespoke telemetry schema for AL/BC concepts
- Bundling a default telemetry destination for easy onboarding

## Why rejected (custom schema)

Reusing an existing, actively maintained standard means the toolkit benefits from tooling that already understands GenAI conventions (Phoenix, Langfuse, OTel-native backends) without building that tooling itself — consistent with [ADR-001](001-library-not-platform.md).

## Why rejected (default destination)

Any default destination reintroduces the platform-vs-library tension from ADR-001 — it implies a place data goes by default, exactly the guarantee the library model is designed not to promise.

## Cost of this decision

Zero-config telemetry isn't available — a developer gets spans emitted locally but sees nothing until wiring up a collector. Real onboarding friction, accepted in favor of not shipping an implicit data destination.

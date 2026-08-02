# AL AI Toolkit

Provider-agnostic AI integration library for Microsoft Dynamics 365 Business Central, written in AL.

Call large language models through one client API — with structured output parsing, retries, telemetry, and a mock provider for unit tests. This is a **library** that ships inside your extension. It is not a Copilot feature, not a hosted AI service, and not a Microsoft product.

Status: **pre-implementation** (v0.1 scaffolding). See [docs/AL-AI-Toolkit-PRD-and-ADR.docx](docs/AL-AI-Toolkit-PRD-and-ADR.docx) and [docs/adr/](docs/adr/).

## Design highlights

- Provider selection is configuration, not a code change (`"AI Provider"` → `"AI Language Model"`)
- Structured output (LLM JSON → AL record) is a first-class primitive
- Mock provider so AI-dependent code is testable without network or API keys
- OpenTelemetry GenAI-compatible signals emitted locally — no default egress
- Direct HTTP to providers (Azure OpenAI, OpenAI, Anthropic, …) — not a wrapper around System.AI

When System.AI / Copilot is already the right tool for a Microsoft-hosted capability, prefer that. Use this toolkit when you need third-party providers, self-hosted endpoints, or a testable provider abstraction.

## Repository layout

```
src/Client/       Public AI Client entry point
src/Provider/     "AI Provider" factory + "AI Language Model" + adapters
src/Config/       Setup and secret handling
src/Structured/   Schema → record binding
src/Retry/        Retry / circuit-breaker policies
src/Telemetry/    Local GenAI span emission
src/Mock/         In-memory mock provider
test/             Mock-based tests (no live keys required)
examples/         Reference usage
docs/adr/         Architecture Decision Records
```

Object IDs: provisional **70100–70199**. Replace with an AppSource-assigned range before publishing.

## Getting started (developers)

1. Install the [AL Language](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al) extension.
2. Ensure BC symbols are in `.alpackages` (Application 28.x).
3. Open this folder and compile with ALC / the AL extension.

Happy path — same shape as Vercel AI SDK’s `generateText({ model, prompt })` (returns text, Errors on failure):

```al
Anthropic: Codeunit "AI Anthropic";
Client: Codeunit "AI Client";
ApiKey: SecretText;
begin
    // Prefer loading into SecretText (Isolated Storage / setup) so the debugger never shows the key
    Message(Client.GenerateText(Anthropic.Model('claude-sonnet-4-5', ApiKey), 'Hello'));
end;
```

```ts
// AI SDK equivalent
const { text } = await generateText({
  model: anthropic('claude-sonnet-4-5'),
  prompt: 'Hello',
});
```

Shipped factories: `"AI Anthropic"`, `"AI OpenAI"`, `"AI OpenCode Zen"`, `"AI Mock"`. API keys are `SecretText` end-to-end (hidden in the debugger; HTTP headers use the SecretText overloads).

- `Client.GenerateText` / `GenerateJson` — return `Text`, Error on failure (like AI SDK throw)
- `Client.TryGenerateText` / `TryGenerateJson` / `TryGenerate` — soft-fail with `AI Chat Response` when you need error type / tokens
- `Client.Generate(Model, Request)` — full request escape hatch that still Errors on failure
- Interfaces remain available if you need a custom provider

See [`examples/AIUsageExample.Codeunit.al`](examples/AIUsageExample.Codeunit.al) for mock / Anthropic / OpenAI / Zen demos.

## License

[MIT](LICENSE) — chosen so ISVs can depend on this from proprietary AppSource apps without licensing friction.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md). Core interface changes need an RFC; new provider adapters have a lower bar.

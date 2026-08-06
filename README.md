# AL AI Open SDK

Provider-agnostic AI integration library for Microsoft Dynamics 365 Business Central, written in AL.

Call large language models through one client API — with structured output parsing, retries, telemetry, and a mock provider for unit tests. This is a **library** that ships inside your extension. It is not a Copilot feature, not a hosted AI service, and not a Microsoft product.

Status: **pre-implementation** (v0.1 scaffolding). See [docs/AL-AI-Toolkit-PRD-and-ADR.docx](docs/AL-AI-Toolkit-PRD-and-ADR.docx) and [docs/adr/](docs/adr/).

## Design highlights

- Provider selection is configuration, not a code change (`"AIOS Provider"` → `"AIOS Language Model"`)
- Structured output (JSON Schema → validated `JsonToken`) is a first-class primitive; flat RecRef binding is a convenience
- Mock provider so AI-dependent code is testable without network or API keys
- OpenTelemetry GenAI-compatible signals emitted locally — no default egress
- Direct HTTP to providers (Azure OpenAI, OpenAI, Anthropic, …) — not a wrapper around System.AI

When System.AI / Copilot is already the right tool for a Microsoft-hosted capability, prefer that. Use this toolkit when you need third-party providers, self-hosted endpoints, or a testable provider abstraction.

## Repository layout

```
src/Client/       Public AIOS Client entry point
src/Provider/     "AIOS Provider" factory + "AIOS Language Model" + adapters
src/Structured/   JSON Schema output on GenerateText; flat RecRef binder (SetOutput)
src/Mock/         In-memory mock provider
test/             Mock-based tests (no live keys required)
examples/         Reference usage
docs/adr/         Architecture Decision Records
```

Object IDs: provisional **87400–87499**. Replace with an AppSource-assigned range before publishing.

## Getting started (developers)

1. Install the [AL Language](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al) extension.
2. Ensure BC symbols are in `.alpackages` (Application 28.x).
3. Open this folder and compile with ALC / the AL extension.

Happy path — `GenerateText` returns `"AIOS Generate Result"` (Errors on failure):

```al
Anthropic: Codeunit "AIOS Anthropic";
Client: Codeunit "AIOS Client";
Result: Codeunit "AIOS Generate Result";
ApiKey: SecretText;
begin
    // Prefer loading into SecretText (Isolated Storage / setup) so the debugger never shows the key
    Result := Client.GenerateText(Anthropic.Model('claude-sonnet-4-5', ApiKey), 'Hello');
    Message(Result.Output());
end;
```

Shipped factories: `"AIOS Anthropic"`, `"AIOS OpenAI"`, `"AIOS OpenCode Zen"`, `"AIOS Mock"`. API keys are `SecretText` end-to-end (hidden in the debugger; HTTP headers use the SecretText overloads).

- **Public:** `Client.GenerateText` — `(Model, Prompt)`, `(Model, System, Prompt)`, or `(Model, Request)` for options; returns `"AIOS Generate Result"`, Errors on failure
- **Result accessors:** `Result.Output()`, `Result.Body()`, `Result.Headers()`, `Result.HttpStatusCode()`, plus token / finish / provider helpers
- **Structured output (preferred):** `Request.SetOutput(Schema.Object(Fields))` then `GenerateText(Model, Request)` — response JSON is validated; read `Result.Output()`. See [RFC 0003](docs/rfc/0003-output-schema.md)
- **Flat record convenience:** `Request.SetOutput(RecRef)` then `GenerateText(Model, Request, RecRef)` — JSON fills bindable fields; raw JSON is on `Result.Output()`
- **Internal** (this app only — tests / demo soft-fail): `TryGenerateText` / `TryGenerate`
- Lifecycle Integration Events on `"AIOS Client"`: `OnBeforeGenerate`, `OnBeforeLanguageModelCall`, `OnAfterLanguageModelCall`, `OnAfterGenerate` (success only) — see [RFC 0001](docs/rfc/0001-lifecycle-callbacks.md)
- Generate options + retries — see [RFC 0002](docs/rfc/0002-generate-options.md)
- Interfaces remain available if you need a custom provider

See [`examples/AIOSUsageExample.Codeunit.al`](examples/AIOSUsageExample.Codeunit.al) for demos starting with `RunBasicDemo`, plus structured output, options, and provider samples.

## License

[MIT](LICENSE) — chosen so ISVs can depend on this from proprietary AppSource apps without licensing friction.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md). Core interface changes need an RFC; new provider adapters have a lower bar.

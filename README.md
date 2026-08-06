# AL AI Open SDK

Provider-agnostic AI integration library for Microsoft Dynamics 365 Business Central, written in AL.

Call large language models through one client API — with structured output parsing, retries, image generation, and a mock provider for unit tests. This is a **library** that ships inside your extension. It is not a Copilot feature, not a hosted AI service, and not a Microsoft product.

Status: **v0.1** (usable client + providers; pre-1.0 — public APIs may still change).

## Design highlights

- Provider selection is configuration, not a code change (`"AIOS Provider"` → `"AIOS Language Model"` / `"AIOS Image Model"`)
- Structured output (JSON Schema → validated text / `JsonToken`) is a first-class primitive; flat RecRef binding is a convenience
- Mock provider so AI-dependent code is testable without network or API keys
- Shared retry / backoff (`"AIOS Retry"`) for text and image generation
- Direct HTTP to providers (OpenAI, Anthropic, OpenCode Zen, …) — not a wrapper around System.AI

When System.AI / Copilot is already the right tool for a Microsoft-hosted capability, prefer that. Use this toolkit when you need third-party providers, self-hosted endpoints, or a testable provider abstraction.

**Not shipped yet:** Azure OpenAI adapter, System.AI platform provider, OpenTelemetry / GenAI telemetry.

## Repository layout

```
src/Client/       Public AIOS Client, results, retry helper
src/Provider/     Interfaces + request/response tables + provider adapters
src/Structured/   JSON Schema builder, validator, RecRef binder
src/Mock/         In-memory mock provider (text + image)
test/             Mock-based tests (no live keys required)
examples/         Demo page, usage examples, feedback buffer DTO
docs/OBJECT_IDS.md
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
- **Structured output (preferred):** `Request.SetOutput(Schema.Object(Fields))` then `GenerateText(Model, Request)` — response JSON is validated; read `Result.Output()`
- **Flat record convenience:** `Request.SetOutput(RecRef)` then `GenerateText(Model, Request, RecRef)` — JSON fills bindable fields; raw JSON is on `Result.Output()`
- **Image generation:** `OpenAI.ImageModel(...)` / `Mock.ImageModel(...)` + `Client.GenerateImage` → `"AIOS Generate Image Result"` with `GetImages()`, `GetUsage()`, `GetResponseCalls()`
- **Internal** (this app only — tests / demo soft-fail): `TryGenerateText` / `TryGenerate` / `TryGenerateImage`
- **Lifecycle** Integration Events on `"AIOS Client"`: `OnBeforeGenerate`, `OnBeforeLanguageModelCall`, `OnAfterLanguageModelCall`, `OnAfterGenerate` (success only)
- **Retries:** request `GetMaxRetries` / `SetMaxRetries` (default 2); retriable errors are rate limit, timeout, and provider unavailable (`"AIOS Retry"`)
- Interfaces remain available if you need a custom provider

See [`examples/AIOSUsageExample.Codeunit.al`](examples/AIOSUsageExample.Codeunit.al) for demos starting with `RunBasicDemo`, plus structured output, options, image, and provider samples. Interactive UI: page `"AIOS Toolkit Demo"`.

## License

[MIT](LICENSE) — chosen so ISVs can depend on this from proprietary AppSource apps without licensing friction.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md).

# AI Open SDK for Business Central

Provider-agnostic AI integration library for Microsoft Dynamics 365 Business Central, written in AL.

Packaged like the [Vercel AI SDK](https://ai-sdk.dev/): **Core** client API + **sibling provider apps**. Install only what you need.

Status: **v0.1** (usable client + providers; pre-1.0 — public APIs may still change).

## Install model

| Need | Apps |
|------|------|
| Client + Mock tests | **AI Open SDK** (Core) |
| OpenAI chat/image | Core + **OpenAI** (+ Provider Utils, pulled in) |
| Anthropic | Core + **Anthropic** |
| Any Chat Completions URL | Core + **OpenAI Compatible** (+ Provider Utils) |
| OpenCode Zen | Core + **OpenCode Zen** (+ Provider Utils) |
| Demo UI | **Examples** (depends on Core + providers) |

```al
OpenAI: Codeunit "AIOS OpenAI";
Client: Codeunit "AIOS Client";
Result: Codeunit "AIOS Generate Result";
ApiKey: SecretText;
begin
    Result := Client.GenerateText(OpenAI.Model('gpt-5.5', ApiKey), 'Hello');
    Message(Result.Output());
end;
```

See [docs/PUBLIC_API.md](docs/PUBLIC_API.md) for the supported surface.

## Design highlights

- Provider selection is configuration, not a code change (`"AIOS Provider"` → `"AIOS Language Model"` / `"AIOS Image Model"`)
- Structured output (JSON Schema → validated text / `JsonToken`) is a first-class primitive; flat RecRef binding is a convenience
- Mock provider in Core so AI-dependent code is testable without network or API keys
- Shared retry / backoff (`"AIOS Retry"`) for text and image generation
- Direct HTTP to providers — not a wrapper around System.AI
- Attachments and tools as documented below
- **No provider→provider dependencies.** Chat Completions sharing lives in **Provider Utils** (like `@ai-sdk/provider-utils`). OpenAI Compatible is a peer package, not a base for OpenAI/Zen.

**Not shipped yet:** Azure OpenAI adapter, System.AI platform provider, OpenTelemetry / GenAI telemetry.

## Repository layout

Each `apps/*` folder is a **standalone AL extension** (own `app.json`, `src/`, `.vscode/`). Optional multi-root: [`AL-AI-Toolkit.code-workspace`](AL-AI-Toolkit.code-workspace).

```
apps/AIOpenSDK.Core/                 Client, contracts, tools, structured, Mock
apps/AIOpenSDK.ProviderUtils/        Shared Chat Completions format/options/HTTP
apps/AIOpenSDK.Provider.OpenAI/
apps/AIOpenSDK.Provider.Anthropic/
apps/AIOpenSDK.Provider.OpenAICompatible/
apps/AIOpenSDK.Provider.OpenCodeZen/
apps/AIOpenSDK.Examples/             Demo page + samples
apps/AIOpenSDK.Test/                 Mock-based tests
docs/OBJECT_IDS.md
docs/PUBLIC_API.md
docs/DEVELOPMENT.md                  How to work on Core / one provider / consumers
scripts/prepare-deps.ps1             Package Core+Utils (Windows)
scripts/prepare-deps.sh              Package Core+Utils (Linux/macOS)
scripts/publish-apps.ps1             Package + publish stack (Windows)
scripts/publish-apps.sh              Package + publish stack (Linux/macOS)
```

Object IDs: provisional — see [docs/OBJECT_IDS.md](docs/OBJECT_IDS.md). Replace with AppSource-assigned ranges before publishing.

## Getting started (developers)

Full workflows (including **provider-only** work): **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**.

1. Install the [AL Language](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al) extension.
2. Open `apps/AIOpenSDK.Core`, configure launch.json, run **Download Symbols** once (fills shared `.alpackages/`).
3. From the repo root, package Core + ProviderUtils into `.alpackages`:

   ```powershell
   .\scripts\prepare-deps.ps1    # Windows
   ```

   ```bash
   ./scripts/prepare-deps.sh     # Linux / macOS
   ```

4. To publish Core + Utils + providers to your BC (dev endpoint), set credentials and run:

   ```powershell
   $env:BC_USERNAME = 'YOUR_USER'
   $env:BC_PASSWORD = 'YOUR_PASSWORD'
   .\scripts\publish-apps.ps1
   ```

   Target comes from `apps/AIOpenSDK.Core/.vscode/launch.json` unless you override with `BC_SERVER` / `-Server`. See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

5. Or open a single app and Package/Publish — or use [`AL-AI-Toolkit.code-workspace`](AL-AI-Toolkit.code-workspace) for the full stack.

Happy path — `GenerateText` returns `"AIOS Generate Result"` (Errors on failure):

```al
Anthropic: Codeunit "AIOS Anthropic";
Client: Codeunit "AIOS Client";
Result: Codeunit "AIOS Generate Result";
ApiKey: SecretText;
begin
    Result := Client.GenerateText(Anthropic.Model('claude-sonnet-4-5', ApiKey), 'Hello');
    Message(Result.Output());
end;
```

Shipped factories: `"AIOS Anthropic"`, `"AIOS OpenAI"`, `"AIOS OpenCode Zen"`, `"AIOS OpenAI Compatible"`, `"AIOS Mock"`. API keys are `SecretText` end-to-end.

- **Public:** `Client.GenerateText` — `(Model, Prompt)`, `(Model, System, Prompt)`, or `(Model, Request)` for options; returns `"AIOS Generate Result"`, Errors on failure
- **Result accessors:** `Result.Output()`, `Result.Body()`, `Result.Headers()`, `Result.HttpStatusCode()`, plus token / finish / provider helpers; `Result.HasToolCalls()` / `Result.GetToolCalls()` when the model requests tools
- **Structured output (preferred):** `Request.SetOutput(Schema.Object(Fields))` then `GenerateText(Model, Request)` — response JSON is validated; read `Result.Output()`
- **Flat record convenience:** `Request.SetOutput(RecRef)` then `GenerateText(Model, Request, RecRef)` — JSON fills bindable fields; raw JSON is on `Result.Output()`
- **Attachments / multimodal:** `Request.Attach(Item.Picture.Item(1))` or `Attach(InStream|TempBlob|TenantMedia|Base64, …)`
- **Tools:** primary `ToolSet.Add(Tool)` (`"AIOS Tool"`). Secondary: `"AIOS Tool Handler"` + `ToolSet.Use(Handler)`. Escape hatch: `ToolSet.Add(Name, Description, Schema)` + `OnExecuteTool`
- **Image generation:** `OpenAI.ImageModel(...)` / `Mock.ImageModel(...)` + `Client.GenerateImage`
- **Soft-fail in your app:** wrap `GenerateText` / `GenerateImage` in a `[TryFunction]` (see Examples). Core `TryGenerate*` stays **internal**.
- **Lifecycle** Integration Events on `"AIOS Client"`: `OnBeforeGenerate`, `OnBeforeLanguageModelCall`, `OnAfterLanguageModelCall`, `OnAfterGenerate` (success only)
- **Retries:** request `GetMaxRetries` / `SetMaxRetries` (default 2)
- **Custom providers:** implement `"AIOS Language Model"` in your own app depending on Core (and Provider Utils if you speak Chat Completions). Or use `"AIOS OpenAI Compatible".Model(Id, Key, BaseUrl)`.

```al
Request.SetPrompt('Write a product description for this item image.');
Request.Attach(Item.Picture.Item(1));
Result := Client.GenerateText(VisionModel, Request);
```

### Tools — Add and Use

| Priority | API | Pattern |
|---|---|---|
| **Primary** | `ToolSet.Add(Echo)` | `"AIOS Tool"` — one codeunit per tool |
| **Secondary** | `ToolSet.Use(Handler)` | `"AIOS Tool Handler"` — many tools, one ID |

```al
ToolSet.Add(Echo);
ToolSet.Use(Handler);   // once per ToolSet
Result := Client.GenerateText(Model, Request, ToolSet);  // default MaxSteps = 5
```

See [`apps/AIOpenSDK.Examples/src/AIOSUsageExample.Codeunit.al`](apps/AIOpenSDK.Examples/src/AIOSUsageExample.Codeunit.al). Interactive UI: page `"AIOS Toolkit Demo"` (Examples app).

## License

[MIT](LICENSE) — chosen so ISVs can depend on this from proprietary AppSource apps without licensing friction.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md).

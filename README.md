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
- Tools via `"AIOS Tool Set"`: prefer `Register` + `"AIOS Tool Handler"` (many tools, one codeunit); optional `"AIOS Tool"` per reusable tool

When System.AI / Copilot is already the right tool for a Microsoft-hosted capability, prefer that. Use this toolkit when you need third-party providers, self-hosted endpoints, or a testable provider abstraction.

**Not shipped yet:** Azure OpenAI adapter, System.AI platform provider, OpenTelemetry / GenAI telemetry.

## Repository layout

```
src/Client/       Public AIOS Client, results, retry helper
src/Provider/     Interfaces + request/response tables + provider adapters
src/Structured/   JSON Schema builder, validator, RecRef binder
src/Tools/        Tool interface/set/call + Chat Format (wire mapping)
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
- **Result accessors:** `Result.Output()`, `Result.Body()`, `Result.Headers()`, `Result.HttpStatusCode()`, plus token / finish / provider helpers; `Result.HasToolCalls()` / `Result.GetToolCalls()` when the model requests tools
- **Structured output (preferred):** `Request.SetOutput(Schema.Object(Fields))` then `GenerateText(Model, Request)` — response JSON is validated; read `Result.Output()`
- **Flat record convenience:** `Request.SetOutput(RecRef)` then `GenerateText(Model, Request, RecRef)` — JSON fills bindable fields; raw JSON is on `Result.Output()`
- **Tools:** prefer `ToolSet.Register(Name, Description, Schema)` + `ToolSet.SetHandler(Handler)` so many tools share one `"AIOS Tool Handler"` codeunit. Alternatively `ToolSet.Add` an `"AIOS Tool"` implementation (one object per tool). Then `GenerateText(Model, Request, ToolSet, MaxSteps)` — the client runs tools between model calls until final text or the step limit (`MaxSteps` less than 1 is treated as 1). Structured output / RecRef binding runs on the **final** non-tool-call step only. Unknown tool names fail the run; tool `Execute` failures are sent back to the model as tool result text and the loop continues. Thinking/reasoning models that return `reasoning_content` (e.g. DeepSeek via OpenCode Zen) have that field preserved and echoed on follow-up turns. The result exposes `GetResponseCalls()` / `GetStepCount()` / `GetTotalInputTokens()` / `GetTotalOutputTokens()` so every model HTTP call (tool steps and retries) is visible, not only the last response.
- **Tools (single step / manual):** `GenerateText(Model, Request)` with `Request.SetTools` returns after the first model call (including tool calls). You can still append messages and call again yourself.
- **Image generation:** `OpenAI.ImageModel(...)` / `Mock.ImageModel(...)` + `Client.GenerateImage` → `"AIOS Generate Image Result"` with `GetImages()`, `GetUsage()`, `GetResponseCalls()`
- **Internal** (this app only — tests / demo soft-fail): `TryGenerateText` / `TryGenerate` / `TryGenerateWithTools` / `TryGenerateImage`
- **Lifecycle** Integration Events on `"AIOS Client"`: `OnBeforeGenerate`, `OnBeforeLanguageModelCall`, `OnAfterLanguageModelCall`, `OnAfterGenerate` (success only)
- **Retries:** request `GetMaxRetries` / `SetMaxRetries` (default 2); retriable errors are rate limit, timeout, and provider unavailable (`"AIOS Retry"`)
- Interfaces remain available if you need a custom provider (`"AIOS Provider"`, `"AIOS Language Model"`, `"AIOS Chat Format"`, `"AIOS Image Model"`, `"AIOS Tool"`, `"AIOS Tool Handler"`)
- **Custom providers:** implement `"AIOS Language Model"` (and optionally `"AIOS Provider"`). For tools/messages, implement `"AIOS Chat Format"` or reuse `"AIOS OpenAI Compatible Format"` / `"AIOS Anthropic Format"` if your API matches those schemas.

### Tools (automatic loop — preferred)

```al
ToolSet: Codeunit "AIOS Tool Set";
Handler: Codeunit "My App Tool Handler"; // implements "AIOS Tool Handler"
Request: Record "AIOS Chat Request";
Result: Codeunit "AIOS Generate Result";
Schema: Codeunit "AIOS Schema";
Fields: List of [JsonObject];
begin
    Fields.Add(Schema.Field('message', Schema.String()));
    ToolSet.Register('echo', 'Echoes the message argument.', Schema.Object(Fields));
    ToolSet.SetHandler(Handler);
    Request.SetPrompt('Use the echo tool when helpful');
    Result := Client.GenerateText(Model, Request, ToolSet, 5);
end;
```

### Tools (automatic loop — one codeunit per tool)

```al
ToolSet: Codeunit "AIOS Tool Set";
Echo: Codeunit "AIOS Echo Tool";
Request: Record "AIOS Chat Request";
Result: Codeunit "AIOS Generate Result";
begin
    ToolSet.Add(Echo);
    Request.SetPrompt('Use the echo tool when helpful');
    Result := Client.GenerateText(Model, Request, ToolSet, 5);
end;
```

### Tools (manual continue)

```al
ToolSet: Codeunit "AIOS Tool Set";
Echo: Codeunit "AIOS Echo Tool";
Request: Record "AIOS Chat Request";
Result: Codeunit "AIOS Generate Result";
ToolCalls: List of [Codeunit "AIOS Tool Call"];
Call: Codeunit "AIOS Tool Call";
ResultText: Text;
i: Integer;
begin
    ToolSet.Add(Echo);
    Request.SetPrompt('Use the echo tool');
    Request.SetTools(ToolSet);
    Request.EnsureMessagesFromPrompt();

    Result := Client.GenerateText(Model, Request);
    if Result.HasToolCalls() then begin
        ToolCalls := Result.GetToolCalls();
        Request.AppendAssistantToolCalls(Result.Output(), ToolCalls);
        for i := 1 to ToolCalls.Count() do begin
            ToolCalls.Get(i, Call);
            ToolSet.Execute(Call.GetName(), Call.GetArguments(), ResultText);
            Request.AppendToolResult(Call.GetId(), Call.GetName(), ResultText);
        end;
        Result := Client.GenerateText(Model, Request);
    end;
end;
```

See [`examples/AIOSUsageExample.Codeunit.al`](examples/AIOSUsageExample.Codeunit.al) for demos starting with `RunBasicDemo`, plus structured output, options, image, tools (`RunToolsManualContinueDemo`, `RunMultiToolHandlerDemo`), and provider samples. Interactive UI: page `"AIOS Toolkit Demo"`.

## License

[MIT](LICENSE) — chosen so ISVs can depend on this from proprietary AppSource apps without licensing friction.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [GOVERNANCE.md](GOVERNANCE.md).

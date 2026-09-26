# Public API (v0.1)

Supported surface for application developers. Prefer these objects; treat anything else as subject to change.

## Core (`AI Open SDK`)

- `"AIOS Client"` — `GenerateText` / `GenerateImage` (raise on failure) + lifecycle events
- `"AIOS Generate Result"` / `"AIOS Generate Image Result"` and related result helpers (`Output`, `GetResponseCalls`, …)
- `"AIOS Chat Request"` / `"AIOS Chat Response"` (and image request/response tables)
  - `SetOutput` keeps its generated JSON/schema instruction apart from the system message: `GetSystemMessage` returns only your text, `GetEffectiveSystemMessage` returns the text sent to providers. `ClearOutput` removes the instruction and turns `"Json Mode"` off.
  - `Messages` holds conversation turns only. `GetProviderMessages` adds the current effective system message first, so system/output changes on a reused request apply. `SetPrompt` on a request with history adds the prompt once as the next user turn.
- `"AIOS Schema"`, `"AIOS Tool Set"`, `"AIOS Tool"` / `"AIOS Tool Handler"` interfaces
- `"AIOS Mock"` — unit tests without network. Configure `SetNext*` before `Model` / `ImageModel`: the bound model takes a copy of that state. `SetNextToolCallThenResponse` returns empty text on the tool-call turn. Use the `ToolTurnText` overload for a preamble.
  - `"AIOS Tool Call".TryGetArguments` returns false when the model sent arguments that are not valid JSON; `GetArguments` returns `{}` in that case and `GetArgumentsJson` returns the raw text.
- `"AIOS Http Error Mapper"` — shared HTTP status → error type mapping (provider authors)
- `"AIOS Privacy Notice"` — company-level privacy-notice approval gate for outbound AI HTTP (no per-call UI)
- `"AIOS Request Options"` — reasoning helpers
- Interfaces: `"AIOS Provider"`, `"AIOS Language Model"`, `"AIOS Image Model"`, `"AIOS Chat Format"`

Soft-fail UI: wrap `GenerateText` / `GenerateImage` in a `[TryFunction]` in your app (see Examples demo). Do **not** call Core `TryGenerate*` — those are Internal.

## Provider apps (install only what you need)

- `"AIOS OpenAI"` (+ image via `ImageModel`)
- `"AIOS Anthropic"`
- `"AIOS OpenAI Compatible"` — any Chat Completions base URL
- `"AIOS OpenCode Zen"` — Zen defaults (or use Compatible with Zen’s URL)

## ProviderUtils

Usually **not** referenced from application code. Provider authors use:

- `"AIOS Chat Completions Format"`
- `"AIOS Chat Completions Options"`
- `"AIOS Chat Completions Client"`

OpenAI / OpenAI Compatible / OpenCode Zen depend on ProviderUtils; Anthropic depends on Core only.

`Client.Generate` and `Options.Apply` each have an overload with an `OpenAIDialect: Boolean` argument. `true` (used by the OpenAI provider) sends `max_completion_tokens` and passes every reasoning level through as `reasoning_effort`; the original overloads use the compatible dialect (`max_tokens`, reasoning coerced to `low` / `medium` / `high` with a compatibility warning).

## Not public for consumers

- `TryGenerate*` / `TryGenerateImage` / `GetChatResponseCalls` on `"AIOS Client"` (`internal`)
- `"AIOS Retry"` (`Access = Internal`)
- `* Model` codeunits (`Access = Internal`)
- `"AIOS Json Binder"`, `"AIOS Schema Validator"` (`Access = Internal`)
- Test app and Examples app objects

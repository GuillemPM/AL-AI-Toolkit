# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Fixed

- HTTP 529 (overloaded) and other transient 5xx responses are now mapped to `ProviderUnavailable` and retried. 501 and 505 stay `Unknown`.
- A failed tool step (unknown tool, or an error raised by tool code) no longer leaves an unanswered assistant tool-call turn in the request history, so the request can be reused. Tool names are all checked before any tool in the step runs.
- Tool calls whose arguments are not valid JSON are no longer executed with `{}`. The tool is skipped, the error is returned to the model as the tool result, and the history keeps the raw arguments.
- `GenerateText(Model, Request, ToolSet, [MaxSteps,] RecRef)` now raises an error when MaxSteps is reached while the model still requests tool calls, instead of returning success with an unfilled record.
- `"AIOS Chat Request".ClearOutput` now also disables `"Json Mode"` and drops the generated output instruction, so a reused request no longer keeps JSON mode or a stale schema hint.
- Calling `SetOutput` repeatedly on the same request no longer stacks schema hints, and calling `SetSystemMessage` after `SetOutput` no longer drops the hint.
- Anthropic tool loops with extended thinking no longer fail on the second request. Thinking and redacted-thinking blocks, signatures included, are now kept from the response and sent back unchanged with the assistant tool-call turn.
- Anthropic thinking options no longer produce requests the API rejects. When the thinking budget would not fit below `max_tokens`, `max_tokens` is raised to budget + requested max tokens, with a `compatibility` warning. With thinking on, `temperature`, `top_k`, and a `top_p` outside 0.95–1 are omitted, each with an `unsupported` warning.
- `RunAnthropicOptionsDemo` now uses 4096 max tokens and only sampling options that Anthropic accepts with thinking.

### Added

- `"AIOS Chat Response"` field `"Provider Content"` with `SetProviderContent` / `GetProviderContent`. It holds opaque, provider-tagged assistant content (`{ "provider": ..., "content": [...] }`) that must be sent back on tool-loop turns.
- `"AIOS Chat Request".AppendAssistantToolCalls(var Response)` appends the assistant tool-call turn straight from a response, including provider content; use it in manual tool loops. There is also a new overload that takes `ProviderContent: JsonObject`. The history key `provider_content` is written only when provider content is present, and only the owning provider's format reads it.
- `"AIOS Anthropic Format".ExtractProviderContent` / `GetThinkingText`. Anthropic responses now also fill `GetReasoningContent()` with the thinking text.
- `"AIOS Mock".SetNextToolCallProviderContent` for testing tool loops.
- `SetPrompt` on a request that already has message history is no longer ignored: the prompt is added once as the next user turn. Repeated generates and manual tool loops do not add it again.
- Requests built from history (`SetMessages` / `AppendUserMessage`) now send the system message and output instruction to Chat Completions providers.
- The system message and output instruction are no longer frozen into history on the first generate, so `SetSystemMessage`, `SetOutput` and `ClearOutput` on a reused request take effect.
- Changes made to the request in an `OnBeforeGenerate` subscriber (prompt, attachments, system message, output) are now sent.
- `GenerateText(Model, Request, RecRef)` and the tool overload with a RecRef always rebind output to that RecRef, so a reused request no longer keeps another table's schema hint.
- Attachments added after a tool result without a new prompt no longer repeat the earlier prompt.
- The OpenAI provider now sends `max_completion_tokens` instead of `max_tokens`, which OpenAI reasoning models (o-series, gpt-5) reject. OpenAI Compatible and OpenCode Zen still send `max_tokens`.
- Malformed or null fields in a Chat Completions response (`choices`, `message`, `content`, `finish_reason`, `usage`, tool call `id` / `name` / `arguments`) now return a `ParseFailed` error instead of raising an AL runtime error. Content returned as an array of text parts is joined.
- Assistant tool-call messages no longer carry an empty `reasoning_content`, in stored history or on the wire.
- Text file attachments sent to Chat Completions and Anthropic are now introduced by `[file: name]` followed by a real line feed rather than a literal `\n`.
- The OpenAI reasoning example uses `High`, because `o4-mini` does not accept `xhigh`.

### Added

- `"AIOS Tool Call".TryGetArguments` to detect malformed tool-call arguments.

### Changed

- `SetOutput` no longer rewrites the system message. The generated output instruction is kept in the new internal field `"Output Instruction"` and added by `GetEffectiveSystemMessage`, so `GetSystemMessage` returns only the text you set. Provider payloads are unchanged; read `GetEffectiveSystemMessage` if you need the text as sent.
- `ClearOutput` resets `"Json Mode"` even if it was set by hand.
- `"AIOS Chat Request".Messages` no longer contains a generated system turn. `GetProviderMessages` puts the current effective system message first (skipped when history already starts with the same system text); system turns you add to history yourself are kept after it.
- `OnBeforeGenerate` now runs before the prompt and pending attachments are added to the history.
- For manual multi-turn chats, add the reply with `AppendAssistantMessage(Result.Output())` before the next `SetPrompt`. To reuse a request for an unrelated prompt, call `ClearMessages` first.
- OpenAI Compatible and OpenCode Zen no longer send `reasoning_effort` values that compatible servers do not document: `XHigh` is sent as `high` and `Minimal` as `low`, each with a `compatibility` warning on the response. The OpenAI provider still passes every level through (`minimal` … `xhigh`); which levels a model accepts is up to OpenAI.
- `"AIOS Chat Completions Client".Generate` and `"AIOS Chat Completions Options".Apply` have new overloads with an `OpenAIDialect` argument. The existing overloads keep their signatures and use the compatible dialect.

## [0.1.0] — 2026-08-09

### Added

- `docs/DEVELOPMENT.md` — consumer / Core / provider-only workflows (Windows-first)
- `scripts/prepare-deps.ps1` / `prepare-deps.sh` — package Core + ProviderUtils into shared `.alpackages`

### Changed

- Split the monolith into AI SDK–shaped apps under `apps/`: Core, ProviderUtils, OpenAI, Anthropic, OpenAICompatible, OpenCodeZen, Examples, Test.
- OpenAI / OpenCode Zen / OpenAI Compatible share Chat Completions via **Provider Utils** (no provider→provider dependencies).
- Anthropic `SetBaseUrl` / configurable messages endpoint (default `https://api.anthropic.com/v1`).
- Rehomed Anthropic Format/Options object IDs to 87452–87453; File Content Tests to 87500.
- Removed per-provider duplicate OpenAI-family Format/Options codeunits in favor of `"AIOS Chat Completions Format"` / `"AIOS Chat Completions Options"`.

### Security

- Stopped tracking personal `.vscode/launch.json`; use `launch.json.example` instead.

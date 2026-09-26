# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Fixed

- `"AIOS Chat Request".ClearOutput` now also disables `"Json Mode"` and drops the generated output instruction, so a reused request no longer keeps JSON mode or a stale schema hint.
- Calling `SetOutput` repeatedly on the same request no longer stacks schema hints, and calling `SetSystemMessage` after `SetOutput` no longer drops the hint.
- `SetPrompt` on a request that already has message history is no longer ignored: the prompt is added once as the next user turn. Repeated generates and manual tool loops do not add it again.
- Requests built from history (`SetMessages` / `AppendUserMessage`) now send the system message and output instruction to Chat Completions providers.
- The system message and output instruction are no longer frozen into history on the first generate, so `SetSystemMessage`, `SetOutput` and `ClearOutput` on a reused request take effect.
- Changes made to the request in an `OnBeforeGenerate` subscriber (prompt, attachments, system message, output) are now sent.
- `GenerateText(Model, Request, RecRef)` and the tool overload with a RecRef always rebind output to that RecRef, so a reused request no longer keeps another table's schema hint.
- Attachments added after a tool result without a new prompt no longer repeat the earlier prompt.

### Changed

- `SetOutput` no longer rewrites the system message. The generated output instruction is kept in the new internal field `"Output Instruction"` and added by `GetEffectiveSystemMessage`, so `GetSystemMessage` returns only the text you set. Provider payloads are unchanged; read `GetEffectiveSystemMessage` if you need the text as sent.
- `ClearOutput` resets `"Json Mode"` even if it was set by hand.
- `"AIOS Chat Request".Messages` no longer contains a generated system turn. `GetProviderMessages` puts the current effective system message first (skipped when history already starts with the same system text); system turns you add to history yourself are kept after it.
- `OnBeforeGenerate` now runs before the prompt and pending attachments are added to the history.
- For manual multi-turn chats, add the reply with `AppendAssistantMessage(Result.Output())` before the next `SetPrompt`. To reuse a request for an unrelated prompt, call `ClearMessages` first.

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

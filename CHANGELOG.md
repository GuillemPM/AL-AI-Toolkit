# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Fixed

- `"AIOS Chat Request".ClearOutput` now also disables `"Json Mode"` and drops the generated output instruction, so a reused request no longer keeps JSON mode or a stale schema hint.
- Calling `SetOutput` repeatedly on the same request no longer stacks schema hints, and calling `SetSystemMessage` after `SetOutput` no longer drops the hint.
- Examples demo page: Generate structured, Generate JSON and Generate choice now work with Mock. The canned Mock response is set before the model is bound, and the choice response is built as JSON instead of by string substitution.
- Examples demo page: Generate images now stores every generated image on the history line. It previously read the provider body, which holds only the last batch, and stored one image (or one corrupt picture with Mock).
- Examples `get_customer_list` tool: the model-supplied `searchName` can no longer add filter clauses or break the filter. Filter characters match any single character instead.

### Changed

- `SetOutput` no longer rewrites the system message. The generated output instruction is kept in the new internal field `"Output Instruction"` and added by `GetEffectiveSystemMessage`, so `GetSystemMessage` returns only the text you set. Provider payloads are unchanged; read `GetEffectiveSystemMessage` if you need the text as sent.
- `ClearOutput` resets `"Json Mode"` even if it was set by hand.
- `"AIOS Mock"`: a tool-call turn no longer carries the final response text. `SetNextToolCallThenResponse(Id, Name, Args, FinalContent)` returns empty text with the tool call and `FinalContent` on the next turn, like real providers. The new overload `SetNextToolCallThenResponse(Id, Name, Args, ToolTurnText, FinalContent)` sets text on the tool-call turn.
- Examples `"AIOS Demo Tools"` and `"AIOS Lifecycle Example"` are now manual event subscribers. Call `BindSubscription` to use them. Installing the Examples app no longer answers other apps' `echo` / `add_numbers` / `to_upper` tools or records every generate call. `"AIOS Lifecycle Example"` now keeps the trace of the last generate only.

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

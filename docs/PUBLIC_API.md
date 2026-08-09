# Public API (v0.1)

Supported surface for application developers. Prefer these objects; treat anything else as subject to change.

## Core (`AL AI Open SDK`)

- `"AIOS Client"` — `GenerateText` / `GenerateImage` (+ lifecycle events)
- `"AIOS Generate Result"` / `"AIOS Generate Image Result"` and related result helpers
- `"AIOS Chat Request"` / `"AIOS Chat Response"` (and image request/response tables)
- `"AIOS Schema"`, `"AIOS Tool Set"`, `"AIOS Tool"` / `"AIOS Tool Handler"` interfaces
- `"AIOS Mock"` — unit tests without network
- Interfaces: `"AIOS Provider"`, `"AIOS Language Model"`, `"AIOS Image Model"`, `"AIOS Chat Format"`

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

## Not public for consumers

- Test app and Examples app objects
- `* Model` codeunits (`Access = Internal`)
- `"AIOS Retry"`, `"AIOS Json Binder"`, `"AIOS Schema Validator"` (Internal)

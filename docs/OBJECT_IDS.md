# Object ID ranges (multi-app)

Provisional IDs until AppSource assignment. Each app owns its `idRanges` in `apps/*/app.json`.

| Band | App |
|------|-----|
| 87400–87417, 87420–87428 | **Core** contracts, client, tools |
| 87446–87447, 87449 | **Core** Mock (+ image mock) |
| 87460–87479 | **Core** structured output, retry, HTTP error mapper |
| 87435–87439 | **ProviderUtils** Chat Completions helpers |
| 87440–87441, 87452–87453 | **Anthropic** |
| 87442–87443, 87448 | **OpenAI** (+ image model) |
| 87444–87445 | **OpenCodeZen** |
| 87450–87451 | **OpenAICompatible** |
| 87480–87489, 87498–87499 | **Examples** |
| 87490–87497, 87500–87509 | **Test** |

Interfaces (`"AIOS Provider"`, `"AIOS Language Model"`, `"AIOS Image Model"`, `"AIOS Chat Format"`, `"AIOS Tool"`, `"AIOS Tool Handler"`) have no numeric object ID in AL.

### Core

| ID | Object |
|----|--------|
| 87400 | AIOS Error Type |
| 87401 | AIOS Chat Request |
| 87402 | AIOS Chat Response |
| 87403 | AIOS Image Request |
| 87404 | AIOS Image Response |
| 87405 | AIOS Reasoning Effort |
| 87407 | AIOS Generated Image |
| 87408 | AIOS Image Response Call |
| 87409 | AIOS Chat Response Call |
| 87410 | AIOS Client |
| 87411 | AIOS Generate Result |
| 87412 | AIOS Generate Image Result |
| 87413 | AIOS Request Options |
| 87414 | AIOS Image Usage |
| 87415 | AIOS Retry Tests |
| 87416 | AIOS Tool Call |
| 87417 | AIOS Tool Set |
| 87420 | AIOS Tool Args |
| 87421 | AIOS Message Content |
| 87423 | AIOS Chat Attachments |
| 87424 | AIOS Chat Prompt |
| 87425 | AIOS Chat Output |
| 87426 | AIOS Chat Parameters |
| 87427 | AIOS Chat Request Tools |
| 87428 | AIOS Chat Messages |
| 87446 | AIOS Mock |
| 87447 | AIOS Mock Model |
| 87449 | AIOS Mock Image Model |
| 87460 | AIOS Retry |
| 87461 | AIOS Json Binder |
| 87462 | AIOS Schema |
| 87463 | AIOS Schema Validator |
| 87464 | AIOS Http Error Mapper |

### ProviderUtils

| ID | Object |
|----|--------|
| 87435 | AIOS Chat Completions Format |
| 87436 | AIOS Chat Completions Options |
| 87437 | AIOS Chat Completions Client |

### Providers

| ID | Object | App |
|----|--------|-----|
| 87440 | AIOS Anthropic | Anthropic |
| 87441 | AIOS Anthropic Model | Anthropic |
| 87452 | AIOS Anthropic Format | Anthropic |
| 87453 | AIOS Anthropic Options | Anthropic |
| 87442 | AIOS OpenAI | OpenAI |
| 87443 | AIOS OpenAI Model | OpenAI |
| 87448 | AIOS OpenAI Image Model | OpenAI |
| 87444 | AIOS OpenCode Zen | OpenCodeZen |
| 87445 | AIOS OpenCode Zen Model | OpenCodeZen |
| 87450 | AIOS OpenAI Compatible | OpenAICompatible |
| 87451 | AIOS OpenAI Compatible Model | OpenAICompatible |

### Examples / Test

| ID | Object | App |
|----|--------|-----|
| 87480 | AIOS Usage Example | Examples |
| 87481 | AIOS Toolkit Demo | Examples |
| 87482–87489 | Demo history / tools UI | Examples |
| 87498 | AIOS Echo Tool | Examples |
| 87499 | AIOS Get Customers Tool | Examples |
| 87490–87497 | Test codeunits / bind target | Test |
| 87500 | AIOS File Content Tests | Test |

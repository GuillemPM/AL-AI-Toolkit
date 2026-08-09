# Object ID ranges

Current provisional range in `app.json`: **87400–87499**.

| Range (planned) | Use |
|---|---|
| 87400–87439 | Core: error enum, chat request/response, interfaces, client, tools |
| 87440–87459 | Provider adapters (each folder = future installable app) |
| 87460–87479 | Structured output, retry, HTTP error mapper |
| 87480–87499 | Examples / reserved |

### Core (87400–87439)

| ID | Object |
|---|---|
| 87400 | AIOS Error Type |
| 87401 | AIOS Chat Request |
| 87402 | AIOS Chat Response |
| 87403 | AIOS Image Request |
| 87404 | AIOS Image Response |
| 87405 | AIOS Reasoning Effort |
| 87406 | AIOS Image Model (interface) |
| 87407 | AIOS Generated Image |
| 87408 | AIOS Image Response Call |
| 87409 | AIOS Chat Response Call |
| 87410 | AIOS Client |
| 87411 | AIOS Generate Result |
| 87412 | AIOS Generate Image Result |
| 87413 | AIOS Request Options (Public — generic reasoning helpers) |
| 87414 | AIOS Image Usage |
| 87415 | AIOS Tool (interface) |
| 87416 | AIOS Tool Call |
| 87417 | AIOS Tool Set |
| 87420 | AIOS Tool Args |
| 87421 | AIOS Message Content (neutral MIME helpers) |
| 87422 | AIOS File Content Tests |
| 87423 | AIOS Chat Attachments |
| 87424 | AIOS Chat Prompt |
| 87425 | AIOS Chat Output |
| 87426 | AIOS Chat Parameters |
| 87427 | AIOS Chat Request Tools |
| 87428 | AIOS Chat Messages |
| — | AIOS Chat Format (interface) |
| — | AIOS Tool Handler (interface) |

### Provider adapters (87440–87459) — Core-only deps; no provider→provider

| ID | Object | Package folder |
|---|---|---|
| 87418 | AIOS OpenAI Compatible Format | OpenAICompatible |
| 87419 | AIOS Anthropic Format | Anthropic |
| 87429 | AIOS OpenAI Compatible Options | OpenAICompatible |
| 87430 | AIOS Anthropic Options | Anthropic |
| 87431 | AIOS OpenAI Format | OpenAI |
| 87432 | AIOS OpenAI Options | OpenAI |
| 87433 | AIOS OpenCode Zen Format | OpenCodeZen |
| 87434 | AIOS OpenCode Zen Options | OpenCodeZen |
| 87440 | AIOS Anthropic | Anthropic |
| 87441 | AIOS Anthropic Model | Anthropic |
| 87442 | AIOS OpenAI | OpenAI |
| 87443 | AIOS OpenAI Model | OpenAI |
| 87444 | AIOS OpenCode Zen | OpenCodeZen |
| 87445 | AIOS OpenCode Zen Model | OpenCodeZen |
| 87446 | AIOS Mock | Mock |
| 87447 | AIOS Mock Model | Mock |
| 87448 | AIOS OpenAI Image Model | OpenAI |
| 87449 | AIOS Mock Image Model | Mock |
| 87450 | AIOS OpenAI Compatible | OpenAICompatible |
| 87451 | AIOS OpenAI Compatible Model | OpenAICompatible |

### Structured output / retry (87460–87479)

| ID | Object |
|---|---|
| 87460 | AIOS Retry |
| 87461 | AIOS Json Binder |
| 87462 | AIOS Schema |
| 87463 | AIOS Schema Validator |
| 87464 | AIOS Http Error Mapper (Public — for provider apps) |

### Examples / tests (87480–87499)

| ID    | Object                              |
| -------| -------------------------------------|
| 87480 | AIOS Usage Example                  |
| 87481 | AIOS Toolkit Demo (page)            |
| 87482 | AIOS Demo History (table)           |
| 87483 | AIOS Demo History (listpart)        |
| 87484 | AIOS Lifecycle Example              |
| 87485 | AIOS Feedback Buffer                |
| 87486 | AIOS Demo History Card              |
| 87487 | AIOS Demo Tools                     |
| 87488 | AIOS Sample Tool Handler            |
| 87489 | AIOS Demo History Picture (factbox) |
| 87490 | AIOS Mock Tests                     |
| 87491 | AIOS Lifecycle Tests                |
| 87492 | AIOS Lifecycle Spy                  |
| 87493 | AIOS Generate Options Tests         |
| 87494 | AIOS Structured Output Tests        |
| 87495 | AIOS Image Tests                    |
| 87496 | AIOS Test Bind Target               |
| 87497 | AIOS Tool Tests                     |
| 87498 | AIOS Echo Tool                      |
| 87499 | AIOS Get Customers Tool             |

Before AppSource publication, replace this range with an assigned ID range and update this file.

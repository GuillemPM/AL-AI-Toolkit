# Object ID ranges

Current provisional range in `app.json`: **87400–87499**.

| Range (planned) | Use |
|---|---|
| 87400–87439 | Core: error enum, chat request/response, AIOS Provider + AIOS Language Model interfaces, AIOS Client |
| 87440–87459 | Provider adapters (OpenAI, Anthropic, OpenCode Zen, mock, …) |
| 87460–87479 | Structured output, retry, telemetry |
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
| 87410 | AIOS Client |
| 87411 | AIOS Generate Result |
| 87412 | AIOS Generate Image Result |
| 87413 | AIOS Request Options |
| 87414 | AIOS Image Usage |

### Provider adapters (87440–87459)

| ID | Object |
|---|---|
| 87440 | AIOS Anthropic |
| 87441 | AIOS Anthropic Model |
| 87442 | AIOS OpenAI |
| 87443 | AIOS OpenAI Model |
| 87444 | AIOS OpenCode Zen |
| 87445 | AIOS OpenCode Zen Model |
| 87446 | AIOS Mock |
| 87447 | AIOS Mock Model |
| 87448 | AIOS OpenAI Image Model |
| 87449 | AIOS Mock Image Model |

### Structured output (87460–87479)

| ID | Object |
|---|---|
| 87461 | AIOS Json Binder |
| 87462 | AIOS Schema |
| 87463 | AIOS Schema Validator |

### Examples / tests (87480–87499)

| ID | Object |
|---|---|
| 87480 | AIOS Usage Example |
| 87481 | AIOS Toolkit Demo (page) |
| 87482 | AIOS Demo History (table) |
| 87483 | AIOS Demo History (listpart) |
| 87484 | AIOS Lifecycle Example |
| 87485 | AIOS Feedback Buffer |
| 87486 | AIOS Demo History Card |
| 87489 | AIOS Demo History Picture (factbox) |
| 87490 | AIOS Mock Tests |
| 87491 | AIOS Lifecycle Tests |
| 87492 | AIOS Lifecycle Spy |
| 87493 | AIOS Generate Options Tests |
| 87494 | AIOS Structured Output Tests |
| 87495 | AIOS Image Tests |

Before AppSource publication, replace this range with an assigned ID range and update this file.

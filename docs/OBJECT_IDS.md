# Object ID ranges

Current provisional range in `app.json`: **70100–70199**.

| Range (planned) | Use |
|---|---|
| 70100–70139 | Core: error enum, chat request/response, AI Provider + AI Language Model interfaces, AI Client |
| 70140–70159 | Provider adapters (OpenAI, Anthropic, OpenCode Zen, mock, …) |
| 70160–70179 | Structured output, retry, telemetry |
| 70180–70199 | Examples / reserved |

### Core (70100–70139)

| ID | Object |
|---|---|
| 70100 | AI Error Type |
| 70101 | AI Chat Request |
| 70102 | AI Chat Response |
| 70110 | AI Client |

### Provider adapters (70140–70159)

| ID | Object |
|---|---|
| 70140 | AI Anthropic |
| 70141 | AI Anthropic Model |
| 70142 | AI OpenAI |
| 70143 | AI OpenAI Model |
| 70144 | AI OpenCode Zen |
| 70145 | AI OpenCode Zen Model |
| 70146 | AI Mock |
| 70147 | AI Mock Model |

### Examples / tests (70180–70199)

| ID | Object |
|---|---|
| 70180 | AI Usage Example |
| 70181 | AI Toolkit Demo (page) |
| 70190 | AI Mock Tests |

Before AppSource publication, replace this range with an assigned ID range and update this file.

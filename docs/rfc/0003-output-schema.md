# RFC 0003: Schema-first structured output on GenerateText

- Status: Accepted
- Author(s): AL AI Open SDK
- Created: 2026-08-05
- Related ADRs: [ADR-007](../adr/007-structured-output.md)

## Summary

Structured output is schema-driven on `GenerateText`: callers attach a JSON Schema via `Request.SetOutput`, then call `GenerateText(Model, Request)`. The response text is validated against the schema. `SetOutput(RecRef)` remains a flat-record convenience binder.

## Motivation

Callers need nested objects and arrays in structured output. AL has no schema DSL; `"AIOS Schema"` builds JSON Schema from `Field` / `Object` / `Array` / `Enum` / `Choice` helpers, and `"AIOS Schema Validator"` checks the model response.

## Detailed design

### Schema builder — `"AIOS Schema"` (public)

```al
AddressFields.Add(Schema.Field('city', Schema.String()));
Fields.Add(Schema.Field('name', Schema.String()));
Fields.Add(Schema.Field('address', Schema.Object(AddressFields)));
Fields.Add(Schema.Field('tags', Schema.Array(Schema.String())));
Request.SetOutput(Schema.Object(Fields));
Result := Client.GenerateText(Model, Request);
JsonText := Result.Output();
```

```al
Request.SetOutput(Schema.Text()); // optional; same as omitting SetOutput
Result := Client.GenerateText(Model, Request); // Result.Output() is plain text, no JSON validation

Request.SetOutput(Schema.Json());
Result := Client.GenerateText(Model, Request); // Result.Output() is any valid JSON text
```

Choice — root classification schema:

```al
Options.Add('sunny');
Options.Add('rainy');
Options.Add('snowy');
Request.SetOutput(Schema.Choice(Options));
Result := Client.GenerateText(Model, Request); // Result.Output() is plain string: rainy
```

Choice schema shape:

```json
{ "type": "object", "properties": { "result": { "type": "string", "enum": ["sunny","rainy","snowy"] } }, "required": ["result"], "additionalProperties": false }
```

The model must return `{ "result": "rainy" }`. `Result.Output()` is the selected option as plain text.

Nested fixed strings use `Enum`, not `Choice`:

```al
Fields.Add(Schema.Field('weather', Schema.Enum(Options)));
Request.SetOutput(Schema.Object(Fields));
```

- `String()` / `Number()` / `Integer()` / `Boolean()` — type schemas
- `Array(Items)` — array schema
- `Enum(Options: List of [Text])` — `{ "type": "string", "enum": [...] }` for nested properties
- `Choice(Options)` — object schema with required `result` enum; empty list, empty option, and duplicates Error
- `Json()` — unstructured JSON; GenerateText requires valid JSON only
- `Text()` — plain text; same as omitting SetOutput; disables JSON mode
- `IsChoiceSchema` / `IsJsonSchema` / `IsTextSchema` — detect output mode documents for client handling
- `Field(name, schema)` — required property fragment
- `OptionalField(name, schema)` — property omitted from `required`
- `Object(Fields: List of [JsonObject])` — object schema from any number of field fragments
- `ToText(Schema)` — serialize; `SetOutput` also accepts `JsonObject` directly

### Request

- `SetOutput(SchemaText)` / `SetOutput(Schema: JsonObject)` — sets output mode; clears RecRef mode
- `Text()`: JSON mode off, no system hint appended
- `Json()`: JSON mode on, JSON-only instruction
- Object/Array/Choice/Enum schemas: JSON mode on, schema embedded in system hint
- `SetOutput(RecRef)` — flat binder; clears schema mode
- `HasOutput` / `HasOutputSchema` / `GetOutputSchema` / `ClearOutput`
- Prefer `SetOutput(Schema.Json())` over any separate JSON-mode API

### Client

- `GenerateText(Model, Request): Codeunit "AIOS Generate Result"` — when `HasOutputSchema()`, applies the output mode; read text via `Result.Output()`
- `Text()`: no validation (default behavior)
- `Json()`: parse-only (valid JSON); shape is not checked
- Choice: after validation, `Result.Output()` is the `result` property as plain text
- RecRef bind path unchanged when `HasOutput()`
- Result also exposes `Body()`, `Headers()`, `HttpStatusCode()`, and usage helpers

### Validator — `"AIOS Schema Validator"` (internal)

Subset: `type` (object | array | string | number | integer | boolean), `properties`, `required`, `items`, `enum`, nested recursion. Builder-only `x-aios-optional` is stripped before the schema is stored. `additionalProperties` may be present on Choice schemas but is not enforced yet.

## Drawbacks

- Not full JSON Schema Draft compliance
- Callers parse `Result.Output()` into `JsonToken` when they need a tree
- Schema text is prompt-injected until native provider structured-output wiring (ADR-007 M9)

## Alternatives

- Separate generate entry point for objects — rejected (one client API: `GenerateText`)
- `Object` arity overloads — rejected (use `List of [JsonObject]`)
- `Properties()` + manual required list — rejected (unclear)
- Separate `SetOutputChoice` API — rejected (`Choice` is a schema; use `SetOutput`)
- Root bare-string Choice (no `{ result }` wrapper) — rejected (model output must be valid JSON matching the Choice schema)

## Adoption / migration

Additive for RecRef path. Prefer `SetOutput(Schema.Object(Fields))` + `GenerateText` for nested or array-rooted payloads. Use `SetOutput(Schema.Choice(Options))` for classification; treat `Result.Output()` as plain text. Use `Schema.Enum` inside `Field` for nested enums. Use `SetOutput(Schema.Json())` when any valid JSON is enough.

## Unresolved questions

None for v1.

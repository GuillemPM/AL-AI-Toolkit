# RFC 0003: Schema-first structured output on GenerateText

- Status: Accepted
- Author(s): AL AI Open SDK
- Created: 2026-08-05
- Related ADRs: [ADR-007](../adr/007-structured-output.md)

## Summary

Structured output is schema-driven on `GenerateText`: callers attach a JSON Schema via `Request.SetOutput`, then call `GenerateText(Model, Request)`. The response text is validated against the schema. `SetOutput(RecRef)` remains a flat-record convenience binder.

## Motivation

Callers need nested objects and arrays in structured output. AL has no schema DSL; `"AIOS Schema"` builds JSON Schema from `Field` / `Object` / `Array` helpers, and `"AIOS Schema Validator"` checks the model response.

## Detailed design

### Schema builder — `"AIOS Schema"` (public)

```al
AddressFields.Add(Schema.Field('city', Schema.String()));
Fields.Add(Schema.Field('name', Schema.String()));
Fields.Add(Schema.Field('address', Schema.Object(AddressFields)));
Fields.Add(Schema.Field('tags', Schema.Array(Schema.String())));
Request.SetOutput(Schema.Object(Fields));
Result := Client.GenerateText(Model, Request);
```

- `String()` / `Number()` / `Integer()` / `Boolean()` — type schemas
- `Array(Items)` — array schema
- `Field(name, schema)` — required property fragment
- `OptionalField(name, schema)` — property omitted from `required`
- `Object(Fields: List of [JsonObject])` — object schema from any number of field fragments
- `ToText(Schema)` — serialize; `SetOutput` also accepts `JsonObject` directly

### Request

- `SetOutput(SchemaText)` / `SetOutput(Schema: JsonObject)` — schema mode; clears RecRef mode
- `SetOutput(RecRef)` — flat binder; clears schema mode
- `HasOutput` / `HasOutputSchema` / `GetOutputSchema` / `ClearOutput`

### Client

- `GenerateText(Model, Request): Text` — when `HasOutputSchema()`, validates response JSON (`ParseFailed` on mismatch)
- RecRef bind path unchanged when `HasOutput()`

### Validator — `"AIOS Schema Validator"` (internal)

Subset: `type` (object | array | string | number | integer | boolean), `properties`, `required`, `items`, nested recursion. Builder-only `x-aios-optional` is stripped before the schema is stored.

## Drawbacks

- Not full JSON Schema Draft compliance
- Callers parse `Text` into `JsonToken` when they need a tree
- Schema text is prompt-injected until native provider structured-output wiring (ADR-007 M9)

## Alternatives

- Separate generate entry point for objects — rejected (one client API: `GenerateText`)
- `Object` arity overloads — rejected (use `List of [JsonObject]`)
- `Properties()` + manual required list — rejected (unclear)

## Adoption / migration

Additive for RecRef path. Prefer `SetOutput(Schema.Object(Fields))` + `GenerateText` for nested or array-rooted payloads.

## Unresolved questions

None for v1.

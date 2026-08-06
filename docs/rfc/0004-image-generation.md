# RFC 0004: GenerateImage

- Status: Accepted
- Created: 2026-08-06

## Summary

`Client.GenerateImage` generates images through `"AIOS Image Model"` bindings. The public result is `"AIOS Generate Image Result"`: lists of `"AIOS Generated Image"` and `"AIOS Image Response Call"`, plus `"AIOS Image Usage"`.

## Public API

```al
Result := Client.GenerateImage(OpenAI.ImageModel('dall-e-3', ApiKey), Request);
foreach Image in Result.GetImages() do
    Image.Base64();
Usage := Result.GetUsage();
Usage.ImagesGenerated();
```

Request: `"AIOS Image Request"` with prompt, `SetImageCount`, size, aspect ratio, seed, provider options, headers, retries, timeout.

## Batching

Total count `n` from `SetImageCount`. Client splits into HTTP batches using `SetMaxImagesPerCall` and `GetDefaultMaxImagesPerCall()` on the model. Usage and provider metadata merge across batches.

## Providers

- `"AIOS OpenAI"`.`ImageModel` → `POST /images/generations`, `b64_json` payloads
- `"AIOS Mock"`.`ImageModel` for tests

## Errors

Empty image list after successful HTTP → `"AIOS Error Type"::NoImageGenerated`. Public `GenerateImage` raises an error; `TryGenerateImage` returns false.

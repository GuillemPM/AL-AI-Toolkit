namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using PM.Guillem.AIOpenSDK.Provider.OpenAI;
using PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;

/// <summary>
/// Consumer-facing samples — copy these patterns into your app.
/// Public client API is GenerateText (Errors on failure).
/// </summary>
codeunit 87480 "AIOS Usage Example"
{
    Access = Public;

    /// <summary>
    /// Minimal usage: Anthropic model + prompt. Errors on failure.
    /// </summary>
    procedure RunBasicDemo(ApiKey: SecretText)
    var
        OpenAI: Codeunit "AIOS OpenAI";
        Client: Codeunit "AIOS Client";
    begin
        Message(SuccessMsg,
            Client.GenerateText(
                OpenAI.Model('gpt-5.5', ApiKey),
                'Say hello.'
            ).Output()
        );
    end;

    /// <summary>
    /// Mock demo — read output, raw body, and response headers from GenerateText result.
    /// </summary>
    procedure RunResponseMetadataDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Headers: JsonObject;
        HeadersText: Text;
    begin
        Mock.SetNextResponse('hello from mock');
        Request.SetPrompt('ping');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request);
        Headers := Result.Headers();
        Headers.WriteTo(HeadersText);
        Message(ResponseMetadataMsg, Result.Output(), Result.Body(), Result.HttpStatusCode(), HeadersText);
    end;

    /// <summary>
    /// Mock demo — structured output into a temporary record via Request.SetOutput.
    /// </summary>
    procedure RunFeedbackSummaryDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Feedback Buffer";
        RecRef: RecordRef;
        Result: Text;
    begin
        Mock.SetNextResponse('{"Sentiment":"positive","Score":0.9,"Urgent":false,"Summary":"Good product, pricey support.","Topics":["pricing","support"]}');

        RecRef.GetTable(Feedback);

        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetOutput(RecRef);

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, RecRef).Output();
        RecRef.SetTable(Feedback, true);
        Message(StructuredMsg, Feedback.Sentiment, Feedback.Score, Feedback.Urgent, Feedback.Summary, Feedback.Topics, Result);
    end;

    /// <summary>
    /// Mock demo — nested JSON Schema structured output via SetOutput and GenerateText.
    /// </summary>
    procedure RunSchemaObjectDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Fields: List of [JsonObject];
        AddressFields: List of [JsonObject];
        Result: Text;
    begin
        Mock.SetNextResponse('{"name":"Ada","address":{"city":"Barcelona"},"tags":["ai","al"]}');

        AddressFields.Add(Schema.Field('city', Schema.String()));
        Fields.Add(Schema.Field('name', Schema.String()));
        Fields.Add(Schema.Field('address', Schema.Object(AddressFields)));
        Fields.Add(Schema.Field('tags', Schema.Array(Schema.String())));

        Request.SetPrompt('Describe Ada Lovelace briefly as structured data.');
        Request.SetOutput(Schema.Object(Fields));

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        Message(SchemaObjectMsg, Result);
    end;

    /// <summary>
    /// Mock demo for Choice output: validates { "result": "…" } and returns the selected option as plain text.
    /// </summary>
    procedure RunSchemaChoiceDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Options: List of [Text];
        Result: Text;
    begin
        Mock.SetNextResponse('{"result":"rainy"}');

        Options.Add('sunny');
        Options.Add('rainy');
        Options.Add('snowy');

        Request.SetPrompt('Is the weather sunny, rainy, or snowy today?');
        Request.SetOutput(Schema.Choice(Options));

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        Message(SchemaChoiceMsg, Result);
    end;

    /// <summary>
    /// Mock demo with generation options on the request
    /// (temperature, topP, seed, stopSequences, reasoning, maxRetries).
    /// Providers map Reasoning to native effort/budget; Mock ignores it.
    /// </summary>
    procedure RunGenerateOptionsDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
    begin
        Mock.SetNextResponse('Done.');

        Request.SetSystemMessage('Reply in one short sentence.');
        Request.SetPrompt('Say hello, then the word END.');
        Request.SetTemperature(0);
        Request.SetTopP(0.9);
        Request.SetSeed(42);
        Request.AddStopSequence('END');
        Request.SetReasoning("AIOS Reasoning Effort"::Low);
        Request.SetMaxRetries(2);
        Request.SetMaxTokens(256);
        Request.SetTimeout(60000);

        Message(SuccessMsg, Client.GenerateText(Mock.Model('demo-model'), Request).Output());
    end;

    /// <summary>
    /// Anthropic — generateText with system + prompt + unstructured JSON output.
    /// </summary>
    procedure RunAnthropicDemo(ApiKey: SecretText)
    var
        Anthropic: Codeunit "AIOS Anthropic";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('You extract sentiment and topics from customer feedback.');
        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetOutput(Schema.Json());

        Message(SuccessMsg, Client.GenerateText(Anthropic.Model('claude-sonnet-4-5', ApiKey), Request).Output());
    end;

    /// <summary>
    /// Anthropic with sampling / thinking options.
    /// Reasoning Medium → thinking.budget_tokens ≈ 30% of Max Tokens (clamped ≥ 1024).
    /// </summary>
    procedure RunAnthropicOptionsDemo(ApiKey: SecretText)
    var
        Anthropic: Codeunit "AIOS Anthropic";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('You extract sentiment and topics from customer feedback.');
        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetOutput(Schema.Json());
        Request.SetTemperature(0.2);
        Request.SetTopP(0.95);
        Request.SetTopK(40);
        Request.SetReasoning("AIOS Reasoning Effort"::Medium);
        Request.SetMaxTokens(1024);
        Request.SetMaxRetries(2);

        Message(SuccessMsg, Client.GenerateText(Anthropic.Model('claude-sonnet-4-5', ApiKey), Request).Output());
    end;

    /// <summary>
    /// Anthropic extended thinking via generic reasoning + %-of-maxTokens budget.
    /// Medium @ 32000 max tokens → budget_tokens 9600.
    /// </summary>
    procedure RunAnthropicReasoningDemo(ApiKey: SecretText)
    var
        Anthropic: Codeunit "AIOS Anthropic";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('Think step by step, then answer briefly.');
        Request.SetPrompt('What is 17 * 24?');
        Request.SetReasoning("AIOS Reasoning Effort"::Medium);
        Request.SetMaxTokens(32000);
        Request.SetMaxRetries(1);

        Message(SuccessMsg, Client.GenerateText(Anthropic.Model('claude-sonnet-4-5', ApiKey), Request).Output());
    end;

    /// <summary>
    /// OpenAI — generateText with system + prompt + unstructured JSON output.
    /// </summary>
    procedure RunOpenAIDemo(ApiKey: SecretText)
    var
        OpenAI: Codeunit "AIOS OpenAI";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('You extract sentiment and topics from customer feedback.');
        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetOutput(Schema.Json());

        Message(SuccessMsg, Client.GenerateText(OpenAI.Model('gpt-4.1-mini', ApiKey), Request).Output());
    end;

    /// <summary>
    /// OpenAI with presence/frequency penalties, seed, stop sequences, and reasoning effort.
    /// Reasoning High → reasoning_effort = "high".
    /// </summary>
    procedure RunOpenAIOptionsDemo(ApiKey: SecretText)
    var
        OpenAI: Codeunit "AIOS OpenAI";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('You extract sentiment and topics from customer feedback.');
        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetOutput(Schema.Json());
        Request.SetTemperature(0.2);
        Request.SetTopP(0.9);
        Request.SetPresencePenalty(0);
        Request.SetFrequencyPenalty(0.2);
        Request.SetSeed(7);
        Request.AddStopSequence('\n\n');
        Request.SetReasoning("AIOS Reasoning Effort"::High);
        Request.SetMaxTokens(512);
        Request.SetMaxRetries(2);

        Message(SuccessMsg, Client.GenerateText(OpenAI.Model('gpt-4.1-mini', ApiKey), Request).Output());
    end;

    /// <summary>
    /// OpenAI reasoning_effort via SetReasoning (XHigh → "xhigh").
    /// Use a reasoning-capable model id for your account.
    /// </summary>
    procedure RunOpenAIReasoningDemo(ApiKey: SecretText)
    var
        OpenAI: Codeunit "AIOS OpenAI";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('Answer in one sentence.');
        Request.SetPrompt('Explain why BC uses temporary tables for request/response records.');
        Request.SetReasoning("AIOS Reasoning Effort"::XHigh);
        Request.SetMaxTokens(512);
        Request.SetMaxRetries(1);

        Message(SuccessMsg, Client.GenerateText(OpenAI.Model('o4-mini', ApiKey), Request).Output());
    end;

    /// <summary>
    /// OpenCode Zen — generateText with system + prompt + unstructured JSON output.
    /// Get a key at https://opencode.ai/auth.
    /// </summary>
    procedure RunOpenCodeZenDemo(ApiKey: SecretText)
    var
        Zen: Codeunit "AIOS OpenCode Zen";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('You extract sentiment and topics from customer feedback.');
        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetOutput(Schema.Json());

        Message(SuccessMsg, Client.GenerateText(Zen.Model('big-pickle', ApiKey), Request).Output());
    end;

    /// <summary>
    /// OpenCode Zen with OpenAI-compatible options including reasoning_effort.
    /// </summary>
    procedure RunOpenCodeZenOptionsDemo(ApiKey: SecretText)
    var
        Zen: Codeunit "AIOS OpenCode Zen";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetSystemMessage('Reply briefly.');
        Request.SetPrompt('Name three BC tables.');
        Request.SetTemperature(0.4);
        Request.SetTopP(0.9);
        Request.SetSeed(1);
        Request.SetReasoning("AIOS Reasoning Effort"::Low);
        Request.SetMaxTokens(300);
        Request.SetMaxRetries(1);

        Message(SuccessMsg, Client.GenerateText(Zen.Model('big-pickle', ApiKey), Request).Output());
    end;

    /// <summary>
    /// Anthropic structured output — same GenerateText call with Request.SetOutput.
    /// </summary>
    procedure RunAnthropicStructuredDemo(ApiKey: SecretText)
    var
        Anthropic: Codeunit "AIOS Anthropic";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Feedback Buffer";
        RecRef: RecordRef;
        Result: Text;
    begin
        RecRef.GetTable(Feedback);

        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetOutput(RecRef);

        Result := Client.GenerateText(Anthropic.Model('claude-sonnet-4-5', ApiKey), Request, RecRef).Output();
        RecRef.SetTable(Feedback, true);
        Message(StructuredMsg, Feedback.Sentiment, Feedback.Score, Feedback.Urgent, Feedback.Summary, Feedback.Topics, Result);
    end;

    /// <summary>
    /// Mock demo — GenerateImage returns a list of AIOS Generated Image codeunits plus usage.
    /// </summary>
    procedure RunMockImageDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Image Request";
        Result: Codeunit "AIOS Generate Image Result";
        Usage: Codeunit "AIOS Image Usage";
        ImageCU: Codeunit "AIOS Generated Image";
        Images: List of [Codeunit "AIOS Generated Image"];
    begin
        Mock.SetNextImageBase64('mock-image-base64', 'image/png');
        Request.SetPrompt('A blue triangle');
        Request.SetSize('1024x1024');

        Result := Client.GenerateImage(Mock.ImageModel('mock-image'), Request);
        Usage := Result.GetUsage();
        Images := Result.GetImages();
        Images.Get(1, ImageCU);
        Message(ImageDemoMsg, Usage.ImagesGenerated(), ImageCU.MediaType(), StrLen(ImageCU.Base64()), Result.HttpStatusCode());
    end;

    procedure RunOpenAIImageDemo()
    var
        Client: Codeunit "AIOS Client";
        OpenAI: Codeunit "AIOS OpenAI";
        Result: Codeunit "AIOS Generate Image Result";
        ResultImage: Codeunit "AIOS Generated Image";
    begin
        Result := Client.GenerateImage(OpenAI.ImageModel('gpt-image-2'), 'Generate an image of a pencil');
        ResultImage := Result.GetImage();
    end;

    var
        SuccessMsg: Label '%1', Comment = '%1 = model response text';
        StructuredMsg: Label 'Sentiment=%1 Score=%2 Urgent=%3 Summary=%4 Topics=%5 | Raw=%6', Comment = '%1 sentiment, %2 score, %3 urgent, %4 summary, %5 topics, %6 raw JSON';
        SchemaObjectMsg: Label '%1', Comment = '%1 = validated JSON object text';
        SchemaChoiceMsg: Label '%1', Comment = '%1 = validated choice string';
        ResponseMetadataMsg: Label 'Text=%1 | Body=%2 | Status=%3 | Headers=%4', Comment = '%1 text, %2 raw body, %3 status, %4 headers JSON';
        ImageDemoMsg: Label 'Generated=%1 type=%2 base64Len=%3 http=%4', Comment = '%1 count, %2 media type, %3 base64 length, %4 status';
}

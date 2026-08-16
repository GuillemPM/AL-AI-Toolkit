namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using PM.Guillem.AIOpenSDK.Provider.OpenAI;
using PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;
using Microsoft.Inventory.Item;
using System.Environment;
using System.Text;

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
    /// Mock demo — attach a text file (FilePart) and generate.
    /// </summary>
    procedure RunFilePartDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Base64Convert: Codeunit "Base64 Convert";
        Result: Codeunit "AIOS Generate Result";
    begin
        Mock.SetNextResponse('Summary: short note about shipping.');
        Request.SetPrompt('Summarize the attached file.');
        Request.Attach(Base64Convert.ToBase64('Ship by Friday. PO-1042.'), 'text/plain', 'note.txt');
        Result := Client.GenerateText(Mock.Model('demo-model'), Request);
        Message(FilePartMsg, Result.Output());
    end;

    /// <summary>
    /// Item.Picture → Attach(MediaId) → GenerateText description.
    /// Uses Mock so it runs without a vision API key; for production use RunItemPictureDescriptionOpenAI.
    /// </summary>
    procedure RunItemPictureDescriptionDemo()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Item: Record Item;
        ItemNo: Code[20];
        Description: Text;
        UsedSampleImage: Boolean;
    begin
        UsedSampleImage := false;
        if not TryAddFirstItemPicture(Request, Item, ItemNo) then begin
            Request.Attach(MinimalPngBase64Tok, 'image/png', 'sample-item.png');
            UsedSampleImage := true;
            ItemNo := '';
        end;

        Mock.SetNextResponse(
            'Durable canvas tote with reinforced handles and a front pocket. Ideal for everyday carry.');

        Request.SetPrompt(
            'Write a concise webshop product description (2–3 sentences) for this item image. ' +
            'Focus on visible materials, color, and use. Do not invent a brand name.');
        Request.SetSystemMessage('You write product copy for Business Central item cards.');

        Result := Client.GenerateText(Mock.Model('demo-vision'), Request);
        Description := Result.Output();

        // Production: Item.Validate(Description, CopyStr(Description, 1, MaxStrLen(Item.Description))); Item.Modify(true);
        if UsedSampleImage then
            Message(ItemPictureSampleMsg, Description)
        else
            Message(ItemPictureMsg, ItemNo, Item.Description, Description);
    end;

    /// <summary>
    /// Live vision model: Request.Attach(Item.Picture.Item(1)) then GenerateText.
    /// </summary>
    procedure RunItemPictureDescriptionOpenAI(ApiKey: SecretText)
    var
        OpenAI: Codeunit "AIOS OpenAI";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Item: Record Item;
        ItemNo: Code[20];
        Description: Text;
    begin
        if not TryAddFirstItemPicture(Request, Item, ItemNo) then
            Error(ItemPictureMissingErr);

        Request.SetPrompt(
            'Write a concise webshop product description (2–3 sentences) for this item image. ' +
            'Focus on visible materials, color, and use. Do not invent a brand name.');
        Request.SetSystemMessage('You write product copy for Business Central item cards.');

        Result := Client.GenerateText(OpenAI.Model('gpt-4.1', ApiKey), Request);
        Description := Result.Output();
        Message(ItemPictureMsg, ItemNo, Item.Description, Description);
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

    /// <summary>
    /// Runs a GenerateImage demo against OpenAI gpt-image-2 and loads the first returned image.
    /// </summary>
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

    /// <summary>
    /// Primary: ToolSet.Add(Tool) — one codeunit implements "AIOS Tool".
    /// </summary>
    procedure RunTools_AddInterfaceTool()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
    begin
        ToolSet.Add(Echo);

        Mock.SetNextToolCallThenResponse('call_1', 'echo', '{"message":"from-interface"}', 'done');
        Request.SetPrompt('Use echo');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet);
        Message(ToolsPrimaryMsg, Result.Output());
    end;

    /// <summary>
    /// Secondary (save IDs): ToolSet.Use(Handler) — many tools in one "AIOS Tool Handler" codeunit.
    /// Always pass ToolSet to GenerateText.
    /// </summary>
    procedure RunTools_UseHandler()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Handler: Codeunit "AIOS Sample Tool Handler";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
    begin
        ToolSet.Use(Handler);

        Mock.SetNextToolCallThenResponse('call_1', 'add_numbers', '{"a":2,"b":3}', '2 + 3 = 5');
        Request.SetPrompt('What is 2 plus 3?');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet);
        Message(ToolsHandlerMsg, ToolSet.Count(), Result.Output());
    end;

    /// <summary>
    /// Mix primary Add(Tool) with secondary Use(Handler) on one ToolSet (names must not overlap).
    /// </summary>
    procedure RunTools_MixAddAndUse()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        GetCustomers: Codeunit "AIOS Get Customers Tool";
        Handler: Codeunit "AIOS Sample Tool Handler";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
    begin
        ToolSet.Add(GetCustomers);
        ToolSet.Use(Handler);

        Mock.SetNextToolCallThenResponse('call_1', 'add_numbers', '{"a":4,"b":5}', '9');
        Request.SetPrompt('What is 4 plus 5?');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet);
        Message(ToolsMixMsg, ToolSet.Count(), Result.Output());
    end;

    /// <summary>
    /// Manual tool loop — GenerateText without ToolSet MaxSteps overload, then ToolSet.Execute yourself.
    /// Prefer GenerateText(..., ToolSet) for the automatic loop.
    /// </summary>
    procedure RunTools_ManualContinue()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        ToolCalls: List of [Codeunit "AIOS Tool Call"];
        Call: Codeunit "AIOS Tool Call";
        ResultText: Text;
        i: Integer;
    begin
        ToolSet.Add(Echo);
        Request.SetPrompt('Use the echo tool');
        Request.SetTools(ToolSet);
        Request.EnsureMessagesFromPrompt();

        Mock.SetNextToolCall('call_1', 'echo', '{"message":"manual"}');
        Result := Client.GenerateText(Mock.Model('demo-model'), Request);
        if not Result.HasToolCalls() then
            Error(ToolsManualExpectedCallsErr);

        ToolCalls := Result.GetToolCalls();
        Request.AppendAssistantToolCalls(Result.Output(), ToolCalls);
        for i := 1 to ToolCalls.Count() do begin
            ToolCalls.Get(i, Call);
            ToolSet.Execute(Call.GetName(), Call.GetArguments(), ResultText);
            Request.AppendToolResult(Call.GetId(), Call.GetName(), ResultText);
        end;

        Mock.SetNextResponse('manual done');
        Result := Client.GenerateText(Mock.Model('demo-model'), Request);
        Message(ToolsManualMsg, ResultText, Result.Output());
    end;

    /// <summary>
    /// Finds the first Item with a Picture and attaches it via Attach(MediaId).
    /// </summary>
    local procedure TryAddFirstItemPicture(var Request: Record "AIOS Chat Request"; var Item: Record Item; var ItemNo: Code[20]): Boolean
    begin
        Item.Reset();
        Item.SetLoadFields("No.", Description, Picture);
        if not Item.FindSet() then
            exit(false);
        repeat
            if Item.Picture.Count = 0 then
                continue;
            Request.Attach(Item.Picture.Item(1), StrSubstNo(ItemPictureFileNameTok, Item."No."));
            ItemNo := Item."No.";
            exit(true);
        until Item.Next() = 0;
        exit(false);
    end;

    var
        SuccessMsg: Label '%1', Comment = '%1 = model response text';
        StructuredMsg: Label 'Sentiment=%1 Score=%2 Urgent=%3 Summary=%4 Topics=%5 | Raw=%6', Comment = '%1 sentiment, %2 score, %3 urgent, %4 summary, %5 topics, %6 raw JSON';
        SchemaObjectMsg: Label '%1', Comment = '%1 = validated JSON object text';
        SchemaChoiceMsg: Label '%1', Comment = '%1 = validated choice string';
        ResponseMetadataMsg: Label 'Text=%1 | Body=%2 | Status=%3 | Headers=%4', Comment = '%1 text, %2 raw body, %3 status, %4 headers JSON';
        ImageDemoMsg: Label 'Generated=%1 type=%2 base64Len=%3 http=%4', Comment = '%1 count, %2 media type, %3 base64 length, %4 status';
        FilePartMsg: Label 'FilePart | Final=%1', Comment = '%1 = output';
        ItemPictureMsg: Label 'Item %1 (%2)| Description=%3', Comment = '%1 = item no, %2 = item description, %3 = generated text';
        ItemPictureSampleMsg: Label 'No item picture found — used sample PNG.| Description=%1', Comment = '%1 = generated text';
        ItemPictureMissingErr: Label 'No item with a Picture was found. Add a picture on an Item card and try again.';
        ItemPictureFileNameTok: Label 'item-%1.jpg', Locked = true;
        MinimalPngBase64Tok: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', Locked = true;
        ToolsPrimaryMsg: Label 'Primary Add(AIOS Tool) | Final=%1', Comment = '%1 = output';
        ToolsHandlerMsg: Label 'Secondary Use(Handler) | Count=%1 Final=%2', Comment = '%1 = count, %2 = output';
        ToolsMixMsg: Label 'Mix Add(Tool)+Use(Handler) | Count=%1 Final=%2', Comment = '%1 = count, %2 = output';
        ToolsManualMsg: Label 'Manual continue | Tool=%1 Final=%2', Comment = '%1 = tool result, %2 = output';
        ToolsManualExpectedCallsErr: Label 'Expected tool calls on the first GenerateText.';
}

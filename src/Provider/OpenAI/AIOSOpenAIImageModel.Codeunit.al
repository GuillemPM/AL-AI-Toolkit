namespace PM.Guillem.AIOpenSDK.Provider.OpenAI;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87448 "AIOS OpenAI Image Model" implements "AIOS Image Model"
{
    Access = Internal;

    var
        BoundModelId: Text;
        ApiKey: SecretText;
        BaseUrl: Text;

    procedure Initialize(ModelId: Text; KeyValue: SecretText; Url: Text)
    begin
        BoundModelId := ModelId;
        ApiKey := KeyValue;
        BaseUrl := Url;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure GetDefaultMaxImagesPerCall(): Integer
    begin
        if BoundModelId = 'dall-e-2' then
            exit(10);
        exit(1);
    end;

    procedure GenerateImage(var Request: Record "AIOS Image Request"; var Response: Record "AIOS Image Response"): Boolean
    var
        HttpErrors: Codeunit "AIOS Http Error Mapper";
        Client: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        Body: Text;
        ResponseText: Text;
    begin
        Clear(Response);
        Response."Provider Name" := 'openai';
        Response."Model Id" := CopyStr(BoundModelId, 1, MaxStrLen(Response."Model Id"));
        Response."Call Timestamp" := CurrentDateTime();

        Body := BuildRequestBody(Request);
        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(BaseUrl + '/images/generations');
        HttpRequest.Content := Content;
        HttpRequest.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', ApiKey));
        Headers.Add('Accept', 'application/json');
        ApplyCustomHeaders(HttpRequest, Request);

        Client.Timeout := Request.GetHttpTimeout();
        if not Client.Send(HttpRequest, HttpResponse) then begin
            Response.SetError("AIOS Error Type"::Timeout, SendFailedErr);
            exit(false);
        end;

        HttpResponse.Content.ReadAs(ResponseText);
        Response.CaptureHttpResponse(HttpResponse, ResponseText);

        if not HttpResponse.IsSuccessStatusCode() then begin
            HttpErrors.Apply(HttpResponse.HttpStatusCode(), ResponseText, Response);
            exit(false);
        end;

        exit(ParseSuccess(ResponseText, Response));
    end;

    local procedure BuildRequestBody(var Request: Record "AIOS Image Request"): Text
    var
        Root: JsonObject;
        OpenAIOptions: JsonObject;
        ProviderOptions: JsonObject;
        OptionToken: JsonToken;
        Body: Text;
        KeyName: Text;
    begin
        Root.Add('model', BoundModelId);
        Root.Add('prompt', Request.GetPrompt());
        Root.Add('n', Request.GetImageCount());
        if Request.GetSize() <> '' then
            Root.Add('size', Request.GetSize());
        if Request.HasSeed() then
            Root.Add('seed', Request.GetSeed());
        // DALL·E defaults to URL; gpt-image-* already returns b64_json and rejects this field.
        if BoundModelId.StartsWith('dall-e') then
            Root.Add('response_format', 'b64_json');

        ProviderOptions := Request.GetProviderOptions();
        if ProviderOptions.Get('openai', OptionToken) and OptionToken.IsObject() then
            OpenAIOptions := OptionToken.AsObject();
        foreach KeyName in OpenAIOptions.Keys() do begin
            if not OpenAIOptions.Get(KeyName, OptionToken) then
                continue;
            if Root.Contains(KeyName) then
                Root.Remove(KeyName);
            Root.Add(KeyName, OptionToken);
        end;

        Root.WriteTo(Body);
        exit(Body);
    end;

    local procedure ApplyCustomHeaders(var HttpRequest: HttpRequestMessage; var Request: Record "AIOS Image Request")
    var
        CustomHeaders: JsonObject;
        HeaderNames: List of [Text];
        HeaderName: Text;
        Token: JsonToken;
        ReqHeaders: HttpHeaders;
    begin
        CustomHeaders := Request.GetRequestHeaders();
        if CustomHeaders.Keys().Count() = 0 then
            exit;
        HttpRequest.GetHeaders(ReqHeaders);
        HeaderNames := CustomHeaders.Keys();
        foreach HeaderName in HeaderNames do begin
            if not CustomHeaders.Get(HeaderName, Token) then
                continue;
            if Token.IsValue() then
                ReqHeaders.Add(HeaderName, Token.AsValue().AsText());
        end;
    end;

    local procedure ParseSuccess(ResponseText: Text; var Response: Record "AIOS Image Response"): Boolean
    var
        Root: JsonObject;
        DataToken: JsonToken;
        Data: JsonArray;
        ItemToken: JsonToken;
        Item: JsonObject;
        B64Token: JsonToken;
        RevisedToken: JsonToken;
        UsageToken: JsonToken;
        Usage: JsonObject;
        Token: JsonToken;
        Base64: Text;
        Revised: Text;
        Metadata: JsonObject;
        ImagesMeta: JsonArray;
        MetaEntry: JsonObject;
        InputTokens: Integer;
        OutputTokens: Integer;
        TotalTokens: Integer;
        i: Integer;
    begin
        if not Root.ReadFrom(ResponseText) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, InvalidJsonErr);
            exit(false);
        end;

        if not Root.Get('data', DataToken) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingDataErr);
            exit(false);
        end;
        Data := DataToken.AsArray();
        Clear(ImagesMeta);
        for i := 0 to Data.Count() - 1 do begin
            Data.Get(i, ItemToken);
            Item := ItemToken.AsObject();
            Base64 := '';
            Revised := '';
            if Item.Get('b64_json', B64Token) then
                Base64 := B64Token.AsValue().AsText();
            if Item.Get('revised_prompt', RevisedToken) then
                Revised := RevisedToken.AsValue().AsText();
            if Base64 = '' then
                continue;
            Response.AppendGeneratedImage(Base64, 'image/png', Revised);
            Clear(MetaEntry);
            if Revised <> '' then
                MetaEntry.Add('revisedPrompt', Revised);
            ImagesMeta.Add(MetaEntry);
        end;

        if Response.GetGeneratedImageCount() = 0 then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingImageDataErr);
            exit(false);
        end;

        InputTokens := 0;
        OutputTokens := 0;
        TotalTokens := 0;
        if Root.Get('usage', UsageToken) and UsageToken.IsObject() then begin
            Usage := UsageToken.AsObject();
            if Usage.Get('input_tokens', Token) then
                InputTokens := Token.AsValue().AsInteger();
            if Usage.Get('output_tokens', Token) then
                OutputTokens := Token.AsValue().AsInteger();
            if Usage.Get('total_tokens', Token) then
                TotalTokens := Token.AsValue().AsInteger();
            if (InputTokens = 0) and Usage.Get('prompt_tokens', Token) then
                InputTokens := Token.AsValue().AsInteger();
            if (OutputTokens = 0) and Usage.Get('completion_tokens', Token) then
                OutputTokens := Token.AsValue().AsInteger();
            if TotalTokens = 0 then
                TotalTokens := InputTokens + OutputTokens;
            Response.SetUsageFromTokens(InputTokens, OutputTokens, TotalTokens);
        end;

        Clear(Metadata);
        Metadata.Add('images', ImagesMeta);
        Clear(Root);
        Root.Add('openai', Metadata);
        Response.SetProviderMetadata(Root);
        Response.ClearError();
        exit(true);
    end;

    var
        SendFailedErr: Label 'Failed to send request to OpenAI.';
        InvalidJsonErr: Label 'OpenAI returned invalid JSON.';
        MissingDataErr: Label 'OpenAI response missing data array.';
        MissingImageDataErr: Label 'OpenAI response contained no image payloads.';
}

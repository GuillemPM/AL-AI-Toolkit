namespace PM.Guillem.AIOpenSDK.Provider.Anthropic;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87441 "AIOS Anthropic Model" implements "AIOS Language Model"
{
    Access = Internal;

    var
        BoundModelId: Text;
        ApiKey: SecretText;
        ApiVersion: Text;

    procedure Initialize(ModelId: Text; KeyValue: SecretText; Version: Text)
    begin
        BoundModelId := ModelId;
        ApiKey := KeyValue;
        ApiVersion := Version;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        HttpErrors: Codeunit "AIOS Http Error Mapper";
        Client: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        Body: Text;
        ResponseText: Text;
        StatusCode: Integer;
        Warnings: JsonArray;
    begin
        Clear(Response);
        Response."Provider Name" := 'anthropic';

        Body := BuildRequestBody(Request, Warnings);
        Response.AppendWarnings(Warnings);
        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri('https://api.anthropic.com/v1/messages');
        HttpRequest.Content := Content;
        HttpRequest.GetHeaders(Headers);
        Headers.Add('x-api-key', ApiKey);
        Headers.Add('anthropic-version', ApiVersion);
        Headers.Add('Accept', 'application/json');

        Client.Timeout := Request.GetHttpTimeout();
        if not Client.Send(HttpRequest, HttpResponse) then begin
            Response.SetError("AIOS Error Type"::Timeout, SendFailedErr);
            exit(false);
        end;

        StatusCode := HttpResponse.HttpStatusCode();
        HttpResponse.Content.ReadAs(ResponseText);
        Response.CaptureHttpResponse(HttpResponse, ResponseText);

        if not HttpResponse.IsSuccessStatusCode() then begin
            HttpErrors.Apply(StatusCode, ResponseText, Response);
            exit(false);
        end;

        exit(ParseSuccess(ResponseText, Response));
    end;

    local procedure BuildRequestBody(var Request: Record "AIOS Chat Request"; var Warnings: JsonArray): Text
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
        FormatCU: Codeunit "AIOS Anthropic Format";
        ChatFormat: Interface "AIOS Chat Format";
        Root: JsonObject;
        Messages: JsonArray;
        UserMessage: JsonObject;
        ToolDefs: JsonArray;
        SystemText: Text;
        Body: Text;
        MaxTokens: Integer;
    begin
        ChatFormat := FormatCU;
        MaxTokens := Request."Max Tokens";
        if MaxTokens <= 0 then
            MaxTokens := 4096;

        if Request.HasMessages() then begin
            Messages := ChatFormat.MapMessages(Request.GetProviderMessages());
            SystemText := ChatFormat.GetSystemText(Request.GetMessages());
            if SystemText = '' then
                SystemText := Request.GetEffectiveSystemMessage();
        end else begin
            SystemText := Request.GetEffectiveSystemMessage();
            UserMessage.Add('role', 'user');
            UserMessage.Add('content', Request.GetPrompt());
            Messages.Add(UserMessage);
        end;

        Root.Add('model', BoundModelId);
        Root.Add('max_tokens', MaxTokens);
        if SystemText <> '' then
            Root.Add('system', SystemText);
        Root.Add('messages', Messages);
        if Request."Has Temperature" then
            Root.Add('temperature', Request.Temperature);
        ToolDefs := Request.GetToolDefinitions();
        if ToolDefs.Count() > 0 then
            Root.Add('tools', ChatFormat.MapTools(ToolDefs));
        FormatOptions.Apply(Root, Request, Warnings);

        Root.WriteTo(Body);
        exit(Body);
    end;

    local procedure ParseSuccess(ResponseText: Text; var Response: Record "AIOS Chat Response"): Boolean
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        ChatFormat: Interface "AIOS Chat Format";
        Root: JsonObject;
        ContentToken: JsonToken;
        ContentArray: JsonArray;
        BlockToken: JsonToken;
        Block: JsonObject;
        TextToken: JsonToken;
        UsageToken: JsonToken;
        Usage: JsonObject;
        ToolCalls: JsonArray;
        BlockType: Text;
        ContentText: Text;
        i: Integer;
    begin
        ChatFormat := FormatCU;
        if not Root.ReadFrom(ResponseText) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, InvalidJsonErr);
            exit(false);
        end;

        if not Root.Get('content', ContentToken) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingContentErr);
            exit(false);
        end;

        ContentArray := ContentToken.AsArray();
        for i := 0 to ContentArray.Count() - 1 do begin
            ContentArray.Get(i, BlockToken);
            Block := BlockToken.AsObject();
            if Block.Get('type', TextToken) then
                BlockType := TextToken.AsValue().AsText()
            else
                BlockType := '';
            if BlockType = 'text' then
                if Block.Get('text', TextToken) then
                    ContentText += TextToken.AsValue().AsText();
        end;

        ToolCalls := ChatFormat.ParseToolCalls(ContentToken);
        if ToolCalls.Count() > 0 then
            Response.SetToolCallsJson(ToolCalls);

        if Root.Get('stop_reason', TextToken) then
            Response."Finish Reason" := CopyStr(TextToken.AsValue().AsText(), 1, MaxStrLen(Response."Finish Reason"));

        if Root.Get('usage', UsageToken) then begin
            Usage := UsageToken.AsObject();
            if Usage.Get('input_tokens', TextToken) then
                Response."Input Tokens" := TextToken.AsValue().AsInteger();
            if Usage.Get('output_tokens', TextToken) then
                Response."Output Tokens" := TextToken.AsValue().AsInteger();
        end;

        if (ContentText = '') and (not Response.HasToolCalls()) then begin
            if Response."Finish Reason" = 'max_tokens' then
                Response.SetError("AIOS Error Type"::InvalidRequest, EmptyDueToMaxTokensErr)
            else
                Response.SetError("AIOS Error Type"::ParseFailed, StrSubstNo(EmptyContentErr, Response."Finish Reason"));
            exit(false);
        end;

        Response.SetText(ContentText);
        Response.ClearError();
        exit(true);
    end;

    var
        SendFailedErr: Label 'Failed to send request to Anthropic.';
        InvalidJsonErr: Label 'Anthropic returned invalid JSON.';
        MissingContentErr: Label 'Anthropic response missing content.';
        EmptyDueToMaxTokensErr: Label 'Empty model content (stop_reason=max_tokens).';
        EmptyContentErr: Label 'Empty model content (stop_reason=%1).', Comment = '%1 = stop reason';
}

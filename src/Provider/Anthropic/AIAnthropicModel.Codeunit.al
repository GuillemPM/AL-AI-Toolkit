codeunit 70141 "AI Anthropic Model" implements "AI Language Model"
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

    procedure Generate(var Request: Record "AI Chat Request"; var Response: Record "AI Chat Response"): Boolean
    var
        Client: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
        Body: Text;
        ResponseText: Text;
        StatusCode: Integer;
    begin
        Clear(Response);
        Response."Provider Name" := 'anthropic';

        Body := BuildRequestBody(Request);
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

        Client.Timeout := 120000;
        if not Client.Send(HttpRequest, HttpResponse) then begin
            Response.SetError("AI Error Type"::Timeout, SendFailedErr);
            exit(false);
        end;

        StatusCode := HttpResponse.HttpStatusCode();
        Response."HTTP Status Code" := StatusCode;
        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode() then begin
            MapHttpError(StatusCode, ResponseText, Response);
            exit(false);
        end;

        exit(ParseSuccess(ResponseText, Response));
    end;

    local procedure BuildRequestBody(var Request: Record "AI Chat Request"): Text
    var
        Root: JsonObject;
        Messages: JsonArray;
        UserMessage: JsonObject;
        SystemText: Text;
        Body: Text;
        MaxTokens: Integer;
    begin
        MaxTokens := Request."Max Tokens";
        if MaxTokens <= 0 then
            MaxTokens := 1024;

        SystemText := Request."System Message";
        if Request."Json Mode" then
            if SystemText = '' then
                SystemText := JsonModeInstructionTxt
            else
                SystemText += ' ' + JsonModeInstructionTxt;

        UserMessage.Add('role', 'user');
        UserMessage.Add('content', Request.GetPrompt());
        Messages.Add(UserMessage);

        Root.Add('model', BoundModelId);
        Root.Add('max_tokens', MaxTokens);
        if SystemText <> '' then
            Root.Add('system', SystemText);
        Root.Add('messages', Messages);
        if Request.Temperature <> 0 then
            Root.Add('temperature', Request.Temperature);

        Root.WriteTo(Body);
        exit(Body);
    end;

    local procedure ParseSuccess(ResponseText: Text; var Response: Record "AI Chat Response"): Boolean
    var
        Root: JsonObject;
        ContentToken: JsonToken;
        ContentArray: JsonArray;
        BlockToken: JsonToken;
        Block: JsonObject;
        TextToken: JsonToken;
        UsageToken: JsonToken;
        Usage: JsonObject;
        BlockType: Text;
        ContentText: Text;
        i: Integer;
    begin
        if not Root.ReadFrom(ResponseText) then begin
            Response.SetError("AI Error Type"::ParseFailed, InvalidJsonErr);
            exit(false);
        end;

        if not Root.Get('content', ContentToken) then begin
            Response.SetError("AI Error Type"::ParseFailed, MissingContentErr);
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

        Response.SetText(ContentText);
        Response.ClearError();

        if Root.Get('usage', UsageToken) then begin
            Usage := UsageToken.AsObject();
            if Usage.Get('input_tokens', TextToken) then
                Response."Input Tokens" := TextToken.AsValue().AsInteger();
            if Usage.Get('output_tokens', TextToken) then
                Response."Output Tokens" := TextToken.AsValue().AsInteger();
        end;

        exit(true);
    end;

    local procedure MapHttpError(StatusCode: Integer; ResponseText: Text; var Response: Record "AI Chat Response")
    begin
        case StatusCode of
            401, 403:
                Response.SetError("AI Error Type"::AuthenticationFailed, CopyStr(ResponseText, 1, 250));
            429:
                Response.SetError("AI Error Type"::RateLimited, CopyStr(ResponseText, 1, 250));
            400, 404, 422:
                Response.SetError("AI Error Type"::InvalidRequest, CopyStr(ResponseText, 1, 250));
            408, 504:
                Response.SetError("AI Error Type"::Timeout, CopyStr(ResponseText, 1, 250));
            500, 502, 503:
                Response.SetError("AI Error Type"::ProviderUnavailable, CopyStr(ResponseText, 1, 250));
            else
                Response.SetError("AI Error Type"::Unknown, CopyStr(ResponseText, 1, 250));
        end;
    end;

    var
        SendFailedErr: Label 'Failed to send request to Anthropic.';
        InvalidJsonErr: Label 'Anthropic returned invalid JSON.';
        MissingContentErr: Label 'Anthropic response missing content.';
        JsonModeInstructionTxt: Label 'Respond with valid JSON only, no markdown fences.';
}

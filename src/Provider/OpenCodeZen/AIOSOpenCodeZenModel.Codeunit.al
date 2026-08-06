namespace PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87445 "AIOS OpenCode Zen Model" implements "AIOS Language Model"
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

    /// <summary>
    /// Calls OpenCode Zen via the OpenAI-compatible chat completions endpoint.
    /// Works for models listed under /v1/chat/completions (e.g. big-pickle, minimax-m2.5).
    /// Claude-family models use /v1/messages and GPT-family use /v1/responses — not covered here.
    /// </summary>
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
        Response."Provider Name" := 'opencode-zen';

        Body := BuildRequestBody(Request, Warnings);
        Response.AppendWarnings(Warnings);
        Content.WriteFrom(Body);
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'application/json');

        HttpRequest.Method := 'POST';
        HttpRequest.SetRequestUri(BaseUrl + '/chat/completions');
        HttpRequest.Content := Content;
        HttpRequest.GetHeaders(Headers);
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', ApiKey));
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
        RequestOptions: Codeunit "AIOS Request Options";
        Root: JsonObject;
        Messages: JsonArray;
        SystemMessage: JsonObject;
        UserMessage: JsonObject;
        ResponseFormat: JsonObject;
        SystemText: Text;
        Body: Text;
    begin
        SystemText := Request.GetEffectiveSystemMessage();

        if SystemText <> '' then begin
            SystemMessage.Add('role', 'system');
            SystemMessage.Add('content', SystemText);
            Messages.Add(SystemMessage);
        end;

        UserMessage.Add('role', 'user');
        UserMessage.Add('content', Request.GetPrompt());
        Messages.Add(UserMessage);

        Root.Add('model', BoundModelId);
        Root.Add('messages', Messages);
        if Request."Max Tokens" > 0 then
            Root.Add('max_tokens', Request."Max Tokens");
        if Request."Has Temperature" then
            Root.Add('temperature', Request.Temperature);
        if Request."Json Mode" then begin
            ResponseFormat.Add('type', 'json_object');
            Root.Add('response_format', ResponseFormat);
        end;
        RequestOptions.ApplyOpenAICompatible(Root, Request, Warnings);

        Root.WriteTo(Body);
        exit(Body);
    end;

    local procedure ParseSuccess(ResponseText: Text; var Response: Record "AIOS Chat Response"): Boolean
    var
        Root: JsonObject;
        ChoicesToken: JsonToken;
        Choices: JsonArray;
        ChoiceToken: JsonToken;
        Choice: JsonObject;
        MessageToken: JsonToken;
        MessageObj: JsonObject;
        ContentToken: JsonToken;
        UsageToken: JsonToken;
        Usage: JsonObject;
        FinishReasonToken: JsonToken;
        ContentText: Text;
        FinishReason: Text;
    begin
        if not Root.ReadFrom(ResponseText) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, InvalidJsonErr);
            exit(false);
        end;

        if not Root.Get('choices', ChoicesToken) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingChoicesErr);
            exit(false);
        end;

        Choices := ChoicesToken.AsArray();
        if Choices.Count() = 0 then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingChoicesErr);
            exit(false);
        end;

        Choices.Get(0, ChoiceToken);
        Choice := ChoiceToken.AsObject();
        if Choice.Get('finish_reason', FinishReasonToken) then
            FinishReason := FinishReasonToken.AsValue().AsText();
        Response."Finish Reason" := CopyStr(FinishReason, 1, MaxStrLen(Response."Finish Reason"));

        if not Choice.Get('message', MessageToken) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingContentErr);
            exit(false);
        end;

        MessageObj := MessageToken.AsObject();
        if not MessageObj.Get('content', ContentToken) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingContentErr);
            exit(false);
        end;

        if not ContentToken.AsValue().IsNull() then
            ContentText := ContentToken.AsValue().AsText();

        if Root.Get('usage', UsageToken) then begin
            Usage := UsageToken.AsObject();
            if Usage.Get('prompt_tokens', ContentToken) then
                Response."Input Tokens" := ContentToken.AsValue().AsInteger();
            if Usage.Get('completion_tokens', ContentToken) then
                Response."Output Tokens" := ContentToken.AsValue().AsInteger();
        end;

        if ContentText = '' then begin
            if FinishReason = 'length' then
                Response.SetError("AIOS Error Type"::InvalidRequest, EmptyDueToMaxTokensErr)
            else
                Response.SetError("AIOS Error Type"::ParseFailed, StrSubstNo(EmptyContentErr, FinishReason));
            exit(false);
        end;

        Response.SetText(ContentText);
        Response.ClearError();
        exit(true);
    end;

    var
        SendFailedErr: Label 'Failed to send request to OpenCode Zen.';
        InvalidJsonErr: Label 'OpenCode Zen returned invalid JSON.';
        MissingChoicesErr: Label 'OpenCode Zen response missing choices.';
        MissingContentErr: Label 'OpenCode Zen response missing message content.';
        EmptyDueToMaxTokensErr: Label 'Empty model content (finish_reason=length).';
        EmptyContentErr: Label 'Empty model content (finish_reason=%1).', Comment = '%1 = finish reason';
}

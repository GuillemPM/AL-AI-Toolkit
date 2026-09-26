namespace PM.Guillem.AIOpenSDK.ProviderUtils;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Shared Chat Completions HTTP + parse pipeline (provider-utils).
/// OpenAI / OpenAI Compatible / OpenCode Zen models call this; they do not depend on each other.
/// </summary>
codeunit 87437 "AIOS Chat Completions Client"
{
    Access = Public;

    /// <summary>
    /// POST {BaseUrl}/chat/completions with Bearer auth and map the response into AIOS Chat Response.
    /// Requires company approval of PrivacyNoticeId (Privacy Notices Status); does not show a consent dialog.
    /// Uses the generic OpenAI-compatible dialect (max_tokens, reasoning_effort low / medium / high).
    /// </summary>
    procedure Generate(ModelId: Text; ApiKey: SecretText; BaseUrl: Text; ProviderName: Text; PrivacyNoticeId: Code[50]; PrivacyIntegrationName: Text[250]; PrivacyLink: Text[2048]; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    begin
        exit(Generate(ModelId, ApiKey, BaseUrl, ProviderName, PrivacyNoticeId, PrivacyIntegrationName, PrivacyLink, false, Request, Response));
    end;

    /// <summary>
    /// Same as Generate, choosing the request dialect. OpenAIDialect = true targets api.openai.com:
    /// max_completion_tokens (required by reasoning models) and pass-through reasoning_effort (minimal … xhigh).
    /// </summary>
    procedure Generate(ModelId: Text; ApiKey: SecretText; BaseUrl: Text; ProviderName: Text; PrivacyNoticeId: Code[50]; PrivacyIntegrationName: Text[250]; PrivacyLink: Text[2048]; OpenAIDialect: Boolean; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        PrivacyGate: Codeunit "AIOS Privacy Notice";
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
        Response."Provider Name" := ProviderName;

        if not PrivacyGate.EnsureApproved(PrivacyNoticeId, PrivacyIntegrationName, PrivacyLink, Response) then
            exit(false);

        Body := BuildRequestBody(ModelId, Request, OpenAIDialect, Warnings);
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

    /// <summary>
    /// Builds the chat completions JSON body. Internal; exposed to the test app via internalsVisibleTo.
    /// </summary>
    internal procedure BuildRequestBody(ModelId: Text; var Request: Record "AIOS Chat Request"; OpenAIDialect: Boolean; var Warnings: JsonArray): Text
    var
        FormatOptions: Codeunit "AIOS Chat Completions Options";
        FormatCU: Codeunit "AIOS Chat Completions Format";
        ChatFormat: Interface "AIOS Chat Format";
        Root: JsonObject;
        Messages: JsonArray;
        SystemMessage: JsonObject;
        UserMessage: JsonObject;
        ResponseFormat: JsonObject;
        ToolDefs: JsonArray;
        SystemText: Text;
        Body: Text;
    begin
        ChatFormat := FormatCU;
        if Request.HasMessages() then
            Messages := ChatFormat.MapMessages(Request.GetProviderMessages())
        else begin
            SystemText := Request.GetEffectiveSystemMessage();
            if SystemText <> '' then begin
                SystemMessage.Add('role', 'system');
                SystemMessage.Add('content', SystemText);
                Messages.Add(SystemMessage);
            end;
            UserMessage.Add('role', 'user');
            UserMessage.Add('content', Request.GetPrompt());
            Messages.Add(UserMessage);
        end;

        Root.Add('model', ModelId);
        Root.Add('messages', Messages);
        if Request."Max Tokens" > 0 then
            if OpenAIDialect then
                Root.Add('max_completion_tokens', Request."Max Tokens")
            else
                Root.Add('max_tokens', Request."Max Tokens");
        if Request."Has Temperature" then
            Root.Add('temperature', Request.Temperature);
        if Request."Json Mode" then begin
            ResponseFormat.Add('type', 'json_object');
            Root.Add('response_format', ResponseFormat);
        end;
        ToolDefs := Request.GetToolDefinitions();
        if ToolDefs.Count() > 0 then
            Root.Add('tools', ChatFormat.MapTools(ToolDefs));
        FormatOptions.Apply(Root, Request, Warnings, OpenAIDialect);

        Root.WriteTo(Body);
        exit(Body);
    end;

    /// <summary>
    /// Maps a 2xx chat completions body into Response. Malformed or unexpected shapes become ParseFailed, never a runtime error.
    /// Internal; exposed to the test app via internalsVisibleTo.
    /// </summary>
    internal procedure ParseSuccess(ResponseText: Text; var Response: Record "AIOS Chat Response"): Boolean
    var
        Parsed: Boolean;
    begin
        ClearLastError();
        if TryParseSuccess(ResponseText, Response, Parsed) then
            exit(Parsed);
        Response.SetError("AIOS Error Type"::ParseFailed, StrSubstNo(UnexpectedShapeErr, GetLastErrorText()));
        exit(false);
    end;

    [TryFunction]
    local procedure TryParseSuccess(ResponseText: Text; var Response: Record "AIOS Chat Response"; var Parsed: Boolean)
    var
        FormatCU: Codeunit "AIOS Chat Completions Format";
        ChatFormat: Interface "AIOS Chat Format";
        Root: JsonObject;
        ChoicesToken: JsonToken;
        Choices: JsonArray;
        ChoiceToken: JsonToken;
        Choice: JsonObject;
        MessageToken: JsonToken;
        MessageObj: JsonObject;
        UsageToken: JsonToken;
        Usage: JsonObject;
        ContentText: Text;
        ReasoningText: Text;
        FinishReason: Text;
        TokenCount: Integer;
        ToolCallsArr: JsonArray;
    begin
        Parsed := false;
        ChatFormat := FormatCU;
        if not Root.ReadFrom(ResponseText) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, InvalidJsonErr);
            exit;
        end;

        if not Root.Get('choices', ChoicesToken) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingChoicesErr);
            exit;
        end;
        if not ChoicesToken.IsArray() then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingChoicesErr);
            exit;
        end;

        Choices := ChoicesToken.AsArray();
        if Choices.Count() = 0 then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingChoicesErr);
            exit;
        end;

        Choices.Get(0, ChoiceToken);
        if not ChoiceToken.IsObject() then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingChoicesErr);
            exit;
        end;
        Choice := ChoiceToken.AsObject();
        FinishReason := GetValueText(Choice, 'finish_reason');
        Response."Finish Reason" := CopyStr(FinishReason, 1, MaxStrLen(Response."Finish Reason"));

        if not Choice.Get('message', MessageToken) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingContentErr);
            exit;
        end;
        if not MessageToken.IsObject() then begin
            Response.SetError("AIOS Error Type"::ParseFailed, MissingContentErr);
            exit;
        end;

        MessageObj := MessageToken.AsObject();
        ContentText := GetContentText(MessageObj);

        ReasoningText := GetValueText(MessageObj, 'reasoning_content');
        if ReasoningText <> '' then
            Response.SetReasoningContent(ReasoningText);

        ToolCallsArr := ChatFormat.ParseToolCalls(MessageToken);
        if ToolCallsArr.Count() > 0 then
            Response.SetToolCallsJson(ToolCallsArr);

        if Root.Get('usage', UsageToken) then
            if UsageToken.IsObject() then begin
                Usage := UsageToken.AsObject();
                if TryGetInteger(Usage, 'prompt_tokens', TokenCount) then
                    Response."Input Tokens" := TokenCount;
                if TryGetInteger(Usage, 'completion_tokens', TokenCount) then
                    Response."Output Tokens" := TokenCount;
            end;

        if (ContentText = '') and (not Response.HasToolCalls()) then begin
            if FinishReason = 'length' then
                Response.SetError("AIOS Error Type"::InvalidRequest, EmptyDueToMaxTokensErr)
            else
                Response.SetError("AIOS Error Type"::ParseFailed, StrSubstNo(EmptyContentErr, FinishReason));
            exit;
        end;

        Response.SetText(ContentText);
        Response.ClearError();
        Parsed := true;
    end;

    /// <summary>
    /// Message content as text: a string, or the joined text of "text" parts when content is a parts array.
    /// </summary>
    local procedure GetContentText(MessageObj: JsonObject): Text
    var
        ContentToken: JsonToken;
        PartToken: JsonToken;
        Part: JsonObject;
        Parts: JsonArray;
        Result: TextBuilder;
        i: Integer;
    begin
        if not MessageObj.Get('content', ContentToken) then
            exit('');
        if not ContentToken.IsArray() then
            exit(GetValueText(MessageObj, 'content'));

        Parts := ContentToken.AsArray();
        for i := 0 to Parts.Count() - 1 do begin
            Parts.Get(i, PartToken);
            if PartToken.IsObject() then begin
                Part := PartToken.AsObject();
                if GetValueText(Part, 'type') = 'text' then
                    Result.Append(GetValueText(Part, 'text'));
            end;
        end;
        exit(Result.ToText());
    end;

    /// <summary>
    /// Text of a scalar property; empty when missing, null, an object, or an array.
    /// </summary>
    local procedure GetValueText(Obj: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Obj.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure TryGetInteger(Obj: JsonObject; PropertyName: Text; var Value: Integer): Boolean
    var
        Token: JsonToken;
    begin
        if not Obj.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(TryReadInteger(Token.AsValue(), Value));
    end;

    [TryFunction]
    local procedure TryReadInteger(JsonValue: JsonValue; var Value: Integer)
    begin
        Value := Round(JsonValue.AsDecimal(), 1);
    end;

    var
        SendFailedErr: Label 'Failed to send request to chat completions endpoint.';
        InvalidJsonErr: Label 'Chat completions provider returned invalid JSON.';
        MissingChoicesErr: Label 'Chat completions response missing choices.';
        MissingContentErr: Label 'Chat completions response missing message content.';
        EmptyDueToMaxTokensErr: Label 'Empty model content (finish_reason=length).';
        EmptyContentErr: Label 'Empty model content (finish_reason=%1).', Comment = '%1 = finish reason';
        UnexpectedShapeErr: Label 'Chat completions response has an unexpected shape: %1', Comment = '%1 = platform error text';
}

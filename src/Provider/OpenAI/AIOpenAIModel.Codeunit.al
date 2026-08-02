codeunit 70143 "AI OpenAI Model" implements "AI Language Model"
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
        Response."Provider Name" := 'openai';

        Body := BuildRequestBody(Request);
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
        SystemMessage: JsonObject;
        UserMessage: JsonObject;
        ResponseFormat: JsonObject;
        Body: Text;
    begin
        if Request."System Message" <> '' then begin
            SystemMessage.Add('role', 'system');
            SystemMessage.Add('content', Request."System Message");
            Messages.Add(SystemMessage);
        end;

        UserMessage.Add('role', 'user');
        UserMessage.Add('content', Request.GetPrompt());
        Messages.Add(UserMessage);

        Root.Add('model', BoundModelId);
        Root.Add('messages', Messages);
        if Request."Max Tokens" > 0 then
            Root.Add('max_tokens', Request."Max Tokens");
        if Request.Temperature <> 0 then
            Root.Add('temperature', Request.Temperature);
        if Request."Json Mode" then begin
            ResponseFormat.Add('type', 'json_object');
            Root.Add('response_format', ResponseFormat);
        end;

        Root.WriteTo(Body);
        exit(Body);
    end;

    local procedure ParseSuccess(ResponseText: Text; var Response: Record "AI Chat Response"): Boolean
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
    begin
        if not Root.ReadFrom(ResponseText) then begin
            Response.SetError("AI Error Type"::ParseFailed, InvalidJsonErr);
            exit(false);
        end;

        if not Root.Get('choices', ChoicesToken) then begin
            Response.SetError("AI Error Type"::ParseFailed, MissingChoicesErr);
            exit(false);
        end;

        Choices := ChoicesToken.AsArray();
        if Choices.Count() = 0 then begin
            Response.SetError("AI Error Type"::ParseFailed, MissingChoicesErr);
            exit(false);
        end;

        Choices.Get(0, ChoiceToken);
        Choice := ChoiceToken.AsObject();
        if not Choice.Get('message', MessageToken) then begin
            Response.SetError("AI Error Type"::ParseFailed, MissingContentErr);
            exit(false);
        end;

        MessageObj := MessageToken.AsObject();
        if not MessageObj.Get('content', ContentToken) then begin
            Response.SetError("AI Error Type"::ParseFailed, MissingContentErr);
            exit(false);
        end;

        Response.SetText(ContentToken.AsValue().AsText());
        Response.ClearError();

        if Root.Get('usage', UsageToken) then begin
            Usage := UsageToken.AsObject();
            if Usage.Get('prompt_tokens', ContentToken) then
                Response."Input Tokens" := ContentToken.AsValue().AsInteger();
            if Usage.Get('completion_tokens', ContentToken) then
                Response."Output Tokens" := ContentToken.AsValue().AsInteger();
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
        SendFailedErr: Label 'Failed to send request to OpenAI.';
        InvalidJsonErr: Label 'OpenAI returned invalid JSON.';
        MissingChoicesErr: Label 'OpenAI response missing choices.';
        MissingContentErr: Label 'OpenAI response missing message content.';
}

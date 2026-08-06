namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Successful GenerateText result: model output plus HTTP metadata from the provider.
/// </summary>
codeunit 87411 "AIOS Generate Result"
{
    Access = Public;

    /// <summary>
    /// Loads fields from a chat response after a successful generation.
    /// </summary>
    procedure SetFromResponse(var Response: Record "AIOS Chat Response")
    var
        HeadersObj: JsonObject;
    begin
        OutputText := Response.GetText();
        BodyText := Response.GetBody();
        HeadersObj := Response.GetHeaders();
        Clear(HeadersText);
        if HeadersObj.Keys().Count() > 0 then
            HeadersObj.WriteTo(HeadersText);
        StatusCode := Response."HTTP Status Code";
        InputTokens := Response."Input Tokens";
        OutputTokens := Response."Output Tokens";
        FinishReason := Response."Finish Reason";
        ProviderName := Response."Provider Name";
        WarningsArray := Response.GetWarnings();
    end;

    /// <summary>
    /// Generated model output text (validated / unwrapped when an output schema was set).
    /// </summary>
    procedure Output(): Text
    begin
        exit(OutputText);
    end;

    /// <summary>
    /// Raw HTTP response body from the provider.
    /// </summary>
    procedure Body(): Text
    begin
        exit(BodyText);
    end;

    /// <summary>
    /// HTTP response headers as a JSON object.
    /// </summary>
    procedure Headers(): JsonObject
    var
        HeadersObj: JsonObject;
    begin
        if HeadersText = '' then
            exit(HeadersObj);
        if not HeadersObj.ReadFrom(HeadersText) then
            Clear(HeadersObj);
        exit(HeadersObj);
    end;

    /// <summary>
    /// HTTP status code from the provider response.
    /// </summary>
    procedure HttpStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    /// <summary>
    /// Reported input token count, when available.
    /// </summary>
    procedure GetInputTokens(): Integer
    begin
        exit(InputTokens);
    end;

    /// <summary>
    /// Reported output token count, when available.
    /// </summary>
    procedure GetOutputTokens(): Integer
    begin
        exit(OutputTokens);
    end;

    /// <summary>
    /// Provider finish reason, when available.
    /// </summary>
    procedure GetFinishReason(): Text
    begin
        exit(FinishReason);
    end;

    /// <summary>
    /// Provider id that produced the response.
    /// </summary>
    procedure GetProviderName(): Text
    begin
        exit(ProviderName);
    end;

    /// <summary>
    /// Compatibility and other warnings collected during the request.
    /// </summary>
    procedure GetWarnings(): JsonArray
    begin
        exit(WarningsArray);
    end;

    var
        WarningsArray: JsonArray;
        OutputText: Text;
        BodyText: Text;
        HeadersText: Text;
        FinishReason: Text[50];
        ProviderName: Text[100];
        StatusCode: Integer;
        InputTokens: Integer;
        OutputTokens: Integer;
}

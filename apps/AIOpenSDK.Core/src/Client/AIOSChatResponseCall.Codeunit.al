namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Metadata for one language-model HTTP call (one step in a GenerateText / tool loop).
/// </summary>
codeunit 87409 "AIOS Chat Response Call"
{
    Access = Public;

    /// <summary>
    /// Loads fields from a chat response after a model call attempt.
    /// </summary>
    procedure SetFromResponse(Step: Integer; var Response: Record "AIOS Chat Response")
    var
        HeadersObj: JsonObject;
    begin
        StepNo := Step;
        CallTimestamp := CurrentDateTime();
        ProviderName := Response."Provider Name";
        StatusCode := Response."HTTP Status Code";
        InputTokens := Response."Input Tokens";
        OutputTokens := Response."Output Tokens";
        FinishReason := Response."Finish Reason";
        HasToolCalls := Response.HasToolCalls();
        Succeeded := Response.GetErrorType() = "AIOS Error Type"::None;
        OutputText := Response.GetText();
        BodyText := Response.GetBody();
        HeadersObj := Response.GetHeaders();
        Clear(HeadersText);
        if HeadersObj.Keys().Count() > 0 then
            HeadersObj.WriteTo(HeadersText);
        ErrorTypeText := Format(Response.GetErrorType());
        ErrorMessageText := Response."Error Message";
    end;

    /// <summary>
    /// Returns the zero-based step index of this model call within the generate/tool loop.
    /// </summary>
    procedure Step(): Integer
    begin
        exit(StepNo);
    end;

    /// <summary>
    /// Returns when this model call was recorded.
    /// </summary>
    procedure Timestamp(): DateTime
    begin
        exit(CallTimestamp);
    end;

    /// <summary>
    /// Returns the provider name from the chat response.
    /// </summary>
    procedure GetProviderName(): Text
    begin
        exit(ProviderName);
    end;

    /// <summary>
    /// Returns the HTTP status code from the model call.
    /// </summary>
    procedure HttpStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    /// <summary>
    /// Returns input token count reported for this call.
    /// </summary>
    procedure GetInputTokens(): Integer
    begin
        exit(InputTokens);
    end;

    /// <summary>
    /// Returns output token count reported for this call.
    /// </summary>
    procedure GetOutputTokens(): Integer
    begin
        exit(OutputTokens);
    end;

    /// <summary>
    /// Returns the provider finish reason for this call.
    /// </summary>
    procedure GetFinishReason(): Text
    begin
        exit(FinishReason);
    end;

    /// <summary>
    /// Returns true when the response included tool calls.
    /// </summary>
    procedure GetHasToolCalls(): Boolean
    begin
        exit(HasToolCalls);
    end;

    /// <summary>
    /// Returns true when the call completed without an AIOS error type.
    /// </summary>
    procedure Success(): Boolean
    begin
        exit(Succeeded);
    end;

    /// <summary>
    /// Returns the assistant text content from this call.
    /// </summary>
    procedure Output(): Text
    begin
        exit(OutputText);
    end;

    /// <summary>
    /// Returns the raw HTTP response body from this call.
    /// </summary>
    procedure Body(): Text
    begin
        exit(BodyText);
    end;

    /// <summary>
    /// Returns response headers as a JSON object.
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
    /// Returns the AIOS error type name when the call failed.
    /// </summary>
    procedure GetErrorType(): Text
    begin
        exit(ErrorTypeText);
    end;

    /// <summary>
    /// Returns the error message when the call failed.
    /// </summary>
    procedure GetErrorMessage(): Text
    begin
        exit(ErrorMessageText);
    end;

    /// <summary>
    /// JSON object for history / diagnostics.
    /// </summary>
    procedure ToJson(): JsonObject
    var
        Obj: JsonObject;
        HeadersObj: JsonObject;
    begin
        Obj.Add('step', StepNo);
        Obj.Add('timestamp', Format(CallTimestamp, 0, 9));
        Obj.Add('provider', ProviderName);
        Obj.Add('httpStatus', StatusCode);
        Obj.Add('inputTokens', InputTokens);
        Obj.Add('outputTokens', OutputTokens);
        Obj.Add('finishReason', FinishReason);
        Obj.Add('hasToolCalls', HasToolCalls);
        Obj.Add('success', Succeeded);
        Obj.Add('output', OutputText);
        Obj.Add('body', BodyText);
        HeadersObj := Headers();
        if HeadersObj.Keys().Count() > 0 then
            Obj.Add('headers', HeadersObj);
        if not Succeeded then begin
            Obj.Add('errorType', ErrorTypeText);
            Obj.Add('errorMessage', ErrorMessageText);
        end;
        exit(Obj);
    end;

    trigger OnRun()
    begin
        Error(OnRunErr);
    end;

    var
        CallTimestamp: DateTime;
        OutputText: Text;
        BodyText: Text;
        HeadersText: Text;
        FinishReason: Text[50];
        ProviderName: Text[100];
        ErrorTypeText: Text[50];
        ErrorMessageText: Text;
        StepNo: Integer;
        StatusCode: Integer;
        InputTokens: Integer;
        OutputTokens: Integer;
        HasToolCalls: Boolean;
        Succeeded: Boolean;
        OnRunErr: Label 'Use AIOS Generate Result.GetResponseCalls, not Codeunit.Run.';
}

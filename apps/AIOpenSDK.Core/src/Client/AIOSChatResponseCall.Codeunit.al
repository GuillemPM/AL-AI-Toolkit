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

    procedure Step(): Integer
    begin
        exit(StepNo);
    end;

    procedure Timestamp(): DateTime
    begin
        exit(CallTimestamp);
    end;

    procedure GetProviderName(): Text
    begin
        exit(ProviderName);
    end;

    procedure HttpStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    procedure GetInputTokens(): Integer
    begin
        exit(InputTokens);
    end;

    procedure GetOutputTokens(): Integer
    begin
        exit(OutputTokens);
    end;

    procedure GetFinishReason(): Text
    begin
        exit(FinishReason);
    end;

    procedure GetHasToolCalls(): Boolean
    begin
        exit(HasToolCalls);
    end;

    procedure Success(): Boolean
    begin
        exit(Succeeded);
    end;

    procedure Output(): Text
    begin
        exit(OutputText);
    end;

    procedure Body(): Text
    begin
        exit(BodyText);
    end;

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

    procedure GetErrorType(): Text
    begin
        exit(ErrorTypeText);
    end;

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

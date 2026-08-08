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
        ToolCallsList := Response.GetToolCalls();
        RecalcTotalsFromCalls();
    end;

    /// <summary>
    /// Attaches per-step language-model HTTP calls (tool loop / retries).
    /// </summary>
    procedure SetResponseCalls(Calls: List of [Codeunit "AIOS Chat Response Call"])
    begin
        ResponseCallList := Calls;
        RecalcTotalsFromCalls();
    end;

    /// <summary>
    /// Generated model output text (validated / unwrapped when an output schema was set).
    /// </summary>
    procedure Output(): Text
    begin
        exit(OutputText);
    end;

    /// <summary>
    /// True when the model requested one or more tool calls.
    /// </summary>
    procedure HasToolCalls(): Boolean
    begin
        exit(ToolCallsList.Count() > 0);
    end;

    /// <summary>
    /// Tool calls from the model (empty when the response was plain text).
    /// </summary>
    procedure GetToolCalls(): List of [Codeunit "AIOS Tool Call"]
    begin
        exit(ToolCallsList);
    end;

    /// <summary>
    /// One entry per language-model HTTP call (including retries and tool-loop steps).
    /// </summary>
    procedure GetResponseCalls(): List of [Codeunit "AIOS Chat Response Call"]
    begin
        exit(ResponseCallList);
    end;

    /// <summary>
    /// Number of language-model HTTP calls recorded for this generation.
    /// </summary>
    procedure GetStepCount(): Integer
    begin
        exit(ResponseCallList.Count());
    end;

    /// <summary>
    /// Raw HTTP response body from the provider (last step).
    /// </summary>
    procedure Body(): Text
    begin
        exit(BodyText);
    end;

    /// <summary>
    /// HTTP response headers as a JSON object (last step).
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
    /// HTTP status code from the provider response (last step).
    /// </summary>
    procedure HttpStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    /// <summary>
    /// Input tokens for the last step (use GetTotalInputTokens for the full run).
    /// </summary>
    procedure GetInputTokens(): Integer
    begin
        exit(InputTokens);
    end;

    /// <summary>
    /// Output tokens for the last step (use GetTotalOutputTokens for the full run).
    /// </summary>
    procedure GetOutputTokens(): Integer
    begin
        exit(OutputTokens);
    end;

    /// <summary>
    /// Sum of input tokens across all recorded model calls.
    /// </summary>
    procedure GetTotalInputTokens(): Integer
    begin
        exit(TotalInputTokens);
    end;

    /// <summary>
    /// Sum of output tokens across all recorded model calls.
    /// </summary>
    procedure GetTotalOutputTokens(): Integer
    begin
        exit(TotalOutputTokens);
    end;

    /// <summary>
    /// Provider finish reason, when available (last step).
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

    /// <summary>
    /// True when the tool loop stopped because MaxSteps was reached while the model still requested tool calls.
    /// </summary>
    procedure StoppedAtStepLimit(): Boolean
    begin
        exit(StoppedAtLimit);
    end;

    /// <summary>
    /// Marks that generation ended at MaxSteps with pending tool calls (not a final text answer).
    /// </summary>
    procedure SetStoppedAtStepLimit(Value: Boolean)
    var
        WarningObj: JsonObject;
    begin
        StoppedAtLimit := Value;
        if not Value then
            exit;
        Clear(WarningObj);
        WarningObj.Add('type', 'tool_loop_step_limit');
        WarningObj.Add('message', StepLimitWarningTok);
        WarningsArray.Add(WarningObj);
    end;

    local procedure RecalcTotalsFromCalls()
    var
        CallCU: Codeunit "AIOS Chat Response Call";
        i: Integer;
    begin
        TotalInputTokens := 0;
        TotalOutputTokens := 0;
        if ResponseCallList.Count() = 0 then begin
            TotalInputTokens := InputTokens;
            TotalOutputTokens := OutputTokens;
            exit;
        end;
        for i := 1 to ResponseCallList.Count() do begin
            ResponseCallList.Get(i, CallCU);
            TotalInputTokens += CallCU.GetInputTokens();
            TotalOutputTokens += CallCU.GetOutputTokens();
        end;
    end;

    var
        WarningsArray: JsonArray;
        ToolCallsList: List of [Codeunit "AIOS Tool Call"];
        ResponseCallList: List of [Codeunit "AIOS Chat Response Call"];
        OutputText: Text;
        BodyText: Text;
        HeadersText: Text;
        FinishReason: Text[50];
        ProviderName: Text[100];
        StatusCode: Integer;
        InputTokens: Integer;
        OutputTokens: Integer;
        TotalInputTokens: Integer;
        TotalOutputTokens: Integer;
        StoppedAtLimit: Boolean;
        StepLimitWarningTok: Label 'Tool loop stopped at MaxSteps while the model still requested tool calls.', Locked = true;
}

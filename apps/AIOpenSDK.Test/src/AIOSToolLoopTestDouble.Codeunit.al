namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Test double for tool-loop tests: a language model that returns a configured tool-call array once, then final text,
/// and a counting tool ('count_calls'). SingleInstance so the ToolSet copy and the test share the execution count.
/// </summary>
codeunit 87501 "AIOS Tool Loop Test Double" implements "AIOS Language Model", "AIOS Tool"
{
    Access = Internal;
    SingleInstance = true;

    /// <summary>
    /// Clears state. The next Generate returns ToolCallsJson (normalized AIOS tool calls); the one after returns FinalText.
    /// </summary>
    procedure Reset(ToolCallsJson: Text; FinalText: Text)
    begin
        PendingToolCalls := ToolCallsJson;
        FinalContent := FinalText;
        ExecuteCount := 0;
    end;

    procedure GetExecuteCount(): Integer
    begin
        exit(ExecuteCount);
    end;

    procedure GetModelId(): Text
    begin
        exit('tool-loop-test-double');
    end;

    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        ToolCalls: JsonArray;
    begin
        Clear(Response);
        Response."Provider Name" := 'test-double';
        if PendingToolCalls <> '' then begin
            ToolCalls.ReadFrom(PendingToolCalls);
            PendingToolCalls := '';
            Response.SetToolCallsJson(ToolCalls);
            Response."Finish Reason" := 'tool_calls';
            exit(true);
        end;
        Response.SetText(FinalContent);
        exit(true);
    end;

    procedure Name(): Text
    begin
        exit('count_calls');
    end;

    procedure Description(): Text
    begin
        exit('Counts how many times it was executed.');
    end;

    procedure InputSchema(): JsonObject
    var
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
    begin
        exit(Schema.Object(Fields));
    end;

    procedure Execute(Arguments: JsonObject; var ResultText: Text): Boolean
    begin
        ExecuteCount += 1;
        ResultText := 'counted';
        exit(true);
    end;

    var
        PendingToolCalls: Text;
        FinalContent: Text;
        ExecuteCount: Integer;
}

namespace PM.Guillem.AIOpenSDK.Provider.Mock;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87447 "AIOS Mock Model" implements "AIOS Language Model"
{
    Access = Internal;

    var
        BoundModelId: Text;
        CannedContent: Text;
        FailOnGenerate: Boolean;
        FailErrorType: Enum "AIOS Error Type";
        FailErrorMessage: Text;
        RemainingFailures: Integer;
        NextToolCallId: Text;
        NextToolCallName: Text;
        NextToolCallArgs: Text;
        HasNextToolCall: Boolean;

    procedure Initialize(ModelId: Text; Content: Text; ShouldFail: Boolean; ErrorType: Enum "AIOS Error Type"; ErrorMessage: Text; FailuresBeforeSuccess: Integer)
    begin
        Initialize(ModelId, Content, ShouldFail, ErrorType, ErrorMessage, FailuresBeforeSuccess, false, '', '', '');
    end;

    procedure Initialize(ModelId: Text; Content: Text; ShouldFail: Boolean; ErrorType: Enum "AIOS Error Type"; ErrorMessage: Text; FailuresBeforeSuccess: Integer; ReturnToolCall: Boolean; ToolCallId: Text; ToolName: Text; ToolArgsJson: Text)
    begin
        BoundModelId := ModelId;
        CannedContent := Content;
        FailOnGenerate := ShouldFail;
        FailErrorType := ErrorType;
        FailErrorMessage := ErrorMessage;
        RemainingFailures := FailuresBeforeSuccess;
        HasNextToolCall := ReturnToolCall;
        NextToolCallId := ToolCallId;
        NextToolCallName := ToolName;
        NextToolCallArgs := ToolArgsJson;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        ToolCalls: JsonArray;
        CallObj: JsonObject;
        Args: JsonObject;
    begin
        Clear(Response);
        Response."Provider Name" := 'mock';

        if RemainingFailures > 0 then begin
            RemainingFailures -= 1;
            Response.SetError(FailErrorType, FailErrorMessage);
            exit(false);
        end;

        if FailOnGenerate then begin
            Response.SetError(FailErrorType, FailErrorMessage);
            exit(false);
        end;

        if HasNextToolCall then begin
            Clear(CallObj);
            if NextToolCallId = '' then
                CallObj.Add('id', 'call_mock_1')
            else
                CallObj.Add('id', NextToolCallId);
            CallObj.Add('name', NextToolCallName);
            Clear(Args);
            if NextToolCallArgs <> '' then
                if not Args.ReadFrom(NextToolCallArgs) then
                    Clear(Args);
            CallObj.Add('arguments', Args);
            ToolCalls.Add(CallObj);
            Response.SetToolCallsJson(ToolCalls);
            Response.SetText(CannedContent);
            Response."Finish Reason" := 'tool_calls';
            Response.SetBody(Response.GetText());
            Response.ClearError();
            Response."Input Tokens" := StrLen(Request.GetPrompt());
            Response."Output Tokens" := 0;
            HasNextToolCall := false;
            exit(true);
        end;

        if CannedContent <> '' then
            Response.SetText(CannedContent)
        else
            Response.SetText(StrSubstNo(DefaultReplyTxt, Request.GetPrompt()));

        Response.SetBody(Response.GetText());
        Response.ClearError();
        Response."Input Tokens" := StrLen(Request.GetPrompt());
        Response."Output Tokens" := StrLen(Response.GetText());
        exit(true);
    end;

    var
        DefaultReplyTxt: Label 'Echo: %1', Comment = '%1 = prompt text';
}

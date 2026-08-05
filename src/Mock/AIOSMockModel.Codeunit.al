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

    procedure Initialize(ModelId: Text; Content: Text; ShouldFail: Boolean; ErrorType: Enum "AIOS Error Type"; ErrorMessage: Text; FailuresBeforeSuccess: Integer)
    begin
        BoundModelId := ModelId;
        CannedContent := Content;
        FailOnGenerate := ShouldFail;
        FailErrorType := ErrorType;
        FailErrorMessage := ErrorMessage;
        RemainingFailures := FailuresBeforeSuccess;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
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

        if CannedContent <> '' then
            Response.SetText(CannedContent)
        else
            Response.SetText(StrSubstNo(DefaultReplyTxt, Request.GetPrompt()));

        Response.ClearError();
        Response."Input Tokens" := StrLen(Request.GetPrompt());
        Response."Output Tokens" := StrLen(Response.GetText());
        exit(true);
    end;

    var
        DefaultReplyTxt: Label 'Echo: %1', Comment = '%1 = prompt text';
}

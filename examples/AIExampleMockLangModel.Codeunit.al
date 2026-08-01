codeunit 70182 "AI Example Mock Lang. Model" implements "AI Language Model"
{
    Access = Internal;

    var
        BoundModelId: Text;
        CannedContent: Text;
        FailOnGenerate: Boolean;
        FailErrorType: Enum "AI Error Type";
        FailErrorMessage: Text;

    procedure Initialize(ModelId: Text; Content: Text; ShouldFail: Boolean; ErrorType: Enum "AI Error Type"; ErrorMessage: Text)
    begin
        BoundModelId := ModelId;
        CannedContent := Content;
        FailOnGenerate := ShouldFail;
        FailErrorType := ErrorType;
        FailErrorMessage := ErrorMessage;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure Generate(var Request: Record "AI Chat Request"; var Response: Record "AI Chat Response"): Boolean
    begin
        Clear(Response);
        Response."Provider Name" := 'example-mock';

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

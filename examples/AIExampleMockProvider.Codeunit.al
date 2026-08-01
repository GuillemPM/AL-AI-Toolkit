codeunit 70181 "AI Example Mock Provider" implements "AI Provider"
{
    Access = Public;

    var
        NextContent: Text;
        NextErrorType: Enum "AI Error Type";
        NextErrorMessage: Text;
        ForceFail: Boolean;

    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

    procedure GetName(): Text
    begin
        exit('example-mock');
    end;

    procedure BindLanguageModel(ModelId: Text; var Model: Interface "AI Language Model"): Boolean
    var
        LanguageModel: Codeunit "AI Example Mock Lang. Model";
    begin
        if ModelId = '' then
            exit(false);

        LanguageModel.Initialize(ModelId, NextContent, ForceFail, NextErrorType, NextErrorMessage);
        Model := LanguageModel;
        exit(true);
    end;

    procedure SetNextResponse(Content: Text)
    begin
        NextContent := Content;
        ForceFail := false;
        NextErrorType := NextErrorType::None;
        NextErrorMessage := '';
    end;

    procedure SetNextError(ErrorType: Enum "AI Error Type"; ErrorMessage: Text)
    begin
        ForceFail := true;
        NextErrorType := ErrorType;
        NextErrorMessage := ErrorMessage;
        NextContent := '';
    end;
}

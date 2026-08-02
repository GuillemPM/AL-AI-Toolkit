codeunit 70146 "AI Mock" implements "AI Provider"
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
        exit('mock');
    end;

    /// <summary>
    /// Bind a mock model (no API key). Use SetNextResponse / SetNextError before calling.
    /// </summary>
    procedure Model(ModelId: Text): Interface "AI Language Model"
    var
        LanguageModel: Interface "AI Language Model";
    begin
        if not BindLanguageModel(ModelId, LanguageModel) then
            Error(BindFailedErr, ModelId, GetName());
        exit(LanguageModel);
    end;

    procedure BindLanguageModel(ModelId: Text; var BoundModel: Interface "AI Language Model"): Boolean
    var
        LanguageModel: Codeunit "AI Mock Model";
    begin
        if ModelId = '' then
            exit(false);

        LanguageModel.Initialize(ModelId, NextContent, ForceFail, NextErrorType, NextErrorMessage);
        BoundModel := LanguageModel;
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

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id).', Comment = '%1 = model id, %2 = provider name';
}

namespace PM.Guillem.AIOpenSDK.Provider.Mock;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87446 "AIOS Mock" implements "AIOS Provider"
{
    Access = Public;

    var
        NextContent: Text;
        NextImageBase64: Text;
        NextImageMediaType: Text;
        NextErrorType: Enum "AIOS Error Type";
        NextErrorMessage: Text;
        ForceFail: Boolean;
        FailuresBeforeSuccess: Integer;

    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

    procedure GetName(): Text
    begin
        exit('mock');
    end;

    /// <summary>
    /// Bind a mock model (no API key). Use SetNextResponse / SetNextError / SetFailuresBeforeSuccess before calling.
    /// </summary>
    procedure Model(ModelId: Text): Interface "AIOS Language Model"
    var
        LanguageModel: Interface "AIOS Language Model";
    begin
        if not BindLanguageModel(ModelId, LanguageModel) then
            Error(BindFailedErr, ModelId, GetName());
        exit(LanguageModel);
    end;

    procedure BindLanguageModel(ModelId: Text; var BoundModel: Interface "AIOS Language Model"): Boolean
    var
        LanguageModel: Codeunit "AIOS Mock Model";
    begin
        if ModelId = '' then
            exit(false);

        LanguageModel.Initialize(ModelId, NextContent, ForceFail, NextErrorType, NextErrorMessage, FailuresBeforeSuccess);
        BoundModel := LanguageModel;
        exit(true);
    end;

    procedure SetNextResponse(Content: Text)
    begin
        NextContent := Content;
        ForceFail := false;
        FailuresBeforeSuccess := 0;
        NextErrorType := NextErrorType::None;
        NextErrorMessage := '';
    end;

    procedure SetNextError(ErrorType: Enum "AIOS Error Type"; ErrorMessage: Text)
    begin
        ForceFail := true;
        FailuresBeforeSuccess := 0;
        NextErrorType := ErrorType;
        NextErrorMessage := ErrorMessage;
        NextContent := '';
    end;

    /// <summary>
    /// Fail the next n Generate calls with RateLimited, then succeed with SetNextResponse content (or echo).
    /// </summary>
    procedure SetFailuresBeforeSuccess(FailureCount: Integer)
    begin
        if FailureCount < 0 then
            FailureCount := 0;
        FailuresBeforeSuccess := FailureCount;
        ForceFail := false;
        NextErrorType := NextErrorType::RateLimited;
        NextErrorMessage := 'simulated rate limit';
    end;

    /// <summary>
    /// Bind a mock image model. Configure with SetNextImageBase64 before calling GenerateImage.
    /// </summary>
    procedure ImageModel(ModelId: Text): Interface "AIOS Image Model"
    var
        ImageModelInstance: Interface "AIOS Image Model";
    begin
        if not BindImageModel(ModelId, ImageModelInstance) then
            Error(BindFailedErr, ModelId, GetName());
        exit(ImageModelInstance);
    end;

    procedure BindImageModel(ModelId: Text; var BoundModel: Interface "AIOS Image Model"): Boolean
    var
        ImageModelCU: Codeunit "AIOS Mock Image Model";
    begin
        if ModelId = '' then
            exit(false);

        ImageModelCU.Initialize(ModelId, NextImageBase64, NextImageMediaType, ForceFail, NextErrorType, NextErrorMessage, FailuresBeforeSuccess);
        BoundModel := ImageModelCU;
        exit(true);
    end;

    procedure SetNextImageBase64(Base64: Text; MediaType: Text)
    begin
        NextImageBase64 := Base64;
        NextImageMediaType := MediaType;
        ForceFail := false;
        FailuresBeforeSuccess := 0;
        NextErrorType := NextErrorType::None;
        NextErrorMessage := '';
    end;

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id).', Comment = '%1 = model id, %2 = provider name';
}

namespace PM.Guillem.AIOpenSDK.Provider.Mock;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87449 "AIOS Mock Image Model" implements "AIOS Image Model"
{
    Access = Internal;

    var
        BoundModelId: Text;
        CannedBase64: Text;
        CannedMediaType: Text;
        FailOnGenerate: Boolean;
        FailErrorType: Enum "AIOS Error Type";
        FailErrorMessage: Text;
        RemainingFailures: Integer;

    procedure Initialize(ModelId: Text; Base64: Text; MediaType: Text; ShouldFail: Boolean; ErrorType: Enum "AIOS Error Type"; ErrorMessage: Text; FailuresBeforeSuccess: Integer)
    begin
        BoundModelId := ModelId;
        CannedBase64 := Base64;
        CannedMediaType := MediaType;
        FailOnGenerate := ShouldFail;
        FailErrorType := ErrorType;
        FailErrorMessage := ErrorMessage;
        RemainingFailures := FailuresBeforeSuccess;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure GetDefaultMaxImagesPerCall(): Integer
    begin
        exit(1);
    end;

    procedure GenerateImage(var Request: Record "AIOS Image Request"; var Response: Record "AIOS Image Response"): Boolean
    var
        i: Integer;
        Base64: Text;
        MediaType: Text;
    begin
        Clear(Response);
        Response."Provider Name" := 'mock';
        Response."Model Id" := CopyStr(BoundModelId, 1, MaxStrLen(Response."Model Id"));
        Response."Call Timestamp" := CurrentDateTime();
        Response."HTTP Status Code" := 200;
        Response.SetBody('{"data":[{"b64_json":"mock"}]}');

        if RemainingFailures > 0 then begin
            RemainingFailures -= 1;
            Response.SetError(FailErrorType, FailErrorMessage);
            exit(false);
        end;

        if FailOnGenerate then begin
            Response.SetError(FailErrorType, FailErrorMessage);
            exit(false);
        end;

        Base64 := CannedBase64;
        if Base64 = '' then
            Base64 := MinimalPngBase64Txt;
        MediaType := CannedMediaType;
        if MediaType = '' then
            MediaType := 'image/png';

        for i := 1 to Request.GetImageCount() do
            Response.AppendGeneratedImage(Base64, MediaType, '');

        Response.SetUsageFromTokens(StrLen(Request.GetPrompt()), 0, StrLen(Request.GetPrompt()));
        Response.ClearError();
        exit(true);
    end;

    var
        MinimalPngBase64Txt: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==', Locked = true;
}

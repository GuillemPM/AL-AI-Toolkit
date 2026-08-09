namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Metadata for one image-model HTTP call (one batch).
/// </summary>
codeunit 87408 "AIOS Image Response Call"
{
    Access = Public;

    internal procedure SetMetadata(NewTimestamp: DateTime; NewModelId: Text; NewStatusCode: Integer; HeadersObj: JsonObject)
    begin
        CallTimestamp := NewTimestamp;
        ModelIdText := CopyStr(NewModelId, 1, MaxStrLen(ModelIdText));
        StatusCode := NewStatusCode;
        Clear(HeadersText);
        if HeadersObj.Keys().Count() > 0 then
            HeadersObj.WriteTo(HeadersText);
    end;

    procedure Timestamp(): DateTime
    begin
        exit(CallTimestamp);
    end;

    procedure ModelId(): Text
    begin
        exit(ModelIdText);
    end;

    procedure HttpStatusCode(): Integer
    begin
        exit(StatusCode);
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

    trigger OnRun()
    begin
        Error(OnRunErr);
    end;

    var
        HeadersText: Text;
        ModelIdText: Text[100];
        CallTimestamp: DateTime;
        StatusCode: Integer;
        OnRunErr: Label 'Use AIOS Client.GenerateImage result GetResponseCalls, not Codeunit.Run.';
}

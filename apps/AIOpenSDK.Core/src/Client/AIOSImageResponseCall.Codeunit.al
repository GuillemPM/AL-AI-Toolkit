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

    /// <summary>
    /// Returns when this image-model HTTP call was recorded.
    /// </summary>
    procedure Timestamp(): DateTime
    begin
        exit(CallTimestamp);
    end;

    /// <summary>
    /// Returns the model id used for this image call.
    /// </summary>
    procedure ModelId(): Text
    begin
        exit(ModelIdText);
    end;

    /// <summary>
    /// Returns the HTTP status code from this image call.
    /// </summary>
    procedure HttpStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    /// <summary>
    /// Returns response headers as a JSON object.
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

namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Successful GenerateImage result: generated files, usage, warnings, and HTTP metadata.
/// </summary>
codeunit 87412 "AIOS Generate Image Result"
{
    Access = Public;

    internal procedure SetFromAggregate(var Aggregate: Record "AIOS Image Response"; var Calls: List of [Codeunit "AIOS Image Response Call"]; var Usage: Codeunit "AIOS Image Usage")
    var
        HeadersObj: JsonObject;
    begin
        Aggregate.CopyGeneratedImagesToList(ImageList);
        CallList := Calls;
        UsageCU := Usage;
        WarningsArray := Aggregate.GetWarnings();
        ProviderMetadataObj := Aggregate.GetProviderMetadata();
        BodyText := Aggregate.GetBody();
        HeadersObj := Aggregate.GetHeaders();
        Clear(HeadersText);
        if HeadersObj.Keys().Count() > 0 then
            HeadersObj.WriteTo(HeadersText);
        StatusCode := Aggregate."HTTP Status Code";
        ProviderName := Aggregate."Provider Name";
    end;

    /// <summary>
    /// Returns every generated image from the successful GenerateImage call.
    /// </summary>
    procedure GetImages(): List of [Codeunit "AIOS Generated Image"]
    begin
        exit(ImageList);
    end;

    /// <summary>
    /// Returns the first generated image. Errors when the result contains no images.
    /// </summary>
    procedure GetImage(): Codeunit "AIOS Generated Image"
    var
        ImageCU: Codeunit "AIOS Generated Image";
    begin
        if ImageList.Count() = 0 then
            Error(NoImageErr);
        ImageList.Get(1, ImageCU);
        exit(ImageCU);
    end;

    /// <summary>
    /// Returns aggregated token and image usage for the GenerateImage operation.
    /// </summary>
    procedure GetUsage(): Codeunit "AIOS Image Usage"
    begin
        exit(UsageCU);
    end;

    /// <summary>
    /// Returns per-batch HTTP call metadata for the GenerateImage operation.
    /// </summary>
    procedure GetResponseCalls(): List of [Codeunit "AIOS Image Response Call"]
    begin
        exit(CallList);
    end;

    /// <summary>
    /// Returns provider warnings collected during image generation.
    /// </summary>
    procedure GetWarnings(): JsonArray
    begin
        exit(WarningsArray);
    end;

    /// <summary>
    /// Returns provider-specific metadata from the image response.
    /// </summary>
    procedure GetProviderMetadata(): JsonObject
    begin
        exit(ProviderMetadataObj);
    end;

    /// <summary>
    /// Returns the raw HTTP body from the last successful image batch.
    /// </summary>
    procedure Body(): Text
    begin
        exit(BodyText);
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

    /// <summary>
    /// Returns the HTTP status code from the last successful image batch.
    /// </summary>
    procedure HttpStatusCode(): Integer
    begin
        exit(StatusCode);
    end;

    /// <summary>
    /// Returns the provider name from the image response.
    /// </summary>
    procedure GetProviderName(): Text
    begin
        exit(ProviderName);
    end;

    trigger OnRun()
    begin
        Error(OnRunErr);
    end;

    var
        ImageList: List of [Codeunit "AIOS Generated Image"];
        CallList: List of [Codeunit "AIOS Image Response Call"];
        UsageCU: Codeunit "AIOS Image Usage";
        WarningsArray: JsonArray;
        ProviderMetadataObj: JsonObject;
        BodyText: Text;
        HeadersText: Text;
        ProviderName: Text[100];
        StatusCode: Integer;
        NoImageErr: Label 'GenerateImage returned no images.';
        OnRunErr: Label 'Use AIOS Client.GenerateImage, not Codeunit.Run.';
}

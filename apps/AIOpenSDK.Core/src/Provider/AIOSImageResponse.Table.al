namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

table 87404 "AIOS Image Response"
{
    Caption = 'AIOS Image Response';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Generated Images"; Blob)
        {
            Caption = 'Generated Images';
            DataClassification = CustomerContent;
        }
        field(20; "Error Type"; Enum "AIOS Error Type")
        {
            Caption = 'Error Type';
            DataClassification = SystemMetadata;
        }
        field(21; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(30; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = SystemMetadata;
        }
        field(31; "Raw Body"; Blob)
        {
            Caption = 'Raw Body';
            DataClassification = CustomerContent;
        }
        field(32; "Response Headers"; Blob)
        {
            Caption = 'Response Headers';
            DataClassification = SystemMetadata;
        }
        field(40; "Input Tokens"; Integer)
        {
            Caption = 'Input Tokens';
            DataClassification = SystemMetadata;
        }
        field(41; "Output Tokens"; Integer)
        {
            Caption = 'Output Tokens';
            DataClassification = SystemMetadata;
        }
        field(42; "Total Tokens"; Integer)
        {
            Caption = 'Total Tokens';
            DataClassification = SystemMetadata;
        }
        field(50; "Provider Name"; Text[100])
        {
            Caption = 'Provider Name';
            DataClassification = SystemMetadata;
        }
        field(51; "Model Id"; Text[100])
        {
            Caption = 'Model Id';
            DataClassification = SystemMetadata;
        }
        field(52; "Call Timestamp"; DateTime)
        {
            Caption = 'Call Timestamp';
            DataClassification = SystemMetadata;
        }
        field(60; Warnings; Blob)
        {
            Caption = 'Warnings';
            DataClassification = SystemMetadata;
        }
        field(61; "Provider Metadata"; Blob)
        {
            Caption = 'Provider Metadata';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure AppendGeneratedImage(Base64: Text; MediaType: Text; RevisedPrompt: Text)
    var
        Images: JsonArray;
        Item: JsonObject;
    begin
        Images := GetGeneratedImagesJson();
        Clear(Item);
        Item.Add('base64', Base64);
        Item.Add('mediaType', MediaType);
        if RevisedPrompt <> '' then
            Item.Add('revisedPrompt', RevisedPrompt);
        Images.Add(Item);
        SetGeneratedImagesJson(Images);
    end;

    procedure GetGeneratedImageCount(): Integer
    begin
        exit(GetGeneratedImagesJson().Count());
    end;

    procedure CopyGeneratedImagesToList(var Images: List of [Codeunit "AIOS Generated Image"])
    var
        JsonImages: JsonArray;
        Token: JsonToken;
        Item: JsonObject;
        ImageCU: Codeunit "AIOS Generated Image";
        Base64: Text;
        MediaType: Text;
        RevisedPrompt: Text;
        i: Integer;
        ValueToken: JsonToken;
    begin
        Clear(Images);
        JsonImages := GetGeneratedImagesJson();
        for i := 0 to JsonImages.Count() - 1 do begin
            JsonImages.Get(i, Token);
            Item := Token.AsObject();
            Base64 := '';
            MediaType := 'image/png';
            RevisedPrompt := '';
            if Item.Get('base64', ValueToken) then
                Base64 := ValueToken.AsValue().AsText();
            if Item.Get('mediaType', ValueToken) then
                MediaType := ValueToken.AsValue().AsText();
            if Item.Get('revisedPrompt', ValueToken) then
                RevisedPrompt := ValueToken.AsValue().AsText();
            Clear(ImageCU);
            ImageCU.SetContent(Base64, MediaType, RevisedPrompt);
            Images.Add(ImageCU);
        end;
    end;

    procedure MergeGeneratedImagesFrom(var BatchResponse: Record "AIOS Image Response")
    var
        BatchImages: JsonArray;
        Images: JsonArray;
        Token: JsonToken;
        i: Integer;
    begin
        BatchImages := BatchResponse.GetGeneratedImagesJson();
        if BatchImages.Count() = 0 then
            exit;
        Images := GetGeneratedImagesJson();
        for i := 0 to BatchImages.Count() - 1 do begin
            BatchImages.Get(i, Token);
            Images.Add(Token);
        end;
        SetGeneratedImagesJson(Images);
    end;

    procedure GetUsage(var Usage: Codeunit "AIOS Image Usage")
    begin
        Usage.ClearUsage();
        Usage.SetInputTokens("Input Tokens");
        Usage.SetOutputTokens("Output Tokens");
        Usage.SetTotalTokens("Total Tokens");
    end;

    procedure SetUsageFromTokens(InputTokens: Integer; OutputTokens: Integer; TotalTokens: Integer)
    begin
        "Input Tokens" := InputTokens;
        "Output Tokens" := OutputTokens;
        "Total Tokens" := TotalTokens;
    end;

    procedure GetBody(): Text
    begin
        exit(ReadBlobField(FieldNo("Raw Body")));
    end;

    procedure SetBody(Value: Text)
    begin
        WriteBlobField(FieldNo("Raw Body"), Value);
    end;

    procedure GetHeaders(): JsonObject
    var
        HeadersObj: JsonObject;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo("Response Headers"));
        if Text = '' then
            exit(HeadersObj);
        if not HeadersObj.ReadFrom(Text) then
            Clear(HeadersObj);
        exit(HeadersObj);
    end;

    procedure SetHeaders(HeadersObj: JsonObject)
    var
        Text: Text;
    begin
        Clear("Response Headers");
        if HeadersObj.Keys().Count() = 0 then
            exit;
        HeadersObj.WriteTo(Text);
        WriteBlobField(FieldNo("Response Headers"), Text);
    end;

    procedure CaptureHttpResponse(HttpResponse: HttpResponseMessage; ResponseBody: Text)
    var
        Headers: HttpHeaders;
        HeaderNames: List of [Text];
        HeaderName: Text;
        Values: List of [Text];
        HeadersObj: JsonObject;
        ValuesArr: JsonArray;
        Value: Text;
    begin
        "HTTP Status Code" := HttpResponse.HttpStatusCode();
        SetBody(ResponseBody);

        Headers := HttpResponse.Headers;
        HeaderNames := Headers.Keys();
        foreach HeaderName in HeaderNames do begin
            Clear(Values);
            Clear(ValuesArr);
            if not Headers.GetValues(HeaderName, Values) then
                continue;
            if Values.Count() = 0 then
                continue;
            if Values.Count() = 1 then begin
                Values.Get(1, Value);
                if HeadersObj.Contains(HeaderName) then
                    HeadersObj.Remove(HeaderName);
                HeadersObj.Add(HeaderName, Value);
            end else begin
                foreach Value in Values do
                    ValuesArr.Add(Value);
                if HeadersObj.Contains(HeaderName) then
                    HeadersObj.Remove(HeaderName);
                HeadersObj.Add(HeaderName, ValuesArr);
            end;
        end;
        SetHeaders(HeadersObj);
    end;

    procedure GetErrorType(): Enum "AIOS Error Type"
    begin
        exit("Error Type");
    end;

    procedure SetError(ErrorType: Enum "AIOS Error Type"; Message: Text)
    begin
        "Error Type" := ErrorType;
        "Error Message" := CopyStr(Message, 1, MaxStrLen("Error Message"));
    end;

    procedure ClearError()
    begin
        "Error Type" := "Error Type"::None;
        "Error Message" := '';
    end;

    procedure IsSuccess(): Boolean
    begin
        exit("Error Type" = "Error Type"::None);
    end;

    procedure GetWarnings(): JsonArray
    var
        WarningsArray: JsonArray;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo(Warnings));
        if Text = '' then
            exit(WarningsArray);
        if not WarningsArray.ReadFrom(Text) then
            Clear(WarningsArray);
        exit(WarningsArray);
    end;

    procedure AppendWarnings(var Source: JsonArray)
    var
        WarningsArray: JsonArray;
        Token: JsonToken;
        i: Integer;
    begin
        if Source.Count() = 0 then
            exit;
        WarningsArray := GetWarnings();
        for i := 0 to Source.Count() - 1 do begin
            Source.Get(i, Token);
            WarningsArray.Add(Token);
        end;
        SetWarnings(WarningsArray);
    end;

    procedure SetWarnings(var WarningsArray: JsonArray)
    var
        Text: Text;
    begin
        Clear(Warnings);
        if WarningsArray.Count() = 0 then
            exit;
        WarningsArray.WriteTo(Text);
        WriteBlobField(FieldNo(Warnings), Text);
    end;

    procedure GetProviderMetadata(): JsonObject
    var
        Metadata: JsonObject;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo("Provider Metadata"));
        if Text = '' then
            exit(Metadata);
        if not Metadata.ReadFrom(Text) then
            Clear(Metadata);
        exit(Metadata);
    end;

    procedure SetProviderMetadata(Metadata: JsonObject)
    var
        Text: Text;
    begin
        Clear("Provider Metadata");
        if Metadata.Keys().Count() = 0 then
            exit;
        Metadata.WriteTo(Text);
        WriteBlobField(FieldNo("Provider Metadata"), Text);
    end;

    procedure MergeProviderMetadataFrom(var BatchResponse: Record "AIOS Image Response")
    var
        Target: JsonObject;
        Source: JsonObject;
        ProviderName: Text;
        TargetProviderToken: JsonToken;
        SourceProviderToken: JsonToken;
        TargetProvider: JsonObject;
        SourceProvider: JsonObject;
        TargetImagesToken: JsonToken;
        SourceImagesToken: JsonToken;
        TargetImages: JsonArray;
        SourceImages: JsonArray;
        Token: JsonToken;
        i: Integer;
    begin
        Source := BatchResponse.GetProviderMetadata();
        if Source.Keys().Count() = 0 then
            exit;
        Target := GetProviderMetadata();
        foreach ProviderName in Source.Keys() do begin
            if not Source.Get(ProviderName, SourceProviderToken) then
                continue;
            if not Target.Get(ProviderName, TargetProviderToken) then begin
                Target.Add(ProviderName, SourceProviderToken);
                continue;
            end;
            if not (SourceProviderToken.IsObject() and TargetProviderToken.IsObject()) then
                continue;
            SourceProvider := SourceProviderToken.AsObject();
            TargetProvider := TargetProviderToken.AsObject();
            if not SourceProvider.Get('images', SourceImagesToken) then
                continue;
            if not SourceImagesToken.IsArray() then
                continue;
            SourceImages := SourceImagesToken.AsArray();
            if TargetProvider.Get('images', TargetImagesToken) and TargetImagesToken.IsArray() then
                TargetImages := TargetImagesToken.AsArray()
            else
                Clear(TargetImages);
            for i := 0 to SourceImages.Count() - 1 do begin
                SourceImages.Get(i, Token);
                TargetImages.Add(Token);
            end;
            if TargetProvider.Contains('images') then
                TargetProvider.Remove('images');
            TargetProvider.Add('images', TargetImages);
            if Target.Contains(ProviderName) then
                Target.Remove(ProviderName);
            Target.Add(ProviderName, TargetProvider);
        end;
        SetProviderMetadata(Target);
    end;

    procedure ClearAggregate()
    begin
        Clear("Generated Images");
        Clear(Warnings);
        Clear("Provider Metadata");
        "Input Tokens" := 0;
        "Output Tokens" := 0;
        "Total Tokens" := 0;
    end;

    procedure GetGeneratedImagesJson(): JsonArray
    var
        Images: JsonArray;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo("Generated Images"));
        if Text = '' then
            exit(Images);
        if not Images.ReadFrom(Text) then
            Clear(Images);
        exit(Images);
    end;

    local procedure SetGeneratedImagesJson(var Images: JsonArray)
    var
        Text: Text;
    begin
        Clear("Generated Images");
        if Images.Count() = 0 then
            exit;
        Images.WriteTo(Text);
        WriteBlobField(FieldNo("Generated Images"), Text);
    end;

    local procedure WriteBlobField(FieldNumber: Integer; Value: Text)
    var
        OutStream: OutStream;
    begin
        case FieldNumber of
            FieldNo("Generated Images"):
                begin
                    Clear("Generated Images");
                    if Value = '' then
                        exit;
                    "Generated Images".CreateOutStream(OutStream, TextEncoding::UTF8);
                    WriteLongText(OutStream, Value);
                end;
            FieldNo("Raw Body"):
                begin
                    Clear("Raw Body");
                    if Value = '' then
                        exit;
                    "Raw Body".CreateOutStream(OutStream, TextEncoding::UTF8);
                    WriteLongText(OutStream, Value);
                end;
            FieldNo("Response Headers"):
                begin
                    Clear("Response Headers");
                    if Value = '' then
                        exit;
                    "Response Headers".CreateOutStream(OutStream, TextEncoding::UTF8);
                    WriteLongText(OutStream, Value);
                end;
            FieldNo(Warnings):
                begin
                    Clear(Warnings);
                    if Value = '' then
                        exit;
                    Warnings.CreateOutStream(OutStream, TextEncoding::UTF8);
                    WriteLongText(OutStream, Value);
                end;
            FieldNo("Provider Metadata"):
                begin
                    Clear("Provider Metadata");
                    if Value = '' then
                        exit;
                    "Provider Metadata".CreateOutStream(OutStream, TextEncoding::UTF8);
                    WriteLongText(OutStream, Value);
                end;
        end;
    end;

    /// <summary>
    /// WriteText in chunks — single-call WriteText can truncate multi-MB payloads (image base64).
    /// </summary>
    local procedure WriteLongText(var OutStream: OutStream; Value: Text)
    var
        Pos: Integer;
        Len: Integer;
        ChunkSize: Integer;
        Chunk: Text;
        Written: Integer;
        WriteBlobFailedErr: Label 'Failed to write large text into AIOS Image Response blob.';
    begin
        Len := StrLen(Value);
        if Len = 0 then
            exit;
        Pos := 1;
        ChunkSize := 64 * 1024;
        while Pos <= Len do begin
            Chunk := CopyStr(Value, Pos, ChunkSize);
            Written := OutStream.WriteText(Chunk);
            if Written <= 0 then
                Error(WriteBlobFailedErr);
            Pos += Written;
        end;
    end;

    local procedure ReadBlobField(FieldNumber: Integer): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        case FieldNumber of
            FieldNo("Generated Images"):
                begin
                    if not "Generated Images".HasValue then
                        exit('');
                    "Generated Images".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo("Raw Body"):
                begin
                    if not "Raw Body".HasValue then
                        exit('');
                    "Raw Body".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo("Response Headers"):
                begin
                    if not "Response Headers".HasValue then
                        exit('');
                    "Response Headers".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo(Warnings):
                begin
                    if not Warnings.HasValue then
                        exit('');
                    Warnings.CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo("Provider Metadata"):
                begin
                    if not "Provider Metadata".HasValue then
                        exit('');
                    "Provider Metadata".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
        end;
        exit('');
    end;
}

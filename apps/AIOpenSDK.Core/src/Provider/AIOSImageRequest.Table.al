namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

table 87403 "AIOS Image Request"
{
    Caption = 'AIOS Image Request';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; Prompt; Blob)
        {
            Caption = 'Prompt';
            DataClassification = CustomerContent;
        }
        field(11; "Prompt Files"; Blob)
        {
            Caption = 'Prompt Files';
            DataClassification = CustomerContent;
        }
        field(12; "Prompt Mask"; Blob)
        {
            Caption = 'Prompt Mask';
            DataClassification = CustomerContent;
        }
        field(20; "Image Count"; Integer)
        {
            Caption = 'Image Count';
            DataClassification = SystemMetadata;
        }
        field(21; Size; Text[30])
        {
            Caption = 'Size';
            DataClassification = SystemMetadata;
        }
        field(22; "Aspect Ratio"; Text[20])
        {
            Caption = 'Aspect Ratio';
            DataClassification = SystemMetadata;
        }
        field(23; Seed; Integer)
        {
            Caption = 'Seed';
            DataClassification = SystemMetadata;
        }
        field(24; "Has Seed"; Boolean)
        {
            Caption = 'Has Seed';
            DataClassification = SystemMetadata;
        }
        field(30; "Provider Options"; Blob)
        {
            Caption = 'Provider Options';
            DataClassification = SystemMetadata;
        }
        field(31; "Max Images Per Call"; Integer)
        {
            Caption = 'Max Images Per Call';
            DataClassification = SystemMetadata;
        }
        field(32; "Max Retries"; Integer)
        {
            Caption = 'Max Retries';
            DataClassification = SystemMetadata;
        }
        field(33; "Has Max Retries"; Boolean)
        {
            Caption = 'Has Max Retries';
            DataClassification = SystemMetadata;
        }
        field(34; "Timeout Ms"; Integer)
        {
            Caption = 'Timeout Ms';
            DataClassification = SystemMetadata;
        }
        field(35; "Has Timeout"; Boolean)
        {
            Caption = 'Has Timeout';
            DataClassification = SystemMetadata;
        }
        field(36; "Request Headers"; Blob)
        {
            Caption = 'Request Headers';
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

    procedure SetPrompt(Value: Text)
    begin
        WriteBlobField(FieldNo(Prompt), Value);
    end;

    procedure GetPrompt(): Text
    begin
        exit(ReadBlobField(FieldNo(Prompt)));
    end;

    procedure SetPromptFiles(Files: JsonArray)
    var
        Text: Text;
    begin
        Clear("Prompt Files");
        if Files.Count() = 0 then
            exit;
        Files.WriteTo(Text);
        WriteBlobField(FieldNo("Prompt Files"), Text);
    end;

    procedure GetPromptFiles(): JsonArray
    var
        Files: JsonArray;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo("Prompt Files"));
        if Text = '' then
            exit(Files);
        if not Files.ReadFrom(Text) then
            Clear(Files);
        exit(Files);
    end;

    procedure SetPromptMask(Mask: JsonObject)
    var
        Text: Text;
    begin
        Clear("Prompt Mask");
        if Mask.Keys().Count() = 0 then
            exit;
        Mask.WriteTo(Text);
        WriteBlobField(FieldNo("Prompt Mask"), Text);
    end;

    procedure GetPromptMask(): JsonObject
    var
        Mask: JsonObject;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo("Prompt Mask"));
        if Text = '' then
            exit(Mask);
        if not Mask.ReadFrom(Text) then
            Clear(Mask);
        exit(Mask);
    end;

    procedure SetImageCount(Value: Integer)
    begin
        if Value < 1 then
            Value := 1;
        "Image Count" := Value;
    end;

    procedure GetImageCount(): Integer
    begin
        if "Image Count" < 1 then
            exit(1);
        exit("Image Count");
    end;

    procedure SetSize(Value: Text)
    begin
        Size := CopyStr(Value, 1, MaxStrLen(Size));
    end;

    procedure GetSize(): Text
    begin
        exit(Size);
    end;

    procedure SetAspectRatio(Value: Text)
    begin
        "Aspect Ratio" := CopyStr(Value, 1, MaxStrLen("Aspect Ratio"));
    end;

    procedure GetAspectRatio(): Text
    begin
        exit("Aspect Ratio");
    end;

    procedure SetSeed(Value: Integer)
    begin
        Seed := Value;
        "Has Seed" := true;
    end;

    procedure ClearSeed()
    begin
        Seed := 0;
        "Has Seed" := false;
    end;

    procedure HasSeed(): Boolean
    begin
        exit("Has Seed");
    end;

    procedure GetSeed(): Integer
    begin
        exit(Seed);
    end;

    procedure SetProviderOptions(Options: JsonObject)
    var
        Text: Text;
    begin
        Clear("Provider Options");
        if Options.Keys().Count() = 0 then
            exit;
        Options.WriteTo(Text);
        WriteBlobField(FieldNo("Provider Options"), Text);
    end;

    procedure GetProviderOptions(): JsonObject
    var
        Options: JsonObject;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo("Provider Options"));
        if Text = '' then
            exit(Options);
        if not Options.ReadFrom(Text) then
            Clear(Options);
        exit(Options);
    end;

    procedure SetMaxImagesPerCall(Value: Integer)
    begin
        if Value < 0 then
            Value := 0;
        "Max Images Per Call" := Value;
    end;

    procedure GetMaxImagesPerCall(): Integer
    begin
        exit("Max Images Per Call");
    end;

    procedure SetMaxRetries(Value: Integer)
    begin
        if Value < 0 then
            Error(MaxRetriesNegativeErr);
        "Max Retries" := Value;
        "Has Max Retries" := true;
    end;

    procedure GetMaxRetries(): Integer
    begin
        if "Has Max Retries" then
            exit("Max Retries");
        exit(2);
    end;

    procedure SetTimeout(Ms: Integer)
    begin
        if Ms < 0 then
            Error(TimeoutNegativeErr);
        "Timeout Ms" := Ms;
        "Has Timeout" := true;
    end;

    procedure GetHttpTimeout(): Integer
    begin
        if "Has Timeout" then
            exit("Timeout Ms");
        exit(120000);
    end;

    procedure SetRequestHeaders(Headers: JsonObject)
    var
        Text: Text;
    begin
        Clear("Request Headers");
        if Headers.Keys().Count() = 0 then
            exit;
        Headers.WriteTo(Text);
        WriteBlobField(FieldNo("Request Headers"), Text);
    end;

    procedure GetRequestHeaders(): JsonObject
    var
        Headers: JsonObject;
        Text: Text;
    begin
        Text := ReadBlobField(FieldNo("Request Headers"));
        if Text = '' then
            exit(Headers);
        if not Headers.ReadFrom(Text) then
            Clear(Headers);
        exit(Headers);
    end;

    procedure CopyFrom(Source: Record "AIOS Image Request")
    begin
        Rec := Source;
    end;

    local procedure WriteBlobField(FieldNumber: Integer; Value: Text)
    var
        OutStream: OutStream;
    begin
        case FieldNumber of
            FieldNo(Prompt):
                begin
                    Clear(Prompt);
                    if Value = '' then
                        exit;
                    Prompt.CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.WriteText(Value);
                end;
            FieldNo("Prompt Files"):
                begin
                    Clear("Prompt Files");
                    if Value = '' then
                        exit;
                    "Prompt Files".CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.WriteText(Value);
                end;
            FieldNo("Prompt Mask"):
                begin
                    Clear("Prompt Mask");
                    if Value = '' then
                        exit;
                    "Prompt Mask".CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.WriteText(Value);
                end;
            FieldNo("Provider Options"):
                begin
                    Clear("Provider Options");
                    if Value = '' then
                        exit;
                    "Provider Options".CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.WriteText(Value);
                end;
            FieldNo("Request Headers"):
                begin
                    Clear("Request Headers");
                    if Value = '' then
                        exit;
                    "Request Headers".CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.WriteText(Value);
                end;
        end;
    end;

    local procedure ReadBlobField(FieldNumber: Integer): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        case FieldNumber of
            FieldNo(Prompt):
                begin
                    if not Prompt.HasValue then
                        exit('');
                    Prompt.CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo("Prompt Files"):
                begin
                    if not "Prompt Files".HasValue then
                        exit('');
                    "Prompt Files".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo("Prompt Mask"):
                begin
                    if not "Prompt Mask".HasValue then
                        exit('');
                    "Prompt Mask".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo("Provider Options"):
                begin
                    if not "Provider Options".HasValue then
                        exit('');
                    "Provider Options".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
            FieldNo("Request Headers"):
                begin
                    if not "Request Headers".HasValue then
                        exit('');
                    "Request Headers".CreateInStream(InStream, TextEncoding::UTF8);
                    exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
                end;
        end;
        exit('');
    end;

    var
        MaxRetriesNegativeErr: Label 'Max retries cannot be negative.';
        TimeoutNegativeErr: Label 'Timeout cannot be negative.';
}

namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

table 87402 "AIOS Chat Response"
{
    Caption = 'AIOS Chat Response';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; Content; Blob)
        {
            Caption = 'Content';
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
        field(50; "Provider Name"; Text[100])
        {
            Caption = 'Provider Name';
            DataClassification = SystemMetadata;
        }
        field(60; "Finish Reason"; Text[50])
        {
            Caption = 'Finish Reason';
            DataClassification = SystemMetadata;
        }
        field(70; Warnings; Blob)
        {
            Caption = 'Warnings';
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

    procedure GetText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not Content.HasValue then
            exit('');
        Content.CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetText(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Content);
        if Value = '' then
            exit;
        Content.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetErrorType(): Enum "AIOS Error Type"
    begin
        exit("Error Type");
    end;

    /// <summary>
    /// Marks the response as failed. Does not clear Content so callers can still
    /// inspect model text after a post-generation validation failure.
    /// </summary>
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

    procedure AddWarning(WarningType: Text; Feature: Text; Message: Text)
    var
        WarningsArray: JsonArray;
        Warning: JsonObject;
    begin
        WarningsArray := GetWarnings();
        Clear(Warning);
        Warning.Add('type', WarningType);
        Warning.Add('feature', Feature);
        Warning.Add('message', Message);
        WarningsArray.Add(Warning);
        SetWarnings(WarningsArray);
    end;

    procedure AppendWarnings(var Source: JsonArray)
    var
        WarningsArray: JsonArray;
        Token: JsonToken;
        WarningObj: JsonObject;
        i: Integer;
    begin
        if Source.Count() = 0 then
            exit;
        WarningsArray := GetWarnings();
        for i := 0 to Source.Count() - 1 do begin
            Source.Get(i, Token);
            WarningObj := Token.AsObject();
            WarningsArray.Add(WarningObj);
        end;
        SetWarnings(WarningsArray);
    end;

    procedure GetWarnings(): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        WarningsArray: JsonArray;
        Text: Text;
    begin
        if not Warnings.HasValue then
            exit(WarningsArray);
        Warnings.CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(WarningsArray);
        if not WarningsArray.ReadFrom(Text) then
            Clear(WarningsArray);
        exit(WarningsArray);
    end;

    procedure ClearWarnings()
    begin
        Clear(Warnings);
    end;

    local procedure SetWarnings(var WarningsArray: JsonArray)
    var
        OutStream: OutStream;
        Text: Text;
    begin
        Clear(Warnings);
        if WarningsArray.Count() = 0 then
            exit;
        WarningsArray.WriteTo(Text);
        Warnings.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;
}

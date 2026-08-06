namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;
using System.Reflection;

table 87482 "AIOS Demo History"
{
    Caption = 'AIOS Demo History';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; Provider; Text[50])
        {
            Caption = 'Provider';
            DataClassification = SystemMetadata;
        }
        field(11; Model; Text[100])
        {
            Caption = 'Model';
            DataClassification = SystemMetadata;
        }
        field(20; "System Message"; Blob)
        {
            Caption = 'System Message';
            DataClassification = CustomerContent;
        }
        field(21; Prompt; Blob)
        {
            Caption = 'Prompt';
            DataClassification = CustomerContent;
        }
        field(22; Result; Blob)
        {
            Caption = 'Result';
            DataClassification = CustomerContent;
        }
        field(23; "Prompt Preview"; Text[250])
        {
            Caption = 'User prompt';
            DataClassification = CustomerContent;
        }
        field(24; "Result Preview"; Text[250])
        {
            Caption = 'Result';
            DataClassification = CustomerContent;
        }
        field(27; "Response Body"; Blob)
        {
            Caption = 'Response Body';
            DataClassification = CustomerContent;
        }
        field(28; "Response Headers"; Blob)
        {
            Caption = 'Response Headers';
            DataClassification = SystemMetadata;
        }
        field(29; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = SystemMetadata;
        }
        field(25; "System Preview"; Text[250])
        {
            Caption = 'System (sent)';
            DataClassification = CustomerContent;
        }
        field(26; "Form System Message"; Blob)
        {
            Caption = 'Form System Message';
            DataClassification = CustomerContent;
        }
        field(30; "JSON Mode"; Boolean)
        {
            Caption = 'JSON Mode';
            DataClassification = SystemMetadata;
        }
        field(31; Temperature; Decimal)
        {
            Caption = 'Temperature';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
        field(32; "Has Temperature"; Boolean)
        {
            Caption = 'Has Temperature';
            DataClassification = SystemMetadata;
        }
        field(33; "Max Tokens"; Integer)
        {
            Caption = 'Max Tokens';
            DataClassification = SystemMetadata;
        }
        field(34; "Timeout Ms"; Integer)
        {
            Caption = 'Timeout Ms';
            DataClassification = SystemMetadata;
        }
        field(40; Success; Boolean)
        {
            Caption = 'Success';
            DataClassification = SystemMetadata;
        }
        field(41; "Error Type"; Enum "AIOS Error Type")
        {
            Caption = 'Error Type';
            DataClassification = SystemMetadata;
        }
        field(42; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(43; "Soft Fail"; Boolean)
        {
            Caption = 'Soft Fail';
            DataClassification = SystemMetadata;
        }
        field(50; "Input Tokens"; Integer)
        {
            Caption = 'Input Tokens';
            DataClassification = SystemMetadata;
        }
        field(51; "Output Tokens"; Integer)
        {
            Caption = 'Output Tokens';
            DataClassification = SystemMetadata;
        }
        field(60; "Top P"; Decimal)
        {
            Caption = 'Top P';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 4;
        }
        field(61; "Has Top P"; Boolean)
        {
            Caption = 'Has Top P';
            DataClassification = SystemMetadata;
        }
        field(62; "Top K"; Integer)
        {
            Caption = 'Top K';
            DataClassification = SystemMetadata;
        }
        field(63; "Has Top K"; Boolean)
        {
            Caption = 'Has Top K';
            DataClassification = SystemMetadata;
        }
        field(64; "Presence Penalty"; Decimal)
        {
            Caption = 'Presence Penalty';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
        field(65; "Has Presence Penalty"; Boolean)
        {
            Caption = 'Has Presence Penalty';
            DataClassification = SystemMetadata;
        }
        field(66; "Frequency Penalty"; Decimal)
        {
            Caption = 'Frequency Penalty';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
        field(67; "Has Frequency Penalty"; Boolean)
        {
            Caption = 'Has Frequency Penalty';
            DataClassification = SystemMetadata;
        }
        field(68; Seed; Integer)
        {
            Caption = 'Seed';
            DataClassification = SystemMetadata;
        }
        field(69; "Has Seed"; Boolean)
        {
            Caption = 'Has Seed';
            DataClassification = SystemMetadata;
        }
        field(70; "Stop Sequences"; Text[250])
        {
            Caption = 'Stop Sequences';
            DataClassification = SystemMetadata;
        }
        field(71; Reasoning; Enum "AIOS Reasoning Effort")
        {
            Caption = 'Reasoning';
            DataClassification = SystemMetadata;
        }
        field(72; "Max Retries"; Integer)
        {
            Caption = 'Max Retries';
            DataClassification = SystemMetadata;
        }
        field(73; "Has Max Retries"; Boolean)
        {
            Caption = 'Has Max Retries';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(UserCreated; "User ID", "Created At")
        {
        }
    }

    procedure GetSystemMessage(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("System Message");
        if not "System Message".HasValue then
            exit('');
        "System Message".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetSystemMessage(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear("System Message");
        "System Preview" := CopyStr(Value, 1, MaxStrLen("System Preview"));
        if Value = '' then
            exit;
        "System Message".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetFormSystemMessage(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Form System Message");
        if not "Form System Message".HasValue then
            exit('');
        "Form System Message".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetFormSystemMessage(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Form System Message");
        if Value = '' then
            exit;
        "Form System Message".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetPrompt(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields(Prompt);
        if not Prompt.HasValue then
            exit('');
        Prompt.CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetPrompt(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Prompt);
        "Prompt Preview" := CopyStr(Value, 1, MaxStrLen("Prompt Preview"));
        if Value = '' then
            exit;
        Prompt.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetResult(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields(Result);
        if not Result.HasValue then
            exit('');
        Result.CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetResult(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Result);
        "Result Preview" := CopyStr(Value, 1, MaxStrLen("Result Preview"));
        if Value = '' then
            exit;
        Result.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetResponseBody(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Response Body");
        if not "Response Body".HasValue then
            exit('');
        "Response Body".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetResponseBody(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Response Body");
        if Value = '' then
            exit;
        "Response Body".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetResponseHeaders(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Response Headers");
        if not "Response Headers".HasValue then
            exit('');
        "Response Headers".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetResponseHeaders(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Response Headers");
        if Value = '' then
            exit;
        "Response Headers".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;
}

table 70102 "AI Chat Response"
{
    Caption = 'AI Chat Response';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; Content; Text[2048])
        {
            Caption = 'Content';
            DataClassification = CustomerContent;
        }
        field(20; "Error Type"; Enum "AI Error Type")
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
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure GetText(): Text
    begin
        exit(Content);
    end;

    procedure SetText(Value: Text)
    begin
        Content := CopyStr(Value, 1, MaxStrLen(Content));
    end;

    procedure GetErrorType(): Enum "AI Error Type"
    begin
        exit("Error Type");
    end;

    procedure SetError(ErrorType: Enum "AI Error Type"; Message: Text)
    begin
        "Error Type" := ErrorType;
        "Error Message" := CopyStr(Message, 1, MaxStrLen("Error Message"));
        Content := '';
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
}

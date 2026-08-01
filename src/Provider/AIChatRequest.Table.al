table 70101 "AI Chat Request"
{
    Caption = 'AI Chat Request';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; Prompt; Text[2048])
        {
            Caption = 'Prompt';
            DataClassification = CustomerContent;
        }
        field(11; "System Message"; Text[2048])
        {
            Caption = 'System Message';
            DataClassification = CustomerContent;
        }
        field(20; "Json Mode"; Boolean)
        {
            Caption = 'JSON Mode';
            DataClassification = SystemMetadata;
        }
        field(30; Model; Text[100])
        {
            Caption = 'Model';
            DataClassification = SystemMetadata;
        }
        field(31; "Max Tokens"; Integer)
        {
            Caption = 'Max Tokens';
            DataClassification = SystemMetadata;
        }
        field(32; Temperature; Decimal)
        {
            Caption = 'Temperature';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
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
        Prompt := CopyStr(Value, 1, MaxStrLen(Prompt));
    end;

    procedure GetPrompt(): Text
    begin
        exit(Prompt);
    end;

    procedure SetSystemMessage(Value: Text)
    begin
        "System Message" := CopyStr(Value, 1, MaxStrLen("System Message"));
    end;

    procedure SetJsonMode(Value: Boolean)
    begin
        "Json Mode" := Value;
    end;
}

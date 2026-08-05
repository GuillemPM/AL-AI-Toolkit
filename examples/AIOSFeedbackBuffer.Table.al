namespace PM.Guillem.AIOpenSDK.Examples;

/// <summary>
/// Temporary DTO for structured-output examples and tests.
/// </summary>
table 87485 "AIOS Feedback Buffer"
{
    Caption = 'AIOS Feedback Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; Sentiment; Text[50])
        {
            Caption = 'Sentiment';
            DataClassification = CustomerContent;
        }
        field(11; Score; Decimal)
        {
            Caption = 'Score';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
        }
        field(12; Urgent; Boolean)
        {
            Caption = 'Urgent';
            DataClassification = CustomerContent;
        }
        field(13; Summary; Text[250])
        {
            Caption = 'Summary';
            DataClassification = CustomerContent;
        }
        field(14; Topics; Text[250])
        {
            Caption = 'Topics';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}

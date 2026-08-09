namespace PM.Guillem.AIOpenSDK.Test;

/// <summary>
/// Temporary DTO for structured-output RecRef binding tests (not for production use).
/// </summary>
table 87496 "AIOS Test Bind Target"
{

    Access = Internal;
    Caption = 'AIOS Test Bind Target';
    TableType = Temporary;
    DataClassification = SystemMetadata;

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
            DataClassification = SystemMetadata;
        }
        field(11; Score; Decimal)
        {
            Caption = 'Score';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
        field(12; Urgent; Boolean)
        {
            Caption = 'Urgent';
            DataClassification = SystemMetadata;
        }
        field(13; Summary; Text[250])
        {
            Caption = 'Summary';
            DataClassification = SystemMetadata;
        }
        field(14; Topics; Text[250])
        {
            Caption = 'Topics';
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
}

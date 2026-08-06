namespace PM.Guillem.AIOpenSDK.Examples;

/// <summary>
/// FactBox for generated images on a demo history row (same pattern as Customer Picture).
/// </summary>
page 87489 "AIOS Demo History Picture"
{
    ApplicationArea = All;
    Caption = 'Pictures';
    PageType = CardPart;
    SourceTable = "AIOS Demo History";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            field(Pictures; Rec.Pictures)
            {
                ApplicationArea = All;
                ShowCaption = false;
                ToolTip = 'Generated images for this history entry.';
            }
        }
    }
}

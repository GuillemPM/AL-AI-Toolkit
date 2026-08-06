namespace PM.Guillem.AIOpenSDK.Examples;

page 87483 "AIOS Demo History"
{
    ApplicationArea = All;
    Caption = 'History';
    PageType = ListPart;
    SourceTable = "AIOS Demo History";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = true;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'When this request was run.';
                }
                field(Success; Rec.Success)
                {
                    ApplicationArea = All;
                    ToolTip = 'Whether the request succeeded.';
                }
                field(Provider; Rec.Provider)
                {
                    ApplicationArea = All;
                    ToolTip = 'Provider used for the request.';
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                    ToolTip = 'Model id used for the request.';
                }
                field("JSON Mode"; Rec."JSON Mode")
                {
                    ApplicationArea = All;
                    ToolTip = 'Whether JSON mode was requested.';
                }
                field("System Preview"; Rec."System Preview")
                {
                    ApplicationArea = All;
                    ToolTip = 'System message actually sent to the model (includes schema / JSON-mode instructions).';
                }
                field("Prompt Preview"; Rec."Prompt Preview")
                {
                    ApplicationArea = All;
                    ToolTip = 'User prompt sent to the model.';
                }
                field("Result Preview"; Rec."Result Preview")
                {
                    ApplicationArea = All;
                    ToolTip = 'Model output or error details.';
                }
                field("Error Type"; Rec."Error Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Error type when the request failed.';
                }
                field("Input Tokens"; Rec."Input Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Reported input tokens, when available.';
                }
                field("Output Tokens"; Rec."Output Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Reported output tokens, when available.';
                }
                field("Soft Fail"; Rec."Soft Fail")
                {
                    ApplicationArea = All;
                    ToolTip = 'True when Try generate was used.';
                }
                field(Temperature; Rec.Temperature)
                {
                    ApplicationArea = All;
                    ToolTip = 'Temperature sent with the request.';
                    Visible = false;
                }
                field("Max Tokens"; Rec."Max Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Max tokens sent with the request.';
                    Visible = false;
                }
                field("Top P"; Rec."Top P")
                {
                    ApplicationArea = All;
                    ToolTip = 'Top P sent with the request.';
                    Visible = false;
                }
                field("Top K"; Rec."Top K")
                {
                    ApplicationArea = All;
                    ToolTip = 'Top K sent with the request.';
                    Visible = false;
                }
                field(Reasoning; Rec.Reasoning)
                {
                    ApplicationArea = All;
                    ToolTip = 'Reasoning effort sent with the request.';
                    Visible = false;
                }
                field("Max Retries"; Rec."Max Retries")
                {
                    ApplicationArea = All;
                    ToolTip = 'Max retries sent with the request.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDetails)
            {
                ApplicationArea = All;
                Caption = 'Show details';
                Image = ViewDetails;
                Scope = Repeater;
                ToolTip = 'Open the full system message, user prompt, result, and generated images on a card page.';

                trigger OnAction()
                begin
                    Page.Run(Page::"AIOS Demo History Card", Rec);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(Rec."User ID")));
    end;

    procedure GetCurrent(var History: Record "AIOS Demo History")
    begin
        History := Rec;
    end;

    procedure Reload()
    begin
        CurrPage.Update(false);
    end;
}

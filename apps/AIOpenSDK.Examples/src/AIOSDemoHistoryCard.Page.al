namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Full details for one AIOS demo history row (system, user prompt, result).
/// </summary>
page 87486 "AIOS Demo History Card"
{
    ApplicationArea = All;
    Caption = 'Demo history details';
    PageType = Card;
    SourceTable = "AIOS Demo History";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataCaptionExpression = DataCaptionTxt;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

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
                field("Soft Fail"; Rec."Soft Fail")
                {
                    ApplicationArea = All;
                    ToolTip = 'True when Try generate was used.';
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
                field("Input Tokens"; Rec."Input Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Total input tokens across all model steps, when available.';
                }
                field("Output Tokens"; Rec."Output Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Total output tokens across all model steps, when available.';
                }
                field("Step Count"; Rec."Step Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of language-model HTTP calls (tool-loop steps and retries).';
                }
            }
            group(RequestOptions)
            {
                Caption = 'Request options';

                field(Temperature; Rec.Temperature)
                {
                    ApplicationArea = All;
                    ToolTip = 'Temperature sent with the request.';
                }
                field("Top P"; Rec."Top P")
                {
                    ApplicationArea = All;
                    ToolTip = 'Top P sent with the request.';
                }
                field("Top K"; Rec."Top K")
                {
                    ApplicationArea = All;
                    ToolTip = 'Top K sent with the request.';
                }
                field(Reasoning; Rec.Reasoning)
                {
                    ApplicationArea = All;
                    ToolTip = 'Reasoning effort sent with the request.';
                }
                field("Max Tokens"; Rec."Max Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Max tokens sent with the request.';
                }
                field("Timeout Ms"; Rec."Timeout Ms")
                {
                    ApplicationArea = All;
                    ToolTip = 'HTTP timeout in milliseconds.';
                }
                field("Max Retries"; Rec."Max Retries")
                {
                    ApplicationArea = All;
                    ToolTip = 'Max retries sent with the request.';
                }
                field("Stop Sequences"; Rec."Stop Sequences")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Stop sequences sent with the request.';
                }
            }
            group(SystemGroup)
            {
                Caption = 'System (sent)';

                field(SystemText; SystemText)
                {
                    ApplicationArea = All;
                    Caption = 'System message';
                    MultiLine = true;
                    ToolTip = 'System message actually sent to the model.';
                }
            }
            group(PromptGroup)
            {
                Caption = 'User prompt';

                field(PromptText; PromptText)
                {
                    ApplicationArea = All;
                    Caption = 'User prompt';
                    MultiLine = true;
                    ToolTip = 'User prompt sent to the model.';
                }
            }
            group(ResultGroup)
            {
                Caption = 'Result';

                field(ResultText; ResultText)
                {
                    ApplicationArea = All;
                    Caption = 'Result';
                    MultiLine = true;
                    ToolTip = 'Model output or structured summary.';
                }
                field(Pictures; Rec.Pictures)
                {
                    ApplicationArea = All;
                    ToolTip = 'Generated images for this history entry (from response body → Tenant Media).';
                }
                field("HTTP Status Code"; Rec."HTTP Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'HTTP status code from the provider response.';
                }
                field(ResponseBodyText; ResponseBodyText)
                {
                    ApplicationArea = All;
                    Caption = 'Response body';
                    MultiLine = true;
                    ToolTip = 'Raw HTTP response body from the provider.';
                }
                field(ResponseHeadersText; ResponseHeadersText)
                {
                    ApplicationArea = All;
                    Caption = 'Response headers';
                    MultiLine = true;
                    ToolTip = 'HTTP response headers from the provider as JSON.';
                }
                field(ResponseCallsText; ResponseCallsText)
                {
                    ApplicationArea = All;
                    Caption = 'Model calls';
                    MultiLine = true;
                    ToolTip = 'JSON array of each language-model HTTP call (steps, tokens, bodies).';
                }
                field("Error Type"; Rec."Error Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Error type when the request failed.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Error message when the request failed.';
                }
            }
        }
        area(FactBoxes)
        {
            part(HistoryPicture; "AIOS Demo History Picture")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SystemText := Rec.GetSystemMessage();
        PromptText := Rec.GetPrompt();
        ResultText := Rec.GetResult();
        ResponseBodyText := Rec.GetResponseBody();
        ResponseHeadersText := Rec.GetResponseHeaders();
        ResponseCallsText := Rec.GetResponseCallsJson();
        DataCaptionTxt := StrSubstNo(DataCaptionLbl, Rec.Provider, Rec.Model, Rec."Created At");
    end;

    var
        SystemText: Text;
        PromptText: Text;
        ResultText: Text;
        ResponseBodyText: Text;
        ResponseHeadersText: Text;
        ResponseCallsText: Text;
        DataCaptionTxt: Text;
        DataCaptionLbl: Label '%1 / %2 — %3', Comment = '%1 = provider, %2 = model, %3 = created at';
}

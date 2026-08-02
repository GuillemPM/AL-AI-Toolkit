page 70181 "AI Toolkit Demo"
{
    ApplicationArea = All;
    Caption = 'AI Toolkit Demo';
    PageType = Card;
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Manual smoke tests';
                InstructionalText = 'Uses the in-memory mock provider — no API key or network required.';

                field(LastResult; LastResult)
                {
                    ApplicationArea = All;
                    Caption = 'Last result';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Output from the last demo run.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunMockDemo)
            {
                ApplicationArea = All;
                Caption = 'Run mock demo';
                Image = TestFile;
                ToolTip = 'Calls AI Client.GenerateJson through AI Mock.';

                trigger OnAction()
                var
                    Mock: Codeunit "AI Mock";
                    Client: Codeunit "AI Client";
                begin
                    Mock.SetNextResponse('{"sentiment":"positive","topics":["pricing","support"]}');
                    LastResult := Client.GenerateJson(
                        Mock.Model('demo-model'),
                        'You extract sentiment and topics from customer feedback.',
                        'Feedback: Great product, but support felt pricey.');
                    Message(LastResult);
                end;
            }
            action(RunMockErrorDemo)
            {
                ApplicationArea = All;
                Caption = 'Run mock error demo';
                Image = ErrorLog;
                ToolTip = 'Verifies soft-fail path returns false with an error type.';

                trigger OnAction()
                var
                    Mock: Codeunit "AI Mock";
                    Client: Codeunit "AI Client";
                    Response: Record "AI Chat Response";
                    Ok: Boolean;
                begin
                    Mock.SetNextError("AI Error Type"::ProviderUnavailable, 'simulated failure');
                    Ok := Client.TryGenerateText(Mock.Model('demo-model'), 'hello', Response);
                    if Ok then
                        Error(UnexpectedSuccessErr);
                    LastResult := StrSubstNo(ErrorResultMsg, Response.GetErrorType(), Response."Error Message");
                    Message(LastResult);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RunMockDemo_Promoted; RunMockDemo) { }
            actionref(RunMockErrorDemo_Promoted; RunMockErrorDemo) { }
        }
    }

    var
        LastResult: Text;
        UnexpectedSuccessErr: Label 'Mock was expected to fail, but TryGenerateText returned true.';
        ErrorResultMsg: Label 'Soft-fail OK — %1: %2', Comment = '%1 = error type, %2 = message';
}

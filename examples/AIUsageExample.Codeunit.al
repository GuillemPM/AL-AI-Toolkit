codeunit 70180 "AI Usage Example"
{
    Access = Public;

    /// <summary>
    /// How a consuming extension would call the toolkit: bind a model from a provider, then Generate.
    /// </summary>
    procedure RunFeedbackSummaryDemo()
    var
        MockProvider: Codeunit "AI Example Mock Provider";
        Provider: Interface "AI Provider";
        LanguageModel: Interface "AI Language Model";
        Request: Record "AI Chat Request";
        Response: Record "AI Chat Response";
    begin
        // 1) Obtain a provider (from setup/DI in real apps; mock here for a runnable demo)
        MockProvider.SetNextResponse('{"sentiment":"positive","topics":["pricing","support"]}');
        Provider := MockProvider;

        // 2) Provider is a factory — bind the model you want
        if not Provider.BindLanguageModel('demo-model', LanguageModel) then
            Error(UnsupportedModelErr, 'demo-model', Provider.GetName());

        // 3) Build the request
        Clear(Request);
        Request.SetSystemMessage('You extract sentiment and topics from customer feedback.');
        Request.SetPrompt('Feedback: Great product, but support felt pricey.');
        Request.SetJsonMode(true);

        // 4) Generate on the language model (not on the provider)
        if not LanguageModel.Generate(Request, Response) then begin
            case Response.GetErrorType() of
                "AI Error Type"::RateLimited:
                    Message(RateLimitedMsg);
                "AI Error Type"::AuthenticationFailed:
                    Message(AuthFailedMsg);
                else
                    Message(FailedMsg, Response.GetErrorType(), Response."Error Message");
            end;
            exit;
        end;

        Message(SuccessMsg, LanguageModel.GetModelId(), Provider.GetName(), Response.GetText());
    end;

    var
        UnsupportedModelErr: Label 'Model %1 is not supported by provider %2.', Comment = '%1 = model id, %2 = provider name';
        SuccessMsg: Label 'Model %1 (%2) returned:\\%3', Comment = '%1 = model id, %2 = provider, %3 = content';
        FailedMsg: Label 'Generation failed (%1): %2', Comment = '%1 = error type, %2 = message';
        RateLimitedMsg: Label 'Rate limited — retry later.';
        AuthFailedMsg: Label 'Authentication failed — check provider configuration.';
}

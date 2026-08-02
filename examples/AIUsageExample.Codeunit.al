codeunit 70180 "AI Usage Example"
{
    Access = Public;

    /// <summary>
    /// Mock demo — no network, no API key.
    /// Same shape as: generateText({ model, system, prompt })
    /// </summary>
    procedure RunFeedbackSummaryDemo()
    var
        Mock: Codeunit "AI Mock";
        Client: Codeunit "AI Client";
    begin
        Mock.SetNextResponse('{"sentiment":"positive","topics":["pricing","support"]}');

        Message(SuccessMsg,
            Client.GenerateJson(
                Mock.Model('demo-model'),
                'You extract sentiment and topics from customer feedback.',
                'Feedback: Great product, but support felt pricey.'));
    end;

    /// <summary>
    /// Anthropic — same shape as: generateText({ model: anthropic('…'), system, prompt })
    /// </summary>
    procedure RunAnthropicDemo(ApiKey: SecretText)
    var
        Anthropic: Codeunit "AI Anthropic";
        Client: Codeunit "AI Client";
    begin
        Message(SuccessMsg,
            Client.GenerateJson(
                Anthropic.Model('claude-sonnet-4-5', ApiKey),
                'You extract sentiment and topics from customer feedback.',
                'Feedback: Great product, but support felt pricey.'));
    end;

    /// <summary>
    /// OpenAI — same shape as: generateText({ model: openai('…'), system, prompt })
    /// </summary>
    procedure RunOpenAIDemo(ApiKey: SecretText)
    var
        OpenAI: Codeunit "AI OpenAI";
        Client: Codeunit "AI Client";
    begin
        Message(SuccessMsg,
            Client.GenerateJson(
                OpenAI.Model('gpt-4.1-mini', ApiKey),
                'You extract sentiment and topics from customer feedback.',
                'Feedback: Great product, but support felt pricey.'));
    end;

    /// <summary>
    /// OpenCode Zen — same shape as: generateText({ model, system, prompt })
    /// Get a key at https://opencode.ai/auth.
    /// </summary>
    procedure RunOpenCodeZenDemo(ApiKey: SecretText)
    var
        Zen: Codeunit "AI OpenCode Zen";
        Client: Codeunit "AI Client";
    begin
        Message(SuccessMsg,
            Client.GenerateJson(
                Zen.Model('big-pickle', ApiKey),
                'You extract sentiment and topics from customer feedback.',
                'Feedback: Great product, but support felt pricey.'));
    end;

    var
        SuccessMsg: Label '%1', Comment = '%1 = model response text';
}

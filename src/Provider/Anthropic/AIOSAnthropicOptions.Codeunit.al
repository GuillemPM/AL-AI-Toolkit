namespace PM.Guillem.AIOpenSDK.Provider.Anthropic;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Maps AIOS Chat Request sampling / reasoning fields to Anthropic Messages API JSON.
/// </summary>
codeunit 87430 "AIOS Anthropic Options"
{
    Access = Public;

    /// <summary>
    /// Adds Anthropic sampling and thinking fields to the messages root object.
    /// </summary>
    procedure Apply(var Root: JsonObject; var Request: Record "AIOS Chat Request"; var Warnings: JsonArray)
    var
        RequestOptions: Codeunit "AIOS Request Options";
        StopSequences: JsonArray;
        Thinking: JsonObject;
        BudgetTokens: Integer;
        MaxOutputTokens: Integer;
    begin
        if Request."Has Top P" then
            Root.Add('top_p', Request."Top P");
        if Request."Has Top K" then
            Root.Add('top_k', Request."Top K");
        if Request.HasStopSequences() then begin
            StopSequences := Request.GetStopSequences();
            Root.Add('stop_sequences', StopSequences);
        end;

        if RequestOptions.IsCustomReasoning(Request.Reasoning) and (Request.Reasoning <> Request.Reasoning::None) then begin
            MaxOutputTokens := Request."Max Tokens";
            BudgetTokens := RequestOptions.MapReasoningToBudget(Request.Reasoning, MaxOutputTokens, 1024, 0, Warnings);
            if BudgetTokens > 0 then begin
                Thinking.Add('type', 'enabled');
                Thinking.Add('budget_tokens', BudgetTokens);
                Root.Add('thinking', Thinking);
            end;
        end;
    end;
}

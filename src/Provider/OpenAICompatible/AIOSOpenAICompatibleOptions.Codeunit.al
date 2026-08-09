namespace PM.Guillem.AIOpenSDK.Provider.OpenAICompatible;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Maps AIOS Chat Request sampling / reasoning fields to OpenAI-compatible chat completions JSON.
/// </summary>
codeunit 87429 "AIOS OpenAI Compatible Options"
{
    Access = Public;

    /// <summary>
    /// Adds OpenAI-compatible sampling fields to the chat completions root object.
    /// </summary>
    procedure Apply(var Root: JsonObject; var Request: Record "AIOS Chat Request"; var Warnings: JsonArray)
    var
        RequestOptions: Codeunit "AIOS Request Options";
        StopSequences: JsonArray;
        ReasoningEffort: Text;
    begin
        if Request."Has Top P" then
            Root.Add('top_p', Request."Top P");
        if Request."Has Presence Penalty" then
            Root.Add('presence_penalty', Request."Presence Penalty");
        if Request."Has Frequency Penalty" then
            Root.Add('frequency_penalty', Request."Frequency Penalty");
        if Request."Has Seed" then
            Root.Add('seed', Request.Seed);
        if Request.HasStopSequences() then begin
            StopSequences := Request.GetStopSequences();
            Root.Add('stop', StopSequences);
        end;

        if RequestOptions.IsCustomReasoning(Request.Reasoning) and (Request.Reasoning <> Request.Reasoning::None) then begin
            ReasoningEffort := RequestOptions.MapReasoningToEffort(
                Request.Reasoning,
                'minimal', 'low', 'medium', 'high', 'xhigh',
                Warnings);
            if ReasoningEffort <> '' then
                Root.Add('reasoning_effort', ReasoningEffort);
        end;
    end;
}

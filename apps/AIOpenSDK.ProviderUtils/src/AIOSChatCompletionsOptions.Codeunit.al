namespace PM.Guillem.AIOpenSDK.ProviderUtils;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Shared Chat Completions sampling / reasoning field mapping (provider-utils).
/// </summary>
codeunit 87436 "AIOS Chat Completions Options"
{
    Access = Public;

    /// <summary>
    /// Adds OpenAI-compatible sampling fields to the chat completions root object.
    /// Uses the generic compatible reasoning map (XHigh → high, Minimal → low, with warnings).
    /// </summary>
    procedure Apply(var Root: JsonObject; var Request: Record "AIOS Chat Request"; var Warnings: JsonArray)
    begin
        Apply(Root, Request, Warnings, false);
    end;

    /// <summary>
    /// Adds sampling fields. OpenAIDialect = true passes every reasoning level through as OpenAI's reasoning_effort
    /// (minimal … xhigh; support varies by model). Otherwise uses the compatible map low / medium / high only.
    /// </summary>
    procedure Apply(var Root: JsonObject; var Request: Record "AIOS Chat Request"; var Warnings: JsonArray; OpenAIDialect: Boolean)
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
            if OpenAIDialect then
                ReasoningEffort := RequestOptions.MapReasoningToEffort(
                    Request.Reasoning,
                    'minimal', 'low', 'medium', 'high', 'xhigh',
                    Warnings)
            else
                ReasoningEffort := RequestOptions.MapReasoningToEffort(
                    Request.Reasoning,
                    'low', 'low', 'medium', 'high', 'high',
                    Warnings);
            if ReasoningEffort <> '' then
                Root.Add('reasoning_effort', ReasoningEffort);
        end;
    end;
}

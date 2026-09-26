namespace PM.Guillem.AIOpenSDK.Provider.Anthropic;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Maps AIOS Chat Request sampling / reasoning fields to Anthropic Messages API JSON.
/// </summary>
codeunit 87453 "AIOS Anthropic Options"
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
        ThinkingEnabled: Boolean;
    begin
        if RequestOptions.IsCustomReasoning(Request.Reasoning) and (Request.Reasoning <> Request.Reasoning::None) then begin
            MaxOutputTokens := GetMaxTokens(Root, Request);
            BudgetTokens := RequestOptions.MapReasoningToBudget(Request.Reasoning, MaxOutputTokens, 1024, 0, Warnings);
            if BudgetTokens > 0 then begin
                ThinkingEnabled := true;
                if BudgetTokens >= MaxOutputTokens then begin
                    SetMaxTokens(Root, BudgetTokens + MaxOutputTokens);
                    AddWarning(Warnings, 'compatibility', 'max_tokens', StrSubstNo(MaxTokensRaisedMsg, MaxOutputTokens, BudgetTokens + MaxOutputTokens, BudgetTokens));
                end;
            end;
        end;

        if Request."Has Top P" then
            if (not ThinkingEnabled) or ((Request."Top P" >= 0.95) and (Request."Top P" <= 1)) then
                Root.Add('top_p', Request."Top P")
            else
                AddWarning(Warnings, 'unsupported', 'top_p', TopPWithThinkingMsg);
        if Request."Has Top K" then
            if ThinkingEnabled then
                AddWarning(Warnings, 'unsupported', 'top_k', StrSubstNo(OmittedWithThinkingMsg, 'top_k'))
            else
                Root.Add('top_k', Request."Top K");
        if ThinkingEnabled and Root.Contains('temperature') then begin
            Root.Remove('temperature');
            AddWarning(Warnings, 'unsupported', 'temperature', StrSubstNo(OmittedWithThinkingMsg, 'temperature'));
        end;
        if Request.HasStopSequences() then begin
            StopSequences := Request.GetStopSequences();
            Root.Add('stop_sequences', StopSequences);
        end;

        if ThinkingEnabled then begin
            Thinking.Add('type', 'enabled');
            Thinking.Add('budget_tokens', BudgetTokens);
            Root.Add('thinking', Thinking);
        end;
    end;

    local procedure GetMaxTokens(Root: JsonObject; var Request: Record "AIOS Chat Request"): Integer
    var
        Token: JsonToken;
    begin
        if Root.Get('max_tokens', Token) then
            if Token.IsValue() then
                if Token.AsValue().AsInteger() > 0 then
                    exit(Token.AsValue().AsInteger());
        if Request."Max Tokens" > 0 then
            exit(Request."Max Tokens");
        exit(4096);
    end;

    local procedure SetMaxTokens(var Root: JsonObject; Value: Integer)
    begin
        if Root.Contains('max_tokens') then
            Root.Replace('max_tokens', Value)
        else
            Root.Add('max_tokens', Value);
    end;

    local procedure AddWarning(var Warnings: JsonArray; WarningType: Text; Feature: Text; Message: Text)
    var
        Warning: JsonObject;
    begin
        Warning.Add('type', WarningType);
        Warning.Add('feature', Feature);
        Warning.Add('message', Message);
        Warnings.Add(Warning);
    end;

    var
        MaxTokensRaisedMsg: Label 'max_tokens raised from %1 to %2 so the Anthropic thinking budget (%3) fits below it.', Comment = '%1 = requested max tokens, %2 = sent max tokens, %3 = thinking budget tokens';
        OmittedWithThinkingMsg: Label '%1 is not supported with Anthropic extended thinking; omitted.', Comment = '%1 = parameter name';
        TopPWithThinkingMsg: Label 'top_p must be between 0.95 and 1 with Anthropic extended thinking; omitted.';
}

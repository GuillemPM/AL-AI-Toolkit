namespace PM.Guillem.AIOpenSDK.Core;

codeunit 87413 "AIOS Request Options"
{
    Access = Internal;

    /// <summary>
    /// True when reasoning should be translated (not provider-default).
    /// </summary>
    procedure IsCustomReasoning(Reasoning: Enum "AIOS Reasoning Effort"): Boolean
    begin
        exit(Reasoning <> Reasoning::ProviderDefault);
    end;

    /// <summary>
    /// Maps generic reasoning to a provider effort string. Empty map entry = unsupported.
    /// Emits compatibility warning when coerced; unsupported when unmapped.
    /// </summary>
    procedure MapReasoningToEffort(Reasoning: Enum "AIOS Reasoning Effort"; MinimalEffort: Text; LowEffort: Text; MediumEffort: Text; HighEffort: Text; XHighEffort: Text; var Warnings: JsonArray): Text
    var
        Mapped: Text;
        GenericName: Text;
    begin
        if not IsCustomReasoning(Reasoning) then
            exit('');
        if Reasoning = Reasoning::None then
            exit('');

        GenericName := GenericReasoningName(Reasoning);
        case Reasoning of
            Reasoning::Minimal:
                Mapped := MinimalEffort;
            Reasoning::Low:
                Mapped := LowEffort;
            Reasoning::Medium:
                Mapped := MediumEffort;
            Reasoning::High:
                Mapped := HighEffort;
            Reasoning::XHigh:
                Mapped := XHighEffort;
            else
                Mapped := '';
        end;

        if Mapped = '' then begin
            AddWarning(Warnings, 'unsupported', 'reasoning', StrSubstNo(UnsupportedReasoningMsg, GenericName));
            exit('');
        end;

        if Mapped <> GenericName then
            AddWarning(Warnings, 'compatibility', 'reasoning', StrSubstNo(CoercedReasoningMsg, GenericName, Mapped));

        exit(Mapped);
    end;

    /// <summary>
    /// Maps generic reasoning to a token budget as a percentage of max output tokens.
    /// </summary>
    procedure MapReasoningToBudget(Reasoning: Enum "AIOS Reasoning Effort"; MaxOutputTokens: Integer; MinBudget: Integer; MaxBudget: Integer; var Warnings: JsonArray): Integer
    var
        BaseTokens: Integer;
        Budget: Integer;
        Percentage: Decimal;
        GenericName: Text;
    begin
        if not IsCustomReasoning(Reasoning) then
            exit(0);
        if Reasoning = Reasoning::None then
            exit(0);

        GenericName := GenericReasoningName(Reasoning);
        Percentage := ReasoningPercentage(Reasoning);
        if Percentage <= 0 then begin
            AddWarning(Warnings, 'unsupported', 'reasoning', StrSubstNo(UnsupportedReasoningMsg, GenericName));
            exit(0);
        end;

        BaseTokens := MaxOutputTokens;
        if BaseTokens <= 0 then
            BaseTokens := 4096;

        Budget := Round(BaseTokens * Percentage, 1);

        if MinBudget <= 0 then
            MinBudget := 1024;
        if Budget < MinBudget then
            Budget := MinBudget;
        if (MaxBudget > 0) and (Budget > MaxBudget) then
            Budget := MaxBudget;

        exit(Budget);
    end;

    /// <summary>
    /// Adds OpenAI-compatible sampling fields to the chat completions root object.
    /// </summary>
    procedure ApplyOpenAICompatible(var Root: JsonObject; var Request: Record "AIOS Chat Request"; var Warnings: JsonArray)
    var
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

        if IsCustomReasoning(Request.Reasoning) and (Request.Reasoning <> Request.Reasoning::None) then begin
            ReasoningEffort := MapReasoningToEffort(
                Request.Reasoning,
                'minimal', 'low', 'medium', 'high', 'xhigh',
                Warnings);
            if ReasoningEffort <> '' then
                Root.Add('reasoning_effort', ReasoningEffort);
        end;
    end;

    /// <summary>
    /// Adds Anthropic-compatible sampling and thinking fields to the messages root object.
    /// </summary>
    procedure ApplyAnthropic(var Root: JsonObject; var Request: Record "AIOS Chat Request"; var Warnings: JsonArray)
    var
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

        if IsCustomReasoning(Request.Reasoning) and (Request.Reasoning <> Request.Reasoning::None) then begin
            MaxOutputTokens := Request."Max Tokens";
            BudgetTokens := MapReasoningToBudget(Request.Reasoning, MaxOutputTokens, 1024, 0, Warnings);
            if BudgetTokens > 0 then begin
                Thinking.Add('type', 'enabled');
                Thinking.Add('budget_tokens', BudgetTokens);
                Root.Add('thinking', Thinking);
            end;
        end;
    end;

    local procedure ReasoningPercentage(Reasoning: Enum "AIOS Reasoning Effort"): Decimal
    begin
        case Reasoning of
            Reasoning::Minimal:
                exit(0.02);
            Reasoning::Low:
                exit(0.10);
            Reasoning::Medium:
                exit(0.30);
            Reasoning::High:
                exit(0.60);
            Reasoning::XHigh:
                exit(0.90);
            else
                exit(0);
        end;
    end;

    local procedure GenericReasoningName(Reasoning: Enum "AIOS Reasoning Effort"): Text
    begin
        case Reasoning of
            Reasoning::None:
                exit('none');
            Reasoning::Minimal:
                exit('minimal');
            Reasoning::Low:
                exit('low');
            Reasoning::Medium:
                exit('medium');
            Reasoning::High:
                exit('high');
            Reasoning::XHigh:
                exit('xhigh');
            else
                exit('provider-default');
        end;
    end;

    local procedure AddWarning(var Warnings: JsonArray; WarningType: Text; Feature: Text; Message: Text)
    var
        Warning: JsonObject;
    begin
        Clear(Warning);
        Warning.Add('type', WarningType);
        Warning.Add('feature', Feature);
        Warning.Add('message', Message);
        Warnings.Add(Warning);
    end;

    var
        UnsupportedReasoningMsg: Label 'Reasoning level ''%1'' is not supported by this provider mapping.', Comment = '%1 = generic level';
        CoercedReasoningMsg: Label 'Reasoning level ''%1'' was coerced to ''%2'' for this provider.', Comment = '%1 = generic, %2 = mapped';
}

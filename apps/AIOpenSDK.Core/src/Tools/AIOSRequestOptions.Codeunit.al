namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Generic reasoning / warning helpers for request options.
/// Provider-specific wire fields live in provider option codeunits.
/// </summary>
codeunit 87413 "AIOS Request Options"
{
    Access = Public;

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

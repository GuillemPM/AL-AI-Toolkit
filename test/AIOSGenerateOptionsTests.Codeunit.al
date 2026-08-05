namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

codeunit 87493 "AIOS Generate Options Tests"
{
    Subtype = Test;

    [Test]
    procedure GetMaxRetries_DefaultsToTwo()
    var
        Request: Record "AIOS Chat Request";
    begin
        Clear(Request);
        if Request.GetMaxRetries() <> 2 then
            Error(UnexpectedIntErr, 2, Request.GetMaxRetries());
    end;

    [Test]
    procedure GetMaxRetries_ZeroDisables()
    var
        Request: Record "AIOS Chat Request";
    begin
        Clear(Request);
        Request.SetMaxRetries(0);
        if Request.GetMaxRetries() <> 0 then
            Error(UnexpectedIntErr, 0, Request.GetMaxRetries());
    end;

    [Test]
    procedure SetTopP_SetsHasFlag()
    var
        Request: Record "AIOS Chat Request";
    begin
        Clear(Request);
        Request.SetTopP(0.9);
        if not Request."Has Top P" then
            Error(ExpectedHasTopPErr);
        if Request."Top P" <> 0.9 then
            Error(UnexpectedDecimalErr, 0.9, Request."Top P");
    end;

    [Test]
    procedure StopSequences_RoundTrip()
    var
        Request: Record "AIOS Chat Request";
        Sequences: JsonArray;
        Token: JsonToken;
    begin
        Clear(Request);
        Request.AddStopSequence('END');
        Request.AddStopSequence('STOP');
        Sequences := Request.GetStopSequences();
        if Sequences.Count() <> 2 then
            Error(UnexpectedIntErr, 2, Sequences.Count());
        Sequences.Get(0, Token);
        if Token.AsValue().AsText() <> 'END' then
            Error(UnexpectedTextErr, 'END', Token.AsValue().AsText());
    end;

    [Test]
    procedure TryGenerate_RetriesThenSucceeds()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
    begin
        Mock.SetNextResponse('recovered');
        Mock.SetFailuresBeforeSuccess(2);
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(2);

        if not Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedSuccessErr);
        if Response.GetText() <> 'recovered' then
            Error(UnexpectedTextErr, 'recovered', Response.GetText());
    end;

    [Test]
    procedure TryGenerate_ExhaustsRetries()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
    begin
        Mock.SetNextResponse('should-not-appear');
        Mock.SetFailuresBeforeSuccess(3);
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(2);

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::RateLimited then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
    end;

    [Test]
    procedure TryGenerate_MaxRetriesZero_NoRetry()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Spy: Codeunit "AIOS Lifecycle Spy";
        ExpectedTrace: Text;
    begin
        Spy.Reset();
        Mock.SetNextError("AIOS Error Type"::ProviderUnavailable, 'fail once');
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(0);
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall';

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedFailureErr);
        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
    end;

    [Test]
    procedure MapReasoningToBudget_MediumAt32000()
    var
        RequestOptions: Codeunit "AIOS Request Options";
        Warnings: JsonArray;
        Budget: Integer;
    begin
        Budget := RequestOptions.MapReasoningToBudget("AIOS Reasoning Effort"::Medium, 32000, 1024, 0, Warnings);
        if Budget <> 9600 then
            Error(UnexpectedIntErr, 9600, Budget);
    end;

    [Test]
    procedure MapReasoningToBudget_MinimalClampsTo1024()
    var
        RequestOptions: Codeunit "AIOS Request Options";
        Warnings: JsonArray;
        Budget: Integer;
    begin
        // 32000 * 0.02 = 640 → clamp to MinBudget 1024
        Budget := RequestOptions.MapReasoningToBudget("AIOS Reasoning Effort"::Minimal, 32000, 1024, 0, Warnings);
        if Budget <> 1024 then
            Error(UnexpectedIntErr, 1024, Budget);
    end;

    [Test]
    procedure MapReasoningToBudget_ProviderDefaultIsZero()
    var
        RequestOptions: Codeunit "AIOS Request Options";
        Warnings: JsonArray;
        Budget: Integer;
    begin
        Budget := RequestOptions.MapReasoningToBudget("AIOS Reasoning Effort"::ProviderDefault, 32000, 1024, 0, Warnings);
        if Budget <> 0 then
            Error(UnexpectedIntErr, 0, Budget);
        if Warnings.Count() <> 0 then
            Error(UnexpectedIntErr, 0, Warnings.Count());
    end;

    [Test]
    procedure MapReasoningToEffort_OpenAI_XHigh()
    var
        RequestOptions: Codeunit "AIOS Request Options";
        Warnings: JsonArray;
        Effort: Text;
    begin
        Effort := RequestOptions.MapReasoningToEffort(
            "AIOS Reasoning Effort"::XHigh,
            'minimal', 'low', 'medium', 'high', 'xhigh',
            Warnings);
        if Effort <> 'xhigh' then
            Error(UnexpectedTextErr, 'xhigh', Effort);
    end;

    [Test]
    procedure ApplyOpenAI_ProviderDefault_OmitsReasoningEffort()
    var
        RequestOptions: Codeunit "AIOS Request Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
        Token: JsonToken;
    begin
        Clear(Request);
        Request.SetReasoning("AIOS Reasoning Effort"::ProviderDefault);
        RequestOptions.ApplyOpenAICompatible(Root, Request, Warnings);
        if Root.Get('reasoning_effort', Token) then
            Error(ExpectedNoReasoningEffortErr);
    end;

    [Test]
    procedure ApplyAnthropic_Medium_UsesPercentBudget()
    var
        RequestOptions: Codeunit "AIOS Request Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
        Token: JsonToken;
        Thinking: JsonObject;
        BudgetToken: JsonToken;
    begin
        Clear(Request);
        Request."Max Tokens" := 32000;
        Request.SetReasoning("AIOS Reasoning Effort"::Medium);
        RequestOptions.ApplyAnthropic(Root, Request, Warnings);
        if not Root.Get('thinking', Token) then
            Error(ExpectedThinkingErr);
        Thinking := Token.AsObject();
        if not Thinking.Get('budget_tokens', BudgetToken) then
            Error(ExpectedBudgetTokensErr);
        if BudgetToken.AsValue().AsInteger() <> 9600 then
            Error(UnexpectedIntErr, 9600, BudgetToken.AsValue().AsInteger());
    end;

    [Test]
    procedure ResponseWarnings_RoundTrip()
    var
        Response: Record "AIOS Chat Response";
        Warnings: JsonArray;
        Token: JsonToken;
        Warning: JsonObject;
        TypeToken: JsonToken;
    begin
        Clear(Response);
        Response.AddWarning('compatibility', 'reasoning', 'coerced');
        Warnings := Response.GetWarnings();
        if Warnings.Count() <> 1 then
            Error(UnexpectedIntErr, 1, Warnings.Count());
        Warnings.Get(0, Token);
        Warning := Token.AsObject();
        if not Warning.Get('type', TypeToken) then
            Error(ExpectedWarningTypeErr);
        if TypeToken.AsValue().AsText() <> 'compatibility' then
            Error(UnexpectedTextErr, 'compatibility', TypeToken.AsValue().AsText());
    end;

    var
        UnexpectedIntErr: Label 'Expected %1, got %2.', Comment = '%1 = expected, %2 = actual';
        UnexpectedDecimalErr: Label 'Expected %1, got %2.', Comment = '%1 = expected, %2 = actual';
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedHasTopPErr: Label 'Has Top P should be true after SetTopP.';
        ExpectedSuccessErr: Label 'TryGenerate should succeed after retries.';
        ExpectedFailureErr: Label 'TryGenerate should return false.';
        UnexpectedErrorTypeErr: Label 'Expected RateLimited, got %1.', Comment = '%1 = actual';
        UnexpectedTraceErr: Label 'Expected event trace ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedNoReasoningEffortErr: Label 'reasoning_effort should be omitted for ProviderDefault.';
        ExpectedThinkingErr: Label 'thinking object expected for Anthropic Medium reasoning.';
        ExpectedBudgetTokensErr: Label 'budget_tokens expected on thinking object.';
        ExpectedWarningTypeErr: Label 'Warning type field expected.';
}

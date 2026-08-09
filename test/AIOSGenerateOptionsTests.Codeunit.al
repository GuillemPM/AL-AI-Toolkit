namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using PM.Guillem.AIOpenSDK.Provider.OpenAI;

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
    procedure Retry_IsRetriable_RateLimitedTimeoutUnavailable()
    var
        Retry: Codeunit "AIOS Retry";
    begin
        if not Retry.IsRetriable("AIOS Error Type"::RateLimited) then
            Error(ExpectedRetriableErr, 'RateLimited');
        if not Retry.IsRetriable("AIOS Error Type"::Timeout) then
            Error(ExpectedRetriableErr, 'Timeout');
        if not Retry.IsRetriable("AIOS Error Type"::ProviderUnavailable) then
            Error(ExpectedRetriableErr, 'ProviderUnavailable');
        if Retry.IsRetriable("AIOS Error Type"::ParseFailed) then
            Error(ExpectedNotRetriableErr, 'ParseFailed');
        if Retry.IsRetriable("AIOS Error Type"::InvalidRequest) then
            Error(ExpectedNotRetriableErr, 'InvalidRequest');
    end;

    [Test]
    procedure Retry_BackoffMs_LinearThenCapped()
    var
        Retry: Codeunit "AIOS Retry";
    begin
        if Retry.BackoffMs(0) <> 200 then
            Error(UnexpectedIntErr, 200, Retry.BackoffMs(0));
        if Retry.BackoffMs(1) <> 400 then
            Error(UnexpectedIntErr, 400, Retry.BackoffMs(1));
        if Retry.BackoffMs(9) <> 2000 then
            Error(UnexpectedIntErr, 2000, Retry.BackoffMs(9));
        if Retry.BackoffMs(20) <> 2000 then
            Error(UnexpectedIntErr, 2000, Retry.BackoffMs(20));
    end;

    [Test]
    procedure HttpErrorMapper_FromHttpStatus_MapsKnownCodes()
    var
        HttpErrors: Codeunit "AIOS Http Error Mapper";
    begin
        if HttpErrors.FromHttpStatus(401) <> "AIOS Error Type"::AuthenticationFailed then
            Error(UnexpectedErrorMapErr, 401, 'AuthenticationFailed');
        if HttpErrors.FromHttpStatus(403) <> "AIOS Error Type"::AuthenticationFailed then
            Error(UnexpectedErrorMapErr, 403, 'AuthenticationFailed');
        if HttpErrors.FromHttpStatus(429) <> "AIOS Error Type"::RateLimited then
            Error(UnexpectedErrorMapErr, 429, 'RateLimited');
        if HttpErrors.FromHttpStatus(400) <> "AIOS Error Type"::InvalidRequest then
            Error(UnexpectedErrorMapErr, 400, 'InvalidRequest');
        if HttpErrors.FromHttpStatus(404) <> "AIOS Error Type"::InvalidRequest then
            Error(UnexpectedErrorMapErr, 404, 'InvalidRequest');
        if HttpErrors.FromHttpStatus(422) <> "AIOS Error Type"::InvalidRequest then
            Error(UnexpectedErrorMapErr, 422, 'InvalidRequest');
        if HttpErrors.FromHttpStatus(408) <> "AIOS Error Type"::Timeout then
            Error(UnexpectedErrorMapErr, 408, 'Timeout');
        if HttpErrors.FromHttpStatus(504) <> "AIOS Error Type"::Timeout then
            Error(UnexpectedErrorMapErr, 504, 'Timeout');
        if HttpErrors.FromHttpStatus(500) <> "AIOS Error Type"::ProviderUnavailable then
            Error(UnexpectedErrorMapErr, 500, 'ProviderUnavailable');
        if HttpErrors.FromHttpStatus(502) <> "AIOS Error Type"::ProviderUnavailable then
            Error(UnexpectedErrorMapErr, 502, 'ProviderUnavailable');
        if HttpErrors.FromHttpStatus(503) <> "AIOS Error Type"::ProviderUnavailable then
            Error(UnexpectedErrorMapErr, 503, 'ProviderUnavailable');
        if HttpErrors.FromHttpStatus(418) <> "AIOS Error Type"::Unknown then
            Error(UnexpectedErrorMapErr, 418, 'Unknown');
    end;

    [Test]
    procedure HttpErrorMapper_PreviewBody_TruncatesTo250()
    var
        HttpErrors: Codeunit "AIOS Http Error Mapper";
        LongText: Text;
        i: Integer;
    begin
        for i := 1 to 300 do
            LongText += 'a';
        if StrLen(HttpErrors.PreviewBody(LongText)) <> 250 then
            Error(UnexpectedIntErr, 250, StrLen(HttpErrors.PreviewBody(LongText)));
        if HttpErrors.PreviewBody('short') <> 'short' then
            Error(UnexpectedTextErr, 'short', HttpErrors.PreviewBody('short'));
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
        Retry: Codeunit "AIOS Retry";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        ExpectedTrace: Text;
    begin
        Retry.SetSkipSleep(true);
        Spy.StartRecording();
        Mock.SetNextResponse('recovered');
        Mock.SetFailuresBeforeSuccess(2);
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(2);
        // 3 model calls: fail, fail, succeed
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnAfterGenerate';

        if not Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedSuccessErr);
        if Response.GetText() <> 'recovered' then
            Error(UnexpectedTextErr, 'recovered', Response.GetText());
        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
        Spy.StopRecording();
        Retry.SetSkipSleep(false);
    end;

    [Test]
    procedure TryGenerate_ExhaustsRetries()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Retry: Codeunit "AIOS Retry";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        ExpectedTrace: Text;
    begin
        Retry.SetSkipSleep(true);
        Spy.StartRecording();
        Mock.SetNextResponse('should-not-appear');
        Mock.SetFailuresBeforeSuccess(3);
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(2);
        // 3 attempts, all fail — no OnAfterGenerate
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnBeforeLanguageModelCall|OnAfterLanguageModelCall';

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::RateLimited then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
        Spy.StopRecording();
        Retry.SetSkipSleep(false);
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
        Spy.StartRecording();
        Mock.SetNextError("AIOS Error Type"::ProviderUnavailable, 'fail once');
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(0);
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall';

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedFailureErr);
        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
        Spy.StopRecording();
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
        FormatOptions: Codeunit "AIOS OpenAI Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
        Token: JsonToken;
    begin
        Clear(Request);
        Request.SetReasoning("AIOS Reasoning Effort"::ProviderDefault);
        FormatOptions.Apply(Root, Request, Warnings);
        if Root.Get('reasoning_effort', Token) then
            Error(ExpectedNoReasoningEffortErr);
    end;

    [Test]
    procedure ApplyAnthropic_Medium_UsesPercentBudget()
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
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
        FormatOptions.Apply(Root, Request, Warnings);
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
        ExpectedRetriableErr: Label 'Expected %1 to be retriable.', Comment = '%1 = error type name';
        ExpectedNotRetriableErr: Label 'Expected %1 not to be retriable.', Comment = '%1 = error type name';
        ExpectedSuccessErr: Label 'TryGenerate should succeed after retries.';
        ExpectedFailureErr: Label 'TryGenerate should return false.';
        UnexpectedErrorTypeErr: Label 'Expected RateLimited, got %1.', Comment = '%1 = actual';
        UnexpectedErrorMapErr: Label 'Status %1 should map to %2.', Comment = '%1 = HTTP status, %2 = expected error type';
        UnexpectedTraceErr: Label 'Expected event trace ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedNoReasoningEffortErr: Label 'reasoning_effort should be omitted for ProviderDefault.';
        ExpectedThinkingErr: Label 'thinking object expected for Anthropic Medium reasoning.';
        ExpectedBudgetTokensErr: Label 'budget_tokens expected on thinking object.';
        ExpectedWarningTypeErr: Label 'Warning type field expected.';
}

namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Internal unit tests for retry classification/backoff (same app as AIOS Retry).
/// </summary>
codeunit 87415 "AIOS Retry Tests"
{
    Access = Internal;
    Subtype = Test;

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

    var
        ExpectedRetriableErr: Label 'Expected %1 to be retriable.', Comment = '%1 = error type';
        ExpectedNotRetriableErr: Label 'Expected %1 not to be retriable.', Comment = '%1 = error type';
        UnexpectedIntErr: Label 'Expected %1, got %2.', Comment = '%1 = expected, %2 = actual';
}

namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Shared retry classification and backoff for GenerateText / GenerateImage.
/// </summary>
codeunit 87460 "AIOS Retry"
{
    Access = Internal;
    SingleInstance = true;

    /// <summary>
    /// True when the error type should be retried (rate limit, timeout, provider unavailable).
    /// </summary>
    procedure IsRetriable(ErrorType: Enum "AIOS Error Type"): Boolean
    begin
        case ErrorType of
            ErrorType::RateLimited,
            ErrorType::Timeout,
            ErrorType::ProviderUnavailable:
                exit(true);
            else
                exit(false);
        end;
    end;

    /// <summary>
    /// Linear backoff in ms for zero-based Attempt: 200, 400, … capped at 2000.
    /// </summary>
    procedure BackoffMs(Attempt: Integer): Integer
    var
        DelayMs: Integer;
    begin
        DelayMs := 200 * (Attempt + 1);
        if DelayMs > 2000 then
            DelayMs := 2000;
        exit(DelayMs);
    end;

    /// <summary>
    /// Sleeps for BackoffMs(Attempt), unless skip-sleep is set (tests).
    /// </summary>
    procedure SleepBackoff(Attempt: Integer)
    begin
        if SkipSleep then
            exit;
        Sleep(BackoffMs(Attempt));
    end;

    /// <summary>
    /// When true, SleepBackoff is a no-op. Default false. Tests set true for speed.
    /// </summary>
    procedure SetSkipSleep(Skip: Boolean)
    begin
        SkipSleep := Skip;
    end;

    var
        SkipSleep: Boolean;
}

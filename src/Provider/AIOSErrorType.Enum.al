namespace PM.Guillem.AIOpenSDK.Core;

enum 87400 "AIOS Error Type"
{
    Extensible = false;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; RateLimited)
    {
        Caption = 'Rate Limited';
    }
    value(2; AuthenticationFailed)
    {
        Caption = 'Authentication Failed';
    }
    value(3; ProviderUnavailable)
    {
        Caption = 'Provider Unavailable';
    }
    value(4; InvalidRequest)
    {
        Caption = 'Invalid Request';
    }
    value(5; ParseFailed)
    {
        Caption = 'Parse Failed';
    }
    value(6; Timeout)
    {
        Caption = 'Timeout';
    }
    value(7; Unknown)
    {
        Caption = 'Unknown';
    }
}

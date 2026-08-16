namespace PM.Guillem.AIOpenSDK.ProviderUtils;

/// <summary>
/// Non-assignable grants for Provider Utils Chat Completions helpers.
/// </summary>
permissionset 87438 "AIOS ProvUtils Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK Provider Utils - Objects';

    Permissions =
        codeunit "AIOS Chat Completions Format" = X,
        codeunit "AIOS Chat Completions Options" = X,
        codeunit "AIOS Chat Completions Client" = X;
}

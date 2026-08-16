namespace PM.Guillem.AIOpenSDK.Provider.Anthropic;

/// <summary>
/// Non-assignable grants for the Anthropic provider codeunits.
/// </summary>
permissionset 87456 "AIOS Anthropic Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK Anthropic - Objects';

    Permissions =
        codeunit "AIOS Anthropic" = X,
        codeunit "AIOS Anthropic Model" = X,
        codeunit "AIOS Anthropic Format" = X,
        codeunit "AIOS Anthropic Options" = X;
}

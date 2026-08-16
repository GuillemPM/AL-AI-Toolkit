namespace PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;

/// <summary>
/// Non-assignable grants for the OpenCode Zen provider codeunits.
/// </summary>
permissionset 87458 "AIOS OCZen Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK OpenCode Zen - Objects';

    Permissions =
        codeunit "AIOS OpenCode Zen" = X,
        codeunit "AIOS OpenCode Zen Model" = X;
}

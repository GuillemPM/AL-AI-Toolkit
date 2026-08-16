namespace PM.Guillem.AIOpenSDK.Provider.OpenAICompatible;

/// <summary>
/// Non-assignable grants for the OpenAI-compatible provider codeunits.
/// </summary>
permissionset 87429 "AIOS Compatible Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK OpenAI Compatible - Objects';

    Permissions =
        codeunit "AIOS OpenAI Compatible" = X,
        codeunit "AIOS OpenAI Compatible Model" = X;
}

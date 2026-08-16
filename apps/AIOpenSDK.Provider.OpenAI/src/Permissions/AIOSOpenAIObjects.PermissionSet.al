namespace PM.Guillem.AIOpenSDK.Provider.OpenAI;

/// <summary>
/// Non-assignable grants for the OpenAI provider codeunits.
/// </summary>
permissionset 87454 "AIOS OpenAI Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK OpenAI - Objects';

    Permissions =
        codeunit "AIOS OpenAI" = X,
        codeunit "AIOS OpenAI Model" = X,
        codeunit "AIOS OpenAI Image Model" = X;
}

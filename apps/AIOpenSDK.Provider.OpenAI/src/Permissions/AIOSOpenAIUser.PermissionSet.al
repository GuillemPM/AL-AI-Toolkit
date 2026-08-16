namespace PM.Guillem.AIOpenSDK.Provider.OpenAI;

using PM.Guillem.AIOpenSDK.ProviderUtils;

/// <summary>
/// Assignable role for OpenAI provider usage (includes Core + Provider Utils).
/// </summary>
permissionset 87455 "AIOS OpenAI User"
{
    Access = Public;
    Assignable = true;
    Caption = 'AI Open SDK OpenAI - User';
    IncludedPermissionSets = "AIOS ProvUtils User", "AIOS OpenAI Objects";
}

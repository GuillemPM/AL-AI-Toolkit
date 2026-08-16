namespace PM.Guillem.AIOpenSDK.Provider.OpenAICompatible;

/// <summary>
/// Assignable role for OpenAI-compatible provider usage (includes Core + Provider Utils).
/// </summary>
permissionset 87430 "AIOS Compatible User"
{
    Access = Public;
    Assignable = true;
    Caption = 'AI Open SDK OpenAI Compatible - User';
    IncludedPermissionSets = "AIOS ProvUtils User", "AIOS Compatible Objects";
}

namespace PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;

using PM.Guillem.AIOpenSDK.ProviderUtils;

/// <summary>
/// Assignable role for OpenCode Zen provider usage (includes Core + Provider Utils).
/// </summary>
permissionset 87459 "AIOS OCZen User"
{
    Access = Public;
    Assignable = true;
    Caption = 'AI Open SDK OpenCode Zen - User';
    IncludedPermissionSets = "AIOS ProvUtils User", "AIOS OCZen Objects";
}

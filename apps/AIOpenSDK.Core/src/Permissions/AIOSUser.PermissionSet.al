namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Assignable role for calling the AI Open SDK client, tools, and structured output.
/// Does not include the mock provider — use "AIOS User Mock" when tests need it.
/// </summary>
permissionset 87467 "AIOS User"
{
    Access = Public;
    Assignable = true;
    Caption = 'AI Open SDK - User';
    IncludedPermissionSets = "AIOS Objects";
}

namespace PM.Guillem.AIOpenSDK.Examples;

/// <summary>
/// Assignable role for the Examples demo (Core mock + OpenAI + Anthropic + OpenCode Zen).
/// </summary>
permissionset 87511 "AIOS Examples User"
{
    Access = Public;
    Assignable = true;
    Caption = 'AI Open SDK Examples - User';
    IncludedPermissionSets =
        "AIOS User Mock",
        "AIOS OpenAI User",
        "AIOS Anthropic User",
        "AIOS OpenCodeZen User",
        "AIOS Examples Objects";
}

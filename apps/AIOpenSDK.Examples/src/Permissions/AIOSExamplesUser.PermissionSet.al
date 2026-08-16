namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.OpenAI;
using PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;

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

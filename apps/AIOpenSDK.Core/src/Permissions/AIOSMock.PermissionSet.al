namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Non-assignable grants for the in-app mock provider (tests and examples).
/// Included by "AIOS User Mock"; keep off production roles that only call real providers.
/// </summary>
permissionset 87466 "AIOS Mock"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK - Mock';

    Permissions =
        codeunit "AIOS Mock" = X,
        codeunit "AIOS Mock Model" = X,
        codeunit "AIOS Mock Image Model" = X;
}

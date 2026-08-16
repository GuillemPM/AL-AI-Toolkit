namespace PM.Guillem.AIOpenSDK.Examples;

/// <summary>
/// Non-assignable grants for the Examples demo pages, tables, and tools.
/// </summary>
permissionset 87510 "AIOS Examples Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK Examples - Objects';

    Permissions =
        tabledata "AIOS Demo History" = RIMD,
        tabledata "AIOS Feedback Buffer" = RIMD,
        table "AIOS Demo History" = X,
        table "AIOS Feedback Buffer" = X,
        page "AIOS Toolkit Demo" = X,
        page "AIOS Demo History" = X,
        page "AIOS Demo History Card" = X,
        page "AIOS Demo History Picture" = X,
        codeunit "AIOS Usage Example" = X,
        codeunit "AIOS Lifecycle Example" = X,
        codeunit "AIOS Demo Tools" = X,
        codeunit "AIOS Sample Tool Handler" = X,
        codeunit "AIOS Echo Tool" = X,
        codeunit "AIOS Get Customers Tool" = X;
}

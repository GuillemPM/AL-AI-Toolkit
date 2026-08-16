namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Non-assignable grants for Core runtime tables and codeunits (excludes mock and tests).
/// Included by "AIOS User" / "AIOS User Mock"; dependent apps may include this set directly.
/// </summary>
permissionset 87465 "AIOS Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'AI Open SDK - Objects';

    Permissions =
        tabledata "AIOS Chat Request" = RIMD,
        tabledata "AIOS Chat Response" = RIMD,
        tabledata "AIOS Image Request" = RIMD,
        tabledata "AIOS Image Response" = RIMD,
        table "AIOS Chat Request" = X,
        table "AIOS Chat Response" = X,
        table "AIOS Image Request" = X,
        table "AIOS Image Response" = X,
        codeunit "AIOS Generated Image" = X,
        codeunit "AIOS Image Response Call" = X,
        codeunit "AIOS Chat Response Call" = X,
        codeunit "AIOS Client" = X,
        codeunit "AIOS Generate Result" = X,
        codeunit "AIOS Generate Image Result" = X,
        codeunit "AIOS Request Options" = X,
        codeunit "AIOS Image Usage" = X,
        codeunit "AIOS Tool Call" = X,
        codeunit "AIOS Tool Set" = X,
        codeunit "AIOS Tool Args" = X,
        codeunit "AIOS Message Content" = X,
        codeunit "AIOS Chat Attachments" = X,
        codeunit "AIOS Chat Prompt" = X,
        codeunit "AIOS Chat Output" = X,
        codeunit "AIOS Chat Parameters" = X,
        codeunit "AIOS Chat Request Tools" = X,
        codeunit "AIOS Chat Messages" = X,
        codeunit "AIOS Retry" = X,
        codeunit "AIOS Json Binder" = X,
        codeunit "AIOS Schema" = X,
        codeunit "AIOS Schema Validator" = X,
        codeunit "AIOS Http Error Mapper" = X,
        codeunit "AIOS Privacy Notice" = X;
}

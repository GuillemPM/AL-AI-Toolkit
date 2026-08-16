namespace PM.Guillem.AIOpenSDK.Core;

using System.Privacy;

/// <summary>
/// Gates outbound AI HTTP on Business Central privacy-notice approval (no UI).
/// Company admins approve integrations on Privacy Notices Status; workflows and jobs only check state.
/// </summary>
codeunit 87469 "AIOS Privacy Notice"
{
    Access = Public;

    /// <summary>
    /// Returns true when the notice exists and approval state is Agreed for the current context.
    /// Never shows a consent dialog. Creates the notice record if it is missing.
    /// </summary>
    procedure IsApproved(NoticeId: Code[50]; IntegrationName: Text[250]; PrivacyLink: Text[2048]): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        if NoticeId = '' then
            exit(false);

        EnsureNoticeExists(NoticeId, IntegrationName, PrivacyLink);
        exit(PrivacyNotice.GetPrivacyNoticeApprovalState(NoticeId) = "Privacy Notice Approval State"::Agreed);
    end;

    /// <summary>
    /// Ensures company approval before chat completions HTTP. Sets InvalidRequest on Response when not approved.
    /// </summary>
    procedure EnsureApproved(NoticeId: Code[50]; IntegrationName: Text[250]; PrivacyLink: Text[2048]; var Response: Record "AIOS Chat Response"): Boolean
    begin
        if IsApproved(NoticeId, IntegrationName, PrivacyLink) then
            exit(true);

        if NoticeId = '' then
            Response.SetError("AIOS Error Type"::InvalidRequest, MissingNoticeIdErr)
        else
            Response.SetError("AIOS Error Type"::InvalidRequest, StrSubstNo(NotApprovedErr, NoticeId));
        exit(false);
    end;

    /// <summary>
    /// Ensures company approval before image HTTP. Sets InvalidRequest on Response when not approved.
    /// </summary>
    procedure EnsureApproved(NoticeId: Code[50]; IntegrationName: Text[250]; PrivacyLink: Text[2048]; var Response: Record "AIOS Image Response"): Boolean
    begin
        if IsApproved(NoticeId, IntegrationName, PrivacyLink) then
            exit(true);

        if NoticeId = '' then
            Response.SetError("AIOS Error Type"::InvalidRequest, MissingNoticeIdErr)
        else
            Response.SetError("AIOS Error Type"::InvalidRequest, StrSubstNo(NotApprovedErr, NoticeId));
        exit(false);
    end;

    /// <summary>
    /// Interactive confirmation (may show UI). Use only from setup/demo pages outside write transactions.
    /// </summary>
    procedure ConfirmApproval(NoticeId: Code[50]; IntegrationName: Text[250]; PrivacyLink: Text[2048]): Boolean
    var
        PrivacyNotice: Codeunit "Privacy Notice";
    begin
        if NoticeId = '' then
            exit(false);

        EnsureNoticeExists(NoticeId, IntegrationName, PrivacyLink);
        exit(PrivacyNotice.ConfirmPrivacyNoticeApproval(NoticeId));
    end;

    local procedure EnsureNoticeExists(NoticeId: Code[50]; IntegrationName: Text[250]; PrivacyLink: Text[2048])
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        Name: Text[250];
    begin
        Name := IntegrationName;
        if Name = '' then
            Name := NoticeId;

        if PrivacyLink = '' then
            PrivacyNotice.CreatePrivacyNotice(NoticeId, Name)
        else
            PrivacyNotice.CreatePrivacyNotice(NoticeId, Name, PrivacyLink);
    end;

    var
        MissingNoticeIdErr: Label 'A privacy notice id is required before sending data to an external AI provider.';
        NotApprovedErr: Label 'Privacy notice %1 is not approved. An administrator must agree on the Privacy Notices Status page before data can be sent to this AI provider.', Comment = '%1 = privacy notice id';
}

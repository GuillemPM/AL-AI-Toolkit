namespace PM.Guillem.AIOpenSDK.Provider.OpenAICompatible;

using PM.Guillem.AIOpenSDK.Core;
using System.Privacy;

/// <summary>
/// Generic OpenAI Chat Completions–compatible provider (AI SDK @ai-sdk/openai-compatible equivalent).
/// Independent of the OpenAI and OpenCode Zen providers — install and use with any compatible base URL.
/// </summary>
codeunit 87450 "AIOS OpenAI Compatible" implements "AIOS Provider"
{
    Access = Public;

    var
        ApiKey: SecretText;
        BaseUrl: Text;
        ProviderName: Text;

    /// <summary>
    /// Returns the OpenAI-compatible provider specification version.
    /// </summary>
    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

    /// <summary>
    /// Returns the configured provider display name.
    /// </summary>
    procedure GetName(): Text
    begin
        if ProviderName = '' then
            exit('openai-compatible');
        exit(ProviderName);
    end;

    /// <summary>
    /// Display name for this provider instance (e.g. 'together', 'groq').
    /// </summary>
    procedure SetName(Name: Text)
    begin
        ProviderName := Name;
    end;

    /// <summary>
    /// Stores the API key used for subsequent Model binds.
    /// </summary>
    procedure SetApiKey(KeyValue: SecretText)
    begin
        ApiKey := KeyValue;
    end;

    /// <summary>
    /// Required base URL including API version path (e.g. https://api.example.com/v1).
    /// </summary>
    procedure SetBaseUrl(Url: Text)
    begin
        BaseUrl := Url;
    end;

    /// <summary>
    /// One-shot factory: bind a model with API key and base URL.
    /// </summary>
    procedure Model(ModelId: Text; KeyValue: SecretText; Url: Text): Interface "AIOS Language Model"
    begin
        SetApiKey(KeyValue);
        SetBaseUrl(Url);
        exit(Model(ModelId));
    end;

    /// <summary>
    /// Bind a model using SetApiKey / SetBaseUrl (and optional SetName).
    /// </summary>
    procedure Model(ModelId: Text): Interface "AIOS Language Model"
    var
        LanguageModel: Interface "AIOS Language Model";
    begin
        if not BindLanguageModel(ModelId, LanguageModel) then
            Error(BindFailedErr, ModelId, GetName());
        exit(LanguageModel);
    end;

    /// <summary>
    /// Binds a language model for ModelId into BoundModel using the configured key, base URL, and name. Returns false when ModelId, API key, or base URL is missing.
    /// </summary>
    procedure BindLanguageModel(ModelId: Text; var BoundModel: Interface "AIOS Language Model"): Boolean
    var
        LanguageModel: Codeunit "AIOS OpenAI Compatible Model";
    begin
        if (ModelId = '') or ApiKey.IsEmpty() or (BaseUrl = '') then
            exit(false);

        LanguageModel.Initialize(ModelId, ApiKey, BaseUrl, GetName());
        BoundModel := LanguageModel;
        exit(true);
    end;

    /// <summary>
    /// Stable privacy notice id for outbound OpenAI-compatible HTTP (approve on Privacy Notices Status).
    /// </summary>
    procedure PrivacyNoticeId(): Code[50]
    begin
        exit(PrivacyNoticeIdTok);
    end;

    /// <summary>
    /// Integration name shown on Privacy Notices Status.
    /// </summary>
    procedure PrivacyIntegrationName(): Text[250]
    begin
        exit(PrivacyIntegrationNameTok);
    end;

    /// <summary>
    /// Link describing privacy notices for custom OpenAI-compatible endpoints.
    /// </summary>
    procedure PrivacyLink(): Text[2048]
    begin
        exit(PrivacyLinkTok);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", 'OnRegisterPrivacyNotices', '', false, false)]
    local procedure RegisterPrivacyNotice(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := PrivacyNoticeIdTok;
        TempPrivacyNotice."Integration Service Name" := PrivacyIntegrationNameTok;
        TempPrivacyNotice.Link := PrivacyLinkTok;
        if not TempPrivacyNotice.Insert() then;
    end;

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id, API key, or base URL).', Comment = '%1 = model id, %2 = provider name';
        PrivacyNoticeIdTok: Label 'AIOS-OPENAI-COMPAT', Locked = true;
        PrivacyIntegrationNameTok: Label 'AI Open SDK OpenAI Compatible', Locked = true;
        PrivacyLinkTok: Label 'https://learn.microsoft.com/dynamics365/business-central/privacy-notices-status', Locked = true;
}

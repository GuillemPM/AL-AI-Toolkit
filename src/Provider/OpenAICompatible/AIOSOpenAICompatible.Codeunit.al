namespace PM.Guillem.AIOpenSDK.Provider.OpenAICompatible;

using PM.Guillem.AIOpenSDK.Core;

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

    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

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

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id, API key, or base URL).', Comment = '%1 = model id, %2 = provider name';
}

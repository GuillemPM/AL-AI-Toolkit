namespace PM.Guillem.AIOpenSDK.Provider.Anthropic;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87440 "AIOS Anthropic" implements "AIOS Provider"
{
    Access = Public;

    var
        ApiKey: SecretText;
        ApiVersion: Text;
        BaseUrl: Text;

    /// <summary>
    /// Returns the Anthropic provider specification version.
    /// </summary>
    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

    /// <summary>
    /// Returns the provider name (anthropic).
    /// </summary>
    procedure GetName(): Text
    begin
        exit('anthropic');
    end;

    /// <summary>
    /// Stores the API key used for subsequent Model binds.
    /// </summary>
    procedure SetApiKey(KeyValue: SecretText)
    begin
        ApiKey := KeyValue;
    end;

    /// <summary>
    /// Optional anthropic-version header override. Defaults to 2023-06-01.
    /// </summary>
    procedure SetApiVersion(Version: Text)
    begin
        ApiVersion := Version;
    end;

    /// <summary>
    /// Optional base URL override (default https://api.anthropic.com/v1).
    /// </summary>
    procedure SetBaseUrl(Url: Text)
    begin
        BaseUrl := Url;
    end;

    /// <summary>
    /// One-shot factory: bind a model with an API key.
    /// </summary>
    procedure Model(ModelId: Text; KeyValue: SecretText): Interface "AIOS Language Model"
    begin
        SetApiKey(KeyValue);
        exit(Model(ModelId));
    end;

    /// <summary>
    /// Bind a model using a key previously set via SetApiKey.
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
    /// Binds a language model for ModelId into BoundModel using the configured key, API version, and base URL. Returns false when ModelId or the API key is missing.
    /// </summary>
    procedure BindLanguageModel(ModelId: Text; var BoundModel: Interface "AIOS Language Model"): Boolean
    var
        LanguageModel: Codeunit "AIOS Anthropic Model";
    begin
        if (ModelId = '') or ApiKey.IsEmpty() then
            exit(false);

        if ApiVersion = '' then
            ApiVersion := '2023-06-01';
        if BaseUrl = '' then
            BaseUrl := 'https://api.anthropic.com/v1';

        LanguageModel.Initialize(ModelId, ApiKey, ApiVersion, BaseUrl);
        BoundModel := LanguageModel;
        exit(true);
    end;

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id or API key).', Comment = '%1 = model id, %2 = provider name';
}

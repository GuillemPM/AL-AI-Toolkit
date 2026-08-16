namespace PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87444 "AIOS OpenCode Zen" implements "AIOS Provider"
{
    Access = Public;

    var
        ApiKey: SecretText;
        BaseUrl: Text;

    /// <summary>
    /// Returns the OpenCode Zen provider specification version.
    /// </summary>
    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

    /// <summary>
    /// Returns the provider name (opencode-zen).
    /// </summary>
    procedure GetName(): Text
    begin
        exit('opencode-zen');
    end;

    /// <summary>
    /// Configure the OpenCode Zen API key from https://opencode.ai/auth.
    /// </summary>
    procedure SetApiKey(KeyValue: SecretText)
    begin
        ApiKey := KeyValue;
    end;

    /// <summary>
    /// Optional base URL override (default https://opencode.ai/zen/v1).
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
    /// Binds a language model for ModelId into BoundModel using the configured key and base URL. Returns false when ModelId or the API key is missing.
    /// </summary>
    procedure BindLanguageModel(ModelId: Text; var BoundModel: Interface "AIOS Language Model"): Boolean
    var
        LanguageModel: Codeunit "AIOS OpenCode Zen Model";
    begin
        if (ModelId = '') or ApiKey.IsEmpty() then
            exit(false);

        if BaseUrl = '' then
            BaseUrl := 'https://opencode.ai/zen/v1';

        LanguageModel.Initialize(ModelId, ApiKey, BaseUrl);
        BoundModel := LanguageModel;
        exit(true);
    end;

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id or API key).', Comment = '%1 = model id, %2 = provider name';
}

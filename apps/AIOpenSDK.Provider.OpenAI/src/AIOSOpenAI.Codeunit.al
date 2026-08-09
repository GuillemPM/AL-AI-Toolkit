namespace PM.Guillem.AIOpenSDK.Provider.OpenAI;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87442 "AIOS OpenAI" implements "AIOS Provider"
{
    Access = Public;

    var
        ApiKey: SecretText;
        BaseUrl: Text;

    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

    procedure GetName(): Text
    begin
        exit('openai');
    end;

    procedure SetApiKey(KeyValue: SecretText)
    begin
        ApiKey := KeyValue;
    end;

    /// <summary>
    /// Optional base URL override (default https://api.openai.com/v1).
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

    procedure BindLanguageModel(ModelId: Text; var BoundModel: Interface "AIOS Language Model"): Boolean
    var
        LanguageModel: Codeunit "AIOS OpenAI Model";
    begin
        if (ModelId = '') or ApiKey.IsEmpty() then
            exit(false);

        if BaseUrl = '' then
            BaseUrl := 'https://api.openai.com/v1';

        LanguageModel.Initialize(ModelId, ApiKey, BaseUrl);
        BoundModel := LanguageModel;
        exit(true);
    end;

    /// <summary>
    /// Bind an image model with an API key.
    /// </summary>
    procedure ImageModel(ModelId: Text; KeyValue: SecretText): Interface "AIOS Image Model"
    begin
        SetApiKey(KeyValue);
        exit(ImageModel(ModelId));
    end;

    /// <summary>
    /// Bind an image model using a key previously set via SetApiKey.
    /// </summary>
    procedure ImageModel(ModelId: Text): Interface "AIOS Image Model"
    var
        ImageModelInstance: Interface "AIOS Image Model";
    begin
        if not BindImageModel(ModelId, ImageModelInstance) then
            Error(BindFailedErr, ModelId, GetName());
        exit(ImageModelInstance);
    end;

    procedure BindImageModel(ModelId: Text; var BoundModel: Interface "AIOS Image Model"): Boolean
    var
        ImageModelCU: Codeunit "AIOS OpenAI Image Model";
    begin
        if (ModelId = '') or ApiKey.IsEmpty() then
            exit(false);

        if BaseUrl = '' then
            BaseUrl := 'https://api.openai.com/v1';

        ImageModelCU.Initialize(ModelId, ApiKey, BaseUrl);
        BoundModel := ImageModelCU;
        exit(true);
    end;

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id or API key).', Comment = '%1 = model id, %2 = provider name';
}

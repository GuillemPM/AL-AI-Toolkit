codeunit 70142 "AI OpenAI" implements "AI Provider"
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
    /// One-shot factory: bind a model with an API key (Vercel AI SDK-style).
    /// </summary>
    procedure Model(ModelId: Text; KeyValue: SecretText): Interface "AI Language Model"
    begin
        SetApiKey(KeyValue);
        exit(Model(ModelId));
    end;

    /// <summary>
    /// Bind a model using a key previously set via SetApiKey.
    /// </summary>
    procedure Model(ModelId: Text): Interface "AI Language Model"
    var
        LanguageModel: Interface "AI Language Model";
    begin
        if not BindLanguageModel(ModelId, LanguageModel) then
            Error(BindFailedErr, ModelId, GetName());
        exit(LanguageModel);
    end;

    procedure BindLanguageModel(ModelId: Text; var BoundModel: Interface "AI Language Model"): Boolean
    var
        LanguageModel: Codeunit "AI OpenAI Model";
    begin
        if (ModelId = '') or ApiKey.IsEmpty() then
            exit(false);

        if BaseUrl = '' then
            BaseUrl := 'https://api.openai.com/v1';

        LanguageModel.Initialize(ModelId, ApiKey, BaseUrl);
        BoundModel := LanguageModel;
        exit(true);
    end;

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id or API key).', Comment = '%1 = model id, %2 = provider name';
}

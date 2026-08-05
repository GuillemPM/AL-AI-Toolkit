namespace PM.Guillem.AIOpenSDK.Provider.Anthropic;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87440 "AIOS Anthropic" implements "AIOS Provider"
{
    Access = Public;

    var
        ApiKey: SecretText;
        ApiVersion: Text;

    procedure SpecificationVersion(): Text
    begin
        exit('v1');
    end;

    procedure GetName(): Text
    begin
        exit('anthropic');
    end;

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
        LanguageModel: Codeunit "AIOS Anthropic Model";
    begin
        if (ModelId = '') or ApiKey.IsEmpty() then
            exit(false);

        if ApiVersion = '' then
            ApiVersion := '2023-06-01';

        LanguageModel.Initialize(ModelId, ApiKey, ApiVersion);
        BoundModel := LanguageModel;
        exit(true);
    end;

    var
        BindFailedErr: Label 'Model %1 is not supported by provider %2 (missing model id or API key).', Comment = '%1 = model id, %2 = provider name';
}

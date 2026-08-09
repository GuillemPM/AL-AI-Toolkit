namespace PM.Guillem.AIOpenSDK.Provider.OpenAICompatible;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.ProviderUtils;

codeunit 87451 "AIOS OpenAI Compatible Model" implements "AIOS Language Model"
{
    Access = Internal;

    var
        BoundModelId: Text;
        ProviderName: Text;
        ApiKey: SecretText;
        BaseUrl: Text;

    procedure Initialize(ModelId: Text; KeyValue: SecretText; Url: Text; Name: Text)
    begin
        BoundModelId := ModelId;
        ApiKey := KeyValue;
        BaseUrl := Url;
        if Name = '' then
            ProviderName := 'openai-compatible'
        else
            ProviderName := Name;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        Completions: Codeunit "AIOS Chat Completions Client";
    begin
        exit(Completions.Generate(BoundModelId, ApiKey, BaseUrl, ProviderName, Request, Response));
    end;
}

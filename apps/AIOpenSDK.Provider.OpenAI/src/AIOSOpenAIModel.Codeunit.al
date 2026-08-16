namespace PM.Guillem.AIOpenSDK.Provider.OpenAI;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.ProviderUtils;

codeunit 87443 "AIOS OpenAI Model" implements "AIOS Language Model"
{
    Access = Internal;

    var
        BoundModelId: Text;
        ApiKey: SecretText;
        BaseUrl: Text;

    procedure Initialize(ModelId: Text; KeyValue: SecretText; Url: Text)
    begin
        BoundModelId := ModelId;
        ApiKey := KeyValue;
        BaseUrl := Url;
    end;

    procedure GetModelId(): Text
    begin
        exit(BoundModelId);
    end;

    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        Completions: Codeunit "AIOS Chat Completions Client";
        OpenAI: Codeunit "AIOS OpenAI";
    begin
        exit(Completions.Generate(
            BoundModelId, ApiKey, BaseUrl, 'openai',
            OpenAI.PrivacyNoticeId(), OpenAI.PrivacyIntegrationName(), OpenAI.PrivacyLink(),
            Request, Response));
    end;
}

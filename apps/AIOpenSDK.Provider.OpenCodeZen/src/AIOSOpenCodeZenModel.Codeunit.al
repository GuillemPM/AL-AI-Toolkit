namespace PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.ProviderUtils;

codeunit 87445 "AIOS OpenCode Zen Model" implements "AIOS Language Model"
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

    /// <summary>
    /// Calls OpenCode Zen via the OpenAI-compatible chat completions endpoint.
    /// Works for models listed under /v1/chat/completions (e.g. big-pickle, minimax-m2.5).
    /// Claude-family models use /v1/messages and GPT-family use /v1/responses — not covered here.
    /// </summary>
    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        Completions: Codeunit "AIOS Chat Completions Client";
        OpenCodeZen: Codeunit "AIOS OpenCode Zen";
    begin
        exit(Completions.Generate(
            BoundModelId, ApiKey, BaseUrl, 'opencode-zen',
            OpenCodeZen.PrivacyNoticeId(), OpenCodeZen.PrivacyIntegrationName(), OpenCodeZen.PrivacyLink(),
            Request, Response));
    end;
}

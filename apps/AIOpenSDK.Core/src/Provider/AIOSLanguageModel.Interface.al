namespace PM.Guillem.AIOpenSDK.Core;

interface "AIOS Language Model"
{
    /// <summary>
    /// Model id this instance was bound with (e.g. deployment or model name).
    /// </summary>
    procedure GetModelId(): Text

    /// <summary>
    /// Run a chat/text generation against this model.
    /// Returns true on success; on failure returns false and populates Response error fields.
    /// </summary>
    procedure Generate(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
}

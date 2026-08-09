namespace PM.Guillem.AIOpenSDK.Core;

interface "AIOS Provider"
{
    /// <summary>
    /// Contract version for this provider factory (e.g. 'v1').
    /// </summary>
    procedure SpecificationVersion(): Text

    /// <summary>
    /// Stable provider id for telemetry and config (e.g. 'azure-openai', 'mock').
    /// </summary>
    procedure GetName(): Text

    /// <summary>
    /// Bind a language model for ModelId into Model (provider as factory).
    /// Returns false if the model id is not supported by this provider.
    /// </summary>
    procedure BindLanguageModel(ModelId: Text; var Model: Interface "AIOS Language Model"): Boolean
}

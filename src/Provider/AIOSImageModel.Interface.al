namespace PM.Guillem.AIOpenSDK.Core;

interface "AIOS Image Model"
{
    /// <summary>
    /// Model id this instance was bound with.
    /// </summary>
    procedure GetModelId(): Text

    /// <summary>
    /// Runs one image-generation HTTP call. Request image count is the batch size for this call.
    /// </summary>
    procedure GenerateImage(var Request: Record "AIOS Image Request"; var Response: Record "AIOS Image Response"): Boolean

    /// <summary>
    /// Maximum images the provider accepts per HTTP call for this model.
    /// </summary>
    procedure GetDefaultMaxImagesPerCall(): Integer
}

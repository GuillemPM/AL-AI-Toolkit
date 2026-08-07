namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Dispatches Execute for tools registered by name on "AIOS Tool Set" (many tools, one codeunit).
/// </summary>
interface "AIOS Tool Handler"
{
    /// <summary>
    /// Runs the tool identified by Name. Returns false on failure; ResultText may still hold an error message.
    /// </summary>
    procedure Execute(Name: Text; Arguments: JsonObject; var ResultText: Text): Boolean
}

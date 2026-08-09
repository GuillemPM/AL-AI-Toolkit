namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Secondary pattern: many tools in one codeunit (saves object IDs).
/// Implement GetDefinitions + Execute, then ToolSet.Use(Handler) and GenerateText(..., ToolSet).
/// </summary>
interface "AIOS Tool Handler"
{
    /// <summary>
    /// Tool definitions for the model: JSON array of { name, description, parameters }.
    /// Build entries with "AIOS Schema".ToolDefinition.
    /// </summary>
    procedure GetDefinitions(): JsonArray

    /// <summary>
    /// Runs the tool identified by Name. Returns false on failure; ResultText may still hold an error message.
    /// </summary>
    procedure Execute(Name: Text; Arguments: JsonObject; var ResultText: Text): Boolean
}

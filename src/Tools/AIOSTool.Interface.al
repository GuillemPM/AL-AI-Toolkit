namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// A callable tool (name, schema, Execute). Primary pattern: ToolSet.Add(Tool).
/// For many tools without burning object IDs, use "AIOS Tool Handler" + ToolSet.Use.
/// </summary>
interface "AIOS Tool"
{
    /// <summary>
    /// Stable tool name sent to the provider (e.g. GetCustomerBalance).
    /// </summary>
    procedure Name(): Text

    /// <summary>
    /// Human-readable description that influences tool selection.
    /// </summary>
    procedure Description(): Text

    /// <summary>
    /// JSON Schema for tool arguments (typically from "AIOS Schema".Object).
    /// </summary>
    procedure InputSchema(): JsonObject

    /// <summary>
    /// Runs the tool. Returns false on failure; ResultText may still hold an error message.
    /// </summary>
    procedure Execute(Arguments: JsonObject; var ResultText: Text): Boolean
}

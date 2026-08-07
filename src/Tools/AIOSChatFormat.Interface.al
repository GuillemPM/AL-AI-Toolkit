namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Maps AIOS-neutral messages and tool definitions to a provider wire format, and parses tool calls back.
/// Implement this when adding a custom provider (or reuse a shipped format such as OpenAI-compatible).
/// </summary>
interface "AIOS Chat Format"
{
    /// <summary>
    /// Map AIOS tool definitions { name, description, parameters } to the provider's tools array.
    /// </summary>
    procedure MapTools(Definitions: JsonArray): JsonArray

    /// <summary>
    /// Map AIOS message history to the provider's messages array.
    /// </summary>
    procedure MapMessages(AiosMessages: JsonArray): JsonArray

    /// <summary>
    /// System text for providers that use a top-level system field (e.g. Anthropic).
    /// Return '' when system stays inside MapMessages (e.g. OpenAI-compatible).
    /// </summary>
    procedure GetSystemText(AiosMessages: JsonArray): Text

    /// <summary>
    /// Parse provider-native tool-call payload into AIOS tool calls { id, name, arguments }.
    /// Pass the fragment your model already located (message object, tool_calls array, content blocks, …).
    /// </summary>
    procedure ParseToolCalls(WireToken: JsonToken): JsonArray
}

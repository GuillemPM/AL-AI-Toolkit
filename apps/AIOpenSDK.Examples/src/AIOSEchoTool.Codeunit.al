namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Primary pattern sample: one tool codeunit. Add with ToolSet.Add(Tool).
/// </summary>
codeunit 87498 "AIOS Echo Tool" implements "AIOS Tool"
{
    Access = Public;

    /// <summary>
    /// Returns the tool name sent to the model (echo).
    /// </summary>
    procedure Name(): Text
    begin
        exit('echo');
    end;

    /// <summary>
    /// Returns the human-readable tool description used for tool selection.
    /// </summary>
    procedure Description(): Text
    begin
        exit('Echoes the message argument back to the model.');
    end;

    /// <summary>
    /// Returns the JSON Schema for tool arguments (required message string).
    /// </summary>
    procedure InputSchema(): JsonObject
    var
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('message', Schema.String()));
        exit(Schema.Object(Fields));
    end;

    /// <summary>
    /// Echoes the message argument into ResultText. Returns false when message is missing.
    /// </summary>
    procedure Execute(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Args: Codeunit "AIOS Tool Args";
        Message: Text;
    begin
        if not Args.RequireText(Arguments, 'message', Message, ResultText) then
            exit(false);
        ResultText := Message;
        exit(true);
    end;
}

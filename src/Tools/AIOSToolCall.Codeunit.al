namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// One tool call returned by the model (id, name, arguments).
/// </summary>
codeunit 87416 "AIOS Tool Call"
{
    Access = Public;

    /// <summary>
    /// Stores id, name, and arguments for one model tool call.
    /// </summary>
    procedure SetCall(Id: Text; Name: Text; Arguments: JsonObject)
    var
        ArgsText: Text;
    begin
        CallId := CopyStr(Id, 1, MaxStrLen(CallId));
        ToolName := CopyStr(Name, 1, MaxStrLen(ToolName));
        Clear(ArgumentsText);
        if Arguments.Keys().Count() > 0 then
            Arguments.WriteTo(ArgsText)
        else
            ArgsText := '{}';
        ArgumentsText := ArgsText;
    end;

    /// <summary>
    /// Stores id, name, and arguments JSON text for one model tool call.
    /// </summary>
    procedure SetCall(Id: Text; Name: Text; ArgumentsJson: Text)
    begin
        CallId := CopyStr(Id, 1, MaxStrLen(CallId));
        ToolName := CopyStr(Name, 1, MaxStrLen(ToolName));
        if DelChr(ArgumentsJson, '<>', ' ') = '' then
            ArgumentsText := '{}'
        else
            ArgumentsText := ArgumentsJson;
    end;

    /// <summary>
    /// Provider-assigned tool call id (correlates tool result messages).
    /// </summary>
    procedure GetId(): Text
    begin
        exit(CallId);
    end;

    /// <summary>
    /// Tool name the model invoked.
    /// </summary>
    procedure GetName(): Text
    begin
        exit(ToolName);
    end;

    /// <summary>
    /// Parsed tool arguments as a JSON object.
    /// </summary>
    procedure GetArguments(): JsonObject
    var
        Arguments: JsonObject;
    begin
        if ArgumentsText = '' then
            exit(Arguments);
        if not Arguments.ReadFrom(ArgumentsText) then
            Clear(Arguments);
        exit(Arguments);
    end;

    /// <summary>
    /// Raw tool arguments JSON text.
    /// </summary>
    procedure GetArgumentsJson(): Text
    begin
        if ArgumentsText = '' then
            exit('{}');
        exit(ArgumentsText);
    end;

    var
        CallId: Text[250];
        ToolName: Text[250];
        ArgumentsText: Text;
}

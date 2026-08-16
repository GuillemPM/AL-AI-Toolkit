namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Secondary pattern (save object IDs): one codeunit, many tools via "AIOS Tool Handler".
/// Use with ToolSet.Use(Handler), then GenerateText(..., ToolSet).
/// </summary>
codeunit 87488 "AIOS Sample Tool Handler" implements "AIOS Tool Handler"
{
    Access = Public;

    /// <summary>
    /// Returns the JSON array of tool definitions this handler exposes.
    /// </summary>
    procedure GetDefinitions(): JsonArray
    var
        Schema: Codeunit "AIOS Schema";
        Definitions: JsonArray;
        Fields: List of [JsonObject];
    begin
        Clear(Fields);
        Fields.Add(Schema.Field('message', Schema.String()));
        Definitions.Add(Schema.ToolDefinition('echo', 'Echoes the message argument back unchanged.', Schema.Object(Fields)));

        Clear(Fields);
        Fields.Add(Schema.Field('a', Schema.Number()));
        Fields.Add(Schema.Field('b', Schema.Number()));
        Definitions.Add(Schema.ToolDefinition('add_numbers', 'Adds two numbers (a and b) and returns the sum as text.', Schema.Object(Fields)));

        Clear(Fields);
        Fields.Add(Schema.Field('text', Schema.String()));
        Definitions.Add(Schema.ToolDefinition('to_upper', 'Converts the text argument to uppercase.', Schema.Object(Fields)));

        exit(Definitions);
    end;

    /// <summary>
    /// Runs a named tool from this handler pack and writes ResultText. Returns false on failure.
    /// </summary>
    procedure Execute(Name: Text; Arguments: JsonObject; var ResultText: Text): Boolean
    begin
        case Name of
            'echo':
                exit(Echo(Arguments, ResultText));
            'add_numbers':
                exit(AddNumbers(Arguments, ResultText));
            'to_upper':
                exit(ToUpper(Arguments, ResultText));
            else begin
                ResultText := StrSubstNo(UnknownToolErr, Name);
                exit(false);
            end;
        end;
    end;

    local procedure Echo(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Args: Codeunit "AIOS Tool Args";
        Message: Text;
    begin
        if not Args.RequireText(Arguments, 'message', Message, ResultText) then
            exit(false);
        ResultText := Message;
        exit(true);
    end;

    local procedure AddNumbers(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Args: Codeunit "AIOS Tool Args";
        A: Decimal;
        B: Decimal;
    begin
        if not Args.RequireDecimal(Arguments, 'a', A, ResultText) then
            exit(false);
        if not Args.RequireDecimal(Arguments, 'b', B, ResultText) then
            exit(false);
        ResultText := Format(A + B);
        exit(true);
    end;

    local procedure ToUpper(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Args: Codeunit "AIOS Tool Args";
        InputText: Text;
    begin
        if not Args.RequireText(Arguments, 'text', InputText, ResultText) then
            exit(false);
        ResultText := UpperCase(InputText);
        exit(true);
    end;

    var
        UnknownToolErr: Label 'Unknown tool %1.', Comment = '%1 = tool name';
}

namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Primary pattern sample: one tool codeunit. Add with ToolSet.Add(Tool).
/// </summary>
codeunit 87498 "AIOS Echo Tool" implements "AIOS Tool"
{
    Access = Public;

    procedure Name(): Text
    begin
        exit('echo');
    end;

    procedure Description(): Text
    begin
        exit('Echoes the message argument back to the model.');
    end;

    procedure InputSchema(): JsonObject
    var
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('message', Schema.String()));
        exit(Schema.Object(Fields));
    end;

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

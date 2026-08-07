namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Sample tool: returns the message argument as ResultText.
/// Implements both "AIOS Tool" (Add) and "AIOS Tool Handler" (Register).
/// </summary>
codeunit 87498 "AIOS Echo Tool" implements "AIOS Tool", "AIOS Tool Handler"
{
    Access = Public;

    /// <summary>
    /// Tool name sent to providers: echo.
    /// </summary>
    procedure Name(): Text
    begin
        exit('echo');
    end;

    /// <summary>
    /// Describes the echo tool for model tool selection.
    /// </summary>
    procedure Description(): Text
    begin
        exit('Echoes the message argument back to the model.');
    end;

    /// <summary>
    /// JSON Schema: required string property message.
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
    /// Returns the message argument in ResultText.
    /// </summary>
    procedure Execute(Arguments: JsonObject; var ResultText: Text): Boolean
    begin
        exit(EchoMessage(Arguments, ResultText));
    end;

    /// <summary>
    /// Handler entry for Register + SetHandler demos/tests.
    /// </summary>
    procedure Execute(ToolName: Text; Arguments: JsonObject; var ResultText: Text): Boolean
    begin
        if ToolName <> 'echo' then begin
            ResultText := StrSubstNo(UnknownToolErr, ToolName);
            exit(false);
        end;
        exit(EchoMessage(Arguments, ResultText));
    end;

    local procedure EchoMessage(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Arguments.Get('message', Token) then begin
            ResultText := MissingMessageErr;
            exit(false);
        end;
        ResultText := Token.AsValue().AsText();
        exit(true);
    end;

    var
        MissingMessageErr: Label 'echo tool requires a message argument.';
        UnknownToolErr: Label 'Unknown tool %1.', Comment = '%1 = tool name';
}

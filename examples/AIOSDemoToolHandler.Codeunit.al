namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Sample: one codeunit, several tools via "AIOS Tool Handler".
/// Copy this pattern into your app instead of one codeunit per tool.
/// </summary>
codeunit 87487 "AIOS Demo Tool Handler" implements "AIOS Tool Handler"
{
    Access = Public;

    /// <summary>
    /// Registers all tools from this handler on the tool set. Call SetHandler with this codeunit afterward.
    /// </summary>
    procedure RegisterAll(var ToolSet: Codeunit "AIOS Tool Set")
    begin
        ToolSet.Register(EchoName(), EchoDescription(), EchoSchema());
        ToolSet.Register(AddNumbersName(), AddNumbersDescription(), AddNumbersSchema());
        ToolSet.Register(ToUpperName(), ToUpperDescription(), ToUpperSchema());
    end;

    /// <summary>
    /// Dispatches by tool name.
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

    procedure EchoName(): Text
    begin
        exit('echo');
    end;

    procedure EchoDescription(): Text
    begin
        exit('Echoes the message argument back unchanged.');
    end;

    procedure EchoSchema(): JsonObject
    var
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('message', Schema.String()));
        exit(Schema.Object(Fields));
    end;

    procedure AddNumbersName(): Text
    begin
        exit('add_numbers');
    end;

    procedure AddNumbersDescription(): Text
    begin
        exit('Adds two numbers (a and b) and returns the sum as text.');
    end;

    procedure AddNumbersSchema(): JsonObject
    var
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('a', Schema.Number()));
        Fields.Add(Schema.Field('b', Schema.Number()));
        exit(Schema.Object(Fields));
    end;

    procedure ToUpperName(): Text
    begin
        exit('to_upper');
    end;

    procedure ToUpperDescription(): Text
    begin
        exit('Converts the text argument to uppercase.');
    end;

    procedure ToUpperSchema(): JsonObject
    var
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('text', Schema.String()));
        exit(Schema.Object(Fields));
    end;

    local procedure Echo(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Arguments.Get('message', Token) then begin
            ResultText := MissingArgErr;
            exit(false);
        end;
        ResultText := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure AddNumbers(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Token: JsonToken;
        A: Decimal;
        B: Decimal;
    begin
        if not Arguments.Get('a', Token) then begin
            ResultText := MissingArgErr;
            exit(false);
        end;
        A := Token.AsValue().AsDecimal();
        if not Arguments.Get('b', Token) then begin
            ResultText := MissingArgErr;
            exit(false);
        end;
        B := Token.AsValue().AsDecimal();
        ResultText := Format(A + B);
        exit(true);
    end;

    local procedure ToUpper(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not Arguments.Get('text', Token) then begin
            ResultText := MissingArgErr;
            exit(false);
        end;
        ResultText := UpperCase(Token.AsValue().AsText());
        exit(true);
    end;

    var
        UnknownToolErr: Label 'Unknown tool %1.', Comment = '%1 = tool name';
        MissingArgErr: Label 'Missing required tool argument.';
}

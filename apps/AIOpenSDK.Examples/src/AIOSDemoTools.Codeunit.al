namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Escape hatch sample: OnBeforeExecuteTool for ToolSet.Add(Name, Description, Schema).
/// Prefer "AIOS Tool" + Add(Tool) or "AIOS Tool Handler" + Use(Handler).
/// </summary>
codeunit 87487 "AIOS Demo Tools"
{
    Access = Public;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Tool Set", 'OnBeforeExecuteTool', '', false, false)]
    local procedure OnBeforeExecuteTool(Name: Text; Arguments: JsonObject; var ResultText: Text; var Succeeded: Boolean; var Handled: Boolean)
    begin
        case Name of
            'echo':
                begin
                    Succeeded := Echo(Arguments, ResultText);
                    Handled := true;
                end;
            'add_numbers':
                begin
                    Succeeded := AddNumbers(Arguments, ResultText);
                    Handled := true;
                end;
            'to_upper':
                begin
                    Succeeded := ToUpper(Arguments, ResultText);
                    Handled := true;
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
}

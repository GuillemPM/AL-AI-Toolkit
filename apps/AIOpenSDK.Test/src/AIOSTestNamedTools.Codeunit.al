namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Manually bound test double for the ToolSet.Add(Name, …) escape hatch.
/// </summary>
codeunit 87505 "AIOS Test Named Tools"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Tool Set", 'OnBeforeExecuteTool', '', false, false)]
    local procedure OnBeforeExecuteTool(Name: Text; Arguments: JsonObject; var ResultText: Text; var Succeeded: Boolean; var Handled: Boolean)
    var
        Args: Codeunit "AIOS Tool Args";
        TextValue: Text;
        A: Decimal;
        B: Decimal;
    begin
        if Handled then
            exit;
        case Name of
            'echo':
                begin
                    Succeeded := Args.RequireText(Arguments, 'message', TextValue, ResultText);
                    if Succeeded then
                        ResultText := TextValue;
                    Handled := true;
                end;
            'add_numbers':
                begin
                    if Args.RequireDecimal(Arguments, 'a', A, ResultText) then
                        if Args.RequireDecimal(Arguments, 'b', B, ResultText) then begin
                            ResultText := Format(A + B);
                            Succeeded := true;
                        end;
                    Handled := true;
                end;
            'to_upper':
                begin
                    Succeeded := Args.RequireText(Arguments, 'text', TextValue, ResultText);
                    if Succeeded then
                        ResultText := UpperCase(TextValue);
                    Handled := true;
                end;
        end;
    end;
}

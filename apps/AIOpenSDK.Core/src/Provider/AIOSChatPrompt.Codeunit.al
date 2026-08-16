namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

/// <summary>
/// Prompt and system message fields on "AIOS Chat Request".
/// </summary>
codeunit 87424 "AIOS Chat Prompt"
{
    Access = Public;

    /// <summary>
    /// Sets the user prompt text on the request.
    /// </summary>
    procedure SetPrompt(var Request: Record "AIOS Chat Request"; Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Request.Prompt);
        if Value = '' then
            exit;
        Request.Prompt.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    /// <summary>
    /// Returns the user prompt text from the request.
    /// </summary>
    procedure GetPrompt(var Request: Record "AIOS Chat Request"): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not Request.Prompt.HasValue then
            exit('');
        Request.Prompt.CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    /// <summary>
    /// Sets the system message text on the request.
    /// </summary>
    procedure SetSystemMessage(var Request: Record "AIOS Chat Request"; Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Request."System Message");
        if Value = '' then
            exit;
        Request."System Message".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    /// <summary>
    /// Returns the system message text from the request.
    /// </summary>
    procedure GetSystemMessage(var Request: Record "AIOS Chat Request"): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not Request."System Message".HasValue then
            exit('');
        Request."System Message".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    /// <summary>
    /// System message as sent to providers. When Json Mode is on and no output schema
    /// hint was already appended by SetOutput, appends a JSON-only instruction.
    /// </summary>
    procedure GetEffectiveSystemMessage(var Request: Record "AIOS Chat Request"): Text
    var
        SystemText: Text;
    begin
        SystemText := GetSystemMessage(Request);
        if not Request."Json Mode" then
            exit(SystemText);
        if Request.HasOutputSchema() then
            exit(SystemText);
        if SystemText = '' then
            exit(JsonModeInstructionTxt);
        if StrPos(LowerCase(SystemText + ' ' + GetPrompt(Request)), 'json') = 0 then
            exit(SystemText + ' ' + JsonModeInstructionTxt);
        exit(SystemText);
    end;

    var
        JsonModeInstructionTxt: Label 'Respond with valid JSON only, no markdown fences.';
}

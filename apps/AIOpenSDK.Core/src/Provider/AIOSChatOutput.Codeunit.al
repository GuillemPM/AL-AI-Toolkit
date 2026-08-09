namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

/// <summary>
/// Structured / JSON output binding on "AIOS Chat Request".
/// </summary>
codeunit 87425 "AIOS Chat Output"
{
    Access = Public;

    /// <summary>
    /// Binds flat JSON fields onto RecRef. Pass the same RecRef to GenerateText(Model, Request, RecRef).
    /// Prefer SetOutput with a JSON Schema for nested shapes.
    /// </summary>
    procedure SetOutput(var Request: Record "AIOS Chat Request"; RecRef: RecordRef)
    var
        JsonBinder: Codeunit "AIOS Json Binder";
        ChatPrompt: Codeunit "AIOS Chat Prompt";
        Hint: Text;
        SystemText: Text;
    begin
        if RecRef.Number() = 0 then
            Error(OutputRecordMissingErr);

        ClearOutput(Request);
        Request."Has Output" := true;
        Request."Json Mode" := true;

        Hint := JsonBinder.BuildSchemaHint(RecRef);
        SystemText := ChatPrompt.GetSystemMessage(Request);
        if SystemText = '' then
            ChatPrompt.SetSystemMessage(Request, Hint)
        else
            ChatPrompt.SetSystemMessage(Request, SystemText + ' ' + Hint);
    end;

    /// <summary>
    /// Sets the output mode from a schema document. Object/Array/Choice/Json enable JSON mode and append a system hint.
    /// Text disables JSON mode and does not append a hint (same as omitting SetOutput).
    /// </summary>
    procedure SetOutput(var Request: Record "AIOS Chat Request"; SchemaText: Text)
    var
        SchemaCodeunit: Codeunit "AIOS Schema";
        ChatPrompt: Codeunit "AIOS Chat Prompt";
        SchemaObj: JsonObject;
        OutStream: OutStream;
        SystemText: Text;
        Hint: Text;
        IsText: Boolean;
        IsJson: Boolean;
    begin
        if DelChr(SchemaText, '<>', ' ') = '' then
            Error(OutputSchemaMissingErr);

        ClearOutput(Request);
        Request."Output Schema".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(SchemaText);
        Request."Has Output Schema" := true;

        IsText := false;
        IsJson := false;
        if SchemaObj.ReadFrom(SchemaText) then begin
            IsText := SchemaCodeunit.IsTextSchema(SchemaObj);
            IsJson := SchemaCodeunit.IsJsonSchema(SchemaObj);
        end;
        Request."Json Mode" := not IsText;

        if IsText then
            Hint := ''
        else
            if IsJson then
                Hint := JsonModeInstructionTxt
            else
                Hint := StrSubstNo(OutputSchemaHintTxt, SchemaText);

        if Hint = '' then
            exit;

        SystemText := ChatPrompt.GetSystemMessage(Request);
        if SystemText = '' then
            ChatPrompt.SetSystemMessage(Request, Hint)
        else
            ChatPrompt.SetSystemMessage(Request, SystemText + ' ' + Hint);
    end;

    /// <summary>
    /// Sets structured output from a schema JsonObject (serialized via "AIOS Schema".ToText).
    /// </summary>
    procedure SetOutput(var Request: Record "AIOS Chat Request"; Schema: JsonObject)
    var
        SchemaCodeunit: Codeunit "AIOS Schema";
    begin
        SetOutput(Request, SchemaCodeunit.ToText(Schema));
    end;

    procedure HasOutput(var Request: Record "AIOS Chat Request"): Boolean
    begin
        exit(Request."Has Output");
    end;

    procedure HasOutputSchema(var Request: Record "AIOS Chat Request"): Boolean
    begin
        exit(Request."Has Output Schema");
    end;

    procedure GetOutputSchema(var Request: Record "AIOS Chat Request"): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not Request."Output Schema".HasValue then
            exit('');
        Request."Output Schema".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure ClearOutput(var Request: Record "AIOS Chat Request")
    begin
        Request."Has Output" := false;
        Clear(Request."Output Schema");
        Request."Has Output Schema" := false;
    end;

    var
        OutputRecordMissingErr: Label 'Structured output requires an open record.';
        OutputSchemaMissingErr: Label 'Output schema text cannot be empty.';
        OutputSchemaHintTxt: Label 'Respond with JSON only (no markdown) that conforms to this JSON Schema: %1', Comment = '%1 = JSON Schema';
        JsonModeInstructionTxt: Label 'Respond with valid JSON only, no markdown fences.';
}

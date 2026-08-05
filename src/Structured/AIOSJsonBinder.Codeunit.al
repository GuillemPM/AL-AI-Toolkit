namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Maps a flat JSON object onto record fields by field name.
/// </summary>
codeunit 87461 "AIOS Json Binder"
{
    Access = Internal;

    /// <summary>
    /// Writes JSON properties onto RecRef field values, then Insert (empty) or Modify (existing).
    /// Callers only need Clear + GetTable — no pre-Insert. RecRef must be var so FieldRef changes persist.
    /// </summary>
    procedure TryBind(JsonText: Text; var RecRef: RecordRef; var ErrorMessage: Text): Boolean
    var
        Root: JsonObject;
        Token: JsonToken;
        FieldIndex: Integer;
        FieldRef: FieldRef;
        FieldName: Text;
        Assigned: Integer;
        NeedsInsert: Boolean;
    begin
        ErrorMessage := '';
        JsonText := StripMarkdownFence(JsonText);
        if not Root.ReadFrom(JsonText) then begin
            ErrorMessage := InvalidJsonErr;
            exit(false);
        end;

        NeedsInsert := RecRef.IsEmpty();
        if NeedsInsert then
            RecRef.Init();

        Assigned := 0;
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if not IsBindableField(FieldRef) then
                continue;

            FieldName := FieldRef.Name();
            if not TryFindToken(Root, FieldName, Token) then
                continue;

            if not TryAssignToken(FieldRef, Token, ErrorMessage) then begin
                ErrorMessage := StrSubstNo(FieldAssignErr, FieldName, ErrorMessage);
                exit(false);
            end;
            Assigned += 1;
        end;

        if Assigned = 0 then begin
            ErrorMessage := NoFieldsBoundErr;
            exit(false);
        end;

        // FieldRef.Value updates the record buffer; Insert/Modify commits it.
        if NeedsInsert then begin
            if not RecRef.Insert(false) then begin
                ErrorMessage := InsertFailedErr;
                exit(false);
            end;
        end else
            if not RecRef.Modify(false) then begin
                ErrorMessage := ModifyFailedErr;
                exit(false);
            end;

        exit(true);
    end;

    procedure BuildSchemaHint(RecRef: RecordRef): Text
    var
        FieldIndex: Integer;
        FieldRef: FieldRef;
        Parts: Text;
        TypeName: Text;
    begin
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if not IsBindableField(FieldRef) then
                continue;
            TypeName := FieldTypeHint(FieldRef);
            if Parts = '' then
                Parts := StrSubstNo('%1 (%2)', FieldRef.Name(), TypeName)
            else
                Parts += StrSubstNo(', %1 (%2)', FieldRef.Name(), TypeName);
        end;
        if Parts = '' then
            exit(SchemaHintEmptyTxt);
        exit(StrSubstNo(SchemaHintTxt, Parts));
    end;

    local procedure TryFindToken(Root: JsonObject; FieldName: Text; var Token: JsonToken): Boolean
    var
        Keys: List of [Text];
        KeyName: Text;
    begin
        if Root.Get(FieldName, Token) then
            exit(true);
        Keys := Root.Keys();
        foreach KeyName in Keys do
            if LowerCase(KeyName) = LowerCase(FieldName) then
                exit(Root.Get(KeyName, Token));
        exit(false);
    end;

    local procedure IsBindableField(FieldRef: FieldRef): Boolean
    begin
        if FieldRef.Class() <> FieldClass::Normal then
            exit(false);
        if FieldRef.Number() < 10 then
            exit(false); // skip typical PK on buffers (e.g. Entry No.)
        case FieldRef.Type() of
            FieldType::Text,
            FieldType::Code,
            FieldType::Integer,
            FieldType::BigInteger,
            FieldType::Decimal,
            FieldType::Boolean,
            FieldType::Date,
            FieldType::Time,
            FieldType::DateTime,
            FieldType::Guid:
                exit(true);
            else
                exit(false);
        end;
    end;

    local procedure FieldTypeHint(FieldRef: FieldRef): Text
    begin
        case FieldRef.Type() of
            FieldType::Boolean:
                exit('boolean');
            FieldType::Integer, FieldType::BigInteger, FieldType::Decimal:
                exit('number');
            FieldType::Date, FieldType::DateTime, FieldType::Time:
                exit('string');
            else
                exit('string');
        end;
    end;

    local procedure TryAssignToken(var FieldRef: FieldRef; Token: JsonToken; var ErrorMessage: Text): Boolean
    var
        JValue: JsonValue;
        Arr: JsonArray;
        Obj: JsonObject;
        TextValue: Text;
        DecValue: Decimal;
        IntValue: Integer;
        BoolValue: Boolean;
        DateValue: Date;
        DateTimeValue: DateTime;
        TimeValue: Time;
        GuidValue: Guid;
    begin
        ErrorMessage := '';

        if Token.IsArray() then begin
            Arr := Token.AsArray();
            Arr.WriteTo(TextValue);
            if FieldRef.Type() in [FieldType::Text, FieldType::Code] then begin
                FieldRef.Value(CopyStr(TextValue, 1, FieldRef.Length()));
                exit(true);
            end;
            ErrorMessage := ArrayNeedsTextErr;
            exit(false);
        end;

        if Token.IsObject() then begin
            Obj := Token.AsObject();
            Obj.WriteTo(TextValue);
            if FieldRef.Type() in [FieldType::Text, FieldType::Code] then begin
                FieldRef.Value(CopyStr(TextValue, 1, FieldRef.Length()));
                exit(true);
            end;
            ErrorMessage := ObjectNeedsTextErr;
            exit(false);
        end;

        if not Token.IsValue() then begin
            ErrorMessage := UnsupportedTokenErr;
            exit(false);
        end;

        JValue := Token.AsValue();
        if JValue.IsNull() then
            exit(true);

        case FieldRef.Type() of
            FieldType::Text, FieldType::Code:
                begin
                    TextValue := JValue.AsText();
                    FieldRef.Value(CopyStr(TextValue, 1, FieldRef.Length()));
                    exit(true);
                end;
            FieldType::Boolean:
                begin
                    BoolValue := JValue.AsBoolean();
                    FieldRef.Value(BoolValue);
                    exit(true);
                end;
            FieldType::Integer:
                begin
                    IntValue := JValue.AsInteger();
                    FieldRef.Value(IntValue);
                    exit(true);
                end;
            FieldType::BigInteger:
                begin
                    IntValue := JValue.AsInteger();
                    FieldRef.Value(IntValue);
                    exit(true);
                end;
            FieldType::Decimal:
                begin
                    DecValue := JValue.AsDecimal();
                    FieldRef.Value(DecValue);
                    exit(true);
                end;
            FieldType::Date:
                begin
                    TextValue := JValue.AsText();
                    if not Evaluate(DateValue, TextValue) then begin
                        ErrorMessage := StrSubstNo(TypeCoerceErr, 'Date', TextValue);
                        exit(false);
                    end;
                    FieldRef.Value(DateValue);
                    exit(true);
                end;
            FieldType::DateTime:
                begin
                    TextValue := JValue.AsText();
                    if not Evaluate(DateTimeValue, TextValue) then begin
                        ErrorMessage := StrSubstNo(TypeCoerceErr, 'DateTime', TextValue);
                        exit(false);
                    end;
                    FieldRef.Value(DateTimeValue);
                    exit(true);
                end;
            FieldType::Time:
                begin
                    TextValue := JValue.AsText();
                    if not Evaluate(TimeValue, TextValue) then begin
                        ErrorMessage := StrSubstNo(TypeCoerceErr, 'Time', TextValue);
                        exit(false);
                    end;
                    FieldRef.Value(TimeValue);
                    exit(true);
                end;
            FieldType::Guid:
                begin
                    TextValue := JValue.AsText();
                    if not Evaluate(GuidValue, TextValue) then begin
                        ErrorMessage := StrSubstNo(TypeCoerceErr, 'Guid', TextValue);
                        exit(false);
                    end;
                    FieldRef.Value(GuidValue);
                    exit(true);
                end;
            else begin
                ErrorMessage := UnsupportedFieldTypeErr;
                exit(false);
            end;
        end;
    end;

    local procedure StripMarkdownFence(JsonText: Text): Text
    var
        Trimmed: Text;
        StartPos: Integer;
        EndPos: Integer;
        i: Integer;
    begin
        Trimmed := DelChr(JsonText, '<>', ' ');
        if CopyStr(Trimmed, 1, 3) <> '```' then
            exit(Trimmed);
        StartPos := StrPos(Trimmed, '{');
        EndPos := 0;
        for i := StrLen(Trimmed) downto 1 do
            if CopyStr(Trimmed, i, 1) = '}' then begin
                EndPos := i;
                break;
            end;
        if (StartPos > 0) and (EndPos >= StartPos) then
            exit(CopyStr(Trimmed, StartPos, EndPos - StartPos + 1));
        exit(Trimmed);
    end;

    var
        InvalidJsonErr: Label 'Response is not a valid JSON object.';
        NoFieldsBoundErr: Label 'No record fields could be matched to JSON properties.';
        InsertFailedErr: Label 'Could not insert the structured output record after binding.';
        ModifyFailedErr: Label 'Could not modify the structured output record after binding.';
        FieldAssignErr: Label 'Field %1: %2', Comment = '%1 = field name, %2 = detail';
        TypeCoerceErr: Label 'cannot convert ''%2'' to %1.', Comment = '%1 = type, %2 = value';
        ArrayNeedsTextErr: Label 'JSON array can only bind to Text or Code.';
        ObjectNeedsTextErr: Label 'JSON object can only bind to Text or Code.';
        UnsupportedTokenErr: Label 'unsupported JSON token.';
        UnsupportedFieldTypeErr: Label 'unsupported field type.';
        SchemaHintTxt: Label 'Respond with a single JSON object only (no markdown). Keys and types: %1.', Comment = '%1 = key list';
        SchemaHintEmptyTxt: Label 'Respond with a single JSON object only (no markdown).';
}

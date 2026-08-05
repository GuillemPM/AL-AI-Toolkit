namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Validates a JsonToken against a JSON Schema subset (type, properties, required, items).
/// </summary>
codeunit 87463 "AIOS Schema Validator"
{
    Access = Internal;

    procedure TryValidate(JsonText: Text; SchemaText: Text; var Output: JsonToken; var ErrorMessage: Text): Boolean
    var
        SchemaObj: JsonObject;
        SchemaToken: JsonToken;
    begin
        ErrorMessage := '';
        Clear(Output);

        JsonText := StripMarkdownFence(JsonText);
        if not Output.ReadFrom(JsonText) then begin
            ErrorMessage := InvalidJsonErr;
            exit(false);
        end;

        if SchemaText = '' then begin
            ErrorMessage := SchemaMissingErr;
            exit(false);
        end;
        if not SchemaObj.ReadFrom(SchemaText) then begin
            ErrorMessage := InvalidSchemaErr;
            exit(false);
        end;
        SchemaToken := SchemaObj.AsToken();
        exit(TryValidateToken(Output, SchemaToken, '$', ErrorMessage));
    end;

    local procedure TryValidateToken(Data: JsonToken; SchemaToken: JsonToken; Path: Text; var ErrorMessage: Text): Boolean
    var
        Schema: JsonObject;
        TypeToken: JsonToken;
        TypeName: Text;
    begin
        if not SchemaToken.IsObject() then begin
            ErrorMessage := StrSubstNo(SchemaNotObjectErr, Path);
            exit(false);
        end;
        Schema := SchemaToken.AsObject();

        if Schema.Get('type', TypeToken) then begin
            if not TypeToken.IsValue() then begin
                ErrorMessage := StrSubstNo(TypeNotStringErr, Path);
                exit(false);
            end;
            TypeName := LowerCase(TypeToken.AsValue().AsText());
            if not MatchesType(Data, TypeName, Path, ErrorMessage) then
                exit(false);

            case TypeName of
                'object':
                    exit(TryValidateObject(Data, Schema, Path, ErrorMessage));
                'array':
                    exit(TryValidateArray(Data, Schema, Path, ErrorMessage));
            end;
        end else begin
            // No type: still walk properties/items if present.
            if Schema.Get('properties', TypeToken) then
                exit(TryValidateObject(Data, Schema, Path, ErrorMessage));
            if Schema.Get('items', TypeToken) then
                exit(TryValidateArray(Data, Schema, Path, ErrorMessage));
        end;

        exit(true);
    end;

    local procedure MatchesType(Data: JsonToken; TypeName: Text; Path: Text; var ErrorMessage: Text): Boolean
    var
        Kind: Text;
    begin
        Kind := TokenKind(Data);
        case TypeName of
            'object':
                if Kind = 'object' then
                    exit(true);
            'array':
                if Kind = 'array' then
                    exit(true);
            'string':
                if Kind = 'string' then
                    exit(true);
            'boolean':
                if Kind = 'boolean' then
                    exit(true);
            'number':
                if (Kind = 'number') or (Kind = 'integer') then
                    exit(true);
            'integer':
                if Kind = 'integer' then
                    exit(true);
            else begin
                ErrorMessage := StrSubstNo(UnsupportedTypeErr, TypeName, Path);
                exit(false);
            end;
        end;

        ErrorMessage := StrSubstNo(TypeMismatchErr, TypeName, Path);
        exit(false);
    end;

    /// <summary>
    /// Classify a token from its JSON serialization (JsonValue has no IsText/IsBoolean helpers).
    /// </summary>
    local procedure TokenKind(Data: JsonToken): Text
    var
        Text: Text;
        First: Text[1];
        Lower: Text;
    begin
        if Data.IsObject() then
            exit('object');
        if Data.IsArray() then
            exit('array');
        if not Data.IsValue() then
            exit('');
        if Data.AsValue().IsNull() then
            exit('null');

        Data.WriteTo(Text);
        Text := DelChr(Text, '<>', ' ');
        if Text = '' then
            exit('');
        First := CopyStr(Text, 1, 1);
        case First of
            '"':
                exit('string');
            't', 'T', 'f', 'F':
                exit('boolean');
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-':
                begin
                    Lower := LowerCase(Text);
                    if (StrPos(Text, '.') > 0) or (StrPos(Lower, 'e') > 0) then
                        exit('number');
                    exit('integer');
                end;
            else
                exit('');
        end;
    end;

    local procedure TryValidateObject(Data: JsonToken; Schema: JsonObject; Path: Text; var ErrorMessage: Text): Boolean
    var
        PropsToken: JsonToken;
        Props: JsonObject;
        RequiredToken: JsonToken;
        RequiredArr: JsonArray;
        PropSchemaToken: JsonToken;
        ValueToken: JsonToken;
        KeyName: Text;
        i: Integer;
        ChildPath: Text;
    begin
        if not Data.IsObject() then begin
            ErrorMessage := StrSubstNo(TypeMismatchErr, 'object', Path);
            exit(false);
        end;

        if Schema.Get('required', RequiredToken) then begin
            if not RequiredToken.IsArray() then begin
                ErrorMessage := StrSubstNo(RequiredNotArrayErr, Path);
                exit(false);
            end;
            RequiredArr := RequiredToken.AsArray();
            for i := 0 to RequiredArr.Count() - 1 do begin
                RequiredArr.Get(i, PropSchemaToken);
                KeyName := PropSchemaToken.AsValue().AsText();
                if not Data.AsObject().Get(KeyName, ValueToken) then begin
                    ErrorMessage := StrSubstNo(MissingRequiredErr, KeyName, Path);
                    exit(false);
                end;
            end;
        end;

        if not Schema.Get('properties', PropsToken) then
            exit(true);
        if not PropsToken.IsObject() then begin
            ErrorMessage := StrSubstNo(PropertiesNotObjectErr, Path);
            exit(false);
        end;
        Props := PropsToken.AsObject();

        foreach KeyName in Props.Keys() do begin
            if not Data.AsObject().Get(KeyName, ValueToken) then
                continue;
            Props.Get(KeyName, PropSchemaToken);
            if Path = '$' then
                ChildPath := '$.' + KeyName
            else
                ChildPath := Path + '.' + KeyName;
            if not TryValidateToken(ValueToken, PropSchemaToken, ChildPath, ErrorMessage) then
                exit(false);
        end;

        exit(true);
    end;

    local procedure TryValidateArray(Data: JsonToken; Schema: JsonObject; Path: Text; var ErrorMessage: Text): Boolean
    var
        ItemsToken: JsonToken;
        Arr: JsonArray;
        Element: JsonToken;
        i: Integer;
        ChildPath: Text;
    begin
        if not Data.IsArray() then begin
            ErrorMessage := StrSubstNo(TypeMismatchErr, 'array', Path);
            exit(false);
        end;

        if not Schema.Get('items', ItemsToken) then
            exit(true);

        Arr := Data.AsArray();
        for i := 0 to Arr.Count() - 1 do begin
            Arr.Get(i, Element);
            ChildPath := StrSubstNo('%1[%2]', Path, i);
            if not TryValidateToken(Element, ItemsToken, ChildPath, ErrorMessage) then
                exit(false);
        end;

        exit(true);
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
        if StartPos = 0 then
            StartPos := StrPos(Trimmed, '[');
        EndPos := 0;
        for i := StrLen(Trimmed) downto 1 do
            if (CopyStr(Trimmed, i, 1) = '}') or (CopyStr(Trimmed, i, 1) = ']') then begin
                EndPos := i;
                break;
            end;
        if (StartPos > 0) and (EndPos >= StartPos) then
            exit(CopyStr(Trimmed, StartPos, EndPos - StartPos + 1));
        exit(Trimmed);
    end;

    var
        InvalidJsonErr: Label 'Response is not valid JSON.';
        SchemaMissingErr: Label 'Output schema is empty.';
        InvalidSchemaErr: Label 'Output schema is not a valid JSON object.';
        SchemaNotObjectErr: Label 'Schema at %1 must be an object.', Comment = '%1 = JSON path';
        TypeNotStringErr: Label 'Schema type at %1 must be a string.', Comment = '%1 = JSON path';
        UnsupportedTypeErr: Label 'Unsupported schema type ''%1'' at %2.', Comment = '%1 = type, %2 = path';
        TypeMismatchErr: Label 'Expected type %1 at %2.', Comment = '%1 = type, %2 = path';
        MissingRequiredErr: Label 'Missing required property ''%1'' at %2.', Comment = '%1 = name, %2 = path';
        RequiredNotArrayErr: Label 'Schema required at %1 must be an array.', Comment = '%1 = path';
        PropertiesNotObjectErr: Label 'Schema properties at %1 must be an object.', Comment = '%1 = path';
}

namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Builds JSON Schema and output-mode documents via Field, Object, Array, Enum, Choice, Json, and Text helpers.
/// </summary>
codeunit 87462 "AIOS Schema"
{
    Access = Public;

    /// <summary>
    /// Builds a JSON Schema fragment with type string.
    /// </summary>
    procedure String(): JsonObject
    begin
        exit(TypeOnly('string'));
    end;

    /// <summary>
    /// Builds a JSON Schema fragment with type number.
    /// </summary>
    procedure Number(): JsonObject
    begin
        exit(TypeOnly('number'));
    end;

    /// <summary>
    /// Builds a JSON Schema fragment with type integer.
    /// </summary>
    procedure Integer(): JsonObject
    begin
        exit(TypeOnly('integer'));
    end;

    /// <summary>
    /// Builds a JSON Schema fragment with type boolean.
    /// </summary>
    procedure Boolean(): JsonObject
    begin
        exit(TypeOnly('boolean'));
    end;

    /// <summary>
    /// Requests plain text output. Same as omitting SetOutput; may be set explicitly to clear a prior output mode.
    /// </summary>
    procedure "Text"(): JsonObject
    var
        Schema: JsonObject;
    begin
        Schema.Add(OutputKindTok, TextKindTok);
        exit(Schema);
    end;

    /// <summary>
    /// Returns true when Schema requests plain text (Text helper).
    /// </summary>
    procedure IsTextSchema(Schema: JsonObject): Boolean
    begin
        exit(OutputKindEquals(Schema, TextKindTok));
    end;

    /// <summary>
    /// Requests unstructured JSON output. GenerateText requires valid JSON and does not check shape.
    /// </summary>
    procedure Json(): JsonObject
    var
        Schema: JsonObject;
    begin
        Schema.Add(OutputKindTok, JsonKindTok);
        exit(Schema);
    end;

    /// <summary>
    /// Returns true when Schema requests unstructured JSON (Json helper).
    /// </summary>
    procedure IsJsonSchema(Schema: JsonObject): Boolean
    begin
        exit(OutputKindEquals(Schema, JsonKindTok));
    end;

    /// <summary>
    /// Array schema with a single items schema.
    /// </summary>
    procedure "Array"(Items: JsonObject): JsonObject
    var
        Schema: JsonObject;
    begin
        Schema.Add('type', 'array');
        Schema.Add('items', Items);
        exit(Schema);
    end;

    /// <summary>
    /// String schema whose value must be one of Options. Use with Field for nested properties.
    /// </summary>
    procedure "Enum"(Options: List of [Text]): JsonObject
    var
        Schema: JsonObject;
        EnumArr: JsonArray;
    begin
        BuildEnumArray(Options, EnumArr);
        Schema.Add('type', 'string');
        Schema.Add('enum', EnumArr);
        exit(Schema);
    end;

    /// <summary>
    /// Object schema with a required result property constrained to Options.
    /// After validation, Result.Output() is the selected option as plain text.
    /// </summary>
    procedure Choice(Options: List of [Text]): JsonObject
    var
        Fields: List of [JsonObject];
        Schema: JsonObject;
    begin
        Fields.Add(Field('result', "Enum"(Options)));
        Schema := Object(Fields);
        Schema.Add('additionalProperties', false);
        exit(Schema);
    end;

    /// <summary>
    /// Returns true when Schema is a Choice document (object with a result string enum).
    /// </summary>
    procedure IsChoiceSchema(Schema: JsonObject): Boolean
    var
        TypeToken: JsonToken;
        PropsToken: JsonToken;
        Props: JsonObject;
        ResultToken: JsonToken;
        ResultSchema: JsonObject;
        EnumToken: JsonToken;
    begin
        if not Schema.Get('type', TypeToken) then
            exit(false);
        if not TypeToken.IsValue() then
            exit(false);
        if LowerCase(TypeToken.AsValue().AsText()) <> 'object' then
            exit(false);
        if not Schema.Get('properties', PropsToken) then
            exit(false);
        if not PropsToken.IsObject() then
            exit(false);
        Props := PropsToken.AsObject();
        if not Props.Get('result', ResultToken) then
            exit(false);
        if not ResultToken.IsObject() then
            exit(false);
        ResultSchema := ResultToken.AsObject();
        if not ResultSchema.Get('enum', EnumToken) then
            exit(false);
        if not EnumToken.IsArray() then
            exit(false);
        exit(EnumToken.AsArray().Count() > 0);
    end;

    /// <summary>
    /// Required object property. Returns a single-key fragment for Object(Fields).
    /// </summary>
    procedure Field(Name: Text; FieldSchema: JsonObject): JsonObject
    var
        Result: JsonObject;
    begin
        if Name = '' then
            Error(FieldNameMissingErr);
        Result.Add(Name, FieldSchema);
        exit(Result);
    end;

    /// <summary>
    /// Optional object property. Included in properties but omitted from required.
    /// </summary>
    procedure OptionalField(Name: Text; FieldSchema: JsonObject): JsonObject
    var
        Result: JsonObject;
        Annotated: JsonObject;
        Text: Text;
    begin
        if Name = '' then
            Error(FieldNameMissingErr);
        FieldSchema.WriteTo(Text);
        Annotated.ReadFrom(Text);
        if Annotated.Contains(OptionalFlagTok) then
            Annotated.Remove(OptionalFlagTok);
        Annotated.Add(OptionalFlagTok, true);
        Result.Add(Name, Annotated);
        exit(Result);
    end;

    /// <summary>
    /// Object schema from any number of Field/OptionalField fragments.
    /// </summary>
    procedure Object(Fields: List of [JsonObject]): JsonObject
    var
        Schema: JsonObject;
        Props: JsonObject;
        Required: JsonArray;
        FieldObj: JsonObject;
    begin
        foreach FieldObj in Fields do
            MergeFieldObject(Props, Required, FieldObj);

        Schema.Add('type', 'object');
        Schema.Add('properties', Props);
        if Required.Count() > 0 then
            Schema.Add('required', Required);
        exit(Schema);
    end;

    /// <summary>
    /// Serializes a schema JsonObject to text.
    /// </summary>
    procedure ToText(Schema: JsonObject): Text
    var
        Text: Text;
    begin
        Schema.WriteTo(Text);
        exit(Text);
    end;

    /// <summary>
    /// Builds { name, description, parameters } for Handler.GetDefinitions or ToolSet.Add(Definition).
    /// </summary>
    procedure ToolDefinition(Name: Text; Description: Text; Parameters: JsonObject): JsonObject
    var
        Definition: JsonObject;
    begin
        if Name = '' then
            Error(ToolNameEmptyErr);
        Clear(Definition);
        Definition.Add('name', Name);
        Definition.Add('description', Description);
        Definition.Add('parameters', Parameters);
        exit(Definition);
    end;

    local procedure BuildEnumArray(Options: List of [Text]; var EnumArr: JsonArray)
    var
        Option: Text;
        Seen: List of [Text];
    begin
        if Options.Count() = 0 then
            Error(ChoiceEmptyErr);

        foreach Option in Options do begin
            if Option = '' then
                Error(ChoiceEmptyOptionErr);
            if Seen.Contains(Option) then
                Error(ChoiceDuplicateErr, Option);
            Seen.Add(Option);
            EnumArr.Add(Option);
        end;
    end;

    local procedure MergeFieldObject(var Props: JsonObject; var Required: JsonArray; FieldObj: JsonObject)
    var
        KeyName: Text;
        SchemaToken: JsonToken;
        SchemaObj: JsonObject;
        Optional: Boolean;
    begin
        foreach KeyName in FieldObj.Keys() do begin
            if not FieldObj.Get(KeyName, SchemaToken) then
                continue;
            Optional := false;
            if SchemaToken.IsObject() then begin
                SchemaObj := SchemaToken.AsObject();
                Optional := RemoveOptionalFlag(SchemaObj);
                if Props.Contains(KeyName) then
                    Error(DuplicateFieldErr, KeyName);
                Props.Add(KeyName, SchemaObj);
            end else begin
                if Props.Contains(KeyName) then
                    Error(DuplicateFieldErr, KeyName);
                Props.Add(KeyName, SchemaToken);
            end;
            if not Optional then
                Required.Add(KeyName);
        end;
    end;

    local procedure RemoveOptionalFlag(var SchemaObj: JsonObject): Boolean
    var
        Token: JsonToken;
    begin
        if not SchemaObj.Get(OptionalFlagTok, Token) then
            exit(false);
        SchemaObj.Remove(OptionalFlagTok);
        exit(true);
    end;

    local procedure OutputKindEquals(Schema: JsonObject; Kind: Text): Boolean
    var
        KindToken: JsonToken;
    begin
        if not Schema.Get(OutputKindTok, KindToken) then
            exit(false);
        if not KindToken.IsValue() then
            exit(false);
        exit(KindToken.AsValue().AsText() = Kind);
    end;

    local procedure TypeOnly(TypeName: Text): JsonObject
    var
        Schema: JsonObject;
    begin
        Schema.Add('type', TypeName);
        exit(Schema);
    end;

    var
        OptionalFlagTok: Label 'x-aios-optional', Locked = true;
        OutputKindTok: Label 'x-aios-output', Locked = true;
        JsonKindTok: Label 'json', Locked = true;
        TextKindTok: Label 'text', Locked = true;
        FieldNameMissingErr: Label 'Schema field name cannot be empty.';
        DuplicateFieldErr: Label 'Duplicate schema field ''%1''.', Comment = '%1 = field name';
        ChoiceEmptyErr: Label 'Choice options cannot be empty.';
        ChoiceEmptyOptionErr: Label 'Choice option cannot be an empty string.';
        ChoiceDuplicateErr: Label 'Duplicate choice option ''%1''.', Comment = '%1 = option value';
        ToolNameEmptyErr: Label 'Tool name cannot be empty.';
}

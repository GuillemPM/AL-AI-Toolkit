namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Builds JSON Schema documents via Field, Object, and Array helpers.
/// </summary>
codeunit 87462 "AIOS Schema"
{
    Access = Public;

    procedure String(): JsonObject
    begin
        exit(TypeOnly('string'));
    end;

    procedure Number(): JsonObject
    begin
        exit(TypeOnly('number'));
    end;

    procedure Integer(): JsonObject
    begin
        exit(TypeOnly('integer'));
    end;

    procedure Boolean(): JsonObject
    begin
        exit(TypeOnly('boolean'));
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

    procedure ToText(Schema: JsonObject): Text
    var
        Text: Text;
    begin
        Schema.WriteTo(Text);
        exit(Text);
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

    local procedure TypeOnly(TypeName: Text): JsonObject
    var
        Schema: JsonObject;
    begin
        Schema.Add('type', TypeName);
        exit(Schema);
    end;

    var
        OptionalFlagTok: Label 'x-aios-optional', Locked = true;
        FieldNameMissingErr: Label 'Schema field name cannot be empty.';
        DuplicateFieldErr: Label 'Duplicate schema field ''%1''.', Comment = '%1 = field name';
}

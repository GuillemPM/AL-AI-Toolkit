namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Helpers for reading tool Execute arguments from a JSON object.
/// Prefer Require* for required fields (sets ErrorText and returns false); TryGet* for optional.
/// </summary>
codeunit 87420 "AIOS Tool Args"
{
    Access = Public;

    /// <summary>
    /// Required text argument. On failure sets ErrorText and returns false.
    /// </summary>
    procedure RequireText(Arguments: JsonObject; Name: Text; var Value: Text; var ErrorText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then begin
            ErrorText := StrSubstNo(MissingArgErr, Name);
            exit(false);
        end;
        if not Token.IsValue() then begin
            ErrorText := StrSubstNo(InvalidArgErr, Name);
            exit(false);
        end;
        Value := Token.AsValue().AsText();
        exit(true);
    end;

    /// <summary>
    /// Required decimal argument. On failure sets ErrorText and returns false.
    /// </summary>
    procedure RequireDecimal(Arguments: JsonObject; Name: Text; var Value: Decimal; var ErrorText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then begin
            ErrorText := StrSubstNo(MissingArgErr, Name);
            exit(false);
        end;
        if not Token.IsValue() then begin
            ErrorText := StrSubstNo(InvalidArgErr, Name);
            exit(false);
        end;
        Value := Token.AsValue().AsDecimal();
        exit(true);
    end;

    /// <summary>
    /// Required integer argument. On failure sets ErrorText and returns false.
    /// </summary>
    procedure RequireInteger(Arguments: JsonObject; Name: Text; var Value: Integer; var ErrorText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then begin
            ErrorText := StrSubstNo(MissingArgErr, Name);
            exit(false);
        end;
        if not Token.IsValue() then begin
            ErrorText := StrSubstNo(InvalidArgErr, Name);
            exit(false);
        end;
        Value := Token.AsValue().AsInteger();
        exit(true);
    end;

    /// <summary>
    /// Required boolean argument. On failure sets ErrorText and returns false.
    /// </summary>
    procedure RequireBoolean(Arguments: JsonObject; Name: Text; var Value: Boolean; var ErrorText: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then begin
            ErrorText := StrSubstNo(MissingArgErr, Name);
            exit(false);
        end;
        if not Token.IsValue() then begin
            ErrorText := StrSubstNo(InvalidArgErr, Name);
            exit(false);
        end;
        Value := Token.AsValue().AsBoolean();
        exit(true);
    end;

    /// <summary>
    /// Optional text; returns false when missing or not a value.
    /// </summary>
    procedure TryGetText(Arguments: JsonObject; Name: Text; var Value: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        Value := Token.AsValue().AsText();
        exit(true);
    end;

    /// <summary>
    /// Optional decimal; returns false when missing or not a value.
    /// </summary>
    procedure TryGetDecimal(Arguments: JsonObject; Name: Text; var Value: Decimal): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        Value := Token.AsValue().AsDecimal();
        exit(true);
    end;

    /// <summary>
    /// Optional integer; returns false when missing or not a value.
    /// </summary>
    procedure TryGetInteger(Arguments: JsonObject; Name: Text; var Value: Integer): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        Value := Token.AsValue().AsInteger();
        exit(true);
    end;

    /// <summary>
    /// Optional boolean; returns false when missing or not a value.
    /// </summary>
    procedure TryGetBoolean(Arguments: JsonObject; Name: Text; var Value: Boolean): Boolean
    var
        Token: JsonToken;
    begin
        if not TryGetToken(Arguments, Name, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        Value := Token.AsValue().AsBoolean();
        exit(true);
    end;

    local procedure TryGetToken(Arguments: JsonObject; Name: Text; var Token: JsonToken): Boolean
    begin
        if Name = '' then
            exit(false);
        exit(Arguments.Get(Name, Token));
    end;

    var
        MissingArgErr: Label 'Missing required tool argument ''%1''.', Comment = '%1 = argument name';
        InvalidArgErr: Label 'Tool argument ''%1'' has an invalid value.', Comment = '%1 = argument name';
}

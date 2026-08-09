namespace PM.Guillem.AIOpenSDK.Provider.OpenAICompatible;

using PM.Guillem.AIOpenSDK.Core;
using System.Text;

/// <summary>
/// Chat/tools wire format for OpenAI Chat Completions–compatible APIs.
/// Owned by the OpenAI Compatible provider — independent of OpenAI / OpenCode Zen.
/// </summary>
codeunit 87418 "AIOS OpenAI Compatible Format" implements "AIOS Chat Format"
{
    Access = Public;

    /// <summary>
    /// Maps AIOS tool definitions to OpenAI-compatible function tools.
    /// </summary>
    procedure MapTools(Definitions: JsonArray): JsonArray
    var
        Tools: JsonArray;
        DefToken: JsonToken;
        Def: JsonObject;
        Tool: JsonObject;
        FunctionObj: JsonObject;
        NameToken: JsonToken;
        DescToken: JsonToken;
        ParamsToken: JsonToken;
        i: Integer;
    begin
        for i := 0 to Definitions.Count() - 1 do begin
            Definitions.Get(i, DefToken);
            Def := DefToken.AsObject();
            Clear(FunctionObj);
            Clear(Tool);
            if Def.Get('name', NameToken) then
                FunctionObj.Add('name', NameToken.AsValue().AsText());
            if Def.Get('description', DescToken) then
                FunctionObj.Add('description', DescToken.AsValue().AsText());
            if Def.Get('parameters', ParamsToken) then
                FunctionObj.Add('parameters', ParamsToken)
            else
                FunctionObj.Add('parameters', EmptyObject());
            Tool.Add('type', 'function');
            Tool.Add('function', FunctionObj);
            Tools.Add(Tool);
        end;
        exit(Tools);
    end;

    /// <summary>
    /// Maps AIOS message history to OpenAI-compatible chat messages.
    /// User content may be a string or TextPart/FilePart array.
    /// </summary>
    procedure MapMessages(AiosMessages: JsonArray): JsonArray
    var
        OutMessages: JsonArray;
        MsgToken: JsonToken;
        Msg: JsonObject;
        RoleToken: JsonToken;
        ContentToken: JsonToken;
        ToolCallsToken: JsonToken;
        OutMsg: JsonObject;
        Role: Text;
        i: Integer;
    begin
        for i := 0 to AiosMessages.Count() - 1 do begin
            AiosMessages.Get(i, MsgToken);
            Msg := MsgToken.AsObject();
            if not Msg.Get('role', RoleToken) then
                continue;
            Role := RoleToken.AsValue().AsText();
            Clear(OutMsg);
            case Role of
                'system':
                    begin
                        OutMsg.Add('role', Role);
                        if Msg.Get('content', ContentToken) and ContentToken.IsValue() then
                            OutMsg.Add('content', ContentToken.AsValue().AsText())
                        else
                            OutMsg.Add('content', '');
                        OutMessages.Add(OutMsg);
                    end;
                'user':
                    begin
                        OutMsg.Add('role', 'user');
                        if Msg.Get('content', ContentToken) then
                            SetUserContent(OutMsg, ContentToken)
                        else
                            OutMsg.Add('content', '');
                        OutMessages.Add(OutMsg);
                    end;
                'assistant':
                    begin
                        OutMsg.Add('role', 'assistant');
                        if Msg.Get('content', ContentToken) and ContentToken.IsValue() and (not ContentToken.AsValue().IsNull()) then
                            OutMsg.Add('content', ContentToken.AsValue().AsText())
                        else
                            OutMsg.Add('content', '');
                        if Msg.Get('tool_calls', ToolCallsToken) then
                            OutMsg.Add('tool_calls', ToWireToolCalls(ToolCallsToken.AsArray()));
                        if Msg.Get('reasoning_content', ContentToken) then
                            OutMsg.Add('reasoning_content', ContentToken.AsValue().AsText());
                        OutMessages.Add(OutMsg);
                    end;
                'tool':
                    begin
                        OutMsg.Add('role', 'tool');
                        if Msg.Get('tool_call_id', ContentToken) then
                            OutMsg.Add('tool_call_id', ContentToken.AsValue().AsText());
                        if Msg.Get('content', ContentToken) and ContentToken.IsValue() then
                            OutMsg.Add('content', ContentToken.AsValue().AsText())
                        else
                            OutMsg.Add('content', '');
                        OutMessages.Add(OutMsg);
                    end;
            end;
        end;
        exit(OutMessages);
    end;

    /// <summary>
    /// System stays inside messages; always returns empty.
    /// </summary>
    procedure GetSystemText(AiosMessages: JsonArray): Text
    begin
        exit('');
    end;

    /// <summary>
    /// Accepts a chat message object (with optional tool_calls) or a tool_calls array.
    /// </summary>
    procedure ParseToolCalls(WireToken: JsonToken): JsonArray
    var
        Empty: JsonArray;
        MessageObj: JsonObject;
        ToolCallsToken: JsonToken;
    begin
        if WireToken.IsArray() then
            exit(ParseWireToolCalls(WireToken.AsArray()));
        if not WireToken.IsObject() then
            exit(Empty);
        MessageObj := WireToken.AsObject();
        if not MessageObj.Get('tool_calls', ToolCallsToken) then
            exit(Empty);
        if not ToolCallsToken.IsArray() then
            exit(Empty);
        exit(ParseWireToolCalls(ToolCallsToken.AsArray()));
    end;

    local procedure SetUserContent(var OutMsg: JsonObject; ContentToken: JsonToken)
    var
        Parts: JsonArray;
        OutParts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        TypeToken: JsonToken;
        i: Integer;
    begin
        if ContentToken.IsValue() then begin
            OutMsg.Add('content', ContentToken.AsValue().AsText());
            exit;
        end;

        if ContentToken.IsArray() then begin
            Parts := ContentToken.AsArray();
            for i := 0 to Parts.Count() - 1 do begin
                Parts.Get(i, PartToken);
                if not PartToken.IsObject() then
                    continue;
                Part := PartToken.AsObject();
                if not Part.Get('type', TypeToken) then
                    continue;
                case TypeToken.AsValue().AsText() of
                    'text':
                        OutParts.Add(TextPart(Part));
                    'file':
                        OutParts.Add(FilePart(Part));
                end;
            end;
        end;

        if OutParts.Count() = 0 then begin
            Clear(Part);
            Part.Add('type', 'text');
            Part.Add('text', '');
            OutParts.Add(Part);
        end;
        OutMsg.Add('content', OutParts);
    end;

    local procedure TextPart(Part: JsonObject): JsonObject
    var
        OutPart: JsonObject;
    begin
        OutPart.Add('type', 'text');
        OutPart.Add('text', GetPartText(Part));
        exit(OutPart);
    end;

    local procedure FilePart(Part: JsonObject): JsonObject
    var
        MessageContent: Codeunit "AIOS Message Content";
        MediaType: Text;
        Data: Text;
        Filename: Text;
        OutPart: JsonObject;
        ImageUrl: JsonObject;
        FileObj: JsonObject;
        Base64Convert: Codeunit "Base64 Convert";
        Decoded: Text;
    begin
        MediaType := GetPartMediaType(Part);
        Data := GetPartData(Part);
        Filename := GetPartFilename(Part);
        EnsureFilePartExpanded(Part, Data);

        if MessageContent.IsTextMediaType(MediaType) then begin
            Decoded := GetPartText(Part);
            if Decoded = '' then
                Decoded := Base64Convert.FromBase64(Data);
            OutPart.Add('type', 'text');
            if Filename <> '' then
                OutPart.Add('text', StrSubstNo(FileAsTextFmtTok, Filename, Decoded))
            else
                OutPart.Add('text', Decoded);
            exit(OutPart);
        end;

        if MessageContent.IsImageMediaType(MediaType) then begin
            if LowerCase(MediaType) = 'image' then
                MediaType := 'image/png';
            ImageUrl.Add('url', StrSubstNo(DataUrlTok, MediaType, Data));
            OutPart.Add('type', 'image_url');
            OutPart.Add('image_url', ImageUrl);
            exit(OutPart);
        end;

        if Filename = '' then
            Filename := 'file';
        FileObj.Add('filename', Filename);
        FileObj.Add('file_data', StrSubstNo(DataUrlTok, MediaType, Data));
        OutPart.Add('type', 'file');
        OutPart.Add('file', FileObj);
        exit(OutPart);
    end;

    local procedure EnsureFilePartExpanded(Part: JsonObject; Data: Text)
    var
        IdToken: JsonToken;
    begin
        if GetPartText(Part) <> '' then
            exit;
        if Data <> '' then
            exit;
        if Part.Get('id', IdToken) then
            if IdToken.AsValue().AsText() <> '' then
                Error(UnexpandedAttachmentErr);
    end;

    local procedure GetPartText(Part: JsonObject): Text
    var
        Token: JsonToken;
    begin
        if Part.Get('text', Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetPartMediaType(Part: JsonObject): Text
    var
        Token: JsonToken;
    begin
        if Part.Get('mediaType', Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetPartData(Part: JsonObject): Text
    var
        Token: JsonToken;
    begin
        if Part.Get('data', Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetPartFilename(Part: JsonObject): Text
    var
        Token: JsonToken;
    begin
        if Part.Get('filename', Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure ToWireToolCalls(AiosToolCalls: JsonArray): JsonArray
    var
        Out: JsonArray;
        CallToken: JsonToken;
        Call: JsonObject;
        OutCall: JsonObject;
        FunctionObj: JsonObject;
        IdToken: JsonToken;
        NameToken: JsonToken;
        ArgsToken: JsonToken;
        ArgsText: Text;
        i: Integer;
    begin
        for i := 0 to AiosToolCalls.Count() - 1 do begin
            AiosToolCalls.Get(i, CallToken);
            Call := CallToken.AsObject();
            Clear(FunctionObj);
            Clear(OutCall);
            if Call.Get('name', NameToken) then
                FunctionObj.Add('name', NameToken.AsValue().AsText());
            if Call.Get('arguments', ArgsToken) then begin
                if ArgsToken.IsObject() then
                    ArgsToken.AsObject().WriteTo(ArgsText)
                else
                    ArgsText := ArgsToken.AsValue().AsText();
                FunctionObj.Add('arguments', ArgsText);
            end else
                FunctionObj.Add('arguments', '{}');
            OutCall.Add('type', 'function');
            if Call.Get('id', IdToken) then
                OutCall.Add('id', IdToken.AsValue().AsText());
            OutCall.Add('function', FunctionObj);
            Out.Add(OutCall);
        end;
        exit(Out);
    end;

    local procedure ParseWireToolCalls(WireCalls: JsonArray): JsonArray
    var
        Out: JsonArray;
        CallToken: JsonToken;
        Call: JsonObject;
        FunctionToken: JsonToken;
        FunctionObj: JsonObject;
        OutCall: JsonObject;
        IdToken: JsonToken;
        NameToken: JsonToken;
        ArgsToken: JsonToken;
        ArgsObj: JsonObject;
        ArgsText: Text;
        i: Integer;
    begin
        for i := 0 to WireCalls.Count() - 1 do begin
            WireCalls.Get(i, CallToken);
            if not CallToken.IsObject() then
                continue;
            Call := CallToken.AsObject();
            Clear(OutCall);
            Clear(ArgsObj);
            if Call.Get('id', IdToken) then
                OutCall.Add('id', IdToken.AsValue().AsText());
            if Call.Get('function', FunctionToken) and FunctionToken.IsObject() then begin
                FunctionObj := FunctionToken.AsObject();
                if FunctionObj.Get('name', NameToken) then
                    OutCall.Add('name', NameToken.AsValue().AsText());
                if FunctionObj.Get('arguments', ArgsToken) then begin
                    if ArgsToken.IsObject() then
                        ArgsObj := ArgsToken.AsObject()
                    else begin
                        ArgsText := ArgsToken.AsValue().AsText();
                        if not ArgsObj.ReadFrom(ArgsText) then
                            Clear(ArgsObj);
                    end;
                    OutCall.Add('arguments', ArgsObj);
                end else
                    OutCall.Add('arguments', EmptyObject());
            end;
            Out.Add(OutCall);
        end;
        exit(Out);
    end;

    local procedure EmptyObject(): JsonObject
    var
        Obj: JsonObject;
    begin
        exit(Obj);
    end;

    var
        DataUrlTok: Label 'data:%1;base64,%2', Locked = true;
        FileAsTextFmtTok: Label '[file: %1]\n%2', Locked = true;
        UnexpandedAttachmentErr: Label 'File part has an attachment id but no payload. Use Request.GetProviderMessages() before MapMessages.';
}

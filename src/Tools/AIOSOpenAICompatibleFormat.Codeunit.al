namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Chat/tools wire format for OpenAI Chat Completions and compatible APIs.
/// Reuse from custom providers that speak the same schema.
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
                'system', 'user':
                    begin
                        OutMsg.Add('role', Role);
                        if Msg.Get('content', ContentToken) then
                            OutMsg.Add('content', ContentToken.AsValue().AsText())
                        else
                            OutMsg.Add('content', '');
                        OutMessages.Add(OutMsg);
                    end;
                'assistant':
                    begin
                        OutMsg.Add('role', 'assistant');
                        if Msg.Get('content', ContentToken) and (not ContentToken.AsValue().IsNull()) then
                            OutMsg.Add('content', ContentToken.AsValue().AsText())
                        else
                            OutMsg.Add('content', '');
                        if Msg.Get('tool_calls', ToolCallsToken) then
                            OutMsg.Add('tool_calls', ToWireToolCalls(ToolCallsToken.AsArray()));
                        // Thinking models (DeepSeek / OpenCode Zen, …) require reasoning_content
                        // on assistant tool-call turns when continuing the conversation.
                        if Msg.Get('reasoning_content', ContentToken) then
                            OutMsg.Add('reasoning_content', ContentToken.AsValue().AsText());
                        OutMessages.Add(OutMsg);
                    end;
                'tool':
                    begin
                        OutMsg.Add('role', 'tool');
                        if Msg.Get('tool_call_id', ContentToken) then
                            OutMsg.Add('tool_call_id', ContentToken.AsValue().AsText());
                        if Msg.Get('content', ContentToken) then
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
    /// OpenAI-compatible APIs carry system in messages; always returns empty.
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
        // Providers often return "tool_calls": null on non-tool turns — AsArray() would throw.
        if not ToolCallsToken.IsArray() then
            exit(Empty);
        exit(ParseWireToolCalls(ToolCallsToken.AsArray()));
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
}

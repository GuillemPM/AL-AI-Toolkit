namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Chat/tools wire format for the Anthropic Messages API.
/// Reuse from custom providers that speak the same schema.
/// </summary>
codeunit 87419 "AIOS Anthropic Format" implements "AIOS Chat Format"
{
    Access = Public;

    /// <summary>
    /// Maps AIOS tool definitions to Anthropic Messages API tools.
    /// </summary>
    procedure MapTools(Definitions: JsonArray): JsonArray
    var
        Tools: JsonArray;
        DefToken: JsonToken;
        Def: JsonObject;
        Tool: JsonObject;
        NameToken: JsonToken;
        DescToken: JsonToken;
        ParamsToken: JsonToken;
        i: Integer;
    begin
        for i := 0 to Definitions.Count() - 1 do begin
            Definitions.Get(i, DefToken);
            Def := DefToken.AsObject();
            Clear(Tool);
            if Def.Get('name', NameToken) then
                Tool.Add('name', NameToken.AsValue().AsText());
            if Def.Get('description', DescToken) then
                Tool.Add('description', DescToken.AsValue().AsText());
            if Def.Get('parameters', ParamsToken) then
                Tool.Add('input_schema', ParamsToken)
            else
                Tool.Add('input_schema', EmptyObject());
            Tools.Add(Tool);
        end;
        exit(Tools);
    end;

    /// <summary>
    /// Maps AIOS message history to Anthropic messages (system extracted separately).
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
        ContentArr: JsonArray;
        Role: Text;
        i: Integer;
    begin
        for i := 0 to AiosMessages.Count() - 1 do begin
            AiosMessages.Get(i, MsgToken);
            Msg := MsgToken.AsObject();
            if not Msg.Get('role', RoleToken) then
                continue;
            Role := RoleToken.AsValue().AsText();
            if Role = 'system' then
                continue;
            Clear(OutMsg);
            case Role of
                'user':
                    begin
                        OutMsg.Add('role', 'user');
                        if Msg.Get('content', ContentToken) then
                            OutMsg.Add('content', ContentToken.AsValue().AsText())
                        else
                            OutMsg.Add('content', '');
                        OutMessages.Add(OutMsg);
                    end;
                'assistant':
                    begin
                        OutMsg.Add('role', 'assistant');
                        Clear(ContentArr);
                        if Msg.Get('content', ContentToken) and (not ContentToken.AsValue().IsNull()) then
                            if ContentToken.AsValue().AsText() <> '' then
                                ContentArr.Add(TextBlock(ContentToken.AsValue().AsText()));
                        if Msg.Get('tool_calls', ToolCallsToken) then
                            AppendToolUseBlocks(ContentArr, ToolCallsToken.AsArray());
                        OutMsg.Add('content', ContentArr);
                        OutMessages.Add(OutMsg);
                    end;
                'tool':
                    begin
                        OutMsg.Add('role', 'user');
                        Clear(ContentArr);
                        ContentArr.Add(ToolResultBlock(Msg));
                        OutMsg.Add('content', ContentArr);
                        OutMessages.Add(OutMsg);
                    end;
            end;
        end;
        exit(OutMessages);
    end;

    /// <summary>
    /// Concatenates system-role messages for Anthropic's top-level system field.
    /// </summary>
    procedure GetSystemText(AiosMessages: JsonArray): Text
    var
        MsgToken: JsonToken;
        Msg: JsonObject;
        RoleToken: JsonToken;
        ContentToken: JsonToken;
        SystemText: Text;
        i: Integer;
    begin
        for i := 0 to AiosMessages.Count() - 1 do begin
            AiosMessages.Get(i, MsgToken);
            Msg := MsgToken.AsObject();
            if not Msg.Get('role', RoleToken) then
                continue;
            if RoleToken.AsValue().AsText() <> 'system' then
                continue;
            if Msg.Get('content', ContentToken) then
                if SystemText = '' then
                    SystemText := ContentToken.AsValue().AsText()
                else
                    SystemText += ' ' + ContentToken.AsValue().AsText();
        end;
        exit(SystemText);
    end;

    /// <summary>
    /// Accepts the Anthropic response content array (blocks including tool_use).
    /// </summary>
    procedure ParseToolCalls(WireToken: JsonToken): JsonArray
    var
        Empty: JsonArray;
        ContentBlocks: JsonArray;
        Out: JsonArray;
        BlockToken: JsonToken;
        Block: JsonObject;
        OutCall: JsonObject;
        TypeToken: JsonToken;
        IdToken: JsonToken;
        NameToken: JsonToken;
        InputToken: JsonToken;
        InputObj: JsonObject;
        i: Integer;
    begin
        if not WireToken.IsArray() then
            exit(Empty);
        ContentBlocks := WireToken.AsArray();
        for i := 0 to ContentBlocks.Count() - 1 do begin
            ContentBlocks.Get(i, BlockToken);
            Block := BlockToken.AsObject();
            if not Block.Get('type', TypeToken) then
                continue;
            if TypeToken.AsValue().AsText() <> 'tool_use' then
                continue;
            Clear(OutCall);
            if Block.Get('id', IdToken) then
                OutCall.Add('id', IdToken.AsValue().AsText());
            if Block.Get('name', NameToken) then
                OutCall.Add('name', NameToken.AsValue().AsText());
            if Block.Get('input', InputToken) and InputToken.IsObject() then
                OutCall.Add('arguments', InputToken.AsObject())
            else begin
                Clear(InputObj);
                OutCall.Add('arguments', InputObj);
            end;
            Out.Add(OutCall);
        end;
        exit(Out);
    end;

    local procedure AppendToolUseBlocks(var ContentArr: JsonArray; AiosToolCalls: JsonArray)
    var
        CallToken: JsonToken;
        Call: JsonObject;
        Block: JsonObject;
        IdToken: JsonToken;
        NameToken: JsonToken;
        i: Integer;
    begin
        for i := 0 to AiosToolCalls.Count() - 1 do begin
            AiosToolCalls.Get(i, CallToken);
            Call := CallToken.AsObject();
            Clear(Block);
            Block.Add('type', 'tool_use');
            if Call.Get('id', IdToken) then
                Block.Add('id', IdToken.AsValue().AsText());
            if Call.Get('name', NameToken) then
                Block.Add('name', NameToken.AsValue().AsText());
            Block.Add('input', ParseArgsObject(Call));
            ContentArr.Add(Block);
        end;
    end;

    local procedure ParseArgsObject(Call: JsonObject): JsonObject
    var
        ArgsToken: JsonToken;
        Args: JsonObject;
        ArgsText: Text;
    begin
        if not Call.Get('arguments', ArgsToken) then
            exit(Args);
        if ArgsToken.IsObject() then
            exit(ArgsToken.AsObject());
        ArgsText := ArgsToken.AsValue().AsText();
        if not Args.ReadFrom(ArgsText) then
            Clear(Args);
        exit(Args);
    end;

    local procedure TextBlock(TextValue: Text): JsonObject
    var
        Block: JsonObject;
    begin
        Block.Add('type', 'text');
        Block.Add('text', TextValue);
        exit(Block);
    end;

    local procedure ToolResultBlock(Msg: JsonObject): JsonObject
    var
        Block: JsonObject;
        Token: JsonToken;
    begin
        Block.Add('type', 'tool_result');
        if Msg.Get('tool_call_id', Token) then
            Block.Add('tool_use_id', Token.AsValue().AsText());
        if Msg.Get('content', Token) then
            Block.Add('content', Token.AsValue().AsText())
        else
            Block.Add('content', '');
        exit(Block);
    end;

    local procedure EmptyObject(): JsonObject
    var
        Obj: JsonObject;
    begin
        exit(Obj);
    end;
}

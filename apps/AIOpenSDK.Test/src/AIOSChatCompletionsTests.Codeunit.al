namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.ProviderUtils;

/// <summary>
/// Tests for the shared Chat Completions request dialects, response parsing, and wire message mapping.
/// </summary>
codeunit 87501 "AIOS Chat Completions Tests"
{

    Access = Internal;
    Subtype = Test;

    [Test]
    procedure BuildRequestBody_OpenAIDialect_UsesMaxCompletionTokens()
    var
        Root: JsonObject;
    begin
        Root := BuildBody(true, "AIOS Reasoning Effort"::ProviderDefault);
        AssertHasKey(Root, 'max_completion_tokens');
        AssertNoKey(Root, 'max_tokens');
    end;

    [Test]
    procedure BuildRequestBody_CompatibleDialect_UsesMaxTokens()
    var
        Root: JsonObject;
    begin
        Root := BuildBody(false, "AIOS Reasoning Effort"::ProviderDefault);
        AssertHasKey(Root, 'max_tokens');
        AssertNoKey(Root, 'max_completion_tokens');
    end;

    [Test]
    procedure BuildRequestBody_MaxTokensZero_OmitsBoth()
    var
        Request: Record "AIOS Chat Request";
        Client: Codeunit "AIOS Chat Completions Client";
        Warnings: JsonArray;
        Root: JsonObject;
    begin
        Request.SetPrompt('hi');
        Root.ReadFrom(Client.BuildRequestBody('m', Request, true, Warnings));
        AssertNoKey(Root, 'max_tokens');
        AssertNoKey(Root, 'max_completion_tokens');
    end;

    [Test]
    procedure BuildRequestBody_OpenAIDialect_XHighPassesThrough()
    var
        Root: JsonObject;
    begin
        Root := BuildBody(true, "AIOS Reasoning Effort"::XHigh);
        AssertTextValue(Root, 'reasoning_effort', 'xhigh');
    end;

    [Test]
    procedure ApplyCompatible_XHigh_CoercesToHighWithWarning()
    var
        Request: Record "AIOS Chat Request";
        FormatOptions: Codeunit "AIOS Chat Completions Options";
        Root: JsonObject;
        Warnings: JsonArray;
        WarningToken: JsonToken;
    begin
        Request.SetReasoning("AIOS Reasoning Effort"::XHigh);
        FormatOptions.Apply(Root, Request, Warnings, false);
        AssertTextValue(Root, 'reasoning_effort', 'high');
        if Warnings.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Warnings.Count());
        Warnings.Get(0, WarningToken);
        AssertTextValue(WarningToken.AsObject(), 'type', 'compatibility');
    end;

    [Test]
    procedure ApplyCompatible_Minimal_CoercesToLow()
    var
        Request: Record "AIOS Chat Request";
        FormatOptions: Codeunit "AIOS Chat Completions Options";
        Root: JsonObject;
        Warnings: JsonArray;
    begin
        Request.SetReasoning("AIOS Reasoning Effort"::Minimal);
        FormatOptions.Apply(Root, Request, Warnings);
        AssertTextValue(Root, 'reasoning_effort', 'low');
    end;

    [Test]
    procedure Parse_ValidResponse_Succeeds()
    var
        Response: Record "AIOS Chat Response";
    begin
        if not Parse('{"choices":[{"finish_reason":"stop","message":{"content":"ok"}}],"usage":{"prompt_tokens":3,"completion_tokens":2}}', Response) then
            Error(UnexpectedParseFailureErr, Response."Error Message");
        AssertText('ok', Response.GetText());
        if (Response."Input Tokens" <> 3) or (Response."Output Tokens" <> 2) then
            Error(UnexpectedUsageErr);
    end;

    [Test]
    procedure Parse_ChoicesNull_ReturnsParseFailed()
    begin
        AssertParseFailed('{"choices":null}');
    end;

    [Test]
    procedure Parse_ChoicesObject_ReturnsParseFailed()
    begin
        AssertParseFailed('{"choices":{"message":{"content":"x"}}}');
    end;

    [Test]
    procedure Parse_ChoiceNotObject_ReturnsParseFailed()
    begin
        AssertParseFailed('{"choices":[null]}');
    end;

    [Test]
    procedure Parse_MessageNull_ReturnsParseFailed()
    begin
        AssertParseFailed('{"choices":[{"finish_reason":"stop","message":null}]}');
    end;

    [Test]
    procedure Parse_ContentObject_ReturnsParseFailed()
    begin
        AssertParseFailed('{"choices":[{"finish_reason":"stop","message":{"content":{"x":1}}}]}');
    end;

    [Test]
    procedure Parse_NullOptionalFields_Succeeds()
    var
        Response: Record "AIOS Chat Response";
    begin
        if not Parse('{"choices":[{"finish_reason":null,"message":{"content":"ok","reasoning_content":null}}],"usage":null}', Response) then
            Error(UnexpectedParseFailureErr, Response."Error Message");
        AssertText('ok', Response.GetText());
        AssertText('', Response.GetReasoningContent());
    end;

    [Test]
    procedure Parse_UsageTokensNull_Succeeds()
    var
        Response: Record "AIOS Chat Response";
    begin
        if not Parse('{"choices":[{"message":{"content":"ok"}}],"usage":{"prompt_tokens":null,"completion_tokens":"n/a"}}', Response) then
            Error(UnexpectedParseFailureErr, Response."Error Message");
        if (Response."Input Tokens" <> 0) or (Response."Output Tokens" <> 0) then
            Error(UnexpectedUsageErr);
    end;

    [Test]
    procedure Parse_ContentPartsArray_JoinsText()
    var
        Response: Record "AIOS Chat Response";
    begin
        if not Parse('{"choices":[{"message":{"content":[{"type":"text","text":"a"},{"type":"image_url"},null,{"type":"text","text":"b"}]}}]}', Response) then
            Error(UnexpectedParseFailureErr, Response."Error Message");
        AssertText('ab', Response.GetText());
    end;

    [Test]
    procedure Parse_ToolCallNullFields_Succeeds()
    var
        Response: Record "AIOS Chat Response";
        Calls: JsonArray;
        CallToken: JsonToken;
        ArgsToken: JsonToken;
    begin
        if not Parse('{"choices":[{"finish_reason":"tool_calls","message":{"content":null,"tool_calls":[{"id":null,"type":"function","function":{"name":"echo","arguments":null}}]}}]}', Response) then
            Error(UnexpectedParseFailureErr, Response."Error Message");
        Calls := Response.GetToolCallsJson();
        if Calls.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Calls.Count());
        Calls.Get(0, CallToken);
        AssertTextValue(CallToken.AsObject(), 'id', '');
        AssertTextValue(CallToken.AsObject(), 'name', 'echo');
        CallToken.AsObject().Get('arguments', ArgsToken);
        if not ArgsToken.IsObject() then
            Error(ExpectedObjectErr, 'arguments');
    end;

    [Test]
    procedure ParseToolCalls_NonObjectArguments_YieldsEmptyObject()
    var
        FormatCU: Codeunit "AIOS Chat Completions Format";
        ChatFormat: Interface "AIOS Chat Format";
        WireToken: JsonToken;
        Calls: JsonArray;
        CallToken: JsonToken;
        ArgsToken: JsonToken;
    begin
        ChatFormat := FormatCU;
        WireToken.ReadFrom('[{"id":"c1","function":{"name":null,"arguments":["x"]}}]');
        Calls := ChatFormat.ParseToolCalls(WireToken);
        if Calls.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Calls.Count());
        Calls.Get(0, CallToken);
        AssertTextValue(CallToken.AsObject(), 'name', '');
        CallToken.AsObject().Get('arguments', ArgsToken);
        if not ArgsToken.IsObject() then
            Error(ExpectedObjectErr, 'arguments');
        if ArgsToken.AsObject().Keys().Count() <> 0 then
            Error(UnexpectedCountErr, 0, ArgsToken.AsObject().Keys().Count());
    end;

    [Test]
    procedure MapMessages_EmptyReasoningContent_Omitted()
    var
        Request: Record "AIOS Chat Request";
        FormatCU: Codeunit "AIOS Chat Completions Format";
        Call: Codeunit "AIOS Tool Call";
        ToolCalls: List of [Codeunit "AIOS Tool Call"];
        Args: JsonObject;
        WireMessages: JsonArray;
        MsgToken: JsonToken;
    begin
        Call.SetCall('call_1', 'echo', Args);
        ToolCalls.Add(Call);
        Request.AppendUserMessage('hi');
        Request.AppendAssistantToolCalls('', ToolCalls, '');

        WireMessages := FormatCU.MapMessages(Request.GetMessages());
        WireMessages.Get(1, MsgToken);
        AssertNoKey(MsgToken.AsObject(), 'reasoning_content');
    end;

    [Test]
    procedure MapMessages_NullOrEmptyReasoningContent_Omitted()
    var
        FormatCU: Codeunit "AIOS Chat Completions Format";
        AiosMessages: JsonArray;
        WireMessages: JsonArray;
        MsgToken: JsonToken;
        i: Integer;
    begin
        AiosMessages.ReadFrom('[{"role":"assistant","content":"a","reasoning_content":null},{"role":"assistant","content":"b","reasoning_content":""}]');
        WireMessages := FormatCU.MapMessages(AiosMessages);
        for i := 0 to 1 do begin
            WireMessages.Get(i, MsgToken);
            AssertNoKey(MsgToken.AsObject(), 'reasoning_content');
        end;
    end;

    [Test]
    procedure ChatCompletionsFormat_TextFilePart_UsesRealNewline()
    var
        FormatCU: Codeunit "AIOS Chat Completions Format";
    begin
        AssertFileTextUsesLf(FormatCU.MapMessages(TextFileMessages()));
    end;

    [Test]
    procedure AnthropicFormat_TextFilePart_UsesRealNewline()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
    begin
        AssertFileTextUsesLf(FormatCU.MapMessages(TextFileMessages()));
    end;

    local procedure BuildBody(OpenAIDialect: Boolean; Reasoning: Enum "AIOS Reasoning Effort"): JsonObject
    var
        Request: Record "AIOS Chat Request";
        Client: Codeunit "AIOS Chat Completions Client";
        Warnings: JsonArray;
        Root: JsonObject;
    begin
        Request.SetPrompt('hi');
        Request.SetMaxTokens(256);
        Request.SetReasoning(Reasoning);
        Root.ReadFrom(Client.BuildRequestBody('m', Request, OpenAIDialect, Warnings));
        exit(Root);
    end;

    local procedure Parse(ResponseText: Text; var Response: Record "AIOS Chat Response"): Boolean
    var
        Client: Codeunit "AIOS Chat Completions Client";
    begin
        exit(Client.ParseSuccess(ResponseText, Response));
    end;

    local procedure AssertParseFailed(ResponseText: Text)
    var
        Response: Record "AIOS Chat Response";
    begin
        if Parse(ResponseText, Response) then
            Error(ExpectedParseFailureErr, ResponseText);
        if Response.GetErrorType() <> "AIOS Error Type"::ParseFailed then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
    end;

    local procedure TextFileMessages(): JsonArray
    var
        AiosMessages: JsonArray;
        Msg: JsonObject;
        ContentParts: JsonArray;
        FilePart: JsonObject;
    begin
        FilePart.Add('type', 'file');
        FilePart.Add('mediaType', 'text/plain');
        FilePart.Add('text', 'body');
        FilePart.Add('filename', 'note.txt');
        ContentParts.Add(FilePart);
        Msg.Add('role', 'user');
        Msg.Add('content', ContentParts);
        AiosMessages.Add(Msg);
        exit(AiosMessages);
    end;

    local procedure AssertFileTextUsesLf(WireMessages: JsonArray)
    var
        MsgToken: JsonToken;
        Lf: Text[1];
        Found: Text;
    begin
        Lf[1] := 10;
        WireMessages.Get(0, MsgToken);
        Found := FindText(MsgToken, '[file: note.txt]');
        AssertText('[file: note.txt]' + Lf + 'body', Found);
    end;

    /// <summary>
    /// Depth-first search for the first "text" property whose value contains Needle.
    /// </summary>
    local procedure FindText(Token: JsonToken; Needle: Text): Text
    var
        Obj: JsonObject;
        Arr: JsonArray;
        Child: JsonToken;
        PropertyName: Text;
        Found: Text;
        i: Integer;
    begin
        if Token.IsObject() then begin
            Obj := Token.AsObject();
            foreach PropertyName in Obj.Keys() do begin
                Obj.Get(PropertyName, Child);
                if (PropertyName = 'text') and Child.IsValue() then
                    if StrPos(Child.AsValue().AsText(), Needle) > 0 then
                        exit(Child.AsValue().AsText());
                Found := FindText(Child, Needle);
                if Found <> '' then
                    exit(Found);
            end;
        end;
        if Token.IsArray() then begin
            Arr := Token.AsArray();
            for i := 0 to Arr.Count() - 1 do begin
                Arr.Get(i, Child);
                Found := FindText(Child, Needle);
                if Found <> '' then
                    exit(Found);
            end;
        end;
        exit('');
    end;

    local procedure AssertHasKey(Obj: JsonObject; PropertyName: Text)
    begin
        if not Obj.Contains(PropertyName) then
            Error(MissingFieldErr, PropertyName);
    end;

    local procedure AssertNoKey(Obj: JsonObject; PropertyName: Text)
    begin
        if Obj.Contains(PropertyName) then
            Error(UnexpectedFieldErr, PropertyName);
    end;

    local procedure AssertTextValue(Obj: JsonObject; PropertyName: Text; Expected: Text)
    var
        Token: JsonToken;
    begin
        if not Obj.Get(PropertyName, Token) then
            Error(MissingFieldErr, PropertyName);
        AssertText(Expected, Token.AsValue().AsText());
    end;

    local procedure AssertText(Expected: Text; Actual: Text)
    begin
        if Expected <> Actual then
            Error(UnexpectedTextErr, Expected, Actual);
    end;

    var
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        MissingFieldErr: Label 'Missing field %1.', Comment = '%1 = field name';
        UnexpectedFieldErr: Label 'Did not expect field %1.', Comment = '%1 = field name';
        ExpectedObjectErr: Label 'Expected %1 to be a JSON object.', Comment = '%1 = field name';
        UnexpectedParseFailureErr: Label 'Expected parse to succeed, got: %1', Comment = '%1 = error message';
        ExpectedParseFailureErr: Label 'Expected parse to fail for: %1', Comment = '%1 = response body';
        UnexpectedErrorTypeErr: Label 'Expected ParseFailed, got %1.', Comment = '%1 = actual';
        UnexpectedUsageErr: Label 'Unexpected usage token counts.';
}

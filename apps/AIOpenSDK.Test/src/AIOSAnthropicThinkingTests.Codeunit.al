namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Examples;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using PM.Guillem.AIOpenSDK.ProviderUtils;

/// <summary>
/// Anthropic extended thinking: thinking-block replay on tool-loop turns and thinking option validation.
/// </summary>
codeunit 87501 "AIOS Anthropic Thinking Tests"
{

    Access = Internal;
    Subtype = Test;

    [Test]
    procedure ExtractProviderContent_KeepsThinkingBlocksAndSignatures()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        WireToken: JsonToken;
        ProviderContent: JsonObject;
        Token: JsonToken;
        Blocks: JsonArray;
    begin
        WireToken := ThinkingToolUseWireContent('toolu_1').AsToken();

        ProviderContent := FormatCU.ExtractProviderContent(WireToken);

        if not ProviderContent.Get('provider', Token) then
            Error(MissingFieldErr, 'provider');
        if Token.AsValue().AsText() <> 'anthropic' then
            Error(UnexpectedTextErr, 'anthropic', Token.AsValue().AsText());
        if not ProviderContent.Get('content', Token) then
            Error(MissingFieldErr, 'content');
        Blocks := Token.AsArray();
        if Blocks.Count() <> 4 then
            Error(UnexpectedCountErr, 4, Blocks.Count());
        AssertBlockField(Blocks, 0, 'signature', 'SIG1');
        AssertBlockField(Blocks, 1, 'data', 'REDACTED1');
        AssertBlockField(Blocks, 3, 'id', 'toolu_1');
        if FormatCU.GetThinkingText(WireToken) <> 'Let me check.' then
            Error(UnexpectedTextErr, 'Let me check.', FormatCU.GetThinkingText(WireToken));
    end;

    [Test]
    procedure ExtractProviderContent_NoThinking_ReturnsEmpty()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        Blocks: JsonArray;
        ProviderContent: JsonObject;
    begin
        Blocks.Add(TextBlock('hello'));
        Blocks.Add(ToolUseBlock('toolu_1'));

        ProviderContent := FormatCU.ExtractProviderContent(Blocks.AsToken());

        if ProviderContent.Keys().Count() <> 0 then
            Error(UnexpectedCountErr, 0, ProviderContent.Keys().Count());
    end;

    [Test]
    procedure AppendAssistantToolCalls_LegacyOverload_NoProviderContentKey()
    var
        Request: Record "AIOS Chat Request";
        Msg: JsonObject;
    begin
        Request.AppendUserMessage('hi');
        Request.AppendAssistantToolCalls('', EchoToolCalls('toolu_1'), 'reasoning');

        Msg := GetMessage(Request.GetMessages(), 1);
        if Msg.Contains('provider_content') then
            Error(UnexpectedFieldErr, 'provider_content');
    end;

    [Test]
    procedure AppendAssistantToolCalls_FromResponse_StoresProviderContent()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        CallsArr: JsonArray;
        Msg: JsonObject;
        Token: JsonToken;
    begin
        CallsArr.Add(ToolCallObject('toolu_1'));
        Response.SetToolCallsJson(CallsArr);
        Response.SetProviderContent(FormatCU.ExtractProviderContent(ThinkingToolUseWireContent('toolu_1').AsToken()));
        Request.AppendUserMessage('hi');

        Request.AppendAssistantToolCalls(Response);

        Msg := GetMessage(Request.GetMessages(), 1);
        if not Msg.Get('provider_content', Token) then
            Error(MissingFieldErr, 'provider_content');
        if not Msg.Get('tool_calls', Token) then
            Error(MissingFieldErr, 'tool_calls');
        if Token.AsArray().Count() <> 1 then
            Error(UnexpectedCountErr, 1, Token.AsArray().Count());
    end;

    [Test]
    procedure AnthropicMapMessages_ReplaysThinkingBeforeToolUse()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        Request: Record "AIOS Chat Request";
        WireMessages: JsonArray;
        Blocks: JsonArray;
    begin
        BuildThinkingToolHistory(Request, 'toolu_1', 'toolu_1');

        WireMessages := FormatCU.MapMessages(Request.GetMessages());

        if WireMessages.Count() <> 3 then
            Error(UnexpectedCountErr, 3, WireMessages.Count());
        Blocks := GetContentBlocks(WireMessages, 1);
        if Blocks.Count() <> 4 then
            Error(UnexpectedCountErr, 4, Blocks.Count());
        AssertBlockField(Blocks, 0, 'type', 'thinking');
        AssertBlockField(Blocks, 0, 'signature', 'SIG1');
        AssertBlockField(Blocks, 1, 'type', 'redacted_thinking');
        AssertBlockField(Blocks, 1, 'data', 'REDACTED1');
        AssertBlockField(Blocks, 2, 'type', 'text');
        AssertBlockField(Blocks, 3, 'type', 'tool_use');
        AssertBlockField(Blocks, 3, 'id', 'toolu_1');
        AssertBlockField(GetContentBlocks(WireMessages, 2), 0, 'tool_use_id', 'toolu_1');
    end;

    [Test]
    procedure AnthropicMapMessages_EditedToolCalls_ThinkingFirstThenRebuilt()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        Request: Record "AIOS Chat Request";
        Blocks: JsonArray;
    begin
        BuildThinkingToolHistory(Request, 'toolu_1', 'toolu_edited');

        Blocks := GetContentBlocks(FormatCU.MapMessages(Request.GetMessages()), 1);

        if Blocks.Count() <> 3 then
            Error(UnexpectedCountErr, 3, Blocks.Count());
        AssertBlockField(Blocks, 0, 'signature', 'SIG1');
        AssertBlockField(Blocks, 1, 'type', 'redacted_thinking');
        AssertBlockField(Blocks, 2, 'type', 'tool_use');
        AssertBlockField(Blocks, 2, 'id', 'toolu_edited');
    end;

    [Test]
    procedure AnthropicMapMessages_OtherProviderContent_Ignored()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        Request: Record "AIOS Chat Request";
        ProviderContent: JsonObject;
        Blocks: JsonArray;
    begin
        ProviderContent.Add('provider', 'other');
        ProviderContent.Add('content', ThinkingToolUseWireContent('toolu_1'));
        Request.AppendUserMessage('hi');
        Request.AppendAssistantToolCalls('', EchoToolCalls('toolu_1'), '', ProviderContent);

        Blocks := GetContentBlocks(FormatCU.MapMessages(Request.GetMessages()), 1);

        if Blocks.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Blocks.Count());
        AssertBlockField(Blocks, 0, 'type', 'tool_use');
    end;

    [Test]
    procedure ChatCompletionsMapMessages_DoesNotSendProviderContent()
    var
        FormatCU: Codeunit "AIOS Chat Completions Format";
        ChatFormat: Interface "AIOS Chat Format";
        Request: Record "AIOS Chat Request";
        WireMessages: JsonArray;
    begin
        ChatFormat := FormatCU;
        BuildThinkingToolHistory(Request, 'toolu_1', 'toolu_1');

        WireMessages := ChatFormat.MapMessages(Request.GetMessages());

        if GetMessage(WireMessages, 1).Contains('provider_content') then
            Error(UnexpectedFieldErr, 'provider_content');
    end;

    [Test]
    procedure GenerateText_ToolLoop_CarriesProviderContentIntoHistory()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        FormatCU: Codeunit "AIOS Anthropic Format";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Tool: Interface "AIOS Tool";
        Messages: JsonArray;
        Msg: JsonObject;
        Token: JsonToken;
        i: Integer;
        Found: Boolean;
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Mock.SetNextToolCallThenResponse('toolu_1', 'echo', '{"message":"loop"}', 'done');
        Mock.SetNextToolCallProviderContent(FormatCU.ExtractProviderContent(ThinkingToolUseWireContent('toolu_1').AsToken()));
        Request.SetPrompt('use echo');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);

        if Result.Output() <> 'done' then
            Error(UnexpectedTextErr, 'done', Result.Output());
        Messages := Request.GetMessages();
        for i := 0 to Messages.Count() - 1 do begin
            Msg := GetMessage(Messages, i);
            if Msg.Contains('tool_calls') then begin
                if not Msg.Get('provider_content', Token) then
                    Error(MissingFieldErr, 'provider_content');
                Found := true;
            end;
        end;
        if not Found then
            Error(MissingFieldErr, 'tool_calls');
    end;

    [Test]
    procedure ApplyOptions_SmallMaxTokens_RaisesMaxTokensAboveBudget()
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
    begin
        Request.SetReasoning("AIOS Reasoning Effort"::Medium);
        Root.Add('max_tokens', 1024);

        FormatOptions.Apply(Root, Request, Warnings);

        AssertInteger(1024, GetBudgetTokens(Root));
        AssertInteger(2048, GetInteger(Root, 'max_tokens'));
        AssertWarning(Warnings, 'compatibility', 'max_tokens');
    end;

    [Test]
    procedure ApplyOptions_BudgetAlwaysBelowMaxTokens()
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
        Efforts: List of [Enum "AIOS Reasoning Effort"];
        Effort: Enum "AIOS Reasoning Effort";
        MaxTokensValues: List of [Integer];
        MaxTokens: Integer;
        Budget: Integer;
    begin
        Efforts.Add("AIOS Reasoning Effort"::Minimal);
        Efforts.Add("AIOS Reasoning Effort"::Low);
        Efforts.Add("AIOS Reasoning Effort"::Medium);
        Efforts.Add("AIOS Reasoning Effort"::High);
        Efforts.Add("AIOS Reasoning Effort"::XHigh);
        MaxTokensValues.Add(256);
        MaxTokensValues.Add(1024);
        MaxTokensValues.Add(1025);
        MaxTokensValues.Add(4096);
        MaxTokensValues.Add(32000);

        foreach Effort in Efforts do
            foreach MaxTokens in MaxTokensValues do begin
                Clear(Request);
                Clear(Root);
                Clear(Warnings);
                Request.SetReasoning(Effort);
                Root.Add('max_tokens', MaxTokens);
                FormatOptions.Apply(Root, Request, Warnings);
                Budget := GetBudgetTokens(Root);
                if (Budget < 1024) or (Budget >= GetInteger(Root, 'max_tokens')) then
                    Error(InvalidBudgetErr, Budget, GetInteger(Root, 'max_tokens'), MaxTokens);
            end;
    end;

    [Test]
    procedure ApplyOptions_LargeMaxTokens_KeepsMaxTokensAndPercentBudget()
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
    begin
        Request.SetReasoning("AIOS Reasoning Effort"::Medium);
        Root.Add('max_tokens', 32000);

        FormatOptions.Apply(Root, Request, Warnings);

        AssertInteger(9600, GetBudgetTokens(Root));
        AssertInteger(32000, GetInteger(Root, 'max_tokens'));
        AssertInteger(0, Warnings.Count());
    end;

    [Test]
    procedure ApplyOptions_Thinking_OmitsTemperatureAndTopK()
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
    begin
        Request.SetReasoning("AIOS Reasoning Effort"::Medium);
        Request.SetTemperature(0.2);
        Request.SetTopK(40);
        Request.SetTopP(0.95);
        Root.Add('max_tokens', 4096);
        Root.Add('temperature', 0.2);

        FormatOptions.Apply(Root, Request, Warnings);

        if Root.Contains('temperature') then
            Error(UnexpectedFieldErr, 'temperature');
        if Root.Contains('top_k') then
            Error(UnexpectedFieldErr, 'top_k');
        if not Root.Contains('top_p') then
            Error(MissingFieldErr, 'top_p');
        if not Root.Contains('thinking') then
            Error(MissingFieldErr, 'thinking');
        AssertWarning(Warnings, 'unsupported', 'temperature');
        AssertWarning(Warnings, 'unsupported', 'top_k');
    end;

    [Test]
    procedure ApplyOptions_Thinking_OmitsTopPBelowRange()
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
    begin
        Request.SetReasoning("AIOS Reasoning Effort"::Medium);
        Request.SetTopP(0.9);
        Root.Add('max_tokens', 4096);

        FormatOptions.Apply(Root, Request, Warnings);

        if Root.Contains('top_p') then
            Error(UnexpectedFieldErr, 'top_p');
        AssertWarning(Warnings, 'unsupported', 'top_p');
    end;

    [Test]
    procedure ApplyOptions_NoThinking_KeepsSampling()
    var
        FormatOptions: Codeunit "AIOS Anthropic Options";
        Request: Record "AIOS Chat Request";
        Root: JsonObject;
        Warnings: JsonArray;
    begin
        Request.SetTemperature(0.2);
        Request.SetTopK(40);
        Request.SetTopP(0.5);
        Root.Add('max_tokens', 1024);
        Root.Add('temperature', 0.2);

        FormatOptions.Apply(Root, Request, Warnings);

        if not Root.Contains('temperature') then
            Error(MissingFieldErr, 'temperature');
        if not Root.Contains('top_k') then
            Error(MissingFieldErr, 'top_k');
        if not Root.Contains('top_p') then
            Error(MissingFieldErr, 'top_p');
        if Root.Contains('thinking') then
            Error(UnexpectedFieldErr, 'thinking');
        AssertInteger(1024, GetInteger(Root, 'max_tokens'));
        AssertInteger(0, Warnings.Count());
    end;

    local procedure BuildThinkingToolHistory(var Request: Record "AIOS Chat Request"; WireToolUseId: Text; HistoryToolCallId: Text)
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
    begin
        Request.AppendUserMessage('Which customers are blocked?');
        Request.AppendAssistantToolCalls(
            'Checking.', EchoToolCalls(HistoryToolCallId), '',
            FormatCU.ExtractProviderContent(ThinkingToolUseWireContent(WireToolUseId).AsToken()));
        Request.AppendToolResult(HistoryToolCallId, 'echo', 'none');
    end;

    local procedure ThinkingToolUseWireContent(ToolUseId: Text): JsonArray
    var
        Blocks: JsonArray;
        Thinking: JsonObject;
        Redacted: JsonObject;
    begin
        Thinking.Add('type', 'thinking');
        Thinking.Add('thinking', 'Let me check.');
        Thinking.Add('signature', 'SIG1');
        Redacted.Add('type', 'redacted_thinking');
        Redacted.Add('data', 'REDACTED1');
        Blocks.Add(Thinking);
        Blocks.Add(Redacted);
        Blocks.Add(TextBlock('Checking.'));
        Blocks.Add(ToolUseBlock(ToolUseId));
        exit(Blocks);
    end;

    local procedure TextBlock(Value: Text): JsonObject
    var
        Block: JsonObject;
    begin
        Block.Add('type', 'text');
        Block.Add('text', Value);
        exit(Block);
    end;

    local procedure ToolUseBlock(Id: Text): JsonObject
    var
        Block: JsonObject;
        Input: JsonObject;
    begin
        Input.Add('message', 'ping');
        Block.Add('type', 'tool_use');
        Block.Add('id', Id);
        Block.Add('name', 'echo');
        Block.Add('input', Input);
        exit(Block);
    end;

    local procedure ToolCallObject(Id: Text): JsonObject
    var
        CallObj: JsonObject;
        Args: JsonObject;
    begin
        Args.Add('message', 'ping');
        CallObj.Add('id', Id);
        CallObj.Add('name', 'echo');
        CallObj.Add('arguments', Args);
        exit(CallObj);
    end;

    local procedure EchoToolCalls(Id: Text): List of [Codeunit "AIOS Tool Call"]
    var
        Call: Codeunit "AIOS Tool Call";
        ToolCalls: List of [Codeunit "AIOS Tool Call"];
        Args: JsonObject;
    begin
        Args.Add('message', 'ping');
        Call.SetCall(Id, 'echo', Args);
        ToolCalls.Add(Call);
        exit(ToolCalls);
    end;

    local procedure GetMessage(Messages: JsonArray; Index: Integer): JsonObject
    var
        Token: JsonToken;
    begin
        Messages.Get(Index, Token);
        exit(Token.AsObject());
    end;

    local procedure GetContentBlocks(Messages: JsonArray; Index: Integer): JsonArray
    var
        Token: JsonToken;
    begin
        if not GetMessage(Messages, Index).Get('content', Token) then
            Error(MissingFieldErr, 'content');
        exit(Token.AsArray());
    end;

    local procedure AssertBlockField(Blocks: JsonArray; Index: Integer; FieldName: Text; Expected: Text)
    var
        BlockToken: JsonToken;
        Token: JsonToken;
    begin
        Blocks.Get(Index, BlockToken);
        if not BlockToken.AsObject().Get(FieldName, Token) then
            Error(MissingFieldErr, FieldName);
        if Token.AsValue().AsText() <> Expected then
            Error(UnexpectedTextErr, Expected, Token.AsValue().AsText());
    end;

    local procedure GetBudgetTokens(Root: JsonObject): Integer
    var
        Token: JsonToken;
    begin
        if not Root.Get('thinking', Token) then
            Error(MissingFieldErr, 'thinking');
        exit(GetInteger(Token.AsObject(), 'budget_tokens'));
    end;

    local procedure GetInteger(Obj: JsonObject; FieldName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not Obj.Get(FieldName, Token) then
            Error(MissingFieldErr, FieldName);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure AssertInteger(Expected: Integer; Actual: Integer)
    begin
        if Expected <> Actual then
            Error(UnexpectedIntErr, Expected, Actual);
    end;

    local procedure AssertWarning(Warnings: JsonArray; WarningType: Text; Feature: Text)
    var
        Token: JsonToken;
        Warning: JsonObject;
        TypeToken: JsonToken;
        FeatureToken: JsonToken;
    begin
        foreach Token in Warnings do begin
            Warning := Token.AsObject();
            if Warning.Get('type', TypeToken) and Warning.Get('feature', FeatureToken) then
                if (TypeToken.AsValue().AsText() = WarningType) and (FeatureToken.AsValue().AsText() = Feature) then
                    exit;
        end;
        Error(MissingWarningErr, WarningType, Feature);
    end;

    var
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedIntErr: Label 'Expected %1, got %2.', Comment = '%1 = expected, %2 = actual';
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        MissingFieldErr: Label 'Missing field %1.', Comment = '%1 = field name';
        UnexpectedFieldErr: Label 'Did not expect field %1.', Comment = '%1 = field name';
        MissingWarningErr: Label 'Expected a %1 warning for %2.', Comment = '%1 = warning type, %2 = feature';
        InvalidBudgetErr: Label 'budget_tokens %1 must be >= 1024 and < max_tokens %2 (requested max tokens %3).', Comment = '%1 = budget, %2 = sent max tokens, %3 = requested max tokens';
}

namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Examples;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using PM.Guillem.AIOpenSDK.ProviderUtils;

codeunit 87491 "AIOS Lifecycle Tests"
{
    Access = Internal;
    Subtype = Test;

    [Test]
    procedure GenerateText_Success_RaisesLifecycleEventsInOrder()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Result: Codeunit "AIOS Generate Result";
        ExpectedTrace: Text;
    begin
        Spy.StartRecording();
        Mock.SetNextResponse('ok');
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnAfterGenerate';

        Result := Client.GenerateText(Mock.Model('demo-model'), 'ping');
        if Result.Output() <> 'ok' then
            Error(UnexpectedOutputErr, 'ok', Result.Output());

        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
        if Spy.GetLastModelId() <> 'demo-model' then
            Error(UnexpectedModelIdErr, 'demo-model', Spy.GetLastModelId());
        if not Spy.WasAfterGenerateCalled() then
            Error(ExpectedAfterGenerateErr);
        Spy.StopRecording();
    end;

    [Test]
    procedure GenerateText_Failure_DoesNotRaiseOnAfterGenerate()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Request: Record "AIOS Chat Request";
        ExpectedTrace: Text;
    begin
        Spy.StartRecording();
        Mock.SetNextError("AIOS Error Type"::ProviderUnavailable, 'simulated failure');
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(0);
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall';

        asserterror Client.GenerateText(Mock.Model('demo-model'), Request);

        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
        if Spy.WasAfterGenerateCalled() then
            Error(UnexpectedAfterGenerateErr);
        Spy.StopRecording();
    end;

    [Test]
    procedure GenerateText_NewPromptAfterHistory_AppendsUserTurn()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Messages: JsonArray;
    begin
        Mock.SetNextResponse('reply');
        Request.SetPrompt('first');
        Client.GenerateText(Mock.Model('demo-model'), Request);
        Request.AppendAssistantMessage('reply');
        Request.SetPrompt('second');
        Client.GenerateText(Mock.Model('demo-model'), Request);

        Messages := Request.GetMessages();
        if Messages.Count() <> 3 then
            Error(UnexpectedCountErr, 3, Messages.Count());
        AssertMessage(Messages, 0, 'user', 'first');
        AssertMessage(Messages, 1, 'assistant', 'reply');
        AssertMessage(Messages, 2, 'user', 'second');
    end;

    [Test]
    procedure GenerateText_Repeated_DoesNotDuplicatePrompt()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Messages: JsonArray;
    begin
        Mock.SetNextResponse('ok');
        Request.SetPrompt('once');
        Client.GenerateText(Mock.Model('demo-model'), Request);
        Client.GenerateText(Mock.Model('demo-model'), Request);

        Messages := Request.GetMessages();
        if Messages.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Messages.Count());
        AssertMessage(Messages, 0, 'user', 'once');
    end;

    [Test]
    procedure GenerateText_HistoryOnly_SendsSystemMessage()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        FormatCU: Codeunit "AIOS Chat Completions Format";
        ProviderMessages: JsonArray;
    begin
        Spy.StartRecording();
        Mock.SetNextResponse('ok');
        Request.SetSystemMessage('Be brief.');
        Request.AppendUserMessage('hi');
        Client.GenerateText(Mock.Model('demo-model'), Request);
        ProviderMessages := Spy.GetLastProviderMessages();
        Spy.StopRecording();

        AssertMessage(ProviderMessages, 0, 'system', 'Be brief.');
        AssertMessage(ProviderMessages, 1, 'user', 'hi');
        AssertMessage(FormatCU.MapMessages(ProviderMessages), 0, 'system', 'Be brief.');
        if CountRole(Request.GetMessages(), 'system') <> 0 then
            Error(UnexpectedCountErr, 0, CountRole(Request.GetMessages(), 'system'));
    end;

    [Test]
    procedure GenerateText_HistoryOnly_SetOutput_SendsHint()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
        SystemText: Text;
    begin
        Fields.Add(Schema.Field('name', Schema.String()));
        Spy.StartRecording();
        Mock.SetNextResponse('{"name":"Ada"}');
        Request.AppendUserMessage('person');
        Request.SetOutput(Schema.Object(Fields));
        Client.GenerateText(Mock.Model('demo-model'), Request);
        SystemText := GetMessageContent(Spy.GetLastProviderMessages(), 0);
        Spy.StopRecording();

        if StrPos(SystemText, 'conforms to this JSON Schema') = 0 then
            Error(ExpectedHintErr, SystemText);
    end;

    [Test]
    procedure GenerateText_ReusedRequest_SendsCurrentSystemMessage()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Schema: Codeunit "AIOS Schema";
        ProviderMessages: JsonArray;
    begin
        Spy.StartRecording();
        Request.SetSystemMessage('First system.');
        Request.SetPrompt('p1');
        Request.SetOutput(Schema.Json());
        Mock.SetNextResponse('{"a":1}');
        Client.GenerateText(Mock.Model('demo-model'), Request);

        Request.AppendAssistantMessage('{"a":1}');
        Request.ClearOutput();
        Request.SetSystemMessage('Second system.');
        Request.SetPrompt('p2');
        Mock.SetNextResponse('plain');
        Client.GenerateText(Mock.Model('demo-model'), Request);
        ProviderMessages := Spy.GetLastProviderMessages();
        Spy.StopRecording();

        if CountRole(ProviderMessages, 'system') <> 1 then
            Error(UnexpectedCountErr, 1, CountRole(ProviderMessages, 'system'));
        AssertMessage(ProviderMessages, 0, 'system', 'Second system.');
        AssertMessage(ProviderMessages, ProviderMessages.Count() - 1, 'user', 'p2');
    end;

    [Test]
    procedure GetProviderMessages_HistoryStartsWithSameSystem_NotDuplicated()
    var
        Request: Record "AIOS Chat Request";
        MessagesArr: JsonArray;
        ProviderMessages: JsonArray;
    begin
        MessagesArr.Add(NewMessage('system', 'Be brief.'));
        MessagesArr.Add(NewMessage('user', 'hi'));
        Request.SetMessages(MessagesArr);
        Request.SetSystemMessage('Be brief.');

        ProviderMessages := Request.GetProviderMessages();
        if ProviderMessages.Count() <> 2 then
            Error(UnexpectedCountErr, 2, ProviderMessages.Count());
        AssertMessage(ProviderMessages, 0, 'system', 'Be brief.');
    end;

    [Test]
    procedure GetProviderMessages_AuthoredSystem_KeptAfterRequestSystem()
    var
        Request: Record "AIOS Chat Request";
        AnthropicFormat: Codeunit "AIOS Anthropic Format";
        MessagesArr: JsonArray;
        ProviderMessages: JsonArray;
    begin
        MessagesArr.Add(NewMessage('system', 'History rule.'));
        MessagesArr.Add(NewMessage('user', 'hi'));
        Request.SetMessages(MessagesArr);
        Request.SetSystemMessage('Request rule.');

        ProviderMessages := Request.GetProviderMessages();
        if ProviderMessages.Count() <> 3 then
            Error(UnexpectedCountErr, 3, ProviderMessages.Count());
        AssertMessage(ProviderMessages, 0, 'system', 'Request rule.');
        AssertMessage(ProviderMessages, 1, 'system', 'History rule.');
        AssertMessage(ProviderMessages, 2, 'user', 'hi');
        if AnthropicFormat.GetSystemText(ProviderMessages) <> 'Request rule. History rule.' then
            Error(UnexpectedTextErr, 'Request rule. History rule.', AnthropicFormat.GetSystemText(ProviderMessages));
    end;

    [Test]
    procedure OnBeforeGenerate_SetPrompt_IsSent()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Messages: JsonArray;
    begin
        Spy.StartRecording();
        Spy.SetBeforeGeneratePrompt('from subscriber');
        Mock.SetNextResponse('ok');
        Request.SetPrompt('original');
        Client.GenerateText(Mock.Model('demo-model'), Request);
        Spy.StopRecording();

        Messages := Request.GetMessages();
        if Messages.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Messages.Count());
        AssertMessage(Messages, 0, 'user', 'from subscriber');
    end;

    [Test]
    procedure OnBeforeGenerate_SetSystemMessage_IsSent()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        ProviderMessages: JsonArray;
    begin
        Spy.StartRecording();
        Spy.SetBeforeGenerateSystemMessage('Subscriber system.');
        Mock.SetNextResponse('ok');
        Request.SetSystemMessage('Original system.');
        Request.SetPrompt('ping');
        Client.GenerateText(Mock.Model('demo-model'), Request);
        ProviderMessages := Spy.GetLastProviderMessages();
        Spy.StopRecording();

        AssertMessage(ProviderMessages, 0, 'system', 'Subscriber system.');
    end;

    [Test]
    procedure OnBeforeGenerate_Attach_IsSentThisCall()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Messages: JsonArray;
        MsgToken: JsonToken;
        ContentToken: JsonToken;
    begin
        Spy.StartRecording();
        Spy.SetBeforeGenerateAttachText('attached by subscriber');
        Mock.SetNextResponse('ok');
        Request.SetPrompt('look');
        Client.GenerateText(Mock.Model('demo-model'), Request);
        Spy.StopRecording();

        if Request.HasAttachments() then
            Error(ExpectedAttachmentsFlushedErr);
        Messages := Request.GetMessages();
        if Messages.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Messages.Count());
        Messages.Get(0, MsgToken);
        MsgToken.AsObject().Get('content', ContentToken);
        if not ContentToken.IsArray() then
            Error(ExpectedMultipartErr);
        if ContentToken.AsArray().Count() <> 2 then
            Error(UnexpectedCountErr, 2, ContentToken.AsArray().Count());
    end;

    [Test]
    procedure OnBeforeGenerate_WithTools_SetPrompt_IsSent()
    var
        Request: Record "AIOS Chat Request";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Messages: JsonArray;
    begin
        ToolSet.Add(Echo);
        Spy.StartRecording();
        Spy.SetBeforeGeneratePrompt('from subscriber');
        Mock.SetNextResponse('done');
        Request.SetPrompt('original');
        Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet);
        Spy.StopRecording();

        Messages := Request.GetMessages();
        if Messages.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Messages.Count());
        AssertMessage(Messages, 0, 'user', 'from subscriber');
    end;

    local procedure NewMessage(Role: Text; Content: Text): JsonObject
    var
        Msg: JsonObject;
    begin
        Msg.Add('role', Role);
        Msg.Add('content', Content);
        exit(Msg);
    end;

    local procedure AssertMessage(Messages: JsonArray; Index: Integer; ExpectedRole: Text; ExpectedContent: Text)
    var
        MsgToken: JsonToken;
        RoleToken: JsonToken;
    begin
        if Index >= Messages.Count() then
            Error(UnexpectedCountErr, Index + 1, Messages.Count());
        Messages.Get(Index, MsgToken);
        MsgToken.AsObject().Get('role', RoleToken);
        if RoleToken.AsValue().AsText() <> ExpectedRole then
            Error(UnexpectedTextErr, ExpectedRole, RoleToken.AsValue().AsText());
        if GetMessageContent(Messages, Index) <> ExpectedContent then
            Error(UnexpectedTextErr, ExpectedContent, GetMessageContent(Messages, Index));
    end;

    local procedure GetMessageContent(Messages: JsonArray; Index: Integer): Text
    var
        MsgToken: JsonToken;
        ContentToken: JsonToken;
    begin
        Messages.Get(Index, MsgToken);
        if not MsgToken.AsObject().Get('content', ContentToken) then
            exit('');
        if not ContentToken.IsValue() then
            exit('');
        exit(ContentToken.AsValue().AsText());
    end;

    local procedure CountRole(Messages: JsonArray; Role: Text): Integer
    var
        MsgToken: JsonToken;
        RoleToken: JsonToken;
        i: Integer;
        Found: Integer;
    begin
        for i := 0 to Messages.Count() - 1 do begin
            Messages.Get(i, MsgToken);
            if MsgToken.AsObject().Get('role', RoleToken) then
                if RoleToken.AsValue().AsText() = Role then
                    Found += 1;
        end;
        exit(Found);
    end;

    var
        UnexpectedOutputErr: Label 'Expected output ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedTraceErr: Label 'Expected event trace ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedModelIdErr: Label 'Expected model id ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedAfterGenerateErr: Label 'OnAfterGenerate should be raised on success.';
        UnexpectedAfterGenerateErr: Label 'OnAfterGenerate must not be raised on failure.';
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        ExpectedHintErr: Label 'Expected the output instruction in the system message, got ''%1''.', Comment = '%1 = system message';
        ExpectedAttachmentsFlushedErr: Label 'Expected attachments added in OnBeforeGenerate to be sent in the same call.';
        ExpectedMultipartErr: Label 'Expected multipart (array) content.';
}

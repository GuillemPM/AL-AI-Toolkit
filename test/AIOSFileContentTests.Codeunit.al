namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using PM.Guillem.AIOpenSDK.Provider.OpenAI;
using System.Reflection;
using System.Text;

/// <summary>
/// Tests for Attach / file-part message content and provider mapping.
/// </summary>
codeunit 87422 "AIOS File Content Tests"
{
    Subtype = Test;

    [Test]
    procedure Attach_EnsureMessages_BuildsMultipartUserContent()
    var
        Request: Record "AIOS Chat Request";
        Messages: JsonArray;
        ProviderMessages: JsonArray;
        Msg: JsonObject;
        ContentToken: JsonToken;
        Parts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        TypeToken: JsonToken;
        MediaToken: JsonToken;
        IdToken: JsonToken;
        DataToken: JsonToken;
        TextToken: JsonToken;
        Base64Convert: Codeunit "Base64 Convert";
        HelloB64: Text;
        PayloadId: Text;
    begin
        HelloB64 := Base64Convert.ToBase64('hello');
        Request.SetPrompt('Describe this');
        Request.Attach(HelloB64, 'text/plain', 'hello.txt');
        Request.EnsureMessagesFromPrompt();

        if Request.HasAttachments() then
            Error(ExpectedAttachmentsClearedErr);

        Messages := Request.GetMessages();
        if not FindRole(Messages, 'user', Msg) then
            Error(ExpectedUserMsgErr);
        if not Msg.Get('content', ContentToken) then
            Error(ExpectedContentErr);
        if not ContentToken.IsArray() then
            Error(ExpectedMultipartErr);
        Parts := ContentToken.AsArray();
        if Parts.Count() <> 2 then
            Error(UnexpectedCountErr, 2, Parts.Count());
        Parts.Get(0, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'text' then
            Error(UnexpectedTextErr, 'text', TypeToken.AsValue().AsText());
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'file' then
            Error(UnexpectedTextErr, 'file', TypeToken.AsValue().AsText());
        Part.Get('mediaType', MediaToken);
        if MediaToken.AsValue().AsText() <> 'text/plain' then
            Error(UnexpectedTextErr, 'text/plain', MediaToken.AsValue().AsText());
        if not Part.Get('id', IdToken) then
            Error(ExpectedAttachmentIdErr);
        if Part.Contains('data') then
            Error(ExpectedNoInlineDataErr);
        PayloadId := IdToken.AsValue().AsText();

        ProviderMessages := Request.GetProviderMessages();
        if not FindRole(ProviderMessages, 'user', Msg) then
            Error(ExpectedUserMsgErr);
        Msg.Get('content', ContentToken);
        Parts := ContentToken.AsArray();
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        if Part.Get('text', TextToken) then begin
            if TextToken.AsValue().AsText() <> 'hello' then
                Error(UnexpectedTextErr, 'hello', TextToken.AsValue().AsText());
        end else if Part.Get('data', DataToken) then begin
            if DataToken.AsValue().AsText() <> HelloB64 then
                Error(UnexpectedTextErr, HelloB64, DataToken.AsValue().AsText());
        end else
            Error(ExpectedExpandedPayloadErr);
        if Part.Get('id', IdToken) then
            if IdToken.AsValue().AsText() <> PayloadId then
                Error(UnexpectedTextErr, PayloadId, IdToken.AsValue().AsText());
    end;

    [Test]
    procedure OpenAIFormat_MapsImageFilePart()
    var
        FormatCU: Codeunit "AIOS OpenAI Format";
        AiosMessages: JsonArray;
        WireMessages: JsonArray;
        Msg: JsonObject;
        ContentParts: JsonArray;
        TextPart: JsonObject;
        FilePart: JsonObject;
        WireMsg: JsonObject;
        ContentToken: JsonToken;
        WireParts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        TypeToken: JsonToken;
        MsgToken: JsonToken;
    begin
        TextPart.Add('type', 'text');
        TextPart.Add('text', 'what is this?');
        FilePart.Add('type', 'file');
        FilePart.Add('mediaType', 'image/png');
        FilePart.Add('data', 'aaa');
        FilePart.Add('filename', 'x.png');
        ContentParts.Add(TextPart);
        ContentParts.Add(FilePart);
        Msg.Add('role', 'user');
        Msg.Add('content', ContentParts);
        AiosMessages.Add(Msg);

        WireMessages := FormatCU.MapMessages(AiosMessages);
        WireMessages.Get(0, MsgToken);
        WireMsg := MsgToken.AsObject();
        WireMsg.Get('content', ContentToken);
        if not ContentToken.IsArray() then
            Error(ExpectedMultipartErr);
        WireParts := ContentToken.AsArray();
        if WireParts.Count() <> 2 then
            Error(UnexpectedCountErr, 2, WireParts.Count());
        WireParts.Get(1, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'image_url' then
            Error(UnexpectedTextErr, 'image_url', TypeToken.AsValue().AsText());
    end;

    [Test]
    procedure AnthropicFormat_MapsPdfFilePart()
    var
        FormatCU: Codeunit "AIOS Anthropic Format";
        AiosMessages: JsonArray;
        WireMessages: JsonArray;
        Msg: JsonObject;
        ContentParts: JsonArray;
        FilePart: JsonObject;
        WireMsg: JsonObject;
        ContentToken: JsonToken;
        WireParts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        TypeToken: JsonToken;
        MsgToken: JsonToken;
    begin
        FilePart.Add('type', 'file');
        FilePart.Add('mediaType', 'application/pdf');
        FilePart.Add('data', 'JVBERg');
        FilePart.Add('filename', 'doc.pdf');
        ContentParts.Add(FilePart);
        Msg.Add('role', 'user');
        Msg.Add('content', ContentParts);
        AiosMessages.Add(Msg);

        WireMessages := FormatCU.MapMessages(AiosMessages);
        WireMessages.Get(0, MsgToken);
        WireMsg := MsgToken.AsObject();
        WireMsg.Get('content', ContentToken);
        WireParts := ContentToken.AsArray();
        WireParts.Get(0, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'document' then
            Error(UnexpectedTextErr, 'document', TypeToken.AsValue().AsText());
    end;

    [Test]
    procedure GenerateText_WithTextFile_MockSucceeds()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Base64Convert: Codeunit "Base64 Convert";
    begin
        Mock.SetNextResponse('ok');
        Request.SetPrompt('Summarize');
        Request.Attach(Base64Convert.ToBase64('note body'), 'text/plain', 'note.txt');
        Result := Client.GenerateText(Mock.Model('demo'), Request);
        if Result.Output() <> 'ok' then
            Error(UnexpectedTextErr, 'ok', Result.Output());
    end;

    [Test]
    procedure Attach_AfterUserMessage_MergesIntoLastTurn()
    var
        Request: Record "AIOS Chat Request";
        Messages: JsonArray;
        Msg: JsonObject;
        ContentToken: JsonToken;
        Parts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        TypeToken: JsonToken;
        Base64Convert: Codeunit "Base64 Convert";
        UserCount: Integer;
    begin
        Request.AppendUserMessage('look at this');
        Request.Attach(Base64Convert.ToBase64('img'), 'image/png', 'x.png');
        Request.EnsureMessagesFromPrompt();

        if Request.HasAttachments() then
            Error(ExpectedAttachmentsClearedErr);

        Messages := Request.GetMessages();
        UserCount := CountRole(Messages, 'user');
        if UserCount <> 1 then
            Error(UnexpectedCountErr, 1, UserCount);
        if not FindRole(Messages, 'user', Msg) then
            Error(ExpectedUserMsgErr);
        if not Msg.Get('content', ContentToken) then
            Error(ExpectedContentErr);
        if not ContentToken.IsArray() then
            Error(ExpectedMultipartErr);
        Parts := ContentToken.AsArray();
        if Parts.Count() <> 2 then
            Error(UnexpectedCountErr, 2, Parts.Count());
        Parts.Get(0, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'text' then
            Error(UnexpectedTextErr, 'text', TypeToken.AsValue().AsText());
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'file' then
            Error(UnexpectedTextErr, 'file', TypeToken.AsValue().AsText());
    end;

    [Test]
    procedure Attach_AfterAssistant_AppendsNewUserTurn()
    var
        Request: Record "AIOS Chat Request";
        Messages: JsonArray;
        Msg: JsonObject;
        ContentToken: JsonToken;
        Parts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        TypeToken: JsonToken;
        Base64Convert: Codeunit "Base64 Convert";
        UserCount: Integer;
        i: Integer;
        MsgToken: JsonToken;
        RoleToken: JsonToken;
        LastUserFound: Boolean;
    begin
        Request.AppendUserMessage('first');
        Request.AppendAssistantMessage('reply');
        Request.SetPrompt('and this?');
        Request.Attach(Base64Convert.ToBase64('img'), 'image/png', 'y.png');
        Request.EnsureMessagesFromPrompt();

        if Request.HasAttachments() then
            Error(ExpectedAttachmentsClearedErr);

        Messages := Request.GetMessages();
        UserCount := CountRole(Messages, 'user');
        if UserCount <> 2 then
            Error(UnexpectedCountErr, 2, UserCount);

        LastUserFound := false;
        for i := Messages.Count() - 1 downto 0 do begin
            Messages.Get(i, MsgToken);
            Msg := MsgToken.AsObject();
            if Msg.Get('role', RoleToken) then
                if RoleToken.AsValue().AsText() = 'user' then begin
                    LastUserFound := true;
                    break;
                end;
        end;
        if not LastUserFound then
            Error(ExpectedUserMsgErr);
        if not Msg.Get('content', ContentToken) then
            Error(ExpectedContentErr);
        if not ContentToken.IsArray() then
            Error(ExpectedMultipartErr);
        Parts := ContentToken.AsArray();
        if Parts.Count() <> 2 then
            Error(UnexpectedCountErr, 2, Parts.Count());
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'file' then
            Error(UnexpectedTextErr, 'file', TypeToken.AsValue().AsText());
    end;

    [Test]
    procedure ClearAttachments_DropsOrphanPayload_KeepsHistoryPayload()
    var
        Request: Record "AIOS Chat Request";
        ChatMessages: Codeunit "AIOS Chat Messages";
        ChatAttachments: Codeunit "AIOS Chat Attachments";
        Base64Convert: Codeunit "Base64 Convert";
        Pending: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        IdToken: JsonToken;
        OrphanId: Text;
        OrphanMessages: JsonArray;
        OrphanMsg: JsonObject;
        OrphanParts: JsonArray;
        OrphanPart: JsonObject;
        Messages: JsonArray;
        Msg: JsonObject;
        ContentToken: JsonToken;
        Parts: JsonArray;
        ProviderMessages: JsonArray;
        TextToken: JsonToken;
    begin
        Request.Attach(Base64Convert.ToBase64('gone'), 'text/plain', 'gone.txt');
        Pending := Request.GetAttachments();
        Pending.Get(0, PartToken);
        Part := PartToken.AsObject();
        Part.Get('id', IdToken);
        OrphanId := IdToken.AsValue().AsText();
        Request.ClearAttachments();
        if Request.HasAttachments() then
            Error(ExpectedAttachmentsClearedErr);

        Clear(OrphanPart);
        OrphanPart.Add('type', 'file');
        OrphanPart.Add('mediaType', 'text/plain');
        OrphanPart.Add('id', OrphanId);
        OrphanParts.Add(OrphanPart);
        OrphanMsg.Add('role', 'user');
        OrphanMsg.Add('content', OrphanParts);
        OrphanMessages.Add(OrphanMsg);
        ChatMessages.SetMessages(Request, OrphanMessages);
        asserterror ChatAttachments.GetProviderMessages(Request);
        if GetLastErrorText() = '' then
            Error(ExpectedPayloadPrunedErr);
        ChatMessages.ClearMessages(Request);

        Request.SetPrompt('keep');
        Request.Attach(Base64Convert.ToBase64('kept'), 'text/plain', 'kept.txt');
        Request.EnsureMessagesFromPrompt();
        if Request.HasAttachments() then
            Error(ExpectedAttachmentsClearedErr);

        Messages := Request.GetMessages();
        if not FindRole(Messages, 'user', Msg) then
            Error(ExpectedUserMsgErr);
        Msg.Get('content', ContentToken);
        Parts := ContentToken.AsArray();
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        if not Part.Get('id', IdToken) then
            Error(ExpectedAttachmentIdErr);

        Request.ClearAttachments();
        ProviderMessages := Request.GetProviderMessages();
        if not FindRole(ProviderMessages, 'user', Msg) then
            Error(ExpectedUserMsgErr);
        Msg.Get('content', ContentToken);
        Parts := ContentToken.AsArray();
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        if not Part.Get('text', TextToken) then
            Error(ExpectedExpandedPayloadErr);
        if TextToken.AsValue().AsText() <> 'kept' then
            Error(UnexpectedTextErr, 'kept', TextToken.AsValue().AsText());
    end;

    [Test]
    procedure ClearMessages_PrunesPayloads_NoLongerExpandable()
    var
        Request: Record "AIOS Chat Request";
        ChatMessages: Codeunit "AIOS Chat Messages";
        ChatAttachments: Codeunit "AIOS Chat Attachments";
        Base64Convert: Codeunit "Base64 Convert";
        Messages: JsonArray;
        Msg: JsonObject;
        ContentToken: JsonToken;
        Parts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        IdToken: JsonToken;
        PayloadId: Text;
        Restored: JsonArray;
        RestoredMsg: JsonObject;
        RestoredParts: JsonArray;
        RestoredPart: JsonObject;
    begin
        Request.SetPrompt('see file');
        Request.Attach(Base64Convert.ToBase64('secret'), 'text/plain', 'secret.txt');
        Request.EnsureMessagesFromPrompt();

        Messages := Request.GetMessages();
        if not FindRole(Messages, 'user', Msg) then
            Error(ExpectedUserMsgErr);
        Msg.Get('content', ContentToken);
        Parts := ContentToken.AsArray();
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        Part.Get('id', IdToken);
        PayloadId := IdToken.AsValue().AsText();

        Request.ClearMessages();
        if Request.HasMessages() then
            Error(ExpectedMessagesClearedErr);

        Clear(RestoredPart);
        RestoredPart.Add('type', 'file');
        RestoredPart.Add('mediaType', 'text/plain');
        RestoredPart.Add('id', PayloadId);
        RestoredParts.Add(RestoredPart);
        RestoredMsg.Add('role', 'user');
        RestoredMsg.Add('content', RestoredParts);
        Restored.Add(RestoredMsg);
        ChatMessages.SetMessages(Request, Restored);

        asserterror ChatAttachments.GetProviderMessages(Request);
        if GetLastErrorText() = '' then
            Error(ExpectedPayloadPrunedErr);
    end;

    [Test]
    procedure SetMessages_WithoutFileRefs_PrunesPayloads()
    var
        Request: Record "AIOS Chat Request";
        Base64Convert: Codeunit "Base64 Convert";
        Messages: JsonArray;
        Msg: JsonObject;
        ContentToken: JsonToken;
        Parts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        IdToken: JsonToken;
        PayloadId: Text;
        Plain: JsonArray;
        PlainMsg: JsonObject;
        ChatAttachments: Codeunit "AIOS Chat Attachments";
        Restored: JsonArray;
        RestoredMsg: JsonObject;
        RestoredParts: JsonArray;
        RestoredPart: JsonObject;
    begin
        Request.SetPrompt('x');
        Request.Attach(Base64Convert.ToBase64('blob'), 'text/plain', 'blob.txt');
        Request.EnsureMessagesFromPrompt();

        Messages := Request.GetMessages();
        FindRole(Messages, 'user', Msg);
        Msg.Get('content', ContentToken);
        Parts := ContentToken.AsArray();
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        Part.Get('id', IdToken);
        PayloadId := IdToken.AsValue().AsText();

        PlainMsg.Add('role', 'user');
        PlainMsg.Add('content', 'no files');
        Plain.Add(PlainMsg);
        Request.SetMessages(Plain);

        Clear(RestoredPart);
        RestoredPart.Add('type', 'file');
        RestoredPart.Add('mediaType', 'text/plain');
        RestoredPart.Add('id', PayloadId);
        RestoredParts.Add(RestoredPart);
        RestoredMsg.Add('role', 'user');
        RestoredMsg.Add('content', RestoredParts);
        Restored.Add(RestoredMsg);
        Request.SetMessages(Restored);

        asserterror ChatAttachments.GetProviderMessages(Request);
        if GetLastErrorText() = '' then
            Error(ExpectedPayloadPrunedErr);
    end;

    [Test]
    procedure Attach_Binary_StoredRaw_ExpandedOnProviderMessages()
    var
        Request: Record "AIOS Chat Request";
        Base64Convert: Codeunit "Base64 Convert";
        PngB64: Text;
        Messages: JsonArray;
        ProviderMessages: JsonArray;
        Msg: JsonObject;
        ContentToken: JsonToken;
        Parts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        TypeToken: JsonToken;
        DataToken: JsonToken;
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        PayloadText: Text;
    begin
        // Minimal 1x1 PNG
        PngB64 := 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        Request.SetPrompt('what is this?');
        Request.Attach(PngB64, 'image/png', 'dot.png');

        if not Request."Attachment Binaries".HasValue then
            Error(ExpectedBinaryStoreErr);

        // Metadata must not inline base64 for binary attachments
        Request."Attachment Payloads".CreateInStream(InStream, TextEncoding::UTF8);
        PayloadText := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if StrPos(PayloadText, '"data"') > 0 then
            Error(ExpectedNoInlineDataErr);
        if StrPos(PayloadText, '"encoding":"binary"') = 0 then
            if StrPos(PayloadText, '"encoding": "binary"') = 0 then
                Error(ExpectedBinaryEncodingErr);

        Request.EnsureMessagesFromPrompt();
        Messages := Request.GetMessages();
        if not FindRole(Messages, 'user', Msg) then
            Error(ExpectedUserMsgErr);

        ProviderMessages := Request.GetProviderMessages();
        if not FindRole(ProviderMessages, 'user', Msg) then
            Error(ExpectedUserMsgErr);
        Msg.Get('content', ContentToken);
        Parts := ContentToken.AsArray();
        Parts.Get(1, PartToken);
        Part := PartToken.AsObject();
        Part.Get('type', TypeToken);
        if TypeToken.AsValue().AsText() <> 'file' then
            Error(UnexpectedTextErr, 'file', TypeToken.AsValue().AsText());
        if not Part.Get('data', DataToken) then
            Error(ExpectedExpandedPayloadErr);
        if DataToken.AsValue().AsText() <> PngB64 then
            Error(UnexpectedTextErr, PngB64, DataToken.AsValue().AsText());
    end;

    local procedure FindRole(Messages: JsonArray; Role: Text; var Msg: JsonObject): Boolean
    var
        MsgToken: JsonToken;
        RoleToken: JsonToken;
        i: Integer;
    begin
        for i := 0 to Messages.Count() - 1 do begin
            Messages.Get(i, MsgToken);
            Msg := MsgToken.AsObject();
            if Msg.Get('role', RoleToken) then
                if RoleToken.AsValue().AsText() = Role then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure CountRole(Messages: JsonArray; Role: Text): Integer
    var
        MsgToken: JsonToken;
        Msg: JsonObject;
        RoleToken: JsonToken;
        i: Integer;
        n: Integer;
    begin
        for i := 0 to Messages.Count() - 1 do begin
            Messages.Get(i, MsgToken);
            Msg := MsgToken.AsObject();
            if Msg.Get('role', RoleToken) then
                if RoleToken.AsValue().AsText() = Role then
                    n += 1;
        end;
        exit(n);
    end;

    var
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        ExpectedAttachmentsClearedErr: Label 'Expected pending attachments to be cleared after EnsureMessagesFromPrompt.';
        ExpectedMessagesClearedErr: Label 'Expected message history to be cleared.';
        ExpectedUserMsgErr: Label 'Expected a user message.';
        ExpectedContentErr: Label 'Expected message content.';
        ExpectedMultipartErr: Label 'Expected multipart (array) content.';
        ExpectedAttachmentIdErr: Label 'Expected attachment id ref in stored message history.';
        ExpectedNoInlineDataErr: Label 'Stored message history must not inline attachment data.';
        ExpectedExpandedPayloadErr: Label 'Expected expanded text or data on provider messages.';
        ExpectedPayloadPrunedErr: Label 'Expected GetProviderMessages to fail after attachment payloads were pruned.';
        ExpectedBinaryStoreErr: Label 'Expected Attachment Binaries to hold raw binary content.';
        ExpectedBinaryEncodingErr: Label 'Expected binary attachment metadata to use encoding binary.';
}

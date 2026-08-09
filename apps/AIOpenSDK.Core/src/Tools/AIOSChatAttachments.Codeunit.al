namespace PM.Guillem.AIOpenSDK.Core;

using System.Environment;
using System.IO;
using System.Reflection;
using System.Text;
using System.Utilities;

/// <summary>
/// Attachment storage and flush for "AIOS Chat Request": pending refs, payloads, and provider expand.
/// Prefer Request.Attach / GetProviderMessages; this codeunit holds the implementation.
/// </summary>
codeunit 87423 "AIOS Chat Attachments"
{
    Access = Public;

    /// <summary>
    /// Ensures Messages includes the prompt and any pending Attach parts on Request.
    /// </summary>
    procedure EnsureMessagesFromPrompt(var Request: Record "AIOS Chat Request")
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        ChatPrompt: Codeunit "AIOS Chat Prompt";
        SystemText: Text;
    begin
        if not ChatMessages.HasMessages(Request) then begin
            SystemText := ChatPrompt.GetEffectiveSystemMessage(Request);
            if SystemText <> '' then
                AppendSystemMessage(Request, SystemText);
            AppendUserMessageWithAttachments(Request, ChatPrompt.GetPrompt(Request));
            exit;
        end;

        if not HasAttachments(Request) then
            exit;

        if not TryMergeAttachmentsIntoLastUserMessage(Request) then
            AppendUserMessageWithAttachments(Request, ChatPrompt.GetPrompt(Request));
    end;

    /// <summary>
    /// Attaches content to the next user turn. mediaType is IANA (e.g. image/png, application/pdf).
    /// </summary>
    procedure Attach(var Request: Record "AIOS Chat Request"; var ContentInStream: InStream; MediaType: Text; Filename: Text)
    var
        MessageContent: Codeunit "AIOS Message Content";
        TypeHelper: Codeunit "Type Helper";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        TextContent: Text;
    begin
        if MediaType = '' then
            Error(AttachMediaTypeEmptyErr);
        if MessageContent.IsTextMediaType(MediaType) then begin
            TextContent := TypeHelper.ReadAsTextWithSeparator(ContentInStream, TypeHelper.LFSeparator());
            AttachTextPayload(Request, TextContent, MediaType, Filename);
        end else begin
            TempBlob.CreateOutStream(OutStream);
            CopyStream(OutStream, ContentInStream);
            if TempBlob.Length() = 0 then
                Error(AttachDataEmptyErr);
            if TempBlob.Length() > MaxAttachmentBytes() then
                Error(AttachmentTooLargeErr);
            TempBlob.CreateInStream(InStream);
            AttachBinaryStream(Request, InStream, MediaType, Filename);
        end;
    end;

    /// <summary>
    /// Attaches raw base64 bytes (no data: URL prefix). Decoded and stored as binary until GetProviderMessages.
    /// </summary>
    procedure Attach(var Request: Record "AIOS Chat Request"; Base64Data: Text; MediaType: Text; Filename: Text)
    var
        MessageContent: Codeunit "AIOS Message Content";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        if MediaType = '' then
            Error(AttachMediaTypeEmptyErr);
        if Base64Data = '' then
            Error(AttachDataEmptyErr);
        if MessageContent.IsTextMediaType(MediaType) then
            AttachTextPayload(Request, Base64Convert.FromBase64(Base64Data), MediaType, Filename)
        else begin
            if StrLen(Base64Data) > MaxAttachmentBase64Chars() then
                Error(AttachmentTooLargeErr);
            TempBlob.CreateOutStream(OutStream);
            Base64Convert.FromBase64(Base64Data, OutStream);
            if TempBlob.Length() = 0 then
                Error(AttachDataEmptyErr);
            if TempBlob.Length() > MaxAttachmentBytes() then
                Error(AttachmentTooLargeErr);
            TempBlob.CreateInStream(InStream);
            AttachBinaryStream(Request, InStream, MediaType, Filename);
        end;
    end;

    /// <summary>
    /// Attaches bytes from a Temp Blob.
    /// </summary>
    procedure Attach(var Request: Record "AIOS Chat Request"; var TempBlob: Codeunit "Temp Blob"; MediaType: Text; Filename: Text)
    var
        InStream: InStream;
    begin
        if not TempBlob.HasValue() then
            Error(AttachDataEmptyErr);
        TempBlob.CreateInStream(InStream);
        Attach(Request, InStream, MediaType, Filename);
    end;

    /// <summary>
    /// Attaches Tenant Media (MIME from the record). Filename defaults from Description or 'attachment'.
    /// </summary>
    procedure Attach(var Request: Record "AIOS Chat Request"; var TenantMedia: Record "Tenant Media")
    begin
        AttachTenantMedia(Request, TenantMedia, '');
    end;

    /// <summary>
    /// Attaches Tenant Media with an explicit filename.
    /// </summary>
    procedure Attach(var Request: Record "AIOS Chat Request"; var TenantMedia: Record "Tenant Media"; Filename: Text)
    begin
        AttachTenantMedia(Request, TenantMedia, Filename);
    end;

    /// <summary>
    /// Attaches Tenant Media by MediaId — e.g. Item.Picture.Item(1).
    /// </summary>
    procedure Attach(var Request: Record "AIOS Chat Request"; MediaId: Guid)
    begin
        Attach(Request, MediaId, '');
    end;

    /// <summary>
    /// Attaches Tenant Media by MediaId with an explicit filename.
    /// </summary>
    procedure Attach(var Request: Record "AIOS Chat Request"; MediaId: Guid; Filename: Text)
    var
        TenantMedia: Record "Tenant Media";
    begin
        if IsNullGuid(MediaId) then
            Error(MediaIdEmptyErr);
        if not TenantMedia.Get(MediaId) then
            Error(TenantMediaMissingErr, MediaId);
        AttachTenantMedia(Request, TenantMedia, Filename);
    end;

    /// <summary>
    /// True when one or more parts were attached for the next user turn.
    /// </summary>
    procedure HasAttachments(var Request: Record "AIOS Chat Request"): Boolean
    begin
        exit(GetAttachments(Request).Count() > 0);
    end;

    /// <summary>
    /// Pending attachment refs: { type: "file", mediaType, id, filename? }.
    /// </summary>
    procedure GetAttachments(var Request: Record "AIOS Chat Request"): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        PendingArr: JsonArray;
        Text: Text;
    begin
        if not Request."Pending Attachments".HasValue then
            exit(PendingArr);
        Request."Pending Attachments".CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(PendingArr);
        if not PendingArr.ReadFrom(Text) then
            Clear(PendingArr);
        exit(PendingArr);
    end;

    /// <summary>
    /// Clears pending attachment refs and drops any payloads no longer referenced by pending or message history.
    /// Payloads still referenced from Messages are kept (required for provider expand / tool loops).
    /// </summary>
    procedure ClearAttachments(var Request: Record "AIOS Chat Request")
    begin
        Clear(Request."Pending Attachments");
        PruneUnreferencedPayloads(Request);
    end;

    /// <summary>
    /// Drops Attachment Payloads that are not referenced by pending attachments or message history.
    /// Call after ClearMessages / SetMessages so logical clears do not retain orphan bytes.
    /// </summary>
    procedure PruneUnreferencedPayloads(var Request: Record "AIOS Chat Request")
    var
        Referenced: Dictionary of [Text, Boolean];
        Store: JsonObject;
        NewStore: JsonObject;
        PayloadToken: JsonToken;
        Payload: JsonObject;
        Keys: List of [Text];
        Id: Text;
        i: Integer;
        Kept: Integer;
        EncodingToken: JsonToken;
        DataCompression: Codeunit "Data Compression";
        OutTempBlob: Codeunit "Temp Blob";
        EntryTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
        HasBinary: Boolean;
        Encoding: Text;
    begin
        CollectReferencedAttachmentIds(Request, Referenced);
        Keys := Referenced.Keys();
        if Keys.Count() = 0 then begin
            Clear(Request."Attachment Payloads");
            Clear(Request."Attachment Binaries");
            exit;
        end;

        Store := GetAttachmentPayloadStore(Request);
        HasBinary := false;
        DataCompression.CreateZipArchive();

        Kept := 0;
        for i := 1 to Keys.Count() do begin
            Id := Keys.Get(i);
            if not Store.Get(Id, PayloadToken) then
                continue;
            if not PayloadToken.IsObject() then
                continue;
            Payload := PayloadToken.AsObject();

            Encoding := '';
            if Payload.Get('encoding', EncodingToken) then
                Encoding := EncodingToken.AsValue().AsText();

            if Encoding = 'binary' then begin
                if not TryExtractBinaryEntry(Request, Id, EntryTempBlob) then
                    continue;
                EntryTempBlob.CreateInStream(InStream);
                DataCompression.AddEntry(InStream, BinaryEntryPath(Id));
                HasBinary := true;
            end;

            if NewStore.Contains(Id) then
                NewStore.Remove(Id);
            NewStore.Add(Id, Payload);
            Kept += 1;
        end;

        if Kept = 0 then begin
            Clear(Request."Attachment Payloads");
            Clear(Request."Attachment Binaries");
            DataCompression.CloseZipArchive();
            exit;
        end;

        SetAttachmentPayloadStore(Request, NewStore);

        if HasBinary then begin
            DataCompression.SaveZipArchive(OutTempBlob);
            DataCompression.CloseZipArchive();
            Clear(Request."Attachment Binaries");
            OutTempBlob.CreateInStream(InStream);
            Request."Attachment Binaries".CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);
        end else begin
            DataCompression.CloseZipArchive();
            Clear(Request."Attachment Binaries");
        end;
    end;

    /// <summary>
    /// Message history with file refs expanded for provider MapMessages. Does not mutate stored Messages.
    /// </summary>
    procedure GetProviderMessages(var Request: Record "AIOS Chat Request"): JsonArray
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        MessagesArr: JsonArray;
        Expanded: JsonArray;
        MsgToken: JsonToken;
        Msg: JsonObject;
        NewMsg: JsonObject;
        ContentToken: JsonToken;
        i: Integer;
        MsgText: Text;
    begin
        MessagesArr := ChatMessages.GetMessages(Request);
        for i := 0 to MessagesArr.Count() - 1 do begin
            MessagesArr.Get(i, MsgToken);
            Msg := MsgToken.AsObject();
            Clear(NewMsg);
            Msg.WriteTo(MsgText);
            if not NewMsg.ReadFrom(MsgText) then
                continue;
            if NewMsg.Get('content', ContentToken) then
                if ContentToken.IsArray() then begin
                    if NewMsg.Contains('content') then
                        NewMsg.Remove('content');
                    NewMsg.Add('content', ExpandContentParts(Request, ContentToken.AsArray()));
                end;
            Expanded.Add(NewMsg);
        end;
        exit(Expanded);
    end;

    local procedure AttachTenantMedia(var Request: Record "AIOS Chat Request"; var TenantMedia: Record "Tenant Media"; Filename: Text)
    var
        InStream: InStream;
        MimeType: Text;
        EffectiveName: Text;
    begin
        TenantMedia.CalcFields(Content);
        if not TenantMedia.Content.HasValue then
            Error(TenantMediaEmptyErr, TenantMedia.ID);

        MimeType := TenantMedia."Mime Type";
        if MimeType = '' then
            Error(AttachMediaTypeEmptyErr);

        EffectiveName := Filename;
        if EffectiveName = '' then
            EffectiveName := TenantMedia.Description;
        if EffectiveName = '' then
            EffectiveName := 'attachment';

        TenantMedia.Content.CreateInStream(InStream);
        Attach(Request, InStream, MimeType, EffectiveName);
    end;

    local procedure AttachTextPayload(var Request: Record "AIOS Chat Request"; TextContent: Text; MediaType: Text; Filename: Text)
    var
        PayloadId: Text;
        Payload: JsonObject;
    begin
        if MediaType = '' then
            Error(AttachMediaTypeEmptyErr);
        if TextContent = '' then
            Error(AttachDataEmptyErr);
        if GetAttachments(Request).Count() >= MaxAttachmentsPerRequest() then
            Error(TooManyAttachmentsErr, MaxAttachmentsPerRequest());
        if StrLen(TextContent) > MaxAttachmentBytes() then
            Error(AttachmentTooLargeErr);

        PayloadId := NewAttachmentId();
        Clear(Payload);
        Payload.Add('mediaType', MediaType);
        if Filename <> '' then
            Payload.Add('filename', Filename);
        Payload.Add('text', TextContent);
        PutAttachmentPayload(Request, PayloadId, Payload);
        AddPendingAttachmentRef(Request, PayloadId, MediaType, Filename);
    end;

    local procedure AttachBinaryStream(var Request: Record "AIOS Chat Request"; var ContentInStream: InStream; MediaType: Text; Filename: Text)
    var
        PayloadId: Text;
        Payload: JsonObject;
    begin
        if MediaType = '' then
            Error(AttachMediaTypeEmptyErr);
        if GetAttachments(Request).Count() >= MaxAttachmentsPerRequest() then
            Error(TooManyAttachmentsErr, MaxAttachmentsPerRequest());

        PayloadId := NewAttachmentId();
        PutBinaryEntry(Request, PayloadId, ContentInStream);

        Clear(Payload);
        Payload.Add('mediaType', MediaType);
        if Filename <> '' then
            Payload.Add('filename', Filename);
        Payload.Add('encoding', 'binary');
        PutAttachmentPayload(Request, PayloadId, Payload);
        AddPendingAttachmentRef(Request, PayloadId, MediaType, Filename);
    end;

    local procedure PutBinaryEntry(var Request: Record "AIOS Chat Request"; PayloadId: Text; var ContentInStream: InStream)
    var
        DataCompression: Codeunit "Data Compression";
        ExistingTempBlob: Codeunit "Temp Blob";
        OutTempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        if Request."Attachment Binaries".HasValue then begin
            Request."Attachment Binaries".CreateInStream(InStream);
            ExistingTempBlob.CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);
            ExistingTempBlob.CreateInStream(InStream);
            DataCompression.OpenZipArchive(InStream, true);
        end else
            DataCompression.CreateZipArchive();

        DataCompression.AddEntry(ContentInStream, BinaryEntryPath(PayloadId));
        DataCompression.SaveZipArchive(OutTempBlob);
        DataCompression.CloseZipArchive();

        Clear(Request."Attachment Binaries");
        OutTempBlob.CreateInStream(InStream);
        Request."Attachment Binaries".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
    end;

    local procedure TryExtractBinaryEntry(var Request: Record "AIOS Chat Request"; PayloadId: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        DataCompression: Codeunit "Data Compression";
        InStream: InStream;
        EntryList: List of [Text];
        EntryLength: Integer;
        Path: Text;
    begin
        Clear(TempBlob);
        if not Request."Attachment Binaries".HasValue then
            exit(false);
        Path := BinaryEntryPath(PayloadId);
        Request."Attachment Binaries".CreateInStream(InStream);
        DataCompression.OpenZipArchive(InStream, false);
        DataCompression.GetEntryList(EntryList);
        if not EntryList.Contains(Path) then begin
            DataCompression.CloseZipArchive();
            exit(false);
        end;
        EntryLength := DataCompression.ExtractEntry(Path, TempBlob);
        DataCompression.CloseZipArchive();
        exit((EntryLength > 0) or TempBlob.HasValue());
    end;

    local procedure GetBinaryAsBase64(var Request: Record "AIOS Chat Request"; PayloadId: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStream: InStream;
    begin
        if not TryExtractBinaryEntry(Request, PayloadId, TempBlob) then
            Error(AttachmentPayloadMissingErr, PayloadId);
        TempBlob.CreateInStream(InStream);
        exit(Base64Convert.ToBase64(InStream));
    end;

    local procedure BinaryEntryPath(PayloadId: Text): Text
    begin
        exit(PayloadId);
    end;

    local procedure AddPendingAttachmentRef(var Request: Record "AIOS Chat Request"; PayloadId: Text; MediaType: Text; Filename: Text)
    var
        PendingArr: JsonArray;
        Part: JsonObject;
        OutStream: OutStream;
        Text: Text;
    begin
        PendingArr := GetAttachments(Request);
        Clear(Part);
        Part.Add('type', 'file');
        Part.Add('mediaType', MediaType);
        Part.Add('id', PayloadId);
        if Filename <> '' then
            Part.Add('filename', Filename);
        PendingArr.Add(Part);

        Clear(Request."Pending Attachments");
        PendingArr.WriteTo(Text);
        Request."Pending Attachments".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    local procedure NewAttachmentId(): Text
    begin
        exit(DelChr(Format(CreateGuid()), '=', '{}'));
    end;

    local procedure GetAttachmentPayloadStore(var Request: Record "AIOS Chat Request"): JsonObject
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        Store: JsonObject;
        Text: Text;
    begin
        if not Request."Attachment Payloads".HasValue then
            exit(Store);
        Request."Attachment Payloads".CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(Store);
        if not Store.ReadFrom(Text) then
            Clear(Store);
        exit(Store);
    end;

    local procedure SetAttachmentPayloadStore(var Request: Record "AIOS Chat Request"; Store: JsonObject)
    var
        OutStream: OutStream;
        Text: Text;
    begin
        Clear(Request."Attachment Payloads");
        Store.WriteTo(Text);
        if Text = '' then
            exit;
        Request."Attachment Payloads".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    local procedure PutAttachmentPayload(var Request: Record "AIOS Chat Request"; PayloadId: Text; Payload: JsonObject)
    var
        Store: JsonObject;
    begin
        Store := GetAttachmentPayloadStore(Request);
        if Store.Contains(PayloadId) then
            Store.Remove(PayloadId);
        Store.Add(PayloadId, Payload);
        SetAttachmentPayloadStore(Request, Store);
    end;

    local procedure CollectReferencedAttachmentIds(var Request: Record "AIOS Chat Request"; var Referenced: Dictionary of [Text, Boolean])
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        PendingArr: JsonArray;
        MessagesArr: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        MsgToken: JsonToken;
        Msg: JsonObject;
        ContentToken: JsonToken;
        TypeToken: JsonToken;
        IdToken: JsonToken;
        Parts: JsonArray;
        i: Integer;
        j: Integer;
    begin
        PendingArr := GetAttachments(Request);
        for i := 0 to PendingArr.Count() - 1 do begin
            PendingArr.Get(i, PartToken);
            if not PartToken.IsObject() then
                continue;
            Part := PartToken.AsObject();
            if Part.Get('id', IdToken) then
                MarkReferencedId(Referenced, IdToken.AsValue().AsText());
        end;

        MessagesArr := ChatMessages.GetMessages(Request);
        for i := 0 to MessagesArr.Count() - 1 do begin
            MessagesArr.Get(i, MsgToken);
            if not MsgToken.IsObject() then
                continue;
            Msg := MsgToken.AsObject();
            if not Msg.Get('content', ContentToken) then
                continue;
            if not ContentToken.IsArray() then
                continue;
            Parts := ContentToken.AsArray();
            for j := 0 to Parts.Count() - 1 do begin
                Parts.Get(j, PartToken);
                if not PartToken.IsObject() then
                    continue;
                Part := PartToken.AsObject();
                if not Part.Get('type', TypeToken) then
                    continue;
                if TypeToken.AsValue().AsText() <> 'file' then
                    continue;
                if Part.Get('id', IdToken) then
                    MarkReferencedId(Referenced, IdToken.AsValue().AsText());
            end;
        end;
    end;

    local procedure MarkReferencedId(var Referenced: Dictionary of [Text, Boolean]; Id: Text)
    begin
        if Id = '' then
            exit;
        if not Referenced.ContainsKey(Id) then
            Referenced.Add(Id, true);
    end;

    local procedure ExpandContentParts(var Request: Record "AIOS Chat Request"; Parts: JsonArray): JsonArray
    var
        Store: JsonObject;
        OutParts: JsonArray;
        PartToken: JsonToken;
        Part: JsonObject;
        NewPart: JsonObject;
        TypeToken: JsonToken;
        IdToken: JsonToken;
        PayloadToken: JsonToken;
        Payload: JsonObject;
        TextToken: JsonToken;
        PartText: Text;
        i: Integer;
        PayloadId: Text;
    begin
        Store := GetAttachmentPayloadStore(Request);
        for i := 0 to Parts.Count() - 1 do begin
            Parts.Get(i, PartToken);
            if not PartToken.IsObject() then begin
                OutParts.Add(PartToken);
                continue;
            end;
            Part := PartToken.AsObject();
            Clear(NewPart);
            Part.WriteTo(PartText);
            if not NewPart.ReadFrom(PartText) then
                continue;

            if NewPart.Get('type', TypeToken) then
                if TypeToken.AsValue().AsText() = 'file' then
                    if NewPart.Get('id', IdToken) then begin
                        PayloadId := IdToken.AsValue().AsText();
                        if not Store.Get(PayloadId, PayloadToken) then
                            Error(AttachmentPayloadMissingErr, PayloadId);
                        Payload := PayloadToken.AsObject();
                        if Payload.Get('text', TextToken) then begin
                            if NewPart.Contains('text') then
                                NewPart.Remove('text');
                            NewPart.Add('text', TextToken.AsValue().AsText());
                            if NewPart.Contains('data') then
                                NewPart.Remove('data');
                        end else begin
                            if NewPart.Contains('data') then
                                NewPart.Remove('data');
                            NewPart.Add('data', GetBinaryAsBase64(Request, PayloadId));
                        end;
                    end;

            OutParts.Add(NewPart);
        end;
        exit(OutParts);
    end;

    local procedure AppendUserMessageWithAttachments(var Request: Record "AIOS Chat Request"; PromptText: Text)
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        MessagesArr: JsonArray;
        Msg: JsonObject;
        ContentParts: JsonArray;
        TextPart: JsonObject;
        PendingArr: JsonArray;
        PartToken: JsonToken;
        i: Integer;
    begin
        MessagesArr := ChatMessages.GetMessages(Request);
        Msg.Add('role', 'user');

        PendingArr := GetAttachments(Request);
        if PendingArr.Count() = 0 then
            Msg.Add('content', PromptText)
        else begin
            if PromptText <> '' then begin
                TextPart.Add('type', 'text');
                TextPart.Add('text', PromptText);
                ContentParts.Add(TextPart);
            end;
            for i := 0 to PendingArr.Count() - 1 do begin
                PendingArr.Get(i, PartToken);
                ContentParts.Add(PartToken.AsObject());
            end;
            if ContentParts.Count() = 0 then begin
                TextPart.Add('type', 'text');
                TextPart.Add('text', '');
                ContentParts.Add(TextPart);
            end;
            Msg.Add('content', ContentParts);
        end;

        MessagesArr.Add(Msg);
        ChatMessages.SetMessages(Request, MessagesArr);
        ClearAttachments(Request);
    end;

    local procedure TryMergeAttachmentsIntoLastUserMessage(var Request: Record "AIOS Chat Request"): Boolean
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        MessagesArr: JsonArray;
        NewMessages: JsonArray;
        MsgToken: JsonToken;
        LastMsg: JsonObject;
        RoleToken: JsonToken;
        ContentToken: JsonToken;
        ContentParts: JsonArray;
        TextPart: JsonObject;
        PendingArr: JsonArray;
        PartToken: JsonToken;
        i: Integer;
        LastIndex: Integer;
    begin
        MessagesArr := ChatMessages.GetMessages(Request);
        if MessagesArr.Count() = 0 then
            exit(false);

        LastIndex := MessagesArr.Count() - 1;
        MessagesArr.Get(LastIndex, MsgToken);
        if not MsgToken.IsObject() then
            exit(false);

        LastMsg := MsgToken.AsObject();
        if not LastMsg.Get('role', RoleToken) then
            exit(false);
        if RoleToken.AsValue().AsText() <> 'user' then
            exit(false);

        PendingArr := GetAttachments(Request);
        if PendingArr.Count() = 0 then
            exit(false);

        if LastMsg.Get('content', ContentToken) then
            if ContentToken.IsArray() then
                ContentParts := ContentToken.AsArray()
            else if ContentToken.IsValue() then
                if ContentToken.AsValue().AsText() <> '' then begin
                    TextPart.Add('type', 'text');
                    TextPart.Add('text', ContentToken.AsValue().AsText());
                    ContentParts.Add(TextPart);
                end;

        for i := 0 to PendingArr.Count() - 1 do begin
            PendingArr.Get(i, PartToken);
            ContentParts.Add(PartToken.AsObject());
        end;

        if ContentParts.Count() = 0 then begin
            Clear(TextPart);
            TextPart.Add('type', 'text');
            TextPart.Add('text', '');
            ContentParts.Add(TextPart);
        end;

        if LastMsg.Contains('content') then
            LastMsg.Remove('content');
        LastMsg.Add('content', ContentParts);

        for i := 0 to MessagesArr.Count() - 1 do
            if i = LastIndex then
                NewMessages.Add(LastMsg)
            else begin
                MessagesArr.Get(i, MsgToken);
                NewMessages.Add(MsgToken);
            end;

        ChatMessages.SetMessages(Request, NewMessages);
        ClearAttachments(Request);
        exit(true);
    end;

    local procedure AppendSystemMessage(var Request: Record "AIOS Chat Request"; Content: Text)
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        MessagesArr: JsonArray;
        Msg: JsonObject;
    begin
        MessagesArr := ChatMessages.GetMessages(Request);
        Msg.Add('role', 'system');
        Msg.Add('content', Content);
        MessagesArr.Add(Msg);
        ChatMessages.SetMessages(Request, MessagesArr);
    end;

    local procedure MaxAttachmentsPerRequest(): Integer
    begin
        exit(10);
    end;

    local procedure MaxAttachmentBase64Chars(): Integer
    begin
        // Bound for Attach(Base64, …) input before decode (~7.5 MB raw)
        exit(10000000);
    end;

    local procedure MaxAttachmentBytes(): Integer
    begin
        exit(7500000);
    end;

    var
        AttachMediaTypeEmptyErr: Label 'Attachment mediaType cannot be empty.';
        AttachDataEmptyErr: Label 'Attachment data cannot be empty.';
        TooManyAttachmentsErr: Label 'A request cannot include more than %1 attachments.', Comment = '%1 = max attachments';
        AttachmentTooLargeErr: Label 'Attachment exceeds the maximum size allowed for Attach.';
        AttachmentPayloadMissingErr: Label 'Attachment payload %1 was not found.', Comment = '%1 = attachment id';
        MediaIdEmptyErr: Label 'Media Id cannot be empty.';
        TenantMediaMissingErr: Label 'Tenant Media %1 was not found.', Comment = '%1 = media id';
        TenantMediaEmptyErr: Label 'Tenant Media %1 has no content.', Comment = '%1 = media id';
}

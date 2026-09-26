namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using System.Text;

codeunit 87492 "AIOS Lifecycle Spy"
{

    Access = Internal;
    SingleInstance = true;

    /// <summary>
    /// Clears the trace and starts recording lifecycle events.
    /// </summary>
    procedure StartRecording()
    begin
        EventTrace := '';
        LastModelId := '';
        AfterGenerateCalled := false;
        BeforeGeneratePrompt := '';
        BeforeGenerateSystemMessage := '';
        BeforeGenerateAttachText := '';
        Clear(LastProviderMessages);
        Recording := true;
    end;

    /// <summary>
    /// Stops recording. Events are ignored until StartRecording.
    /// </summary>
    procedure StopRecording()
    begin
        Recording := false;
    end;

    procedure GetEventTrace(): Text
    begin
        exit(EventTrace);
    end;

    procedure GetLastModelId(): Text
    begin
        exit(LastModelId);
    end;

    procedure WasAfterGenerateCalled(): Boolean
    begin
        exit(AfterGenerateCalled);
    end;

    /// <summary>
    /// While recording, OnBeforeGenerate sets this prompt on the request.
    /// </summary>
    procedure SetBeforeGeneratePrompt(Value: Text)
    begin
        BeforeGeneratePrompt := Value;
    end;

    /// <summary>
    /// While recording, OnBeforeGenerate sets this system message on the request.
    /// </summary>
    procedure SetBeforeGenerateSystemMessage(Value: Text)
    begin
        BeforeGenerateSystemMessage := Value;
    end;

    /// <summary>
    /// While recording, OnBeforeGenerate attaches this text as a text/plain file.
    /// </summary>
    procedure SetBeforeGenerateAttachText(Value: Text)
    begin
        BeforeGenerateAttachText := Value;
    end;

    /// <summary>
    /// Provider messages (GetProviderMessages) captured at the last OnBeforeLanguageModelCall while recording.
    /// </summary>
    procedure GetLastProviderMessages(): JsonArray
    begin
        exit(LastProviderMessages);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnBeforeGenerate, '', false, false)]
    local procedure SpyOnBeforeGenerate(ModelId: Text; var AIOSChatRequest: Record "AIOS Chat Request"; var AIOSChatResponse: Record "AIOS Chat Response")
    begin
        Append('OnBeforeGenerate', ModelId);
        ApplyBeforeGenerateChanges(AIOSChatRequest);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnBeforeLanguageModelCall, '', false, false)]
    local procedure SpyOnBeforeLanguageModelCall(ModelId: Text; var AIOSChatRequest: Record "AIOS Chat Request"; var AIOSChatResponse: Record "AIOS Chat Response")
    begin
        Append('OnBeforeLanguageModelCall', ModelId);
        if Recording then
            LastProviderMessages := AIOSChatRequest.GetProviderMessages();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnAfterLanguageModelCall, '', false, false)]
    local procedure SpyOnAfterLanguageModelCall(ModelId: Text; var AIOSChatRequest: Record "AIOS Chat Request"; var AIOSChatResponse: Record "AIOS Chat Response")
    begin
        Append('OnAfterLanguageModelCall', ModelId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnAfterGenerate, '', false, false)]
    local procedure SpyOnAfterGenerate(ModelId: Text; var AIOSChatRequest: Record "AIOS Chat Request"; var AIOSChatResponse: Record "AIOS Chat Response")
    begin
        AfterGenerateCalled := true;
        Append('OnAfterGenerate', ModelId);
    end;

    local procedure ApplyBeforeGenerateChanges(var Request: Record "AIOS Chat Request")
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        if not Recording then
            exit;
        if BeforeGeneratePrompt <> '' then
            Request.SetPrompt(BeforeGeneratePrompt);
        if BeforeGenerateSystemMessage <> '' then
            Request.SetSystemMessage(BeforeGenerateSystemMessage);
        if BeforeGenerateAttachText <> '' then
            Request.Attach(Base64Convert.ToBase64(BeforeGenerateAttachText), 'text/plain', 'subscriber.txt');
    end;

    local procedure Append(EventName: Text; ModelId: Text)
    begin
        if not Recording then
            exit;
        LastModelId := ModelId;
        if EventTrace = '' then
            EventTrace := EventName
        else
            EventTrace += '|' + EventName;
    end;

    var
        LastProviderMessages: JsonArray;
        EventTrace: Text;
        LastModelId: Text;
        AfterGenerateCalled: Boolean;
        Recording: Boolean;
        BeforeGeneratePrompt: Text;
        BeforeGenerateSystemMessage: Text;
        BeforeGenerateAttachText: Text;
}

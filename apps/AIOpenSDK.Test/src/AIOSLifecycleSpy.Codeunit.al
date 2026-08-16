namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnBeforeGenerate, '', false, false)]
    local procedure SpyOnBeforeGenerate(ModelId: Text; var AIOSChatRequest: Record "AIOS Chat Request"; var AIOSChatResponse: Record "AIOS Chat Response")
    begin
        Append('OnBeforeGenerate', ModelId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnBeforeLanguageModelCall, '', false, false)]
    local procedure SpyOnBeforeLanguageModelCall(ModelId: Text; var AIOSChatRequest: Record "AIOS Chat Request"; var AIOSChatResponse: Record "AIOS Chat Response")
    begin
        Append('OnBeforeLanguageModelCall', ModelId);
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
        EventTrace: Text;
        LastModelId: Text;
        AfterGenerateCalled: Boolean;
        Recording: Boolean;
}

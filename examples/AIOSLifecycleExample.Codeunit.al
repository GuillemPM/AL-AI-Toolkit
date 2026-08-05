namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

codeunit 87484 "AIOS Lifecycle Example"
{
    SingleInstance = true;

    /// <summary>
    /// Last ModelId seen by a lifecycle event (demo / diagnostics).
    /// </summary>
    procedure GetLastModelId(): Text
    begin
        exit(LastModelId);
    end;

    /// <summary>
    /// Ordered event names from the last generate (pipe-separated).
    /// </summary>
    procedure GetLastEventTrace(): Text
    begin
        exit(LastEventTrace);
    end;

    procedure ClearTrace()
    begin
        LastModelId := '';
        LastEventTrace := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnBeforeGenerate, '', false, false)]
    local procedure LogOnBeforeGenerate(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
        AppendTrace('OnBeforeGenerate', ModelId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnBeforeLanguageModelCall, '', false, false)]
    local procedure LogOnBeforeLanguageModelCall(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
        AppendTrace('OnBeforeLanguageModelCall', ModelId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnAfterLanguageModelCall, '', false, false)]
    local procedure LogOnAfterLanguageModelCall(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
        AppendTrace('OnAfterLanguageModelCall', ModelId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIOS Client", OnAfterGenerate, '', false, false)]
    local procedure LogOnAfterGenerate(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
        AppendTrace('OnAfterGenerate', ModelId);
    end;

    local procedure AppendTrace(EventName: Text; ModelId: Text)
    begin
        LastModelId := ModelId;
        if LastEventTrace = '' then
            LastEventTrace := EventName
        else
            LastEventTrace += '|' + EventName;
    end;

    var
        LastModelId: Text;
        LastEventTrace: Text;
}

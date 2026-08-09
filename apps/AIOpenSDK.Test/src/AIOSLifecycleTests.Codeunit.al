namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

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

    var
        UnexpectedOutputErr: Label 'Expected output ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedTraceErr: Label 'Expected event trace ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedModelIdErr: Label 'Expected model id ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedAfterGenerateErr: Label 'OnAfterGenerate should be raised on success.';
        UnexpectedAfterGenerateErr: Label 'OnAfterGenerate must not be raised on failure.';
}

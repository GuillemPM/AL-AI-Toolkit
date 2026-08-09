namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

codeunit 87491 "AIOS Lifecycle Tests"
{

    Access = Internal;
    Subtype = Test;

    [Test]
    procedure TryGenerate_Success_RaisesLifecycleEventsInOrder()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Response: Record "AIOS Chat Response";
        ExpectedTrace: Text;
    begin
        Spy.StartRecording();
        Mock.SetNextResponse('ok');
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnAfterGenerate';

        if not Client.TryGenerateText(Mock.Model('demo-model'), 'ping', Response) then
            Error(ExpectedSuccessErr);

        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
        if Spy.GetLastModelId() <> 'demo-model' then
            Error(UnexpectedModelIdErr, 'demo-model', Spy.GetLastModelId());
        if not Spy.WasAfterGenerateCalled() then
            Error(ExpectedAfterGenerateErr);
        Spy.StopRecording();
    end;

    [Test]
    procedure TryGenerate_SoftFail_DoesNotRaiseOnAfterGenerate()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Spy: Codeunit "AIOS Lifecycle Spy";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        ExpectedTrace: Text;
    begin
        Spy.StartRecording();
        Mock.SetNextError("AIOS Error Type"::ProviderUnavailable, 'simulated failure');
        Clear(Request);
        Request.SetPrompt('ping');
        Request.SetMaxRetries(0);
        ExpectedTrace := 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall';

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedFailureErr);

        if Spy.GetEventTrace() <> ExpectedTrace then
            Error(UnexpectedTraceErr, ExpectedTrace, Spy.GetEventTrace());
        if Spy.WasAfterGenerateCalled() then
            Error(UnexpectedAfterGenerateErr);
        Spy.StopRecording();
    end;

    var
        ExpectedSuccessErr: Label 'TryGenerateText should succeed with the mock.';
        ExpectedFailureErr: Label 'TryGenerateText should return false when the mock is set to fail.';
        UnexpectedTraceErr: Label 'Expected event trace ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedModelIdErr: Label 'Expected model id ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedAfterGenerateErr: Label 'OnAfterGenerate should be raised on success.';
        UnexpectedAfterGenerateErr: Label 'OnAfterGenerate must not be raised on soft-fail.';
}

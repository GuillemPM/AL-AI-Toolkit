namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

codeunit 87490 "AIOS Mock Tests"
{
    Subtype = Test;

    [Test]
    procedure GenerateText_JsonMode_ReturnsConfiguredMockContent()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Result: Text;
        Expected: Text;
    begin
        Expected := '{"sentiment":"positive","topics":["pricing","support"]}';
        Mock.SetNextResponse(Expected);

        Request.SetSystemMessage('You extract sentiment and topics.');
        Request.SetPrompt('Feedback: Great product.');
        Request.SetJsonMode(true);

        Result := Client.GenerateText(Mock.Model('demo-model'), Request);

        if Result <> Expected then
            Error(UnexpectedResultErr, Expected, Result);
    end;

    [Test]
    procedure TryGenerateText_ReturnsFalseOnMockError()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Response: Record "AIOS Chat Response";
    begin
        Mock.SetNextError("AIOS Error Type"::ProviderUnavailable, 'simulated failure');

        if Client.TryGenerateText(Mock.Model('demo-model'), 'hello', Response) then
            Error(ExpectedFailureErr);

        if Response.GetErrorType() <> "AIOS Error Type"::ProviderUnavailable then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
    end;

    [Test]
    procedure GenerateText_ReturnsMockContent()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Result: Text;
    begin
        Mock.SetNextResponse('hello from mock');
        Result := Client.GenerateText(Mock.Model('demo-model'), 'ping');
        if Result <> 'hello from mock' then
            Error(UnexpectedResultErr, 'hello from mock', Result);
    end;

    var
        UnexpectedResultErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedFailureErr: Label 'TryGenerateText should return false when the mock is set to fail.';
        UnexpectedErrorTypeErr: Label 'Expected ProviderUnavailable error type, got %1.', Comment = '%1 = actual error type';
}

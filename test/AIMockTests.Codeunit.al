codeunit 70190 "AI Mock Tests"
{
    Subtype = Test;

    [Test]
    procedure GenerateJson_ReturnsConfiguredMockContent()
    var
        Mock: Codeunit "AI Mock";
        Client: Codeunit "AI Client";
        Result: Text;
        Expected: Text;
    begin
        Expected := '{"sentiment":"positive","topics":["pricing","support"]}';
        Mock.SetNextResponse(Expected);

        Result := Client.GenerateJson(
            Mock.Model('demo-model'),
            'You extract sentiment and topics.',
            'Feedback: Great product.');

        if Result <> Expected then
            Error(UnexpectedResultErr, Expected, Result);
    end;

    [Test]
    procedure TryGenerateText_ReturnsFalseOnMockError()
    var
        Mock: Codeunit "AI Mock";
        Client: Codeunit "AI Client";
        Response: Record "AI Chat Response";
    begin
        Mock.SetNextError("AI Error Type"::ProviderUnavailable, 'simulated failure');

        if Client.TryGenerateText(Mock.Model('demo-model'), 'hello', Response) then
            Error(ExpectedFailureErr);

        if Response.GetErrorType() <> "AI Error Type"::ProviderUnavailable then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
    end;

    [Test]
    procedure GenerateText_ReturnsMockContent()
    var
        Mock: Codeunit "AI Mock";
        Client: Codeunit "AI Client";
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

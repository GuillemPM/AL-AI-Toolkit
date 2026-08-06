namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

codeunit 87490 "AIOS Mock Tests"
{
    Subtype = Test;

    [Test]
    procedure GenerateText_JsonOutput_ReturnsConfiguredMockContent()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Result: Text;
        Expected: Text;
    begin
        Expected := '{"sentiment":"positive","topics":["pricing","support"]}';
        Mock.SetNextResponse(Expected);

        Request.SetSystemMessage('You extract sentiment and topics.');
        Request.SetPrompt('Feedback: Great product.');
        Request.SetOutput(Schema.Json());

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();

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
        Result := Client.GenerateText(Mock.Model('demo-model'), 'ping').Output();
        if Result <> 'hello from mock' then
            Error(UnexpectedResultErr, 'hello from mock', Result);
    end;

    [Test]
    procedure GenerateText_Result_ExposesOutputAndBody()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Result: Codeunit "AIOS Generate Result";
    begin
        Mock.SetNextResponse('hello from mock');
        Result := Client.GenerateText(Mock.Model('demo-model'), 'ping');
        if Result.Output() <> 'hello from mock' then
            Error(UnexpectedResultErr, 'hello from mock', Result.Output());
        if Result.Body() <> 'hello from mock' then
            Error(UnexpectedResultErr, 'hello from mock', Result.Body());
    end;

    [Test]
    procedure ChatResponse_BodyAndHeaders_RoundTrip()
    var
        Response: Record "AIOS Chat Response";
        Headers: JsonObject;
        Loaded: JsonObject;
        Token: JsonToken;
        Body: Text;
    begin
        Headers.Add('x-request-id', 'abc-123');
        Response.SetBody('{"id":"resp_1"}');
        Response.SetHeaders(Headers);

        Body := Response.GetBody();
        if Body <> '{"id":"resp_1"}' then
            Error(UnexpectedResultErr, '{"id":"resp_1"}', Body);

        Loaded := Response.GetHeaders();
        if not Loaded.Get('x-request-id', Token) then
            Error(MissingHeaderErr);
        if Token.AsValue().AsText() <> 'abc-123' then
            Error(UnexpectedResultErr, 'abc-123', Token.AsValue().AsText());
    end;

    var
        UnexpectedResultErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedFailureErr: Label 'TryGenerateText should return false when the mock is set to fail.';
        UnexpectedErrorTypeErr: Label 'Expected ProviderUnavailable error type, got %1.', Comment = '%1 = actual error type';
        MissingHeaderErr: Label 'Expected x-request-id header.';
}

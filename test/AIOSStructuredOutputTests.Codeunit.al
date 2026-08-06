namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

codeunit 87494 "AIOS Structured Output Tests"
{
    Subtype = Test;

    [Test]
    procedure GenerateText_SetOutput_BindsFlatJsonToRecord()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Test Bind Target";
        RecRef: RecordRef;
        Result: Text;
    begin
        Mock.SetNextResponse('{"Sentiment":"positive","Score":0.85,"Urgent":true,"Summary":"Worth it","Topics":["pricing","support"]}');

        RecRef.GetTable(Feedback);
        Request.SetPrompt('feedback');
        Request.SetOutput(RecRef);

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, RecRef).Output();
        RecRef.SetTable(Feedback, true);

        if Feedback.Sentiment <> 'positive' then
            Error(UnexpectedTextErr, 'positive', Feedback.Sentiment);
        if Feedback.Score <> 0.85 then
            Error(UnexpectedDecErr, 0.85, Feedback.Score);
        if not Feedback.Urgent then
            Error(ExpectedUrgentErr);
        if Feedback.Summary <> 'Worth it' then
            Error(UnexpectedTextErr, 'Worth it', Feedback.Summary);
        if Feedback.Topics <> '["pricing","support"]' then
            Error(UnexpectedTextErr, '["pricing","support"]', Feedback.Topics);
        if Result = '' then
            Error(ExpectedRawJsonErr);
    end;

    [Test]
    procedure GenerateText_SetOutput_CaseInsensitiveKeys()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Test Bind Target";
        RecRef: RecordRef;
    begin
        Mock.SetNextResponse('{"sentiment":"neutral","score":0.1,"urgent":false,"summary":"ok"}');

        RecRef.GetTable(Feedback);
        Request.SetPrompt('x');
        Request.SetOutput(RecRef);

        Client.GenerateText(Mock.Model('demo-model'), Request, RecRef);
        RecRef.SetTable(Feedback, true);

        if Feedback.Sentiment <> 'neutral' then
            Error(UnexpectedTextErr, 'neutral', Feedback.Sentiment);
    end;

    [Test]
    procedure TryGenerate_SetOutput_InvalidJson_ReturnsParseFailed()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Feedback: Record "AIOS Test Bind Target";
        RecRef: RecordRef;
    begin
        Mock.SetNextResponse('not-json');

        RecRef.GetTable(Feedback);
        Request.SetPrompt('x');
        Request.SetMaxRetries(0);
        Request.SetOutput(RecRef);

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response, RecRef) then
            Error(ExpectedFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::ParseFailed then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
    end;

    [Test]
    procedure GenerateText_NestedSchema_ReturnsValidatedJson()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Fields: List of [JsonObject];
        AddressFields: List of [JsonObject];
        Root: JsonToken;
        RootObj: JsonObject;
        AddrToken: JsonToken;
        AddrObj: JsonObject;
        TagsToken: JsonToken;
        Tags: JsonArray;
        NameToken: JsonToken;
        CityToken: JsonToken;
        Result: Text;
    begin
        Mock.SetNextResponse('{"name":"Ada","address":{"city":"Barcelona"},"tags":["ai","al"]}');

        AddressFields.Add(Schema.Field('city', Schema.String()));
        Fields.Add(Schema.Field('name', Schema.String()));
        Fields.Add(Schema.Field('address', Schema.Object(AddressFields)));
        Fields.Add(Schema.Field('tags', Schema.Array(Schema.String())));

        Request.SetPrompt('person');
        Request.SetOutput(Schema.Object(Fields));

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        if Result = '' then
            Error(ExpectedRawJsonErr);
        if not Root.ReadFrom(Result) then
            Error(ExpectedRawJsonErr);
        RootObj := Root.AsObject();
        if not RootObj.Get('name', NameToken) then
            Error(MissingPropErr, 'name');
        if NameToken.AsValue().AsText() <> 'Ada' then
            Error(UnexpectedTextErr, 'Ada', NameToken.AsValue().AsText());
        if not RootObj.Get('address', AddrToken) then
            Error(MissingPropErr, 'address');
        AddrObj := AddrToken.AsObject();
        if not AddrObj.Get('city', CityToken) then
            Error(MissingPropErr, 'city');
        if CityToken.AsValue().AsText() <> 'Barcelona' then
            Error(UnexpectedTextErr, 'Barcelona', CityToken.AsValue().AsText());
        if not RootObj.Get('tags', TagsToken) then
            Error(MissingPropErr, 'tags');
        Tags := TagsToken.AsArray();
        if Tags.Count() <> 2 then
            Error(UnexpectedCountErr, 2, Tags.Count());
    end;

    [Test]
    procedure GenerateText_ArrayOfObjects_ValidatesElements()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        ItemFields: List of [JsonObject];
        Root: JsonToken;
        Arr: JsonArray;
        Result: Text;
    begin
        Mock.SetNextResponse('[{"name":"a"},{"name":"b"}]');

        ItemFields.Add(Schema.Field('name', Schema.String()));
        Request.SetPrompt('list');
        Request.SetOutput(Schema.Array(Schema.Object(ItemFields)));

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        if not Root.ReadFrom(Result) then
            Error(ExpectedRawJsonErr);
        Arr := Root.AsArray();
        if Arr.Count() <> 2 then
            Error(UnexpectedCountErr, 2, Arr.Count());
    end;

    [Test]
    procedure TryGenerate_SchemaTypeMismatch_ReturnsParseFailed()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Fields: List of [JsonObject];
    begin
        Mock.SetNextResponse('{"name":123}');

        Fields.Add(Schema.Field('name', Schema.String()));
        Request.SetPrompt('x');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Object(Fields));

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedSchemaFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::ParseFailed then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
    end;

    [Test]
    procedure GenerateText_TextOutput_ReturnsPlainText()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Result: Text;
    begin
        Mock.SetNextResponse('hello world');

        Request.SetPrompt('say hello');
        Request.SetOutput(Schema.Text());

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        if Result <> 'hello world' then
            Error(UnexpectedTextErr, 'hello world', Result);
        if Request."Json Mode" then
            Error(ExpectedNoJsonModeErr);
    end;

    [Test]
    procedure GenerateText_JsonOutput_AcceptsAnyValidJson()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Result: Text;
    begin
        Mock.SetNextResponse('{"a":1,"b":[true,"x"]}');

        Request.SetPrompt('json');
        Request.SetOutput(Schema.Json());

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        if Result <> '{"a":1,"b":[true,"x"]}' then
            Error(UnexpectedTextErr, '{"a":1,"b":[true,"x"]}', Result);
    end;

    [Test]
    procedure TryGenerate_JsonOutput_InvalidJson_ReturnsParseFailed()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
    begin
        Mock.SetNextResponse('not-json');

        Request.SetPrompt('json');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Json());

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedSchemaFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::ParseFailed then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
        if Response.GetText() <> 'not-json' then
            Error(UnexpectedTextErr, 'not-json', Response.GetText());
    end;

    [Test]
    procedure GenerateText_Choice_ReturnsPlainString()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Options: List of [Text];
        Result: Text;
    begin
        Mock.SetNextResponse('{"result":"rainy"}');

        Options.Add('sunny');
        Options.Add('rainy');
        Options.Add('snowy');
        Request.SetPrompt('weather');
        Request.SetOutput(Schema.Choice(Options));

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        if Result <> 'rainy' then
            Error(UnexpectedTextErr, 'rainy', Result);
    end;

    [Test]
    procedure GenerateText_Choice_BareText_ReturnsParseFailed()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Options: List of [Text];
    begin
        Mock.SetNextResponse('sunny');

        Options.Add('sunny');
        Options.Add('rainy');
        Options.Add('snowy');
        Request.SetPrompt('weather');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Choice(Options));

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedSchemaFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::ParseFailed then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
        if Response.GetText() <> 'sunny' then
            Error(UnexpectedTextErr, 'sunny', Response.GetText());
    end;

    [Test]
    procedure TryGenerate_Choice_InvalidOption_ReturnsParseFailed()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Options: List of [Text];
    begin
        Mock.SetNextResponse('{"result":"windy"}');

        Options.Add('sunny');
        Options.Add('rainy');
        Options.Add('snowy');
        Request.SetPrompt('weather');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Choice(Options));

        if Client.TryGenerate(Mock.Model('demo-model'), Request, Response) then
            Error(ExpectedSchemaFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::ParseFailed then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
        if Response.GetText() <> '{"result":"windy"}' then
            Error(UnexpectedTextErr, '{"result":"windy"}', Response.GetText());
    end;

    [Test]
    procedure GenerateText_NestedEnum_Validates()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Fields: List of [JsonObject];
        Options: List of [Text];
        Root: JsonToken;
        RootObj: JsonObject;
        WeatherToken: JsonToken;
        Result: Text;
    begin
        Mock.SetNextResponse('{"weather":"snowy"}');

        Options.Add('sunny');
        Options.Add('rainy');
        Options.Add('snowy');
        Fields.Add(Schema.Field('weather', Schema.Enum(Options)));
        Request.SetPrompt('forecast');
        Request.SetOutput(Schema.Object(Fields));

        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();
        if not Root.ReadFrom(Result) then
            Error(ExpectedRawJsonErr);
        RootObj := Root.AsObject();
        if not RootObj.Get('weather', WeatherToken) then
            Error(MissingPropErr, 'weather');
        if WeatherToken.AsValue().AsText() <> 'snowy' then
            Error(UnexpectedTextErr, 'snowy', WeatherToken.AsValue().AsText());
    end;

    [Test]
    procedure Choice_EmptyOptions_Errors()
    var
        Schema: Codeunit "AIOS Schema";
        Options: List of [Text];
    begin
        asserterror Schema.Choice(Options);
        if StrPos(GetLastErrorText(), 'Choice options cannot be empty') = 0 then
            Error(UnexpectedChoiceEmptyErr, GetLastErrorText());
    end;

    var
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedDecErr: Label 'Expected %1, got %2.', Comment = '%1 = expected, %2 = actual';
        ExpectedUrgentErr: Label 'Expected Urgent = true.';
        ExpectedRawJsonErr: Label 'Expected raw JSON text to be returned.';
        ExpectedFailureErr: Label 'TryGenerate should fail when JSON cannot be bound.';
        ExpectedSchemaFailureErr: Label 'TryGenerate should fail when JSON does not match the schema.';
        UnexpectedErrorTypeErr: Label 'Expected ParseFailed, got %1.', Comment = '%1 = actual';
        ExpectedNoJsonModeErr: Label 'Text output should not enable JSON mode.';
        MissingPropErr: Label 'Missing property %1.', Comment = '%1 = name';
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        UnexpectedChoiceEmptyErr: Label 'Expected empty-options error, got: %1', Comment = '%1 = actual error text';
}

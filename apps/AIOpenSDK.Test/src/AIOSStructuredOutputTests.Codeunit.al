namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

codeunit 87494 "AIOS Structured Output Tests"
{

    Access = Internal;
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
    procedure GenerateText_SetOutput_InvalidJson_Errors()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Test Bind Target";
        RecRef: RecordRef;
    begin
        Mock.SetNextResponse('not-json');

        RecRef.GetTable(Feedback);
        Request.SetPrompt('x');
        Request.SetMaxRetries(0);
        Request.SetOutput(RecRef);

        asserterror Client.GenerateText(Mock.Model('demo-model'), Request, RecRef);
        if GetLastErrorText() = '' then
            Error(ExpectedFailureErr);
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
    procedure GenerateText_SchemaTypeMismatch_Errors()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Fields: List of [JsonObject];
    begin
        Mock.SetNextResponse('{"name":123}');

        Fields.Add(Schema.Field('name', Schema.String()));
        Request.SetPrompt('x');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Object(Fields));

        asserterror Client.GenerateText(Mock.Model('demo-model'), Request);
        if GetLastErrorText() = '' then
            Error(ExpectedSchemaFailureErr);
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
    procedure GenerateText_JsonOutput_InvalidJson_Errors()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
    begin
        Mock.SetNextResponse('not-json');

        Request.SetPrompt('json');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Json());

        asserterror Client.GenerateText(Mock.Model('demo-model'), Request);
        if GetLastErrorText() = '' then
            Error(ExpectedSchemaFailureErr);
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
    procedure GenerateText_Choice_BareText_Errors()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Options: List of [Text];
    begin
        Mock.SetNextResponse('sunny');

        Options.Add('sunny');
        Options.Add('rainy');
        Options.Add('snowy');
        Request.SetPrompt('weather');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Choice(Options));

        asserterror Client.GenerateText(Mock.Model('demo-model'), Request);
        if GetLastErrorText() = '' then
            Error(ExpectedSchemaFailureErr);
    end;

    [Test]
    procedure GenerateText_Choice_InvalidOption_Errors()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Options: List of [Text];
    begin
        Mock.SetNextResponse('{"result":"windy"}');

        Options.Add('sunny');
        Options.Add('rainy');
        Options.Add('snowy');
        Request.SetPrompt('weather');
        Request.SetMaxRetries(0);
        Request.SetOutput(Schema.Choice(Options));

        asserterror Client.GenerateText(Mock.Model('demo-model'), Request);
        if GetLastErrorText() = '' then
            Error(ExpectedSchemaFailureErr);
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

    [Test]
    procedure GenerateText_ReusedRequest_TextAfterStructured_ReturnsPlainText()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Fields: List of [JsonObject];
        Result: Text;
    begin
        Fields.Add(Schema.Field('name', Schema.String()));
        Request.SetSystemMessage('You are a helper.');
        Request.SetPrompt('person');
        Request.SetOutput(Schema.Object(Fields));
        Mock.SetNextResponse('{"name":"Ada"}');
        Client.GenerateText(Mock.Model('demo-model'), Request);

        // History is reset separately; the system message is never stored in it.
        Request.ClearMessages();
        Request.SetOutput(Schema.Text());
        Mock.SetNextResponse('plain words');
        Result := Client.GenerateText(Mock.Model('demo-model'), Request).Output();

        if Result <> 'plain words' then
            Error(UnexpectedTextErr, 'plain words', Result);
        if Request."Json Mode" then
            Error(ExpectedNoJsonModeErr);
        if Request.GetEffectiveSystemMessage() <> 'You are a helper.' then
            Error(UnexpectedTextErr, 'You are a helper.', Request.GetEffectiveSystemMessage());
    end;

    [Test]
    procedure ClearOutput_AfterSchema_ResetsJsonModeAndInstruction()
    var
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('name', Schema.String()));
        Request.SetSystemMessage('You are a helper.');
        Request.SetOutput(Schema.Object(Fields));
        if not Request."Json Mode" then
            Error(ExpectedJsonModeErr);
        if StrPos(Request.GetEffectiveSystemMessage(), 'conforms to this JSON Schema') = 0 then
            Error(ExpectedHintErr, Request.GetEffectiveSystemMessage());

        Request.ClearOutput();

        if Request."Json Mode" then
            Error(ExpectedNoJsonModeAfterClearErr);
        if Request.HasOutputSchema() then
            Error(ExpectedNoOutputSchemaErr);
        if Request.GetEffectiveSystemMessage() <> 'You are a helper.' then
            Error(UnexpectedTextErr, 'You are a helper.', Request.GetEffectiveSystemMessage());
    end;

    [Test]
    procedure ClearOutput_ManualJsonMode_DisablesJsonMode()
    var
        Request: Record "AIOS Chat Request";
    begin
        Request."Json Mode" := true;
        Request.SetSystemMessage('Be brief.');

        Request.ClearOutput();

        if Request."Json Mode" then
            Error(ExpectedNoJsonModeAfterClearErr);
        if Request.GetEffectiveSystemMessage() <> 'Be brief.' then
            Error(UnexpectedTextErr, 'Be brief.', Request.GetEffectiveSystemMessage());
    end;

    [Test]
    procedure ClearOutput_AfterRecRef_ResetsJsonModeAndInstruction()
    var
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Test Bind Target";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Feedback);
        Request.SetOutput(RecRef);
        if Request.GetEffectiveSystemMessage() = '' then
            Error(ExpectedHintErr, '');

        Request.ClearOutput();

        if Request.HasOutput() then
            Error(ExpectedNoOutputErr);
        if Request."Json Mode" then
            Error(ExpectedNoJsonModeAfterClearErr);
        if Request.GetEffectiveSystemMessage() <> '' then
            Error(UnexpectedTextErr, '', Request.GetEffectiveSystemMessage());
    end;

    [Test]
    procedure SetOutput_RepeatedSchema_DoesNotAccumulateHints()
    var
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        FirstFields: List of [JsonObject];
        SecondFields: List of [JsonObject];
        Effective: Text;
    begin
        FirstFields.Add(Schema.Field('firstonly', Schema.String()));
        SecondFields.Add(Schema.Field('secondonly', Schema.String()));
        Request.SetSystemMessage('You are a helper.');
        Request.SetOutput(Schema.Object(FirstFields));
        Request.SetOutput(Schema.Object(SecondFields));

        Effective := Request.GetEffectiveSystemMessage();
        if StrPos(Effective, 'firstonly') <> 0 then
            Error(UnexpectedStaleHintErr, Effective);
        if StrPos(Effective, 'secondonly') = 0 then
            Error(ExpectedHintErr, Effective);
        if CountOccurrences(Effective, 'conforms to this JSON Schema') <> 1 then
            Error(UnexpectedCountErr, 1, CountOccurrences(Effective, 'conforms to this JSON Schema'));
        if StrPos(Effective, 'You are a helper. ') <> 1 then
            Error(UnexpectedTextErr, 'You are a helper. ...', Effective);
    end;

    [Test]
    procedure SetOutput_RepeatedRecRef_DoesNotAccumulateHints()
    var
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Test Bind Target";
        RecRef: RecordRef;
        Effective: Text;
    begin
        RecRef.GetTable(Feedback);
        Request.SetSystemMessage('You are a helper.');
        Request.SetOutput(RecRef);
        Request.SetOutput(RecRef);

        Effective := Request.GetEffectiveSystemMessage();
        if CountOccurrences(Effective, 'Respond with a single JSON object only') <> 1 then
            Error(UnexpectedCountErr, 1, CountOccurrences(Effective, 'Respond with a single JSON object only'));
    end;

    [Test]
    procedure GenerateText_RecRef_DifferentTable_RebindsHint()
    var
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Test Bind Target";
        OtherTarget: Record "AIOS Chat Response";
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        FeedbackRecRef: RecordRef;
        OtherRecRef: RecordRef;
        Effective: Text;
    begin
        FeedbackRecRef.GetTable(Feedback);
        Request.SetPrompt('feedback');
        Mock.SetNextResponse('{"Sentiment":"positive"}');
        Client.GenerateText(Mock.Model('demo-model'), Request, FeedbackRecRef);

        OtherRecRef.GetTable(OtherTarget);
        Request.ClearMessages();
        Mock.SetNextResponse('{"Provider Name":"bound"}');
        Client.GenerateText(Mock.Model('demo-model'), Request, OtherRecRef);
        OtherRecRef.SetTable(OtherTarget, true);

        Effective := Request.GetEffectiveSystemMessage();
        if StrPos(Effective, 'Provider Name') = 0 then
            Error(ExpectedHintErr, Effective);
        if StrPos(Effective, 'Sentiment') > 0 then
            Error(UnexpectedStaleHintErr, Effective);
        if OtherTarget."Provider Name" <> 'bound' then
            Error(UnexpectedTextErr, 'bound', OtherTarget."Provider Name");
    end;

    [Test]
    procedure SetOutput_PreservesUserSystemMessage()
    var
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Feedback: Record "AIOS Test Bind Target";
        RecRef: RecordRef;
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('name', Schema.String()));
        Request.SetSystemMessage('You are a helper.');
        Request.SetOutput(Schema.Object(Fields));
        if Request.GetSystemMessage() <> 'You are a helper.' then
            Error(UnexpectedTextErr, 'You are a helper.', Request.GetSystemMessage());

        RecRef.GetTable(Feedback);
        Request.SetOutput(RecRef);
        if Request.GetSystemMessage() <> 'You are a helper.' then
            Error(UnexpectedTextErr, 'You are a helper.', Request.GetSystemMessage());
    end;

    [Test]
    procedure SetSystemMessage_AfterSetOutput_KeepsInstruction()
    var
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Effective: Text;
    begin
        Request.SetOutput(Schema.Json());
        Request.SetSystemMessage('Be brief.');

        Effective := Request.GetEffectiveSystemMessage();
        if Effective <> 'Be brief. Respond with valid JSON only, no markdown fences.' then
            Error(UnexpectedTextErr, 'Be brief. Respond with valid JSON only, no markdown fences.', Effective);
    end;

    [Test]
    procedure GetEffectiveSystemMessage_SchemaWithoutUserText_IsInstructionOnly()
    var
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
    begin
        Request.SetOutput(Schema.Json());
        if Request.GetEffectiveSystemMessage() <> 'Respond with valid JSON only, no markdown fences.' then
            Error(UnexpectedTextErr, 'Respond with valid JSON only, no markdown fences.', Request.GetEffectiveSystemMessage());

        Request.ClearOutput();
        if Request.GetEffectiveSystemMessage() <> '' then
            Error(UnexpectedTextErr, '', Request.GetEffectiveSystemMessage());
    end;

    [Test]
    procedure GetEffectiveSystemMessage_ManualJsonMode_AppendsJsonInstruction()
    var
        Request: Record "AIOS Chat Request";
    begin
        Request."Json Mode" := true;
        Request.SetSystemMessage('Be brief.');
        Request.SetPrompt('hello');

        if Request.GetEffectiveSystemMessage() <> 'Be brief. Respond with valid JSON only, no markdown fences.' then
            Error(UnexpectedTextErr, 'Be brief. Respond with valid JSON only, no markdown fences.', Request.GetEffectiveSystemMessage());
    end;

    local procedure CountOccurrences(Value: Text; Search: Text): Integer
    var
        Position: Integer;
        Occurrences: Integer;
    begin
        Position := StrPos(Value, Search);
        while Position <> 0 do begin
            Occurrences += 1;
            Value := CopyStr(Value, Position + StrLen(Search));
            Position := StrPos(Value, Search);
        end;
        exit(Occurrences);
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
        ExpectedJsonModeErr: Label 'Structured output should enable JSON mode.';
        ExpectedNoJsonModeAfterClearErr: Label 'ClearOutput should disable JSON mode.';
        ExpectedNoOutputSchemaErr: Label 'ClearOutput should remove the output schema.';
        ExpectedNoOutputErr: Label 'ClearOutput should remove the RecRef output binding.';
        ExpectedHintErr: Label 'Expected the output instruction in the effective system message, got: %1', Comment = '%1 = effective system message';
        UnexpectedStaleHintErr: Label 'Effective system message still contains a stale output instruction: %1', Comment = '%1 = effective system message';
}

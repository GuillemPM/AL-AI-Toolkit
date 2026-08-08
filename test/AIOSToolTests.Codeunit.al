namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Examples;
using PM.Guillem.AIOpenSDK.Provider.Mock;

/// <summary>
/// Mock-based tests for tool definitions, tool calls, message history, and multi-step GenerateText.
/// </summary>
codeunit 87497 "AIOS Tool Tests"
{
    Subtype = Test;

    [Test]
    procedure ToolSet_GetDefinitions_IncludesNameDescriptionParameters()
    var
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Definitions: JsonArray;
        DefToken: JsonToken;
        Def: JsonObject;
        NameToken: JsonToken;
        DescToken: JsonToken;
        ParamsToken: JsonToken;
        Tool: Interface "AIOS Tool";
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Definitions := ToolSet.GetDefinitions();
        if Definitions.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Definitions.Count());
        Definitions.Get(0, DefToken);
        Def := DefToken.AsObject();
        if not Def.Get('name', NameToken) then
            Error(MissingFieldErr, 'name');
        if NameToken.AsValue().AsText() <> 'echo' then
            Error(UnexpectedTextErr, 'echo', NameToken.AsValue().AsText());
        if not Def.Get('description', DescToken) then
            Error(MissingFieldErr, 'description');
        if DescToken.AsValue().AsText() = '' then
            Error(ExpectedDescriptionErr);
        if not Def.Get('parameters', ParamsToken) then
            Error(MissingFieldErr, 'parameters');
        if not ParamsToken.IsObject() then
            Error(ExpectedParametersObjectErr);
    end;

    [Test]
    procedure Request_SetTools_StoresDefinitions()
    var
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Tool: Interface "AIOS Tool";
        Definitions: JsonArray;
        DefToken: JsonToken;
        NameToken: JsonToken;
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Request.SetTools(ToolSet);
        if not Request.HasTools() then
            Error(ExpectedHasToolsErr);
        Definitions := Request.GetToolDefinitions();
        Definitions.Get(0, DefToken);
        if not DefToken.AsObject().Get('name', NameToken) then
            Error(MissingFieldErr, 'name');
        if NameToken.AsValue().AsText() <> 'echo' then
            Error(UnexpectedTextErr, 'echo', NameToken.AsValue().AsText());
    end;

    [Test]
    procedure Mock_SetNextToolCall_EmptyContentIsSuccess()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        ToolCalls: List of [Codeunit "AIOS Tool Call"];
        Call: Codeunit "AIOS Tool Call";
        Args: JsonObject;
        Token: JsonToken;
    begin
        Mock.SetNextToolCall('echo', '{"message":"hi"}');
        Request.SetPrompt('use echo');
        Result := Client.GenerateText(Mock.Model('demo-model'), Request);

        if not Result.HasToolCalls() then
            Error(ExpectedToolCallsErr);
        if Result.Output() <> '' then
            Error(UnexpectedTextErr, '', Result.Output());
        ToolCalls := Result.GetToolCalls();
        if ToolCalls.Count() <> 1 then
            Error(UnexpectedCountErr, 1, ToolCalls.Count());
        ToolCalls.Get(1, Call);
        if Call.GetName() <> 'echo' then
            Error(UnexpectedTextErr, 'echo', Call.GetName());
        Args := Call.GetArguments();
        if not Args.Get('message', Token) then
            Error(MissingFieldErr, 'message');
        if Token.AsValue().AsText() <> 'hi' then
            Error(UnexpectedTextErr, 'hi', Token.AsValue().AsText());
    end;

    [Test]
    procedure ChatRequest_MessageAppend_RoundTrip()
    var
        Request: Record "AIOS Chat Request";
        ToolCalls: List of [Codeunit "AIOS Tool Call"];
        Call: Codeunit "AIOS Tool Call";
        Args: JsonObject;
        Messages: JsonArray;
        MsgToken: JsonToken;
        Msg: JsonObject;
        RoleToken: JsonToken;
        ToolCallsToken: JsonToken;
        ContentToken: JsonToken;
    begin
        Args.Add('message', 'ping');
        Call.SetCall('call_1', 'echo', Args);
        ToolCalls.Add(Call);

        Request.AppendUserMessage('please echo');
        Request.AppendAssistantToolCalls('', ToolCalls);
        Request.AppendToolResult('call_1', 'echo', 'ping');

        Messages := Request.GetMessages();
        if Messages.Count() <> 3 then
            Error(UnexpectedCountErr, 3, Messages.Count());

        Messages.Get(0, MsgToken);
        Msg := MsgToken.AsObject();
        if not Msg.Get('role', RoleToken) or (RoleToken.AsValue().AsText() <> 'user') then
            Error(UnexpectedRoleErr, 'user');

        Messages.Get(1, MsgToken);
        Msg := MsgToken.AsObject();
        if not Msg.Get('role', RoleToken) or (RoleToken.AsValue().AsText() <> 'assistant') then
            Error(UnexpectedRoleErr, 'assistant');
        if not Msg.Get('tool_calls', ToolCallsToken) then
            Error(MissingFieldErr, 'tool_calls');
        if ToolCallsToken.AsArray().Count() <> 1 then
            Error(UnexpectedCountErr, 1, ToolCallsToken.AsArray().Count());
        if not Msg.Get('reasoning_content', ContentToken) then
            Error(MissingFieldErr, 'reasoning_content');

        Messages.Get(2, MsgToken);
        Msg := MsgToken.AsObject();
        if not Msg.Get('role', RoleToken) or (RoleToken.AsValue().AsText() <> 'tool') then
            Error(UnexpectedRoleErr, 'tool');
        if not Msg.Get('content', ContentToken) or (ContentToken.AsValue().AsText() <> 'ping') then
            Error(UnexpectedTextErr, 'ping', ContentToken.AsValue().AsText());
    end;

    [Test]
    procedure ToolSet_AddNamed_LoadsDefinition()
    var
        ToolSet: Codeunit "AIOS Tool Set";
        Schema: Codeunit "AIOS Schema";
        Definitions: JsonArray;
        DefToken: JsonToken;
        NameToken: JsonToken;
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('message', Schema.String()));
        ToolSet.Add('echo', 'Echoes the message.', Schema.Object(Fields));
        if ToolSet.Count() <> 1 then
            Error(UnexpectedCountErr, 1, ToolSet.Count());
        if not ToolSet.HasTool('echo') then
            Error(ExpectedHasToolsErr);
        Definitions := ToolSet.GetDefinitions();
        Definitions.Get(0, DefToken);
        if not DefToken.AsObject().Get('name', NameToken) then
            Error(MissingFieldErr, 'name');
        if NameToken.AsValue().AsText() <> 'echo' then
            Error(UnexpectedTextErr, 'echo', NameToken.AsValue().AsText());
    end;

    [Test]
    procedure GenerateText_NamedTools_OnExecuteTool_AutoExecutes()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
    begin
        AddDemoNamedTools(ToolSet);
        Mock.SetNextToolCallThenResponse('call_1', 'echo', '{"message":"via-event"}', 'done via event');
        Request.SetPrompt('use echo');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);
        if Result.HasToolCalls() then
            Error(UnexpectedToolCallsErr);
        if Result.Output() <> 'done via event' then
            Error(UnexpectedTextErr, 'done via event', Result.Output());
        if Result.GetStepCount() < 2 then
            Error(UnexpectedCountErr, 2, Result.GetStepCount());
    end;

    [Test]
    procedure ToolSet_Use_Twice_Errors()
    var
        ToolSet: Codeunit "AIOS Tool Set";
        Handler: Codeunit "AIOS Sample Tool Handler";
    begin
        ToolSet.Use(Handler);
        asserterror ToolSet.Use(Handler);
    end;

    [Test]
    procedure ToolSet_ClearTools_AllowsReuse()
    var
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Handler: Codeunit "AIOS Sample Tool Handler";
    begin
        ToolSet.Add(Echo);
        if ToolSet.Count() <> 1 then
            Error(UnexpectedCountErr, 1, ToolSet.Count());
        ToolSet.ClearTools();
        if ToolSet.Count() <> 0 then
            Error(UnexpectedCountErr, 0, ToolSet.Count());
        if ToolSet.HasTool(Echo.Name()) then
            Error(ExpectedClearedToolErr);
        ToolSet.Use(Handler);
        if ToolSet.Count() <> 3 then
            Error(UnexpectedCountErr, 3, ToolSet.Count());
        ToolSet.ClearTools();
        ToolSet.Use(Handler);
        if ToolSet.Count() <> 3 then
            Error(UnexpectedCountErr, 3, ToolSet.Count());
    end;

    [Test]
    procedure ToolArgs_RequireText_Missing_ReturnsFalse()
    var
        Args: Codeunit "AIOS Tool Args";
        Arguments: JsonObject;
        Value: Text;
        ErrorText: Text;
    begin
        if Args.RequireText(Arguments, 'message', Value, ErrorText) then
            Error(ExpectedRequireFailErr);
        if ErrorText = '' then
            Error(ExpectedErrorTextErr);
    end;

    [Test]
    procedure ToolArgs_RequireDecimal_AndTryGetInteger()
    var
        Args: Codeunit "AIOS Tool Args";
        Arguments: JsonObject;
        A: Decimal;
        Count: Integer;
        ErrorText: Text;
    begin
        Arguments.Add('a', 2.5);
        Arguments.Add('maxCount', 10);
        if not Args.RequireDecimal(Arguments, 'a', A, ErrorText) then
            Error(UnexpectedRequireFailErr, ErrorText);
        if A <> 2.5 then
            Error(UnexpectedDecimalErr, 2.5, A);
        if not Args.TryGetInteger(Arguments, 'maxCount', Count) then
            Error(ExpectedTryGetErr);
        if Count <> 10 then
            Error(UnexpectedCountErr, 10, Count);
    end;

    [Test]
    procedure ToolSet_MixAddAndUse_DefinitionsAndExecute()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        GetCustomers: Codeunit "AIOS Get Customers Tool";
        Handler: Codeunit "AIOS Sample Tool Handler";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
    begin
        ToolSet.Add(GetCustomers);
        ToolSet.Use(Handler);
        if ToolSet.Count() <> 4 then
            Error(UnexpectedCountErr, 4, ToolSet.Count());
        if not ToolSet.HasTool(GetCustomers.Name()) then
            Error(ExpectedHasToolsErr);
        if not ToolSet.HasTool('add_numbers') then
            Error(ExpectedHasToolsErr);

        Mock.SetNextToolCallThenResponse('call_1', 'to_upper', '{"text":"ab"}', 'AB');
        Request.SetPrompt('upper');
        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet);
        if Result.Output() <> 'AB' then
            Error(UnexpectedTextErr, 'AB', Result.Output());
    end;

    [Test]
    procedure ToolSet_Add_DuplicateName_Errors()
    var
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Tool: Interface "AIOS Tool";
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        asserterror ToolSet.Add(Echo.Name(), Echo.Description(), Echo.InputSchema());
    end;

    [Test]
    procedure GenerateText_NamedTool_WithoutSubscriber_Errors()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Fields: List of [JsonObject];
    begin
        Fields.Add(Schema.Field('x', Schema.String()));
        ToolSet.Add('orphan_tool_no_subscriber', 'Unused', Schema.Object(Fields));
        Mock.SetNextToolCall('orphan_tool_no_subscriber', '{}');
        Request.SetPrompt('x');
        asserterror Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);
    end;

    [Test]
    procedure GenerateText_MultiTool_ToolSetAdd_ExecutesAddNumbers()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
    begin
        AddDemoNamedTools(ToolSet);
        Mock.SetNextToolCallThenResponse('call_1', 'add_numbers', '{"a":2,"b":3}', 'sum is 5');
        Request.SetPrompt('add');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);
        if Result.Output() <> 'sum is 5' then
            Error(UnexpectedTextErr, 'sum is 5', Result.Output());
        if ToolSet.Count() <> 3 then
            Error(UnexpectedCountErr, 3, ToolSet.Count());
    end;

    [Test]
    procedure ManualSecondStep_ExecuteToolAndContinue()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        ToolCalls: List of [Codeunit "AIOS Tool Call"];
        Call: Codeunit "AIOS Tool Call";
        ResultText: Text;
        i: Integer;
    begin
        ToolSet.Add(Echo);

        Mock.SetNextToolCall('call_1', 'echo', '{"message":"hello-tool"}');
        Request.SetPrompt('Use the echo tool with message hello-tool');
        Request.SetTools(ToolSet);
        Request.EnsureMessagesFromPrompt();

        Result := Client.GenerateText(Mock.Model('demo-model'), Request);
        if not Result.HasToolCalls() then
            Error(ExpectedToolCallsErr);

        ToolCalls := Result.GetToolCalls();
        Request.AppendAssistantToolCalls(Result.Output(), ToolCalls);
        for i := 1 to ToolCalls.Count() do begin
            ToolCalls.Get(i, Call);
            if not ToolSet.HasTool(Call.GetName()) then
                Error(UnknownToolErr, Call.GetName());
            if not ToolSet.Execute(Call.GetName(), Call.GetArguments(), ResultText) then
                Error(ToolExecuteFailedErr, Call.GetName(), ResultText);
            Request.AppendToolResult(Call.GetId(), Call.GetName(), ResultText);
        end;

        Mock.SetNextResponse('done after echo');
        Result := Client.GenerateText(Mock.Model('demo-model'), Request);
        if Result.HasToolCalls() then
            Error(UnexpectedToolCallsErr);
        if Result.Output() <> 'done after echo' then
            Error(UnexpectedTextErr, 'done after echo', Result.Output());
        if ResultText <> 'hello-tool' then
            Error(UnexpectedTextErr, 'hello-tool', ResultText);
    end;

    [Test]
    procedure EchoTool_Execute_ReturnsMessage()
    var
        Echo: Codeunit "AIOS Echo Tool";
        Args: JsonObject;
        ResultText: Text;
        Tool: Interface "AIOS Tool";
    begin
        Tool := Echo;
        Args.Add('message', 'abc');
        if not Tool.Execute(Args, ResultText) then
            Error(ToolExecuteFailedErr, Tool.Name(), ResultText);
        if ResultText <> 'abc' then
            Error(UnexpectedTextErr, 'abc', ResultText);
    end;

    [Test]
    procedure OpenAIFormat_MapMessages_IncludesReasoningContentForToolCalls()
    var
        FormatCU: Codeunit "AIOS OpenAI Compatible Format";
        ChatFormat: Interface "AIOS Chat Format";
        Request: Record "AIOS Chat Request";
        ToolCalls: List of [Codeunit "AIOS Tool Call"];
        Call: Codeunit "AIOS Tool Call";
        Args: JsonObject;
        WireMessages: JsonArray;
        MsgToken: JsonToken;
        Msg: JsonObject;
        ReasoningToken: JsonToken;
        ToolCallsToken: JsonToken;
    begin
        ChatFormat := FormatCU;
        Args.Add('q', '1');
        Call.SetCall('call_1', 'echo', Args);
        ToolCalls.Add(Call);
        Request.AppendUserMessage('hi');
        Request.AppendAssistantToolCalls('', ToolCalls, 'think step 1');

        WireMessages := ChatFormat.MapMessages(Request.GetMessages());
        WireMessages.Get(1, MsgToken);
        Msg := MsgToken.AsObject();
        if not Msg.Get('tool_calls', ToolCallsToken) then
            Error(MissingFieldErr, 'tool_calls');
        if not Msg.Get('reasoning_content', ReasoningToken) then
            Error(MissingFieldErr, 'reasoning_content');
        if ReasoningToken.AsValue().AsText() <> 'think step 1' then
            Error(UnexpectedTextErr, 'think step 1', ReasoningToken.AsValue().AsText());
    end;

    [Test]
    procedure GenerateText_MaxSteps_AutoExecutesToolAndReturnsFinalText()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Tool: Interface "AIOS Tool";
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Mock.SetNextToolCallThenResponse('call_1', 'echo', '{"message":"loop"}', 'done after echo');
        Request.SetPrompt('use echo');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);
        if Result.HasToolCalls() then
            Error(UnexpectedToolCallsErr);
        if Result.Output() <> 'done after echo' then
            Error(UnexpectedTextErr, 'done after echo', Result.Output());
        if Result.GetStepCount() < 2 then
            Error(UnexpectedCountErr, 2, Result.GetStepCount());
        if Result.StoppedAtStepLimit() then
            Error(UnexpectedStoppedAtStepLimitErr);
        AssertTotalsMatchCalls(Result);
    end;

    [Test]
    procedure GenerateText_MaxStepsOne_ReturnsToolCallsWithoutExecuting()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Tool: Interface "AIOS Tool";
        Messages: JsonArray;
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Mock.SetNextToolCall('echo', '{"message":"x"}');
        Request.SetPrompt('use echo');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 1);
        if not Result.HasToolCalls() then
            Error(ExpectedToolCallsErr);
        if not Result.StoppedAtStepLimit() then
            Error(ExpectedStoppedAtStepLimitErr);
        Messages := Request.GetMessages();
        if Messages.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Messages.Count());
    end;

    [Test]
    procedure GenerateText_MaxSteps_UnknownTool_Fails()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Tool: Interface "AIOS Tool";
        EmptyOutput: RecordRef;
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Mock.SetNextToolCall('missing_tool', '{}');
        Request.SetPrompt('x');
        Request.SetMaxRetries(0);

        if Client.TryGenerateWithTools(Mock.Model('demo-model'), Request, ToolSet, 5, Response, EmptyOutput) then
            Error(ExpectedFailureErr);
        if Response.GetErrorType() <> "AIOS Error Type"::InvalidRequest then
            Error(UnexpectedErrorTypeErr, Response.GetErrorType());
    end;

    [Test]
    procedure GenerateText_MaxSteps_ToolExecuteFailure_ContinuesWithErrorAsResult()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Tool: Interface "AIOS Tool";
        Messages: JsonArray;
        MsgToken: JsonToken;
        Msg: JsonObject;
        ContentToken: JsonToken;
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Mock.SetNextToolCallThenResponse('call_1', 'echo', '{}', 'after bad args');
        Request.SetPrompt('x');

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);
        if Result.Output() <> 'after bad args' then
            Error(UnexpectedTextErr, 'after bad args', Result.Output());
        Messages := Request.GetMessages();
        Messages.Get(2, MsgToken);
        Msg := MsgToken.AsObject();
        if not Msg.Get('content', ContentToken) then
            Error(MissingFieldErr, 'content');
        if ContentToken.AsValue().AsText() = '' then
            Error(ExpectedToolErrorContentErr);
    end;

    [Test]
    procedure GenerateText_MaxSteps_StructuredOutputValidatedOnFinalStepOnly()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
        Result: Codeunit "AIOS Generate Result";
        Tool: Interface "AIOS Tool";
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Mock.SetNextToolCallThenResponse('call_1', 'echo', '{"message":"x"}', '{"answer":"42"}');
        Fields.Add(Schema.Field('answer', Schema.String()));
        Request.SetPrompt('structured');
        Request.SetOutput(Schema.Object(Fields));

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);
        if Result.Output() <> '{"answer":"42"}' then
            Error(UnexpectedTextErr, '{"answer":"42"}', Result.Output());
    end;

    [Test]
    procedure TryGenerateWithTools_RetriesThenToolThenText()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        ToolSet: Codeunit "AIOS Tool Set";
        Echo: Codeunit "AIOS Echo Tool";
        Request: Record "AIOS Chat Request";
        Result: Codeunit "AIOS Generate Result";
        Tool: Interface "AIOS Tool";
    begin
        Tool := Echo;
        ToolSet.Add(Tool);
        Mock.SetFailuresBeforeSuccess(2);
        Mock.SetNextToolCallThenResponse('call_1', 'echo', '{"message":"retry"}', 'ok');
        Request.SetPrompt('x');
        Request.SetMaxRetries(3);

        Result := Client.GenerateText(Mock.Model('demo-model'), Request, ToolSet, 5);
        if Result.Output() <> 'ok' then
            Error(UnexpectedTextErr, 'ok', Result.Output());
        if Result.GetStepCount() < 3 then
            Error(UnexpectedCountErr, 3, Result.GetStepCount());
        AssertTotalsMatchCalls(Result);
    end;

    local procedure AssertTotalsMatchCalls(Result: Codeunit "AIOS Generate Result")
    var
        Calls: List of [Codeunit "AIOS Chat Response Call"];
        CallCU: Codeunit "AIOS Chat Response Call";
        SumIn: Integer;
        SumOut: Integer;
        i: Integer;
    begin
        Calls := Result.GetResponseCalls();
        for i := 1 to Calls.Count() do begin
            Calls.Get(i, CallCU);
            SumIn += CallCU.GetInputTokens();
            SumOut += CallCU.GetOutputTokens();
        end;
        if Result.GetTotalInputTokens() <> SumIn then
            Error(UnexpectedCountErr, SumIn, Result.GetTotalInputTokens());
        if Result.GetTotalOutputTokens() <> SumOut then
            Error(UnexpectedCountErr, SumOut, Result.GetTotalOutputTokens());
    end;

    /// <summary>
    /// Test helper: registers demo tools only through ToolSet.Add (same as production call sites).
    /// </summary>
    local procedure AddDemoNamedTools(var ToolSet: Codeunit "AIOS Tool Set")
    var
        Schema: Codeunit "AIOS Schema";
        Fields: List of [JsonObject];
    begin
        Clear(Fields);
        Fields.Add(Schema.Field('message', Schema.String()));
        ToolSet.Add('echo', 'Echoes the message argument back unchanged.', Schema.Object(Fields));

        Clear(Fields);
        Fields.Add(Schema.Field('a', Schema.Number()));
        Fields.Add(Schema.Field('b', Schema.Number()));
        ToolSet.Add('add_numbers', 'Adds two numbers (a and b) and returns the sum as text.', Schema.Object(Fields));

        Clear(Fields);
        Fields.Add(Schema.Field('text', Schema.String()));
        ToolSet.Add('to_upper', 'Converts the text argument to uppercase.', Schema.Object(Fields));
    end;

    var
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        MissingFieldErr: Label 'Missing field %1.', Comment = '%1 = field name';
        ExpectedDescriptionErr: Label 'Expected a non-empty tool description.';
        ExpectedParametersObjectErr: Label 'Expected parameters to be a JSON object.';
        ExpectedHasToolsErr: Label 'Expected request to have tools.';
        ExpectedToolCallsErr: Label 'Expected tool calls on the result.';
        UnexpectedToolCallsErr: Label 'Did not expect tool calls on the final result.';
        ExpectedStoppedAtStepLimitErr: Label 'Expected StoppedAtStepLimit when MaxSteps ends on tool calls.';
        UnexpectedStoppedAtStepLimitErr: Label 'Did not expect StoppedAtStepLimit on a completed text result.';
        UnexpectedRoleErr: Label 'Expected role %1.', Comment = '%1 = role';
        UnknownToolErr: Label 'Unknown tool %1.', Comment = '%1 = tool name';
        ToolExecuteFailedErr: Label 'Tool %1 failed: %2', Comment = '%1 = tool name, %2 = result';
        ExpectedFailureErr: Label 'Expected TryGenerateWithTools to fail.';
        UnexpectedErrorTypeErr: Label 'Expected InvalidRequest, got %1.', Comment = '%1 = error type';
        ExpectedToolErrorContentErr: Label 'Expected non-empty tool result after execute failure.';
        ExpectedRequireFailErr: Label 'Expected RequireText to return false for a missing argument.';
        ExpectedErrorTextErr: Label 'Expected a non-empty error text from RequireText.';
        UnexpectedRequireFailErr: Label 'RequireDecimal failed unexpectedly: %1', Comment = '%1 = error text';
        UnexpectedDecimalErr: Label 'Expected decimal %1, got %2.', Comment = '%1 = expected, %2 = actual';
        ExpectedTryGetErr: Label 'Expected TryGetInteger to succeed.';
        ExpectedClearedToolErr: Label 'Expected tool to be removed after ClearTools.';
}

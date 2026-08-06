namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Entry point for language-model generation.
/// </summary>
codeunit 87410 "AIOS Client"
{
    Access = Public;

    /// <summary>
    /// Generates text from a prompt. Returns result with Output and HTTP metadata. Raises an error if generation fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; Prompt: Text): Codeunit "AIOS Generate Result"
    begin
        exit(GenerateText(Model, '', Prompt));
    end;

    /// <summary>
    /// Generates text from a system message and prompt. Returns result with Output and HTTP metadata. Raises an error if generation fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; SystemMessage: Text; Prompt: Text): Codeunit "AIOS Generate Result"
    var
        Response: Record "AIOS Chat Response";
        Result: Codeunit "AIOS Generate Result";
    begin
        if not TryGenerateText(Model, SystemMessage, Prompt, Response) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        Result.SetFromResponse(Response);
        exit(Result);
    end;

    /// <summary>
    /// Generates text using a fully configured request. Returns result with Output and HTTP metadata. Raises an error if generation fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; var Request: Record "AIOS Chat Request"): Codeunit "AIOS Generate Result"
    var
        Response: Record "AIOS Chat Response";
        Result: Codeunit "AIOS Generate Result";
        EmptyOutput: RecordRef;
    begin
        if not TryGenerate(Model, Request, Response, EmptyOutput) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        Result.SetFromResponse(Response);
        exit(Result);
    end;

    /// <summary>
    /// Generates text and binds JSON into OutputRecRef (flat structured output). Returns result with Output and HTTP metadata. Raises an error if generation or binding fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; var Request: Record "AIOS Chat Request"; var OutputRecRef: RecordRef): Codeunit "AIOS Generate Result"
    var
        Response: Record "AIOS Chat Response";
        Result: Codeunit "AIOS Generate Result";
    begin
        if OutputRecRef.Number() = 0 then
            Error(OutputRecordMissingErr);
        if not Request.HasOutput() then
            Request.SetOutput(OutputRecRef);
        if not TryGenerate(Model, Request, Response, OutputRecRef) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        Result.SetFromResponse(Response);
        exit(Result);
    end;

    /// <summary>
    /// Generates images from a prompt. Returns files, usage, and HTTP metadata. Raises an error if generation fails.
    /// </summary>
    procedure GenerateImage(Model: Interface "AIOS Image Model"; Prompt: Text): Codeunit "AIOS Generate Image Result"
    var
        Request: Record "AIOS Image Request";
    begin
        Clear(Request);
        Request.SetPrompt(Prompt);
        exit(GenerateImage(Model, Request));
    end;

    /// <summary>
    /// Generates images using a fully configured request. Raises an error if generation fails.
    /// </summary>
    procedure GenerateImage(Model: Interface "AIOS Image Model"; var Request: Record "AIOS Image Request"): Codeunit "AIOS Generate Image Result"
    var
        Response: Record "AIOS Image Response";
        Result: Codeunit "AIOS Generate Image Result";
    begin
        if not TryGenerateImage(Model, Request, Response) then
            Error(ImageGenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        Result.SetFromAggregate(Response, ResponseCallList, AggregateUsage);
        exit(Result);
    end;

    /// <summary>
    /// Attempts image generation for the full request (including batching). Returns false and fills Response on failure.
    /// </summary>
    internal procedure TryGenerateImage(Model: Interface "AIOS Image Model"; var Request: Record "AIOS Image Request"; var Response: Record "AIOS Image Response"): Boolean
    var
        Aggregate: Record "AIOS Image Response";
        BatchRequest: Record "AIOS Image Request";
        BatchResponse: Record "AIOS Image Response";
        BatchUsage: Codeunit "AIOS Image Usage";
        TotalN: Integer;
        MaxPerCall: Integer;
        CallCount: Integer;
        CallIndex: Integer;
        BatchN: Integer;
        BatchWarnings: JsonArray;
    begin
        Clear(Response);
        Clear(Aggregate);
        Clear(ResponseCallList);
        AggregateUsage.ClearUsage();

        TotalN := Request.GetImageCount();
        MaxPerCall := Request.GetMaxImagesPerCall();
        if MaxPerCall <= 0 then
            MaxPerCall := Model.GetDefaultMaxImagesPerCall();
        if MaxPerCall <= 0 then
            MaxPerCall := 1;

        CallCount := (TotalN + MaxPerCall - 1) div MaxPerCall;

        for CallIndex := 1 to CallCount do begin
            BatchN := GetBatchImageCount(TotalN, MaxPerCall, CallIndex, CallCount);
            BatchRequest.CopyFrom(Request);
            BatchRequest.SetImageCount(BatchN);

            if not TryGenerateImageBatch(Model, BatchRequest, BatchResponse) then begin
                Response := BatchResponse;
                exit(false);
            end;

            Aggregate.MergeGeneratedImagesFrom(BatchResponse);
            BatchWarnings := BatchResponse.GetWarnings();
            Aggregate.AppendWarnings(BatchWarnings);
            Aggregate.MergeProviderMetadataFrom(BatchResponse);
            BatchResponse.GetUsage(BatchUsage);
            AggregateUsage.Add(BatchUsage);
            AppendResponseCall(BatchResponse);
            Aggregate."HTTP Status Code" := BatchResponse."HTTP Status Code";
            Aggregate.SetBody(BatchResponse.GetBody());
            Aggregate.SetHeaders(BatchResponse.GetHeaders());
            Aggregate."Provider Name" := BatchResponse."Provider Name";
        end;

        if Aggregate.GetGeneratedImageCount() = 0 then begin
            Response := Aggregate;
            Response.SetError("AIOS Error Type"::NoImageGenerated, NoImageGeneratedErr);
            exit(false);
        end;

        AggregateUsage.SetImagesGenerated(Aggregate.GetGeneratedImageCount());
        Response := Aggregate;
        Response.ClearError();
        exit(true);
    end;

    local procedure TryGenerateImageBatch(Model: Interface "AIOS Image Model"; var BatchRequest: Record "AIOS Image Request"; var BatchResponse: Record "AIOS Image Response"): Boolean
    var
        Attempt: Integer;
        MaxRetries: Integer;
        DelayMs: Integer;
    begin
        MaxRetries := BatchRequest.GetMaxRetries();
        for Attempt := 0 to MaxRetries do begin
            Clear(BatchResponse);
            if Model.GenerateImage(BatchRequest, BatchResponse) then
                exit(true);

            if (Attempt = MaxRetries) or (not IsRetriableImageError(BatchResponse)) then
                exit(false);

            DelayMs := 200 * (Attempt + 1);
            if DelayMs > 2000 then
                DelayMs := 2000;
            Sleep(DelayMs);
        end;
        exit(false);
    end;

    local procedure GetBatchImageCount(TotalN: Integer; MaxPerCall: Integer; CallIndex: Integer; CallCount: Integer): Integer
    var
        Remainder: Integer;
    begin
        if CallIndex < CallCount then
            exit(MaxPerCall);
        Remainder := TotalN mod MaxPerCall;
        if Remainder = 0 then
            exit(MaxPerCall);
        exit(Remainder);
    end;

    local procedure AppendResponseCall(var BatchResponse: Record "AIOS Image Response")
    var
        CallCU: Codeunit "AIOS Image Response Call";
    begin
        CallCU.SetMetadata(BatchResponse."Call Timestamp", BatchResponse."Model Id", BatchResponse."HTTP Status Code", BatchResponse.GetHeaders());
        ResponseCallList.Add(CallCU);
    end;

    local procedure IsRetriableImageError(var Response: Record "AIOS Image Response"): Boolean
    begin
        case Response.GetErrorType() of
            "AIOS Error Type"::RateLimited,
            "AIOS Error Type"::Timeout,
            "AIOS Error Type"::ProviderUnavailable:
                exit(true);
            else
                exit(false);
        end;
    end;

    /// <summary>
    /// Attempts generation from a prompt. Returns false and fills Response on failure.
    /// </summary>
    internal procedure TryGenerateText(Model: Interface "AIOS Language Model"; Prompt: Text; var Response: Record "AIOS Chat Response"): Boolean
    begin
        exit(TryGenerateText(Model, '', Prompt, Response));
    end;

    /// <summary>
    /// Attempts generation from a system message and prompt. Returns false and fills Response on failure.
    /// </summary>
    internal procedure TryGenerateText(Model: Interface "AIOS Language Model"; SystemMessage: Text; Prompt: Text; var Response: Record "AIOS Chat Response"): Boolean
    begin
        exit(TryGenerateBuiltRequest(Model, SystemMessage, Prompt, Response));
    end;

    /// <summary>
    /// Attempts generation with a fully configured request, including retries for retriable errors.
    /// </summary>
    internal procedure TryGenerate(Model: Interface "AIOS Language Model"; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        EmptyOutput: RecordRef;
    begin
        exit(TryGenerate(Model, Request, Response, EmptyOutput));
    end;

    /// <summary>
    /// Attempts generation and binds JSON into OutputRecRef when structured output is requested.
    /// </summary>
    internal procedure TryGenerate(Model: Interface "AIOS Language Model"; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"; var OutputRecRef: RecordRef): Boolean
    var
        ModelId: Text;
        Attempt: Integer;
        MaxRetries: Integer;
        DelayMs: Integer;
    begin
        Clear(Response);
        ModelId := Model.GetModelId();
        MaxRetries := Request.GetMaxRetries();

        OnBeforeGenerate(ModelId, Request, Response);

        for Attempt := 0 to MaxRetries do begin
            OnBeforeLanguageModelCall(ModelId, Request, Response);

            if Model.Generate(Request, Response) then begin
                OnAfterLanguageModelCall(ModelId, Request, Response);
                if not TryValidateOutputSchema(Request, Response) then
                    exit(false);
                if not TryBindStructuredOutput(Request, Response, OutputRecRef) then
                    exit(false);
                OnAfterGenerate(ModelId, Request, Response);
                exit(true);
            end;

            OnAfterLanguageModelCall(ModelId, Request, Response);

            if (Attempt = MaxRetries) or (not IsRetriableError(Response)) then
                exit(false);

            DelayMs := 200 * (Attempt + 1);
            if DelayMs > 2000 then
                DelayMs := 2000;
            Sleep(DelayMs);
        end;

        exit(false);
    end;

    local procedure TryValidateOutputSchema(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"): Boolean
    var
        Validator: Codeunit "AIOS Schema Validator";
        SchemaCodeunit: Codeunit "AIOS Schema";
        SchemaObj: JsonObject;
        Output: JsonToken;
        BindError: Text;
        SchemaText: Text;
    begin
        if not Request.HasOutputSchema() then
            exit(true);
        SchemaText := Request.GetOutputSchema();
        if not SchemaObj.ReadFrom(SchemaText) then begin
            SetOutputValidationError(Response, InvalidOutputSchemaErr);
            exit(false);
        end;

        if SchemaCodeunit.IsTextSchema(SchemaObj) then
            exit(true);

        if SchemaCodeunit.IsJsonSchema(SchemaObj) then begin
            if not Validator.TryParseJson(Response.GetText(), Output, BindError) then begin
                SetOutputValidationError(Response, BindError);
                exit(false);
            end;
            exit(true);
        end;

        if not Validator.TryValidate(Response.GetText(), SchemaText, Output, BindError) then begin
            SetOutputValidationError(Response, BindError);
            exit(false);
        end;
        // Choice: model returns { "result": "…" }; expose the selected option as plain text.
        if SchemaCodeunit.IsChoiceSchema(SchemaObj) then
            if not TryUnwrapChoiceResult(Output, Response) then begin
                SetOutputValidationError(Response, ChoiceUnwrapFailedErr);
                exit(false);
            end;
        exit(true);
    end;

    local procedure TryUnwrapChoiceResult(Output: JsonToken; var Response: Record "AIOS Chat Response"): Boolean
    var
        Root: JsonObject;
        ResultToken: JsonToken;
    begin
        if not Output.IsObject() then
            exit(false);
        Root := Output.AsObject();
        if not Root.Get('result', ResultToken) then
            exit(false);
        if not ResultToken.IsValue() then
            exit(false);
        Response.SetText(ResultToken.AsValue().AsText());
        exit(true);
    end;

    local procedure TryBindStructuredOutput(var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response"; var OutputRecRef: RecordRef): Boolean
    var
        JsonBinder: Codeunit "AIOS Json Binder";
        BindError: Text;
    begin
        if not Request.HasOutput() then
            exit(true);
        if OutputRecRef.Number() = 0 then begin
            Response.SetError("AIOS Error Type"::InvalidRequest, StructuredNeedsRecRefErr);
            exit(false);
        end;
        if not JsonBinder.TryBind(Response.GetText(), OutputRecRef, BindError) then begin
            SetOutputValidationError(Response, BindError);
            exit(false);
        end;
        exit(true);
    end;

    local procedure SetOutputValidationError(var Response: Record "AIOS Chat Response"; Reason: Text)
    begin
        Response.SetError("AIOS Error Type"::ParseFailed, StrSubstNo(OutputValidationFailedMsg, Reason));
    end;

    local procedure IsRetriableError(var Response: Record "AIOS Chat Response"): Boolean
    begin
        case Response.GetErrorType() of
            "AIOS Error Type"::RateLimited,
            "AIOS Error Type"::Timeout,
            "AIOS Error Type"::ProviderUnavailable:
                exit(true);
            else
                exit(false);
        end;
    end;

    local procedure TryGenerateBuiltRequest(Model: Interface "AIOS Language Model"; SystemMessage: Text; Prompt: Text; var Response: Record "AIOS Chat Response"): Boolean
    var
        Request: Record "AIOS Chat Request";
        EmptyOutput: RecordRef;
    begin
        Clear(Request);
        if SystemMessage <> '' then
            Request.SetSystemMessage(SystemMessage);
        Request.SetPrompt(Prompt);
        exit(TryGenerate(Model, Request, Response, EmptyOutput));
    end;

    /// <summary>
    /// Raised once when generation starts, before any model call.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerate(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
    end;

    /// <summary>
    /// Raised immediately before each language-model call attempt.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLanguageModelCall(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
    end;

    /// <summary>
    /// Raised after each language-model call attempt returns, success or failure.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLanguageModelCall(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
    end;

    /// <summary>
    /// Raised after a successful generation completes.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerate(ModelId: Text; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    begin
    end;

    var
        ResponseCallList: List of [Codeunit "AIOS Image Response Call"];
        AggregateUsage: Codeunit "AIOS Image Usage";
        GenerationFailedErr: Label 'Generation failed (%1): %2', Comment = '%1 = error type, %2 = message';
        ImageGenerationFailedErr: Label 'Image generation failed (%1): %2', Comment = '%1 = error type, %2 = message';
        NoImageGeneratedErr: Label 'The model returned no images.';
        OutputRecordMissingErr: Label 'Structured output requires an open record.';
        StructuredNeedsRecRefErr: Label 'Structured output requires GenerateText(Model, Request, RecRef) so the record can be filled.';
        OutputValidationFailedMsg: Label 'Output validation failed: %1', Comment = '%1 = validation reason';
        ChoiceUnwrapFailedErr: Label 'Choice response missing a string result property.';
        InvalidOutputSchemaErr: Label 'Output schema is not a valid JSON object.';
}

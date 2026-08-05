namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Entry point for language-model generation.
/// </summary>
codeunit 87410 "AIOS Client"
{
    Access = Public;

    /// <summary>
    /// Generates text from a prompt. Raises an error if generation fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; Prompt: Text): Text
    begin
        exit(GenerateText(Model, '', Prompt));
    end;

    /// <summary>
    /// Generates text from a system message and prompt. Raises an error if generation fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; SystemMessage: Text; Prompt: Text): Text
    var
        Response: Record "AIOS Chat Response";
    begin
        if not TryGenerateText(Model, SystemMessage, Prompt, Response) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        exit(Response.GetText());
    end;

    /// <summary>
    /// Generates text using a fully configured request. Raises an error if generation fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; var Request: Record "AIOS Chat Request"): Text
    var
        Response: Record "AIOS Chat Response";
        EmptyOutput: RecordRef;
    begin
        if not TryGenerate(Model, Request, Response, EmptyOutput) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        exit(Response.GetText());
    end;

    /// <summary>
    /// Generates text and binds JSON into OutputRecRef (flat structured output). Raises an error if generation or binding fails.
    /// </summary>
    procedure GenerateText(Model: Interface "AIOS Language Model"; var Request: Record "AIOS Chat Request"; var OutputRecRef: RecordRef): Text
    var
        Response: Record "AIOS Chat Response";
    begin
        if OutputRecRef.Number() = 0 then
            Error(OutputRecordMissingErr);
        if not Request.HasOutput() then
            Request.SetOutput(OutputRecRef);
        if not TryGenerate(Model, Request, Response, OutputRecRef) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        exit(Response.GetText());
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
        Output: JsonToken;
        BindError: Text;
    begin
        if not Request.HasOutputSchema() then
            exit(true);
        if not Validator.TryValidate(Response.GetText(), Request.GetOutputSchema(), Output, BindError) then begin
            Response.SetError("AIOS Error Type"::ParseFailed, BindError);
            exit(false);
        end;
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
            Response.SetError("AIOS Error Type"::ParseFailed, BindError);
            exit(false);
        end;
        exit(true);
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
        GenerationFailedErr: Label 'Generation failed (%1): %2', Comment = '%1 = error type, %2 = message';
        OutputRecordMissingErr: Label 'Structured output requires an open record.';
        StructuredNeedsRecRefErr: Label 'Structured output requires GenerateText(Model, Request, RecRef) so the record can be filled.';
}

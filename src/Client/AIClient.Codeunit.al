codeunit 70110 "AI Client"
{
    Access = Public;

    /// <summary>
    /// Like AI SDK generateText({ model, prompt }) — returns text, Errors on failure.
    /// </summary>
    procedure GenerateText(Model: Interface "AI Language Model"; Prompt: Text): Text
    begin
        exit(GenerateText(Model, '', Prompt));
    end;

    /// <summary>
    /// Like AI SDK generateText({ model, system, prompt }) — returns text, Errors on failure.
    /// </summary>
    procedure GenerateText(Model: Interface "AI Language Model"; SystemMessage: Text; Prompt: Text): Text
    var
        Response: Record "AI Chat Response";
    begin
        if not TryGenerateText(Model, SystemMessage, Prompt, Response) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        exit(Response.GetText());
    end;

    /// <summary>
    /// Like AI SDK generateText with JSON output — returns text, Errors on failure.
    /// </summary>
    procedure GenerateJson(Model: Interface "AI Language Model"; Prompt: Text): Text
    begin
        exit(GenerateJson(Model, '', Prompt));
    end;

    /// <summary>
    /// Like AI SDK generateText with system + JSON output — returns text, Errors on failure.
    /// </summary>
    procedure GenerateJson(Model: Interface "AI Language Model"; SystemMessage: Text; Prompt: Text): Text
    var
        Response: Record "AI Chat Response";
    begin
        if not TryGenerateJson(Model, SystemMessage, Prompt, Response) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        exit(Response.GetText());
    end;

    /// <summary>
    /// Soft-fail variant: fills Response and returns false on failure (no Error).
    /// </summary>
    procedure TryGenerateText(Model: Interface "AI Language Model"; Prompt: Text; var Response: Record "AI Chat Response"): Boolean
    begin
        exit(TryGenerateText(Model, '', Prompt, Response));
    end;

    procedure TryGenerateText(Model: Interface "AI Language Model"; SystemMessage: Text; Prompt: Text; var Response: Record "AI Chat Response"): Boolean
    var
        Request: Record "AI Chat Request";
    begin
        Clear(Request);
        if SystemMessage <> '' then
            Request.SetSystemMessage(SystemMessage);
        Request.SetPrompt(Prompt);
        exit(TryGenerate(Model, Request, Response));
    end;

    procedure TryGenerateJson(Model: Interface "AI Language Model"; Prompt: Text; var Response: Record "AI Chat Response"): Boolean
    begin
        exit(TryGenerateJson(Model, '', Prompt, Response));
    end;

    procedure TryGenerateJson(Model: Interface "AI Language Model"; SystemMessage: Text; Prompt: Text; var Response: Record "AI Chat Response"): Boolean
    var
        Request: Record "AI Chat Request";
    begin
        Clear(Request);
        if SystemMessage <> '' then
            Request.SetSystemMessage(SystemMessage);
        Request.SetPrompt(Prompt);
        Request.SetJsonMode(true);
        exit(TryGenerate(Model, Request, Response));
    end;

    /// <summary>
    /// Escape hatch: full request control. Soft-fail (like model.doGenerate + inspect result).
    /// </summary>
    procedure TryGenerate(Model: Interface "AI Language Model"; var Request: Record "AI Chat Request"; var Response: Record "AI Chat Response"): Boolean
    begin
        exit(Model.Generate(Request, Response));
    end;

    /// <summary>
    /// Escape hatch that Errors on failure (like generateText throwing).
    /// </summary>
    procedure Generate(Model: Interface "AI Language Model"; var Request: Record "AI Chat Request"): Text
    var
        Response: Record "AI Chat Response";
    begin
        if not TryGenerate(Model, Request, Response) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
        exit(Response.GetText());
    end;

    var
        GenerationFailedErr: Label 'Generation failed (%1): %2', Comment = '%1 = error type, %2 = message';
}

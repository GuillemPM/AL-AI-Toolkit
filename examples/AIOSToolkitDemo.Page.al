namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Anthropic;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using PM.Guillem.AIOpenSDK.Provider.OpenAI;
using PM.Guillem.AIOpenSDK.Provider.OpenCodeZen;
using System.Reflection;
using System.Text;
using System.Utilities;

page 87481 "AIOS Toolkit Demo"
{
    ApplicationArea = All;
    Caption = 'AIOS Toolkit Demo';
    PageType = Card;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'AI, LLM, mock, toolkit, openai, anthropic, alaidemo, provider, image, dalle';
    AboutTitle = 'AIOS Toolkit Demo';
    AboutText = 'Pick a provider, model, and API key, then Generate text or Generate image(s). Image generation works with Mock and OpenAI.';

    layout
    {
        area(Content)
        {
            group(ProviderGroup)
            {
                Caption = 'Provider';

                field(SelectedProvider; SelectedProvider)
                {
                    ApplicationArea = All;
                    Caption = 'Provider';
                    OptionCaption = 'Mock,Anthropic,OpenAI,OpenCode Zen';
                    ToolTip = 'Which AI provider to call.';

                    trigger OnValidate()
                    begin
                        ApplyProviderDefaults();
                        SaveSettings();
                    end;
                }
                field(ModelId; ModelId)
                {
                    ApplicationArea = All;
                    Caption = 'Model';
                    ToolTip = 'Language model id for text generation.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(ImageModelId; ImageModelId)
                {
                    ApplicationArea = All;
                    Caption = 'Image model';
                    ToolTip = 'Image model id for Generate image / Generate images. Used by Mock and OpenAI.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(ApiKeyText; ApiKeyText)
                {
                    ApplicationArea = All;
                    Caption = 'API key';
                    ExtendedDatatype = Masked;
                    Editable = ApiKeyEditable;
                    ToolTip = 'Provider API key. Not required for Mock. Stored per user in Isolated Storage.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
            }
            group(PromptGroup)
            {
                Caption = 'Prompt';

                field(SystemPrompt; SystemPrompt)
                {
                    ApplicationArea = All;
                    Caption = 'System';
                    MultiLine = true;
                    ToolTip = 'Optional system message.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UserPrompt; UserPrompt)
                {
                    ApplicationArea = All;
                    Caption = 'Prompt';
                    MultiLine = true;
                    ToolTip = 'User prompt sent to the language or image model.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(ChoiceOptionsText; ChoiceOptionsText)
                {
                    ApplicationArea = All;
                    Caption = 'Choice options';
                    MultiLine = true;
                    ToolTip = 'Comma-separated options for Generate choice. Example: sunny, rainy, snowy';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
            }
            group(OptionsGroup)
            {
                Caption = 'Generate options';

                field(Temperature; Temperature)
                {
                    ApplicationArea = All;
                    Caption = 'Temperature';
                    DecimalPlaces = 0 : 2;
                    ToolTip = 'Sampling temperature. Sent when Send temperature is enabled.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UseTemperature; UseTemperature)
                {
                    ApplicationArea = All;
                    Caption = 'Send temperature';
                    ToolTip = 'When enabled, temperature is included in the provider request.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(TopP; TopP)
                {
                    ApplicationArea = All;
                    Caption = 'Top P';
                    DecimalPlaces = 0 : 4;
                    ToolTip = 'Nucleus sampling. Sent when Send top P is enabled.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UseTopP; UseTopP)
                {
                    ApplicationArea = All;
                    Caption = 'Send top P';
                    ToolTip = 'When enabled, top P is included in the provider request.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(TopK; TopK)
                {
                    ApplicationArea = All;
                    Caption = 'Top K';
                    ToolTip = 'Sample from top K tokens. Mainly Anthropic. Sent when Send top K is enabled.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UseTopK; UseTopK)
                {
                    ApplicationArea = All;
                    Caption = 'Send top K';
                    ToolTip = 'When enabled, top K is included in the provider request.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(PresencePenalty; PresencePenalty)
                {
                    ApplicationArea = All;
                    Caption = 'Presence penalty';
                    DecimalPlaces = 0 : 2;
                    ToolTip = 'Presence penalty. OpenAI-compatible providers.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UsePresencePenalty; UsePresencePenalty)
                {
                    ApplicationArea = All;
                    Caption = 'Send presence penalty';
                    ToolTip = 'When enabled, presence penalty is included in the provider request.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(FrequencyPenalty; FrequencyPenalty)
                {
                    ApplicationArea = All;
                    Caption = 'Frequency penalty';
                    DecimalPlaces = 0 : 2;
                    ToolTip = 'Frequency penalty. OpenAI-compatible providers.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UseFrequencyPenalty; UseFrequencyPenalty)
                {
                    ApplicationArea = All;
                    Caption = 'Send frequency penalty';
                    ToolTip = 'When enabled, frequency penalty is included in the provider request.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(Seed; Seed)
                {
                    ApplicationArea = All;
                    Caption = 'Seed';
                    ToolTip = 'Seed for deterministic sampling when the provider supports it.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UseSeed; UseSeed)
                {
                    ApplicationArea = All;
                    Caption = 'Send seed';
                    ToolTip = 'When enabled, seed is included in the provider request.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(StopSequencesText; StopSequencesText)
                {
                    ApplicationArea = All;
                    Caption = 'Stop sequences';
                    MultiLine = true;
                    ToolTip = 'One stop sequence per line.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(Reasoning; Reasoning)
                {
                    ApplicationArea = All;
                    Caption = 'Reasoning';
                    ToolTip = 'Reasoning effort. ProviderDefault omits the option.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(MaxTokens; MaxTokens)
                {
                    ApplicationArea = All;
                    Caption = 'Max tokens';
                    ToolTip = 'Maximum tokens to generate. 0 omits the limit where the provider allows it.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(TimeoutMs; TimeoutMs)
                {
                    ApplicationArea = All;
                    Caption = 'Timeout (ms)';
                    ToolTip = 'HTTP timeout in milliseconds. 0 means the default (120000).';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(MaxRetries; MaxRetries)
                {
                    ApplicationArea = All;
                    Caption = 'Max retries';
                    ToolTip = 'Max retries. 0 disables retries. Default when Send max retries is off is still client default (2) unless you enable and set a value.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
                field(UseMaxRetries; UseMaxRetries)
                {
                    ApplicationArea = All;
                    Caption = 'Send max retries';
                    ToolTip = 'When enabled, Max retries is applied on the request (including 0 to disable).';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
            }
            group(ImageGroup)
            {
                Caption = 'Image generation';

                field(ImageCount; ImageCount)
                {
                    ApplicationArea = All;
                    Caption = 'Image count';
                    MinValue = 1;
                    MaxValue = 10;
                    ToolTip = 'How many images Generate images requests. Generate image always requests 1.';

                    trigger OnValidate()
                    begin
                        if ImageCount < 1 then
                            ImageCount := 1;
                        SaveSettings();
                    end;
                }
                field(ImageSize; ImageSize)
                {
                    ApplicationArea = All;
                    Caption = 'Size';
                    ToolTip = 'Optional provider size string (for example 1024x1024). Leave blank to omit.';

                    trigger OnValidate()
                    begin
                        SaveSettings();
                    end;
                }
            }
            group(ResultGroup)
            {
                Caption = 'Result';

                field(LastResult; LastResult)
                {
                    ApplicationArea = All;
                    Caption = 'Output';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Last generation result or error details.';
                }
                field(LastHttpStatus; LastHttpStatus)
                {
                    ApplicationArea = All;
                    Caption = 'HTTP status';
                    Editable = false;
                    ToolTip = 'HTTP status code from the provider response.';
                }
                field(LastResponseBody; LastResponseBody)
                {
                    ApplicationArea = All;
                    Caption = 'Response body';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Raw HTTP response body from the provider.';
                }
                field(LastResponseHeaders; LastResponseHeaders)
                {
                    ApplicationArea = All;
                    Caption = 'Response headers';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'HTTP response headers from the provider as JSON.';
                }
            }
            part(HistoryPart; "AIOS Demo History")
            {
                ApplicationArea = All;
                Caption = 'Request history';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Generate)
            {
                ApplicationArea = All;
                Caption = 'Generate';
                Image = Process;
                ToolTip = 'Call AI Client with the selected provider and model.';

                trigger OnAction()
                begin
                    RunGenerate(false);
                end;
            }
            action(TryGenerate)
            {
                ApplicationArea = All;
                Caption = 'Try generate';
                Image = TestFile;
                ToolTip = 'Soft-fail generate — shows error type instead of throwing.';

                trigger OnAction()
                begin
                    RunGenerate(true);
                end;
            }
            action(GenerateStructured)
            {
                ApplicationArea = All;
                Caption = 'Generate structured';
                Image = ExportFile;
                ToolTip = 'GenerateText with Request.SetOutput(JSON Schema). Response is validated and shown as JSON.';

                trigger OnAction()
                begin
                    RunGenerateStructured();
                end;
            }
            action(GenerateJson)
            {
                ApplicationArea = All;
                Caption = 'Generate JSON';
                Image = ExportFile;
                ToolTip = 'GenerateText with Request.SetOutput(Schema.Json). Response must be valid JSON; shape is not checked.';

                trigger OnAction()
                begin
                    RunGenerateJson();
                end;
            }
            action(GenerateChoice)
            {
                ApplicationArea = All;
                Caption = 'Generate choice';
                Image = SelectLine;
                ToolTip = 'GenerateText with Request.SetOutput(Schema.Choice). Result is one plain option string from Choice options.';

                trigger OnAction()
                begin
                    RunGenerateChoice();
                end;
            }
            action(GenerateImage)
            {
                ApplicationArea = All;
                Caption = 'Generate image';
                Image = Camera;
                ToolTip = 'Generate one image with AIOS Client.GenerateImage and store it on the history row. OpenAI or Mock.';

                trigger OnAction()
                begin
                    RunGenerateImages(1);
                end;
            }
            action(GenerateImages)
            {
                ApplicationArea = All;
                Caption = 'Generate images';
                Image = Picture;
                ToolTip = 'Generate Image count images and store them on the history row. OpenAI or Mock.';

                trigger OnAction()
                begin
                    RunGenerateImages(ImageCount);
                end;
            }
            action(ResetSettings)
            {
                ApplicationArea = All;
                Caption = 'Reset settings';
                Image = Restore;
                ToolTip = 'Clear saved settings and restore demo defaults.';

                trigger OnAction()
                begin
                    ClearSavedSettings();
                    ApplyFirstOpenDefaults();
                    CurrPage.Update(false);
                end;
            }
            action(ReuseSelected)
            {
                ApplicationArea = All;
                Caption = 'Reuse selected';
                Image = Restore;
                ToolTip = 'Load the selected history line back into the form.';

                trigger OnAction()
                begin
                    ReuseSelectedHistory();
                end;
            }
            action(ClearHistory)
            {
                ApplicationArea = All;
                Caption = 'Clear history';
                Image = Delete;
                ToolTip = 'Delete all demo history lines for the current user.';

                trigger OnAction()
                begin
                    ClearUserHistory();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Generate_Promoted; Generate) { }
            actionref(TryGenerate_Promoted; TryGenerate) { }
            actionref(GenerateStructured_Promoted; GenerateStructured) { }
            actionref(GenerateJson_Promoted; GenerateJson) { }
            actionref(GenerateChoice_Promoted; GenerateChoice) { }
            actionref(GenerateImage_Promoted; GenerateImage) { }
            actionref(GenerateImages_Promoted; GenerateImages) { }
            actionref(ReuseSelected_Promoted; ReuseSelected) { }
            actionref(ClearHistory_Promoted; ClearHistory) { }
            actionref(ResetSettings_Promoted; ResetSettings) { }
        }
    }

    trigger OnOpenPage()
    begin
        if not LoadSettings() then
            ApplyFirstOpenDefaults();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        SaveSettings();
        exit(true);
    end;

    local procedure ApplyFirstOpenDefaults()
    begin
        SelectedProvider := SelectedProvider::Mock;
        ApplyProviderDefaults();
        SystemPrompt := 'You extract sentiment and topics from customer feedback.';
        UserPrompt := 'Feedback: Great product, but support felt pricey.';
        ChoiceOptionsText := 'sunny, rainy, snowy';
        ImageCount := 3;
        ImageSize := '1024x1024';
        Temperature := 0.2;
        UseTemperature := true;
        TopP := 0;
        UseTopP := false;
        TopK := 0;
        UseTopK := false;
        PresencePenalty := 0;
        UsePresencePenalty := false;
        FrequencyPenalty := 0;
        UseFrequencyPenalty := false;
        Seed := 0;
        UseSeed := false;
        StopSequencesText := '';
        Reasoning := Reasoning::ProviderDefault;
        MaxTokens := 1024;
        TimeoutMs := 120000;
        MaxRetries := 2;
        UseMaxRetries := true;
        SaveSettings();
    end;

    local procedure ApplyProviderDefaults()
    begin
        case SelectedProvider of
            SelectedProvider::Mock:
                begin
                    ModelId := 'demo-model';
                    ImageModelId := 'mock-image';
                    ApiKeyEditable := false;
                    ApiKeyText := '';
                end;
            SelectedProvider::Anthropic:
                begin
                    ModelId := 'claude-sonnet-4-5';
                    ImageModelId := '';
                    ApiKeyEditable := true;
                end;
            SelectedProvider::OpenAI:
                begin
                    ModelId := 'gpt-4.1-mini';
                    ImageModelId := 'dall-e-3';
                    ApiKeyEditable := true;
                end;
            SelectedProvider::"OpenCode Zen":
                begin
                    ModelId := 'big-pickle';
                    ImageModelId := '';
                    ApiKeyEditable := true;
                end;
        end;
    end;

    local procedure RunGenerate(SoftFail: Boolean)
    var
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Model: Interface "AIOS Language Model";
        Ok: Boolean;
    begin
        if ModelId = '' then
            Error(ModelRequiredErr);
        if (SelectedProvider <> SelectedProvider::Mock) and (ApiKeyText = '') then
            Error(ApiKeyRequiredErr);

        SaveSettings();
        Model := BindSelectedModel();
        BuildRequest(Request);

        Ok := Client.TryGenerate(Model, Request, Response);
        ApplyResponseToPage(Ok, Response);

        LogHistory(SoftFail, Ok, Request, Response);
        CurrPage.HistoryPart.Page.Reload();
        CurrPage.Update(false);

        if (not SoftFail) and (not Ok) then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
    end;

    local procedure RunGenerateStructured()
    var
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Fields: List of [JsonObject];
        Model: Interface "AIOS Language Model";
        Ok: Boolean;
    begin
        if ModelId = '' then
            Error(ModelRequiredErr);
        if (SelectedProvider <> SelectedProvider::Mock) and (ApiKeyText = '') then
            Error(ApiKeyRequiredErr);
        if UserPrompt = '' then
            Error(PromptRequiredErr);

        SaveSettings();
        Model := BindSelectedModel();
        if SelectedProvider = SelectedProvider::Mock then
            MockProvider.SetNextResponse(MockStructuredJsonTok);

        Fields.Add(Schema.Field('Sentiment', Schema.String()));
        Fields.Add(Schema.Field('Score', Schema.Number()));
        Fields.Add(Schema.Field('Urgent', Schema.Boolean()));
        Fields.Add(Schema.Field('Summary', Schema.String()));
        Fields.Add(Schema.Field('Topics', Schema.Array(Schema.String())));

        BuildRequest(Request);
        Request.SetOutput(Schema.Object(Fields));

        Ok := Client.TryGenerate(Model, Request, Response);
        ApplyResponseToPage(Ok, Response);

        LogHistory(false, Ok, Request, Response);
        CurrPage.HistoryPart.Page.Reload();
        CurrPage.Update(false);

        if not Ok then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
    end;

    local procedure RunGenerateJson()
    var
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Model: Interface "AIOS Language Model";
        Ok: Boolean;
    begin
        if ModelId = '' then
            Error(ModelRequiredErr);
        if (SelectedProvider <> SelectedProvider::Mock) and (ApiKeyText = '') then
            Error(ApiKeyRequiredErr);
        if UserPrompt = '' then
            Error(JsonPromptRequiredErr);

        SaveSettings();
        Model := BindSelectedModel();
        if SelectedProvider = SelectedProvider::Mock then
            MockProvider.SetNextResponse(MockJsonTok);

        BuildRequest(Request);
        Request.SetOutput(Schema.Json());

        Ok := Client.TryGenerate(Model, Request, Response);
        ApplyResponseToPage(Ok, Response);

        LogHistory(false, Ok, Request, Response);
        CurrPage.HistoryPart.Page.Reload();
        CurrPage.Update(false);

        if not Ok then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
    end;

    local procedure RunGenerateChoice()
    var
        Client: Codeunit "AIOS Client";
        Schema: Codeunit "AIOS Schema";
        Request: Record "AIOS Chat Request";
        Response: Record "AIOS Chat Response";
        Options: List of [Text];
        Model: Interface "AIOS Language Model";
        FirstOption: Text;
        Ok: Boolean;
    begin
        if ModelId = '' then
            Error(ModelRequiredErr);
        if (SelectedProvider <> SelectedProvider::Mock) and (ApiKeyText = '') then
            Error(ApiKeyRequiredErr);
        if UserPrompt = '' then
            Error(ChoicePromptRequiredErr);

        ParseChoiceOptions(ChoiceOptionsText, Options);
        if Options.Count() = 0 then
            Error(ChoiceOptionsRequiredErr);

        SaveSettings();
        Model := BindSelectedModel();
        if SelectedProvider = SelectedProvider::Mock then begin
            Options.Get(1, FirstOption);
            MockProvider.SetNextResponse(StrSubstNo('{"result":"%1"}', FirstOption));
        end;

        BuildRequest(Request);
        Request.SetOutput(Schema.Choice(Options));

        Ok := Client.TryGenerate(Model, Request, Response);
        ApplyResponseToPage(Ok, Response);

        LogHistory(false, Ok, Request, Response);
        CurrPage.HistoryPart.Page.Reload();
        CurrPage.Update(false);

        if not Ok then
            Error(GenerationFailedErr, Response.GetErrorType(), Response."Error Message");
    end;

    local procedure RunGenerateImages(RequestedCount: Integer)
    var
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Image Request";
        Result: Codeunit "AIOS Generate Image Result";
        Usage: Codeunit "AIOS Image Usage";
        ImageModel: Interface "AIOS Image Model";
        Headers: JsonObject;
        CountToRequest: Integer;
    begin
        if ImageModelId = '' then
            Error(ImageModelRequiredErr);
        if (SelectedProvider <> SelectedProvider::Mock) and (ApiKeyText = '') then
            Error(ApiKeyRequiredErr);
        if UserPrompt = '' then
            Error(ImagePromptRequiredErr);
        if not (SelectedProvider in [SelectedProvider::Mock, SelectedProvider::OpenAI]) then
            Error(ImageProviderUnsupportedErr, Format(SelectedProvider));

        CountToRequest := RequestedCount;
        if CountToRequest < 1 then
            CountToRequest := 1;

        SaveSettings();
        ImageModel := BindSelectedImageModel();

        Clear(Request);
        Request.SetPrompt(UserPrompt);
        Request.SetImageCount(CountToRequest);
        if ImageSize <> '' then
            Request.SetSize(ImageSize);
        if TimeoutMs > 0 then
            Request.SetTimeout(TimeoutMs);
        if UseMaxRetries then
            Request.SetMaxRetries(MaxRetries);

        Result := Client.GenerateImage(ImageModel, Request);
        Usage := Result.GetUsage();

        LastResult := StrSubstNo(ImageResultMsg, Result.GetImages().Count(), Usage.ImagesGenerated(), Result.HttpStatusCode());
        LastHttpStatus := Result.HttpStatusCode();
        LastResponseBody := Result.Body();
        Clear(LastResponseHeaders);
        Headers := Result.Headers();
        if Headers.Keys().Count() > 0 then
            Headers.WriteTo(LastResponseHeaders);

        LogImageHistory(true, UserPrompt, CountToRequest, Usage, Result);
        CurrPage.HistoryPart.Page.Reload();
        CurrPage.Update(false);
    end;

    local procedure BindSelectedImageModel(): Interface "AIOS Image Model"
    var
        OpenAI: Codeunit "AIOS OpenAI";
        ApiKey: SecretText;
    begin
        ApiKey := ApiKeyText;

        case SelectedProvider of
            SelectedProvider::Mock:
                exit(MockProvider.ImageModel(ImageModelId));
            SelectedProvider::OpenAI:
                exit(OpenAI.ImageModel(ImageModelId, ApiKey));
            else
                Error(ImageProviderUnsupportedErr, Format(SelectedProvider));
        end;
    end;

    local procedure LogImageHistory(Ok: Boolean; PromptText: Text; RequestedCount: Integer; Usage: Codeunit "AIOS Image Usage"; Result: Codeunit "AIOS Generate Image Result")
    var
        History: Record "AIOS Demo History";
        ImageCU: Codeunit "AIOS Generated Image";
        Images: List of [Codeunit "AIOS Generated Image"];
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        MimeType: Text;
        FileName: Text;
        Base64: Text;
        BodyText: Text;
        i: Integer;
    begin
        History.Init();
        History."Created At" := CurrentDateTime();
        History."User ID" := CopyStr(UserId(), 1, MaxStrLen(History."User ID"));
        History.Provider := Format(SelectedProvider);
        History.Model := ImageModelId;
        History.SetFormSystemMessage('');
        History.SetSystemMessage(StrSubstNo(ImageHistorySystemTok, RequestedCount, ImageSize));
        History.SetPrompt(PromptText);
        History.SetResult(LastResult);
        BodyText := Result.Body();
        if BodyText = '' then
            BodyText := LastResponseBody;
        History.SetResponseBody(BodyText);
        History.SetResponseHeaders(LastResponseHeaders);
        History."HTTP Status Code" := LastHttpStatus;
        History."Timeout Ms" := TimeoutMs;
        History."Max Retries" := MaxRetries;
        History."Has Max Retries" := UseMaxRetries;
        History.Success := Ok;
        History."Soft Fail" := false;
        History."Input Tokens" := Usage.InputTokens();
        History."Output Tokens" := Usage.OutputTokens();
        History.Insert(true);

        // Prefer provider JSON body (data[].b64_json) — avoids large-base64 JSON roundtrip truncation.
        if not History.ImportPicturesFromImageJson(BodyText) then begin
            Images := Result.GetImages();
            for i := 1 to Images.Count() do begin
                Images.Get(i, ImageCU);
                Base64 := ImageCU.Base64();
                if Base64 = '' then
                    Error(MissingGeneratedBase64Err, i);

                MimeType := ImageCU.MediaType();
                if MimeType = '' then
                    MimeType := 'image/png';
                FileName := StrSubstNo(ImageFileNameTok, i);

                Clear(TempBlob);
                TempBlob.CreateOutStream(OutStream);
                Base64Convert.FromBase64(Base64, OutStream);
                TempBlob.CreateInStream(InStream);
                History.Pictures.ImportStream(InStream, FileName, MimeType);
            end;
            if (Images.Count() > 0) and (History.Pictures.Count() = 0) then
                Error(ImportGeneratedMediaErr, Images.Count());
        end;
        History.Modify(true);
        Commit();
    end;

    local procedure ApplyResponseToPage(Ok: Boolean; var Response: Record "AIOS Chat Response")
    var
        Headers: JsonObject;
    begin
        if Ok then
            LastResult := Response.GetText()
        else
            LastResult := FormatFailedResult(Response);

        LastHttpStatus := Response."HTTP Status Code";
        LastResponseBody := Response.GetBody();
        Headers := Response.GetHeaders();
        Clear(LastResponseHeaders);
        if Headers.Keys().Count() > 0 then
            Headers.WriteTo(LastResponseHeaders);
    end;

    local procedure FormatFailedResult(var Response: Record "AIOS Chat Response"): Text
    var
        ModelText: Text;
        ErrMsg: Text;
    begin
        ErrMsg := Response."Error Message";
        ModelText := Response.GetText();
        if (ModelText = '') or (StrPos(ErrMsg, ModelText) > 0) then
            exit(StrSubstNo(ErrorResultMsg, Response.GetErrorType(), ErrMsg));
        exit(StrSubstNo(ErrorResultWithTextMsg, Response.GetErrorType(), ErrMsg, ModelText));
    end;

    local procedure ParseChoiceOptions(OptionsText: Text; var Options: List of [Text])
    var
        Remaining: Text;
        Piece: Text;
        CommaPos: Integer;
    begin
        Clear(Options);
        Remaining := DelChr(OptionsText, '<>', ' ');
        while Remaining <> '' do begin
            CommaPos := StrPos(Remaining, ',');
            if CommaPos = 0 then begin
                Piece := DelChr(Remaining, '<>', ' ');
                Remaining := '';
            end else begin
                Piece := DelChr(CopyStr(Remaining, 1, CommaPos - 1), '<>', ' ');
                Remaining := DelChr(CopyStr(Remaining, CommaPos + 1), '<>', ' ');
            end;
            if Piece <> '' then
                Options.Add(Piece);
        end;
    end;

    local procedure LogHistory(SoftFail: Boolean; Ok: Boolean; var Request: Record "AIOS Chat Request"; var Response: Record "AIOS Chat Response")
    var
        History: Record "AIOS Demo History";
    begin
        History.Init();
        History."Created At" := CurrentDateTime();
        History."User ID" := CopyStr(UserId(), 1, MaxStrLen(History."User ID"));
        History.Provider := Format(SelectedProvider);
        History.Model := ModelId;
        History.SetFormSystemMessage(SystemPrompt);
        History.SetSystemMessage(Request.GetEffectiveSystemMessage());
        History.SetPrompt(Request.GetPrompt());
        History.SetResult(LastResult);
        History.SetResponseBody(LastResponseBody);
        History.SetResponseHeaders(LastResponseHeaders);
        History."HTTP Status Code" := LastHttpStatus;
        History."JSON Mode" := Request."Json Mode";
        History.Temperature := Temperature;
        History."Has Temperature" := UseTemperature;
        History."Top P" := TopP;
        History."Has Top P" := UseTopP;
        History."Top K" := TopK;
        History."Has Top K" := UseTopK;
        History."Presence Penalty" := PresencePenalty;
        History."Has Presence Penalty" := UsePresencePenalty;
        History."Frequency Penalty" := FrequencyPenalty;
        History."Has Frequency Penalty" := UseFrequencyPenalty;
        History.Seed := Seed;
        History."Has Seed" := UseSeed;
        History."Stop Sequences" := CopyStr(StopSequencesText, 1, MaxStrLen(History."Stop Sequences"));
        History.Reasoning := Reasoning;
        History."Max Tokens" := MaxTokens;
        History."Timeout Ms" := TimeoutMs;
        History."Max Retries" := MaxRetries;
        History."Has Max Retries" := UseMaxRetries;
        History.Success := Ok;
        History."Soft Fail" := SoftFail;
        if not Ok then begin
            History."Error Type" := Response.GetErrorType();
            History."Error Message" := Response."Error Message";
        end;
        History."Input Tokens" := Response."Input Tokens";
        History."Output Tokens" := Response."Output Tokens";
        History.Insert(true);
        Commit();
    end;

    local procedure ReuseSelectedHistory()
    var
        History: Record "AIOS Demo History";
        ProviderName: Text;
    begin
        CurrPage.HistoryPart.Page.GetCurrent(History);
        if History."Entry No." = 0 then
            Error(NoHistorySelectedErr);

        ProviderName := History.Provider;
        case ProviderName of
            Format(SelectedProvider::Mock):
                SelectedProvider := SelectedProvider::Mock;
            Format(SelectedProvider::Anthropic):
                SelectedProvider := SelectedProvider::Anthropic;
            Format(SelectedProvider::OpenAI):
                SelectedProvider := SelectedProvider::OpenAI;
            Format(SelectedProvider::"OpenCode Zen"):
                SelectedProvider := SelectedProvider::"OpenCode Zen";
            else
                Error(UnknownProviderErr, ProviderName);
        end;

        ApiKeyEditable := SelectedProvider <> SelectedProvider::Mock;
        ModelId := History.Model;
        if History.GetFormSystemMessage() <> '' then
            SystemPrompt := History.GetFormSystemMessage()
        else
            SystemPrompt := History.GetSystemMessage();
        UserPrompt := History.GetPrompt();
        Temperature := History.Temperature;
        UseTemperature := History."Has Temperature";
        TopP := History."Top P";
        UseTopP := History."Has Top P";
        TopK := History."Top K";
        UseTopK := History."Has Top K";
        PresencePenalty := History."Presence Penalty";
        UsePresencePenalty := History."Has Presence Penalty";
        FrequencyPenalty := History."Frequency Penalty";
        UseFrequencyPenalty := History."Has Frequency Penalty";
        Seed := History.Seed;
        UseSeed := History."Has Seed";
        StopSequencesText := History."Stop Sequences";
        Reasoning := History.Reasoning;
        MaxTokens := History."Max Tokens";
        TimeoutMs := History."Timeout Ms";
        MaxRetries := History."Max Retries";
        UseMaxRetries := History."Has Max Retries";
        LastResult := History.GetResult();
        LastResponseBody := History.GetResponseBody();
        LastResponseHeaders := History.GetResponseHeaders();
        LastHttpStatus := History."HTTP Status Code";
        SaveSettings();
        CurrPage.Update(false);
    end;

    local procedure ClearUserHistory()
    var
        History: Record "AIOS Demo History";
    begin
        if not Confirm(ClearHistoryQst) then
            exit;
        History.SetRange("User ID", CopyStr(UserId(), 1, MaxStrLen(History."User ID")));
        History.DeleteAll(true);
        CurrPage.HistoryPart.Page.Reload();
        CurrPage.Update(false);
    end;

    local procedure BuildRequest(var Request: Record "AIOS Chat Request")
    begin
        Clear(Request);
        if SystemPrompt <> '' then
            Request.SetSystemMessage(SystemPrompt);
        Request.SetPrompt(UserPrompt);
        if UseTemperature then
            Request.SetTemperature(Temperature);
        if UseTopP then
            Request.SetTopP(TopP);
        if UseTopK then
            Request.SetTopK(TopK);
        if UsePresencePenalty then
            Request.SetPresencePenalty(PresencePenalty);
        if UseFrequencyPenalty then
            Request.SetFrequencyPenalty(FrequencyPenalty);
        if UseSeed then
            Request.SetSeed(Seed);
        ApplyStopSequences(Request);
        Request.SetReasoning(Reasoning);
        if MaxTokens > 0 then
            Request.SetMaxTokens(MaxTokens);
        if TimeoutMs > 0 then
            Request.SetTimeout(TimeoutMs);
        if UseMaxRetries then
            Request.SetMaxRetries(MaxRetries);
    end;

    local procedure ApplyStopSequences(var Request: Record "AIOS Chat Request")
    var
        TypeHelper: Codeunit "Type Helper";
        Lines: List of [Text];
        Line: Text;
        Normalized: Text;
        CR: Char;
    begin
        if StopSequencesText = '' then
            exit;
        CR := 13;
        Normalized := DelChr(StopSequencesText, '=', Format(CR));
        Lines := Normalized.Split(TypeHelper.LFSeparator());
        foreach Line in Lines do begin
            Line := Line.Trim();
            if Line <> '' then
                Request.AddStopSequence(Line);
        end;
    end;

    local procedure BindSelectedModel(): Interface "AIOS Language Model"
    var
        Anthropic: Codeunit "AIOS Anthropic";
        OpenAI: Codeunit "AIOS OpenAI";
        Zen: Codeunit "AIOS OpenCode Zen";
        ApiKey: SecretText;
    begin
        ApiKey := ApiKeyText;

        case SelectedProvider of
            SelectedProvider::Mock:
                begin
                    MockProvider.SetNextResponse('Mock response: Great product, support felt pricey.');
                    exit(MockProvider.Model(ModelId));
                end;
            SelectedProvider::Anthropic:
                exit(Anthropic.Model(ModelId, ApiKey));
            SelectedProvider::OpenAI:
                exit(OpenAI.Model(ModelId, ApiKey));
            SelectedProvider::"OpenCode Zen":
                exit(Zen.Model(ModelId, ApiKey));
        end;
    end;

    local procedure SaveSettings()
    var
        Settings: JsonObject;
        SettingsText: Text;
    begin
        Clear(Settings);
        Settings.Add('provider', SelectedProvider);
        Settings.Add('model', ModelId);
        Settings.Add('imageModel', ImageModelId);
        Settings.Add('system', SystemPrompt);
        Settings.Add('prompt', UserPrompt);
        Settings.Add('choiceOptions', ChoiceOptionsText);
        Settings.Add('imageCount', ImageCount);
        Settings.Add('imageSize', ImageSize);
        Settings.Add('temperature', Temperature);
        Settings.Add('useTemperature', UseTemperature);
        Settings.Add('topP', TopP);
        Settings.Add('useTopP', UseTopP);
        Settings.Add('topK', TopK);
        Settings.Add('useTopK', UseTopK);
        Settings.Add('presencePenalty', PresencePenalty);
        Settings.Add('usePresencePenalty', UsePresencePenalty);
        Settings.Add('frequencyPenalty', FrequencyPenalty);
        Settings.Add('useFrequencyPenalty', UseFrequencyPenalty);
        Settings.Add('seed', Seed);
        Settings.Add('useSeed', UseSeed);
        Settings.Add('stopSequences', StopSequencesText);
        Settings.Add('reasoning', Reasoning.AsInteger());
        Settings.Add('maxTokens', MaxTokens);
        Settings.Add('timeoutMs', TimeoutMs);
        Settings.Add('maxRetries', MaxRetries);
        Settings.Add('useMaxRetries', UseMaxRetries);
        Settings.WriteTo(SettingsText);
        IsolatedStorage.Set(SettingsKeyTok, SettingsText, DataScope::User);

        if ApiKeyText = '' then begin
            if IsolatedStorage.Contains(ApiKeyKeyTok, DataScope::User) then
                IsolatedStorage.Delete(ApiKeyKeyTok, DataScope::User);
        end else
            IsolatedStorage.Set(ApiKeyKeyTok, ApiKeyText, DataScope::User);
    end;

    local procedure LoadSettings(): Boolean
    var
        Settings: JsonObject;
        SettingsToken: JsonToken;
        SettingsText: Text;
        ProviderValue: Integer;
    begin
        if not IsolatedStorage.Contains(SettingsKeyTok, DataScope::User) then
            exit(false);
        if not IsolatedStorage.Get(SettingsKeyTok, DataScope::User, SettingsText) then
            exit(false);
        if not Settings.ReadFrom(SettingsText) then
            exit(false);

        if Settings.Get('provider', SettingsToken) then begin
            ProviderValue := SettingsToken.AsValue().AsInteger();
            SelectedProvider := ProviderValue;
        end;
        if Settings.Get('model', SettingsToken) then
            ModelId := CopyStr(SettingsToken.AsValue().AsText(), 1, MaxStrLen(ModelId));
        if Settings.Get('imageModel', SettingsToken) then
            ImageModelId := CopyStr(SettingsToken.AsValue().AsText(), 1, MaxStrLen(ImageModelId));
        if Settings.Get('system', SettingsToken) then
            SystemPrompt := SettingsToken.AsValue().AsText();
        if Settings.Get('prompt', SettingsToken) then
            UserPrompt := SettingsToken.AsValue().AsText();
        if Settings.Get('choiceOptions', SettingsToken) then
            ChoiceOptionsText := SettingsToken.AsValue().AsText();
        if ChoiceOptionsText = '' then
            ChoiceOptionsText := 'sunny, rainy, snowy';
        if Settings.Get('imageCount', SettingsToken) then
            ImageCount := SettingsToken.AsValue().AsInteger();
        if ImageCount < 1 then
            ImageCount := 3;
        if Settings.Get('imageSize', SettingsToken) then
            ImageSize := CopyStr(SettingsToken.AsValue().AsText(), 1, MaxStrLen(ImageSize));
        if Settings.Get('temperature', SettingsToken) then
            Temperature := SettingsToken.AsValue().AsDecimal();
        if Settings.Get('useTemperature', SettingsToken) then
            UseTemperature := SettingsToken.AsValue().AsBoolean();
        if Settings.Get('topP', SettingsToken) then
            TopP := SettingsToken.AsValue().AsDecimal();
        if Settings.Get('useTopP', SettingsToken) then
            UseTopP := SettingsToken.AsValue().AsBoolean();
        if Settings.Get('topK', SettingsToken) then
            TopK := SettingsToken.AsValue().AsInteger();
        if Settings.Get('useTopK', SettingsToken) then
            UseTopK := SettingsToken.AsValue().AsBoolean();
        if Settings.Get('presencePenalty', SettingsToken) then
            PresencePenalty := SettingsToken.AsValue().AsDecimal();
        if Settings.Get('usePresencePenalty', SettingsToken) then
            UsePresencePenalty := SettingsToken.AsValue().AsBoolean();
        if Settings.Get('frequencyPenalty', SettingsToken) then
            FrequencyPenalty := SettingsToken.AsValue().AsDecimal();
        if Settings.Get('useFrequencyPenalty', SettingsToken) then
            UseFrequencyPenalty := SettingsToken.AsValue().AsBoolean();
        if Settings.Get('seed', SettingsToken) then
            Seed := SettingsToken.AsValue().AsInteger();
        if Settings.Get('useSeed', SettingsToken) then
            UseSeed := SettingsToken.AsValue().AsBoolean();
        if Settings.Get('stopSequences', SettingsToken) then
            StopSequencesText := SettingsToken.AsValue().AsText();
        if Settings.Get('reasoning', SettingsToken) then
            Reasoning := "AIOS Reasoning Effort".FromInteger(SettingsToken.AsValue().AsInteger());
        if Settings.Get('maxTokens', SettingsToken) then
            MaxTokens := SettingsToken.AsValue().AsInteger();
        if Settings.Get('timeoutMs', SettingsToken) then
            TimeoutMs := SettingsToken.AsValue().AsInteger();
        if Settings.Get('maxRetries', SettingsToken) then
            MaxRetries := SettingsToken.AsValue().AsInteger();
        if Settings.Get('useMaxRetries', SettingsToken) then
            UseMaxRetries := SettingsToken.AsValue().AsBoolean();

        ApiKeyEditable := SelectedProvider <> SelectedProvider::Mock;
        ApiKeyText := '';
        if IsolatedStorage.Contains(ApiKeyKeyTok, DataScope::User) then
            IsolatedStorage.Get(ApiKeyKeyTok, DataScope::User, ApiKeyText);

        if ImageModelId = '' then
            case SelectedProvider of
                SelectedProvider::Mock:
                    ImageModelId := 'mock-image';
                SelectedProvider::OpenAI:
                    ImageModelId := 'dall-e-3';
            end;
        if ImageCount < 1 then
            ImageCount := 3;

        exit(true);
    end;

    local procedure ClearSavedSettings()
    begin
        if IsolatedStorage.Contains(SettingsKeyTok, DataScope::User) then
            IsolatedStorage.Delete(SettingsKeyTok, DataScope::User);
        if IsolatedStorage.Contains(ApiKeyKeyTok, DataScope::User) then
            IsolatedStorage.Delete(ApiKeyKeyTok, DataScope::User);
    end;

    var
        MockProvider: Codeunit "AIOS Mock";
        Reasoning: Enum "AIOS Reasoning Effort";
        SelectedProvider: Option Mock,Anthropic,OpenAI,"OpenCode Zen";
        ModelId: Text[100];
        ImageModelId: Text[100];
        ApiKeyText: Text[250];
        SystemPrompt: Text;
        UserPrompt: Text;
        ChoiceOptionsText: Text;
        ImageSize: Text[30];
        LastResult: Text;
        LastResponseBody: Text;
        LastResponseHeaders: Text;
        LastHttpStatus: Integer;
        ImageCount: Integer;
        StopSequencesText: Text;
        Temperature: Decimal;
        UseTemperature: Boolean;
        TopP: Decimal;
        UseTopP: Boolean;
        TopK: Integer;
        UseTopK: Boolean;
        PresencePenalty: Decimal;
        UsePresencePenalty: Boolean;
        FrequencyPenalty: Decimal;
        UseFrequencyPenalty: Boolean;
        Seed: Integer;
        UseSeed: Boolean;
        MaxTokens: Integer;
        TimeoutMs: Integer;
        MaxRetries: Integer;
        UseMaxRetries: Boolean;
        ApiKeyEditable: Boolean;
        SettingsKeyTok: Label 'AIToolkitDemo.Settings', Locked = true;
        ApiKeyKeyTok: Label 'AIToolkitDemo.ApiKey', Locked = true;
        ModelRequiredErr: Label 'Enter a model id.';
        ImageModelRequiredErr: Label 'Enter an image model id (for example mock-image or dall-e-3).';
        ApiKeyRequiredErr: Label 'Enter an API key for this provider (not needed for Mock).';
        ErrorResultMsg: Label 'Failed (%1): %2', Comment = '%1 = error type, %2 = message';
        ErrorResultWithTextMsg: Label 'Failed (%1): %2\n\nModel response:\n%3', Comment = '%1 = error type, %2 = message, %3 = model text';
        GenerationFailedErr: Label 'Generation failed (%1): %2', Comment = '%1 = error type, %2 = message';
        PromptRequiredErr: Label 'Enter a prompt before structured generate.';
        JsonPromptRequiredErr: Label 'Enter a prompt before generate JSON.';
        ChoicePromptRequiredErr: Label 'Enter a prompt before generate choice.';
        ChoiceOptionsRequiredErr: Label 'Enter at least one choice option (comma-separated).';
        ImagePromptRequiredErr: Label 'Enter a prompt before generating images.';
        ImageProviderUnsupportedErr: Label 'Image generation is not available for %1. Use Mock or OpenAI.', Comment = '%1 = provider name';
        ImageResultMsg: Label 'Generated %1 image(s). Usage images=%2. HTTP %3.', Comment = '%1 = list count, %2 = usage count, %3 = status';
        ImageFileNameTok: Label 'aios-demo-%1.png', Locked = true, Comment = '%1 = entry no';
        MissingGeneratedBase64Err: Label 'GenerateImage returned empty base64 for image %1.', Comment = '%1 = entry no';
        ImportGeneratedMediaErr: Label 'Could not import generated images into history MediaSet (expected %1).', Comment = '%1 = image count';
        ImageHistorySystemTok: Label 'Image generation (count=%1, size=%2)', Comment = '%1 = image count, %2 = size';
        MockStructuredJsonTok: Label '{"Sentiment":"positive","Score":0.9,"Urgent":false,"Summary":"Good product, pricey support.","Topics":["pricing","support"]}', Locked = true;
        MockJsonTok: Label '{"sentiment":"positive","topics":["pricing","support"]}', Locked = true;
        NoHistorySelectedErr: Label 'Select a history line first.';
        UnknownProviderErr: Label 'Unknown provider in history: %1', Comment = '%1 = provider name';
        ClearHistoryQst: Label 'Delete all demo history for your user?';
}

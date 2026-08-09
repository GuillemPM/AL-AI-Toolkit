namespace PM.Guillem.AIOpenSDK.Core;

using System.Environment;
using System.Utilities;

table 87401 "AIOS Chat Request"
{
    Caption = 'AIOS Chat Request';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; Prompt; Blob)
        {
            Caption = 'Prompt';
            DataClassification = CustomerContent;
        }
        field(11; "System Message"; Blob)
        {
            Caption = 'System Message';
            DataClassification = CustomerContent;
        }
        field(12; "Stop Sequences"; Blob)
        {
            Caption = 'Stop Sequences';
            DataClassification = SystemMetadata;
        }
        field(13; "Output Schema"; Blob)
        {
            Caption = 'Output Schema';
            DataClassification = SystemMetadata;
        }
        field(20; "Json Mode"; Boolean)
        {
            Caption = 'JSON Mode';
            DataClassification = SystemMetadata;
        }
        field(30; Model; Text[100])
        {
            Caption = 'Model';
            DataClassification = SystemMetadata;
        }
        field(31; "Max Tokens"; Integer)
        {
            Caption = 'Max Tokens';
            DataClassification = SystemMetadata;
        }
        field(32; Temperature; Decimal)
        {
            Caption = 'Temperature';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
        field(33; "Has Temperature"; Boolean)
        {
            Caption = 'Has Temperature';
            DataClassification = SystemMetadata;
        }
        field(34; "Timeout Ms"; Integer)
        {
            Caption = 'Timeout Ms';
            DataClassification = SystemMetadata;
        }
        field(35; "Has Timeout"; Boolean)
        {
            Caption = 'Has Timeout';
            DataClassification = SystemMetadata;
        }
        field(36; "Top P"; Decimal)
        {
            Caption = 'Top P';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 4;
        }
        field(37; "Has Top P"; Boolean)
        {
            Caption = 'Has Top P';
            DataClassification = SystemMetadata;
        }
        field(38; "Top K"; Integer)
        {
            Caption = 'Top K';
            DataClassification = SystemMetadata;
        }
        field(39; "Has Top K"; Boolean)
        {
            Caption = 'Has Top K';
            DataClassification = SystemMetadata;
        }
        field(40; "Presence Penalty"; Decimal)
        {
            Caption = 'Presence Penalty';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
        field(41; "Has Presence Penalty"; Boolean)
        {
            Caption = 'Has Presence Penalty';
            DataClassification = SystemMetadata;
        }
        field(42; "Frequency Penalty"; Decimal)
        {
            Caption = 'Frequency Penalty';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 2;
        }
        field(43; "Has Frequency Penalty"; Boolean)
        {
            Caption = 'Has Frequency Penalty';
            DataClassification = SystemMetadata;
        }
        field(44; Seed; Integer)
        {
            Caption = 'Seed';
            DataClassification = SystemMetadata;
        }
        field(45; "Has Seed"; Boolean)
        {
            Caption = 'Has Seed';
            DataClassification = SystemMetadata;
        }
        field(46; Reasoning; Enum "AIOS Reasoning Effort")
        {
            Caption = 'Reasoning';
            DataClassification = SystemMetadata;
        }
        field(47; "Max Retries"; Integer)
        {
            Caption = 'Max Retries';
            DataClassification = SystemMetadata;
        }
        field(48; "Has Max Retries"; Boolean)
        {
            Caption = 'Has Max Retries';
            DataClassification = SystemMetadata;
        }
        field(50; "Has Output"; Boolean)
        {
            Caption = 'Has Output';
            DataClassification = SystemMetadata;
        }
        field(51; "Has Output Schema"; Boolean)
        {
            Caption = 'Has Output Schema';
            DataClassification = SystemMetadata;
        }
        field(60; Messages; Blob)
        {
            Caption = 'Messages';
            DataClassification = CustomerContent;
        }
        field(61; Tools; Blob)
        {
            Caption = 'Tools';
            DataClassification = SystemMetadata;
        }
        field(62; "Pending Attachments"; Blob)
        {
            Caption = 'Pending Attachments';
            DataClassification = CustomerContent;
        }
        field(63; "Attachment Payloads"; Blob)
        {
            Caption = 'Attachment Payloads';
            DataClassification = CustomerContent;
        }
        field(64; "Attachment Binaries"; Blob)
        {
            Caption = 'Attachment Binaries';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure SetPrompt(Value: Text)
    var
        ChatPrompt: Codeunit "AIOS Chat Prompt";
    begin
        ChatPrompt.SetPrompt(Rec, Value);
    end;

    procedure GetPrompt(): Text
    var
        ChatPrompt: Codeunit "AIOS Chat Prompt";
    begin
        exit(ChatPrompt.GetPrompt(Rec));
    end;

    procedure SetSystemMessage(Value: Text)
    var
        ChatPrompt: Codeunit "AIOS Chat Prompt";
    begin
        ChatPrompt.SetSystemMessage(Rec, Value);
    end;

    procedure GetSystemMessage(): Text
    var
        ChatPrompt: Codeunit "AIOS Chat Prompt";
    begin
        exit(ChatPrompt.GetSystemMessage(Rec));
    end;

    /// <summary>
    /// System message as sent to providers. When Json Mode is on and no output schema
    /// hint was already appended by SetOutput, appends a JSON-only instruction.
    /// </summary>
    procedure GetEffectiveSystemMessage(): Text
    var
        ChatPrompt: Codeunit "AIOS Chat Prompt";
    begin
        exit(ChatPrompt.GetEffectiveSystemMessage(Rec));
    end;

    /// <summary>
    /// Binds flat JSON fields onto RecRef. Pass the same RecRef to GenerateText(Model, Request, RecRef).
    /// Prefer SetOutput with a JSON Schema for nested shapes.
    /// </summary>
    procedure SetOutput(RecRef: RecordRef)
    var
        ChatOutput: Codeunit "AIOS Chat Output";
    begin
        ChatOutput.SetOutput(Rec, RecRef);
    end;

    /// <summary>
    /// Sets the output mode from a schema document. Object/Array/Choice/Json enable JSON mode and append a system hint.
    /// Text disables JSON mode and does not append a hint (same as omitting SetOutput).
    /// Use with GenerateText(Model, Request). For Choice, Result.Output() is the result property as plain text.
    /// </summary>
    procedure SetOutput(SchemaText: Text)
    var
        ChatOutput: Codeunit "AIOS Chat Output";
    begin
        ChatOutput.SetOutput(Rec, SchemaText);
    end;

    /// <summary>
    /// Sets structured output from a schema JsonObject (serialized via "AIOS Schema".ToText).
    /// </summary>
    procedure SetOutput(Schema: JsonObject)
    var
        ChatOutput: Codeunit "AIOS Chat Output";
    begin
        ChatOutput.SetOutput(Rec, Schema);
    end;

    procedure HasOutput(): Boolean
    var
        ChatOutput: Codeunit "AIOS Chat Output";
    begin
        exit(ChatOutput.HasOutput(Rec));
    end;

    procedure HasOutputSchema(): Boolean
    var
        ChatOutput: Codeunit "AIOS Chat Output";
    begin
        exit(ChatOutput.HasOutputSchema(Rec));
    end;

    procedure GetOutputSchema(): Text
    var
        ChatOutput: Codeunit "AIOS Chat Output";
    begin
        exit(ChatOutput.GetOutputSchema(Rec));
    end;

    procedure ClearOutput()
    var
        ChatOutput: Codeunit "AIOS Chat Output";
    begin
        ChatOutput.ClearOutput(Rec);
    end;

    /// <summary>
    /// Sets sampling temperature (0–2 typical). Marks the value as specified so providers send it even when 0.
    /// </summary>
    procedure SetTemperature(Value: Decimal)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetTemperature(Rec, Value);
    end;

    procedure ClearTemperature()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearTemperature(Rec);
    end;

    /// <summary>
    /// Maximum tokens to generate. Ignored when &lt;= 0.
    /// </summary>
    procedure SetMaxTokens(Value: Integer)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetMaxTokens(Rec, Value);
    end;

    procedure ClearMaxTokens()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearMaxTokens(Rec);
    end;

    /// <summary>
    /// HTTP client timeout in milliseconds. Default is 120000 when unset.
    /// </summary>
    procedure SetTimeout(TimeoutMs: Integer)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetTimeout(Rec, TimeoutMs);
    end;

    procedure ClearTimeout()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearTimeout(Rec);
    end;

    /// <summary>
    /// Timeout to apply on HttpClient (default 120s).
    /// </summary>
    procedure GetHttpTimeout(): Integer
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        exit(ChatParameters.GetHttpTimeout(Rec));
    end;

    /// <summary>
    /// Nucleus sampling (top-P).
    /// </summary>
    procedure SetTopP(Value: Decimal)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetTopP(Rec, Value);
    end;

    procedure ClearTopP()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearTopP(Rec);
    end;

    /// <summary>
    /// Sample from the top K tokens.
    /// </summary>
    procedure SetTopK(Value: Integer)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetTopK(Rec, Value);
    end;

    procedure ClearTopK()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearTopK(Rec);
    end;

    /// <summary>
    /// Presence penalty for token sampling.
    /// </summary>
    procedure SetPresencePenalty(Value: Decimal)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetPresencePenalty(Rec, Value);
    end;

    procedure ClearPresencePenalty()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearPresencePenalty(Rec);
    end;

    /// <summary>
    /// Frequency penalty for token sampling.
    /// </summary>
    procedure SetFrequencyPenalty(Value: Decimal)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetFrequencyPenalty(Rec, Value);
    end;

    procedure ClearFrequencyPenalty()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearFrequencyPenalty(Rec);
    end;

    /// <summary>
    /// Seed for deterministic sampling when the provider supports it.
    /// </summary>
    procedure SetSeed(Value: Integer)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetSeed(Rec, Value);
    end;

    procedure ClearSeed()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearSeed(Rec);
    end;

    /// <summary>
    /// Reasoning effort for models that support it.
    /// </summary>
    procedure SetReasoning(Value: Enum "AIOS Reasoning Effort")
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetReasoning(Rec, Value);
    end;

    procedure ClearReasoning()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearReasoning(Rec);
    end;

    /// <summary>
    /// Max generation retries. 0 disables retries. Default when unset is 2.
    /// </summary>
    procedure SetMaxRetries(Value: Integer)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.SetMaxRetries(Rec, Value);
    end;

    procedure ClearMaxRetries()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearMaxRetries(Rec);
    end;

    procedure GetMaxRetries(): Integer
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        exit(ChatParameters.GetMaxRetries(Rec));
    end;

    procedure AddStopSequence(Value: Text)
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.AddStopSequence(Rec, Value);
    end;

    procedure ClearStopSequences()
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        ChatParameters.ClearStopSequences(Rec);
    end;

    procedure GetStopSequences(): JsonArray
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        exit(ChatParameters.GetStopSequences(Rec));
    end;

    procedure HasStopSequences(): Boolean
    var
        ChatParameters: Codeunit "AIOS Chat Parameters";
    begin
        exit(ChatParameters.HasStopSequences(Rec));
    end;

    /// <summary>
    /// Copies tool definitions from ToolSet onto this request for provider HTTP.
    /// </summary>
    procedure SetTools(ToolSet: Codeunit "AIOS Tool Set")
    var
        ChatRequestTools: Codeunit "AIOS Chat Request Tools";
    begin
        ChatRequestTools.SetTools(Rec, ToolSet);
    end;

    /// <summary>
    /// Stores neutral tool definitions JSON on the request (name, description, parameters).
    /// </summary>
    procedure SetToolDefinitions(Definitions: JsonArray)
    var
        ChatRequestTools: Codeunit "AIOS Chat Request Tools";
    begin
        ChatRequestTools.SetToolDefinitions(Rec, Definitions);
    end;

    /// <summary>
    /// Tool definitions sent to the provider when non-empty.
    /// </summary>
    procedure GetToolDefinitions(): JsonArray
    var
        ChatRequestTools: Codeunit "AIOS Chat Request Tools";
    begin
        exit(ChatRequestTools.GetToolDefinitions(Rec));
    end;

    /// <summary>
    /// True when at least one tool definition is stored on the request.
    /// </summary>
    procedure HasTools(): Boolean
    var
        ChatRequestTools: Codeunit "AIOS Chat Request Tools";
    begin
        exit(ChatRequestTools.HasTools(Rec));
    end;

    /// <summary>
    /// Removes stored tool definitions from the request.
    /// </summary>
    procedure ClearTools()
    var
        ChatRequestTools: Codeunit "AIOS Chat Request Tools";
    begin
        ChatRequestTools.ClearTools(Rec);
    end;

    /// <summary>
    /// AIOS-normalized conversation history (system, user, assistant, tool roles).
    /// </summary>
    procedure GetMessages(): JsonArray
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
    begin
        exit(ChatMessages.GetMessages(Rec));
    end;

    /// <summary>
    /// True when the messages history blob is non-empty.
    /// </summary>
    procedure HasMessages(): Boolean
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
    begin
        exit(ChatMessages.HasMessages(Rec));
    end;

    /// <summary>
    /// Clears the messages history and prunes Attachment Payloads that are no longer referenced.
    /// </summary>
    procedure ClearMessages()
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatMessages.ClearMessages(Rec);
        ChatAttachments.PruneUnreferencedPayloads(Rec);
    end;

    /// <summary>
    /// Replaces the full messages history and prunes Attachment Payloads that are no longer referenced.
    /// </summary>
    procedure SetMessages(MessagesArr: JsonArray)
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatMessages.SetMessages(Rec, MessagesArr);
        ChatAttachments.PruneUnreferencedPayloads(Rec);
    end;

    /// <summary>
    /// Appends a user message to the history.
    /// </summary>
    procedure AppendUserMessage(Content: Text)
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
    begin
        ChatMessages.AppendUserMessage(Rec, Content);
    end;

    /// <summary>
    /// Appends an assistant text message to the history.
    /// </summary>
    procedure AppendAssistantMessage(Content: Text)
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
    begin
        ChatMessages.AppendAssistantMessage(Rec, Content);
    end;

    /// <summary>
    /// Appends an assistant message that requested tool calls (from a generate result).
    /// </summary>
    procedure AppendAssistantToolCalls(Content: Text; ToolCalls: List of [Codeunit "AIOS Tool Call"])
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
    begin
        ChatMessages.AppendAssistantToolCalls(Rec, Content, ToolCalls);
    end;

    /// <summary>
    /// Appends an assistant tool-call message, including reasoning_content for thinking-mode providers.
    /// </summary>
    procedure AppendAssistantToolCalls(Content: Text; ToolCalls: List of [Codeunit "AIOS Tool Call"]; ReasoningContent: Text)
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
    begin
        ChatMessages.AppendAssistantToolCalls(Rec, Content, ToolCalls, ReasoningContent);
    end;

    /// <summary>
    /// Appends a tool result message for a prior tool call id.
    /// </summary>
    procedure AppendToolResult(ToolCallId: Text; ToolName: Text; Content: Text)
    var
        ChatMessages: Codeunit "AIOS Chat Messages";
    begin
        ChatMessages.AppendToolResult(Rec, ToolCallId, ToolName, Content);
    end;

    /// <summary>
    /// Ensures Messages includes the prompt and any pending Attach parts.
    /// When history is empty: system (effective) + user turn.
    /// When history exists and Attachments are pending: merge into the last user message, or append a new user turn.
    /// </summary>
    procedure EnsureMessagesFromPrompt()
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.EnsureMessagesFromPrompt(Rec);
    end;

    /// <summary>
    /// Attaches content to the next user turn (AI SDK–style file part). mediaType is IANA (e.g. image/png, application/pdf).
    /// Binary bytes are stored raw in Attachment Binaries; message history stores an id ref. Base64 is produced only in GetProviderMessages.
    /// Applied in EnsureMessagesFromPrompt / Generate: into a new user turn when history is empty or last turn is not user;
    /// otherwise merged into the last user message.
    /// </summary>
    procedure Attach(var ContentInStream: InStream; MediaType: Text; Filename: Text)
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.Attach(Rec, ContentInStream, MediaType, Filename);
    end;

    /// <summary>
    /// Attaches raw base64 bytes (no data: URL prefix). Decoded to binary storage; history keeps an id ref.
    /// </summary>
    procedure Attach(Base64Data: Text; MediaType: Text; Filename: Text)
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.Attach(Rec, Base64Data, MediaType, Filename);
    end;

    /// <summary>
    /// Attaches bytes from a Temp Blob.
    /// </summary>
    procedure Attach(var TempBlob: Codeunit "Temp Blob"; MediaType: Text; Filename: Text)
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.Attach(Rec, TempBlob, MediaType, Filename);
    end;

    /// <summary>
    /// Attaches Tenant Media (MIME from the record). Filename defaults from Description or 'attachment'.
    /// </summary>
    procedure Attach(var TenantMedia: Record "Tenant Media")
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.Attach(Rec, TenantMedia);
    end;

    /// <summary>
    /// Attaches Tenant Media with an explicit filename.
    /// </summary>
    procedure Attach(var TenantMedia: Record "Tenant Media"; Filename: Text)
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.Attach(Rec, TenantMedia, Filename);
    end;

    /// <summary>
    /// Attaches Tenant Media by MediaId — e.g. Request.Attach(Item.Picture.Item(1)).
    /// </summary>
    procedure Attach(MediaId: Guid)
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.Attach(Rec, MediaId);
    end;

    /// <summary>
    /// Attaches Tenant Media by MediaId with an explicit filename.
    /// </summary>
    procedure Attach(MediaId: Guid; Filename: Text)
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.Attach(Rec, MediaId, Filename);
    end;

    /// <summary>
    /// True when one or more parts were attached for the next user turn.
    /// </summary>
    procedure HasAttachments(): Boolean
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        exit(ChatAttachments.HasAttachments(Rec));
    end;

    /// <summary>
    /// Pending attachment refs: { type: "file", mediaType, id, filename? }. Binary bytes live in Attachment Binaries until GetProviderMessages.
    /// </summary>
    procedure GetAttachments(): JsonArray
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        exit(ChatAttachments.GetAttachments(Rec));
    end;

    /// <summary>
    /// Clears pending attachment refs and drops payloads that are not referenced by message history.
    /// </summary>
    procedure ClearAttachments()
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        ChatAttachments.ClearAttachments(Rec);
    end;

    /// <summary>
    /// Message history with file refs expanded (text or base64 data) for provider MapMessages. Does not mutate stored Messages.
    /// </summary>
    procedure GetProviderMessages(): JsonArray
    var
        ChatAttachments: Codeunit "AIOS Chat Attachments";
    begin
        exit(ChatAttachments.GetProviderMessages(Rec));
    end;
}

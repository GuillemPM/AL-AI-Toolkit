namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

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
        OutStream: OutStream;
    begin
        Clear(Prompt);
        if Value = '' then
            exit;
        Prompt.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetPrompt(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not Prompt.HasValue then
            exit('');
        Prompt.CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetSystemMessage(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear("System Message");
        if Value = '' then
            exit;
        "System Message".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    procedure GetSystemMessage(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not "System Message".HasValue then
            exit('');
        "System Message".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    /// <summary>
    /// System message as sent to providers. Appends a JSON-mode instruction when Json Mode is on
    /// and no output schema hint is already present.
    /// </summary>
    procedure GetEffectiveSystemMessage(): Text
    var
        SystemText: Text;
    begin
        SystemText := GetSystemMessage();
        if not "Json Mode" then
            exit(SystemText);
        if HasOutputSchema() then
            exit(SystemText);
        if SystemText = '' then
            exit(JsonModeInstructionTxt);
        if StrPos(LowerCase(SystemText + ' ' + GetPrompt()), 'json') = 0 then
            exit(SystemText + ' ' + JsonModeInstructionTxt);
        exit(SystemText);
    end;

    procedure SetJsonMode(Value: Boolean)
    begin
        "Json Mode" := Value;
    end;

    /// <summary>
    /// Binds flat JSON fields onto RecRef. Pass the same RecRef to GenerateText(Model, Request, RecRef).
    /// Prefer SetOutput with a JSON Schema for nested shapes.
    /// </summary>
    procedure SetOutput(RecRef: RecordRef)
    var
        JsonBinder: Codeunit "AIOS Json Binder";
        Hint: Text;
        SystemText: Text;
    begin
        if RecRef.Number() = 0 then
            Error(OutputRecordMissingErr);

        ClearOutput();
        "Has Output" := true;
        SetJsonMode(true);

        Hint := JsonBinder.BuildSchemaHint(RecRef);
        SystemText := GetSystemMessage();
        if SystemText = '' then
            SetSystemMessage(Hint)
        else
            SetSystemMessage(SystemText + ' ' + Hint);
    end;

    /// <summary>
    /// Sets a JSON Schema for structured output. Enables JSON mode and appends a schema hint.
    /// Use with GenerateText(Model, Request). Response JSON is validated against the schema.
    /// </summary>
    procedure SetOutput(SchemaText: Text)
    var
        OutStream: OutStream;
        SystemText: Text;
        Hint: Text;
    begin
        if DelChr(SchemaText, '<>', ' ') = '' then
            Error(OutputSchemaMissingErr);

        ClearOutput();
        "Output Schema".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(SchemaText);
        "Has Output Schema" := true;
        SetJsonMode(true);

        Hint := StrSubstNo(OutputSchemaHintTxt, SchemaText);
        SystemText := GetSystemMessage();
        if SystemText = '' then
            SetSystemMessage(Hint)
        else
            SetSystemMessage(SystemText + ' ' + Hint);
    end;

    /// <summary>
    /// Sets structured output from a schema JsonObject (serialized via "AIOS Schema".ToText).
    /// </summary>
    procedure SetOutput(Schema: JsonObject)
    var
        SchemaCodeunit: Codeunit "AIOS Schema";
    begin
        SetOutput(SchemaCodeunit.ToText(Schema));
    end;

    procedure HasOutput(): Boolean
    begin
        exit("Has Output");
    end;

    procedure HasOutputSchema(): Boolean
    begin
        exit("Has Output Schema");
    end;

    procedure GetOutputSchema(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not "Output Schema".HasValue then
            exit('');
        "Output Schema".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure ClearOutput()
    begin
        "Has Output" := false;
        Clear("Output Schema");
        "Has Output Schema" := false;
    end;

    /// <summary>
    /// Sets sampling temperature (0–2 typical). Marks the value as specified so providers send it even when 0.
    /// </summary>
    procedure SetTemperature(Value: Decimal)
    begin
        Temperature := Value;
        "Has Temperature" := true;
    end;

    procedure ClearTemperature()
    begin
        Temperature := 0;
        "Has Temperature" := false;
    end;

    /// <summary>
    /// Maximum tokens to generate. Ignored when &lt;= 0.
    /// </summary>
    procedure SetMaxTokens(Value: Integer)
    begin
        if Value < 0 then
            Error(MaxTokensNegativeErr);
        "Max Tokens" := Value;
    end;

    procedure ClearMaxTokens()
    begin
        "Max Tokens" := 0;
    end;

    /// <summary>
    /// HTTP client timeout in milliseconds. Default is 120000 when unset.
    /// </summary>
    procedure SetTimeout(TimeoutMs: Integer)
    begin
        if TimeoutMs <= 0 then
            Error(TimeoutInvalidErr);
        "Timeout Ms" := TimeoutMs;
        "Has Timeout" := true;
    end;

    procedure ClearTimeout()
    begin
        "Timeout Ms" := 0;
        "Has Timeout" := false;
    end;

    /// <summary>
    /// Timeout to apply on HttpClient (default 120s).
    /// </summary>
    procedure GetHttpTimeout(): Integer
    begin
        if "Has Timeout" then
            exit("Timeout Ms");
        exit(120000);
    end;

    /// <summary>
    /// Nucleus sampling (top-P).
    /// </summary>
    procedure SetTopP(Value: Decimal)
    begin
        "Top P" := Value;
        "Has Top P" := true;
    end;

    procedure ClearTopP()
    begin
        "Top P" := 0;
        "Has Top P" := false;
    end;

    /// <summary>
    /// Sample from the top K tokens.
    /// </summary>
    procedure SetTopK(Value: Integer)
    begin
        if Value < 0 then
            Error(TopKNegativeErr);
        "Top K" := Value;
        "Has Top K" := true;
    end;

    procedure ClearTopK()
    begin
        "Top K" := 0;
        "Has Top K" := false;
    end;

    /// <summary>
    /// Presence penalty for token sampling.
    /// </summary>
    procedure SetPresencePenalty(Value: Decimal)
    begin
        "Presence Penalty" := Value;
        "Has Presence Penalty" := true;
    end;

    procedure ClearPresencePenalty()
    begin
        "Presence Penalty" := 0;
        "Has Presence Penalty" := false;
    end;

    /// <summary>
    /// Frequency penalty for token sampling.
    /// </summary>
    procedure SetFrequencyPenalty(Value: Decimal)
    begin
        "Frequency Penalty" := Value;
        "Has Frequency Penalty" := true;
    end;

    procedure ClearFrequencyPenalty()
    begin
        "Frequency Penalty" := 0;
        "Has Frequency Penalty" := false;
    end;

    /// <summary>
    /// Seed for deterministic sampling when the provider supports it.
    /// </summary>
    procedure SetSeed(Value: Integer)
    begin
        Seed := Value;
        "Has Seed" := true;
    end;

    procedure ClearSeed()
    begin
        Seed := 0;
        "Has Seed" := false;
    end;

    /// <summary>
    /// Reasoning effort for models that support it.
    /// </summary>
    procedure SetReasoning(Value: Enum "AIOS Reasoning Effort")
    begin
        Reasoning := Value;
    end;

    procedure ClearReasoning()
    begin
        Reasoning := Reasoning::ProviderDefault;
    end;

    /// <summary>
    /// Max generation retries. 0 disables retries. Default when unset is 2.
    /// </summary>
    procedure SetMaxRetries(Value: Integer)
    begin
        if Value < 0 then
            Error(MaxRetriesNegativeErr);
        "Max Retries" := Value;
        "Has Max Retries" := true;
    end;

    procedure ClearMaxRetries()
    begin
        "Max Retries" := 0;
        "Has Max Retries" := false;
    end;

    procedure GetMaxRetries(): Integer
    begin
        if "Has Max Retries" then
            exit("Max Retries");
        exit(2);
    end;

    procedure AddStopSequence(Value: Text)
    var
        Sequences: JsonArray;
        OutStream: OutStream;
        Text: Text;
    begin
        if Value = '' then
            exit;
        Sequences := GetStopSequences();
        Sequences.Add(Value);
        Sequences.WriteTo(Text);
        Clear("Stop Sequences");
        "Stop Sequences".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    procedure ClearStopSequences()
    begin
        Clear("Stop Sequences");
    end;

    procedure GetStopSequences(): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        Sequences: JsonArray;
        Text: Text;
    begin
        if not "Stop Sequences".HasValue then
            exit(Sequences);
        "Stop Sequences".CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(Sequences);
        if not Sequences.ReadFrom(Text) then
            Clear(Sequences);
        exit(Sequences);
    end;

    procedure HasStopSequences(): Boolean
    begin
        exit(GetStopSequences().Count() > 0);
    end;

    var
        MaxTokensNegativeErr: Label 'Max tokens cannot be negative.';
        TimeoutInvalidErr: Label 'Timeout must be greater than 0 milliseconds.';
        TopKNegativeErr: Label 'Top K cannot be negative.';
        MaxRetriesNegativeErr: Label 'Max retries cannot be negative.';
        OutputRecordMissingErr: Label 'Structured output requires an open record.';
        OutputSchemaMissingErr: Label 'Output schema text cannot be empty.';
        OutputSchemaHintTxt: Label 'Respond with JSON only (no markdown) that conforms to this JSON Schema: %1', Comment = '%1 = JSON Schema';
        JsonModeInstructionTxt: Label 'Respond with valid JSON only, no markdown fences.';
}

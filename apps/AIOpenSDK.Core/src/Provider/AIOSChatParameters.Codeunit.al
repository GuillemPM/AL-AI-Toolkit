namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

/// <summary>
/// Sampling, timeout, retry, and stop-sequence parameters on "AIOS Chat Request".
/// </summary>
codeunit 87426 "AIOS Chat Parameters"
{
    Access = Public;

    /// <summary>
    /// Sets sampling temperature on the request.
    /// </summary>
    procedure SetTemperature(var Request: Record "AIOS Chat Request"; Value: Decimal)
    begin
        Request.Temperature := Value;
        Request."Has Temperature" := true;
    end;

    /// <summary>
    /// Clears the temperature override so the provider default applies.
    /// </summary>
    procedure ClearTemperature(var Request: Record "AIOS Chat Request")
    begin
        Request.Temperature := 0;
        Request."Has Temperature" := false;
    end;

    /// <summary>
    /// Sets the maximum completion tokens. Errors when Value is negative.
    /// </summary>
    procedure SetMaxTokens(var Request: Record "AIOS Chat Request"; Value: Integer)
    begin
        if Value < 0 then
            Error(MaxTokensNegativeErr);
        Request."Max Tokens" := Value;
    end;

    /// <summary>
    /// Clears the max-tokens override.
    /// </summary>
    procedure ClearMaxTokens(var Request: Record "AIOS Chat Request")
    begin
        Request."Max Tokens" := 0;
    end;

    /// <summary>
    /// Sets the HTTP timeout in milliseconds. Errors when TimeoutMs is not greater than zero.
    /// </summary>
    procedure SetTimeout(var Request: Record "AIOS Chat Request"; TimeoutMs: Integer)
    begin
        if TimeoutMs <= 0 then
            Error(TimeoutInvalidErr);
        Request."Timeout Ms" := TimeoutMs;
        Request."Has Timeout" := true;
    end;

    /// <summary>
    /// Clears the timeout override so the default (120s) applies.
    /// </summary>
    procedure ClearTimeout(var Request: Record "AIOS Chat Request")
    begin
        Request."Timeout Ms" := 0;
        Request."Has Timeout" := false;
    end;

    /// <summary>
    /// Returns the effective HTTP timeout in milliseconds (default 120000).
    /// </summary>
    procedure GetHttpTimeout(var Request: Record "AIOS Chat Request"): Integer
    begin
        if Request."Has Timeout" then
            exit(Request."Timeout Ms");
        exit(120000);
    end;

    /// <summary>
    /// Sets nucleus sampling top-p on the request.
    /// </summary>
    procedure SetTopP(var Request: Record "AIOS Chat Request"; Value: Decimal)
    begin
        Request."Top P" := Value;
        Request."Has Top P" := true;
    end;

    /// <summary>
    /// Clears the top-p override.
    /// </summary>
    procedure ClearTopP(var Request: Record "AIOS Chat Request")
    begin
        Request."Top P" := 0;
        Request."Has Top P" := false;
    end;

    /// <summary>
    /// Sets top-k sampling. Errors when Value is negative.
    /// </summary>
    procedure SetTopK(var Request: Record "AIOS Chat Request"; Value: Integer)
    begin
        if Value < 0 then
            Error(TopKNegativeErr);
        Request."Top K" := Value;
        Request."Has Top K" := true;
    end;

    /// <summary>
    /// Clears the top-k override.
    /// </summary>
    procedure ClearTopK(var Request: Record "AIOS Chat Request")
    begin
        Request."Top K" := 0;
        Request."Has Top K" := false;
    end;

    /// <summary>
    /// Sets the presence penalty on the request.
    /// </summary>
    procedure SetPresencePenalty(var Request: Record "AIOS Chat Request"; Value: Decimal)
    begin
        Request."Presence Penalty" := Value;
        Request."Has Presence Penalty" := true;
    end;

    /// <summary>
    /// Clears the presence penalty override.
    /// </summary>
    procedure ClearPresencePenalty(var Request: Record "AIOS Chat Request")
    begin
        Request."Presence Penalty" := 0;
        Request."Has Presence Penalty" := false;
    end;

    /// <summary>
    /// Sets the frequency penalty on the request.
    /// </summary>
    procedure SetFrequencyPenalty(var Request: Record "AIOS Chat Request"; Value: Decimal)
    begin
        Request."Frequency Penalty" := Value;
        Request."Has Frequency Penalty" := true;
    end;

    /// <summary>
    /// Clears the frequency penalty override.
    /// </summary>
    procedure ClearFrequencyPenalty(var Request: Record "AIOS Chat Request")
    begin
        Request."Frequency Penalty" := 0;
        Request."Has Frequency Penalty" := false;
    end;

    /// <summary>
    /// Sets the sampling seed on the request.
    /// </summary>
    procedure SetSeed(var Request: Record "AIOS Chat Request"; Value: Integer)
    begin
        Request.Seed := Value;
        Request."Has Seed" := true;
    end;

    /// <summary>
    /// Clears the seed override.
    /// </summary>
    procedure ClearSeed(var Request: Record "AIOS Chat Request")
    begin
        Request.Seed := 0;
        Request."Has Seed" := false;
    end;

    /// <summary>
    /// Sets the reasoning effort level on the request.
    /// </summary>
    procedure SetReasoning(var Request: Record "AIOS Chat Request"; Value: Enum "AIOS Reasoning Effort")
    begin
        Request.Reasoning := Value;
    end;

    /// <summary>
    /// Resets reasoning effort to ProviderDefault.
    /// </summary>
    procedure ClearReasoning(var Request: Record "AIOS Chat Request")
    begin
        Request.Reasoning := "AIOS Reasoning Effort"::ProviderDefault;
    end;

    /// <summary>
    /// Sets how many times retriable failures are retried. Errors when Value is negative.
    /// </summary>
    procedure SetMaxRetries(var Request: Record "AIOS Chat Request"; Value: Integer)
    begin
        if Value < 0 then
            Error(MaxRetriesNegativeErr);
        Request."Max Retries" := Value;
        Request."Has Max Retries" := true;
    end;

    /// <summary>
    /// Clears the max-retries override so the default (2) applies.
    /// </summary>
    procedure ClearMaxRetries(var Request: Record "AIOS Chat Request")
    begin
        Request."Max Retries" := 0;
        Request."Has Max Retries" := false;
    end;

    /// <summary>
    /// Returns the effective max retries (default 2).
    /// </summary>
    procedure GetMaxRetries(var Request: Record "AIOS Chat Request"): Integer
    begin
        if Request."Has Max Retries" then
            exit(Request."Max Retries");
        exit(2);
    end;

    /// <summary>
    /// Appends a stop sequence to the request. Empty values are ignored.
    /// </summary>
    procedure AddStopSequence(var Request: Record "AIOS Chat Request"; Value: Text)
    var
        Sequences: JsonArray;
        OutStream: OutStream;
        Text: Text;
    begin
        if Value = '' then
            exit;
        Sequences := GetStopSequences(Request);
        Sequences.Add(Value);
        Sequences.WriteTo(Text);
        Clear(Request."Stop Sequences");
        Request."Stop Sequences".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    /// <summary>
    /// Clears all stop sequences on the request.
    /// </summary>
    procedure ClearStopSequences(var Request: Record "AIOS Chat Request")
    begin
        Clear(Request."Stop Sequences");
    end;

    /// <summary>
    /// Returns stop sequences stored on the request as a JSON array.
    /// </summary>
    procedure GetStopSequences(var Request: Record "AIOS Chat Request"): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        Sequences: JsonArray;
        Text: Text;
    begin
        if not Request."Stop Sequences".HasValue then
            exit(Sequences);
        Request."Stop Sequences".CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(Sequences);
        if not Sequences.ReadFrom(Text) then
            Clear(Sequences);
        exit(Sequences);
    end;

    /// <summary>
    /// Returns true when the request has one or more stop sequences.
    /// </summary>
    procedure HasStopSequences(var Request: Record "AIOS Chat Request"): Boolean
    begin
        exit(GetStopSequences(Request).Count() > 0);
    end;

    var
        MaxTokensNegativeErr: Label 'Max tokens cannot be negative.';
        TimeoutInvalidErr: Label 'Timeout must be greater than 0 milliseconds.';
        TopKNegativeErr: Label 'Top K cannot be negative.';
        MaxRetriesNegativeErr: Label 'Max retries cannot be negative.';
}

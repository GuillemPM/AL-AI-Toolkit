namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

table 87402 "AIOS Chat Response"
{
    Caption = 'AIOS Chat Response';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; Content; Blob)
        {
            Caption = 'Content';
            DataClassification = CustomerContent;
        }
        field(20; "Error Type"; Enum "AIOS Error Type")
        {
            Caption = 'Error Type';
            DataClassification = SystemMetadata;
        }
        field(21; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(30; "HTTP Status Code"; Integer)
        {
            Caption = 'HTTP Status Code';
            DataClassification = SystemMetadata;
        }
        field(40; "Input Tokens"; Integer)
        {
            Caption = 'Input Tokens';
            DataClassification = SystemMetadata;
        }
        field(41; "Output Tokens"; Integer)
        {
            Caption = 'Output Tokens';
            DataClassification = SystemMetadata;
        }
        field(50; "Provider Name"; Text[100])
        {
            Caption = 'Provider Name';
            DataClassification = SystemMetadata;
        }
        field(60; "Finish Reason"; Text[50])
        {
            Caption = 'Finish Reason';
            DataClassification = SystemMetadata;
        }
        field(70; Warnings; Blob)
        {
            Caption = 'Warnings';
            DataClassification = SystemMetadata;
        }
        field(80; "Raw Body"; Blob)
        {
            Caption = 'Raw Body';
            DataClassification = CustomerContent;
        }
        field(81; "Response Headers"; Blob)
        {
            Caption = 'Response Headers';
            DataClassification = SystemMetadata;
        }
        field(90; "Tool Calls"; Blob)
        {
            Caption = 'Tool Calls';
            DataClassification = CustomerContent;
        }
        field(91; "Reasoning Content"; Blob)
        {
            Caption = 'Reasoning Content';
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

    procedure GetText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not Content.HasValue then
            exit('');
        Content.CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    procedure SetText(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Content);
        if Value = '' then
            exit;
        Content.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    /// <summary>
    /// Raw HTTP response body from the provider (full payload before content extraction).
    /// </summary>
    procedure GetBody(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not "Raw Body".HasValue then
            exit('');
        "Raw Body".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    /// <summary>
    /// Stores the raw HTTP response body from the provider.
    /// </summary>
    procedure SetBody(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Raw Body");
        if Value = '' then
            exit;
        "Raw Body".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    /// <summary>
    /// Response HTTP headers as a JSON object. Multi-value headers are JSON arrays of strings.
    /// </summary>
    procedure GetHeaders(): JsonObject
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        HeadersObj: JsonObject;
        Text: Text;
    begin
        if not "Response Headers".HasValue then
            exit(HeadersObj);
        "Response Headers".CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(HeadersObj);
        if not HeadersObj.ReadFrom(Text) then
            Clear(HeadersObj);
        exit(HeadersObj);
    end;

    /// <summary>
    /// Stores response HTTP headers as a JSON object.
    /// </summary>
    procedure SetHeaders(HeadersObj: JsonObject)
    var
        OutStream: OutStream;
        Text: Text;
    begin
        Clear("Response Headers");
        if HeadersObj.Keys().Count() = 0 then
            exit;
        HeadersObj.WriteTo(Text);
        "Response Headers".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    /// <summary>
    /// Captures HTTP status, raw body, and response headers from a provider HTTP response.
    /// </summary>
    procedure CaptureHttpResponse(HttpResponse: HttpResponseMessage; ResponseBody: Text)
    var
        Headers: HttpHeaders;
        HeaderNames: List of [Text];
        HeaderName: Text;
        Values: List of [Text];
        HeadersObj: JsonObject;
        ValuesArr: JsonArray;
        Value: Text;
    begin
        "HTTP Status Code" := HttpResponse.HttpStatusCode();
        SetBody(ResponseBody);

        Headers := HttpResponse.Headers;
        HeaderNames := Headers.Keys();
        foreach HeaderName in HeaderNames do begin
            Clear(Values);
            Clear(ValuesArr);
            if not Headers.GetValues(HeaderName, Values) then
                continue;
            if Values.Count() = 0 then
                continue;
            if Values.Count() = 1 then begin
                Values.Get(1, Value);
                if HeadersObj.Contains(HeaderName) then
                    HeadersObj.Remove(HeaderName);
                HeadersObj.Add(HeaderName, Value);
            end else begin
                foreach Value in Values do
                    ValuesArr.Add(Value);
                if HeadersObj.Contains(HeaderName) then
                    HeadersObj.Remove(HeaderName);
                HeadersObj.Add(HeaderName, ValuesArr);
            end;
        end;
        SetHeaders(HeadersObj);
    end;

    procedure GetErrorType(): Enum "AIOS Error Type"
    begin
        exit("Error Type");
    end;

    /// <summary>
    /// Marks the response as failed. Does not clear Content so callers can still
    /// inspect model text after a post-generation validation failure.
    /// </summary>
    procedure SetError(ErrorType: Enum "AIOS Error Type"; Message: Text)
    begin
        "Error Type" := ErrorType;
        "Error Message" := CopyStr(Message, 1, MaxStrLen("Error Message"));
    end;

    procedure ClearError()
    begin
        "Error Type" := "Error Type"::None;
        "Error Message" := '';
    end;

    procedure IsSuccess(): Boolean
    begin
        exit("Error Type" = "Error Type"::None);
    end;

    procedure AddWarning(WarningType: Text; Feature: Text; Message: Text)
    var
        WarningsArray: JsonArray;
        Warning: JsonObject;
    begin
        WarningsArray := GetWarnings();
        Clear(Warning);
        Warning.Add('type', WarningType);
        Warning.Add('feature', Feature);
        Warning.Add('message', Message);
        WarningsArray.Add(Warning);
        SetWarnings(WarningsArray);
    end;

    procedure AppendWarnings(var Source: JsonArray)
    var
        WarningsArray: JsonArray;
        Token: JsonToken;
        WarningObj: JsonObject;
        i: Integer;
    begin
        if Source.Count() = 0 then
            exit;
        WarningsArray := GetWarnings();
        for i := 0 to Source.Count() - 1 do begin
            Source.Get(i, Token);
            WarningObj := Token.AsObject();
            WarningsArray.Add(WarningObj);
        end;
        SetWarnings(WarningsArray);
    end;

    procedure GetWarnings(): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        WarningsArray: JsonArray;
        Text: Text;
    begin
        if not Warnings.HasValue then
            exit(WarningsArray);
        Warnings.CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(WarningsArray);
        if not WarningsArray.ReadFrom(Text) then
            Clear(WarningsArray);
        exit(WarningsArray);
    end;

    procedure ClearWarnings()
    begin
        Clear(Warnings);
    end;

    /// <summary>
    /// Persists parsed tool calls as JSON on the response (internal wire format).
    /// </summary>
    procedure SetToolCallsJson(ToolCallsArr: JsonArray)
    var
        OutStream: OutStream;
        Text: Text;
    begin
        Clear("Tool Calls");
        if ToolCallsArr.Count() = 0 then
            exit;
        ToolCallsArr.WriteTo(Text);
        "Tool Calls".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    /// <summary>
    /// Tool calls JSON blob stored on the response.
    /// </summary>
    procedure GetToolCallsJson(): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        ToolCallsArr: JsonArray;
        Text: Text;
    begin
        if not "Tool Calls".HasValue then
            exit(ToolCallsArr);
        "Tool Calls".CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(ToolCallsArr);
        if not ToolCallsArr.ReadFrom(Text) then
            Clear(ToolCallsArr);
        exit(ToolCallsArr);
    end;

    /// <summary>
    /// True when the model returned one or more tool calls.
    /// </summary>
    procedure HasToolCalls(): Boolean
    begin
        exit(GetToolCallsJson().Count() > 0);
    end;

    /// <summary>
    /// Tool calls from the model as "AIOS Tool Call" instances.
    /// </summary>
    procedure GetToolCalls(): List of [Codeunit "AIOS Tool Call"]
    var
        Result: List of [Codeunit "AIOS Tool Call"];
        ToolCallsArr: JsonArray;
        CallToken: JsonToken;
        CallObj: JsonObject;
        CallCU: Codeunit "AIOS Tool Call";
        IdToken: JsonToken;
        NameToken: JsonToken;
        ArgsToken: JsonToken;
        ArgsObj: JsonObject;
        ArgsText: Text;
        Id: Text;
        Name: Text;
        i: Integer;
    begin
        ToolCallsArr := GetToolCallsJson();
        for i := 0 to ToolCallsArr.Count() - 1 do begin
            ToolCallsArr.Get(i, CallToken);
            CallObj := CallToken.AsObject();
            Id := '';
            Name := '';
            if CallObj.Get('id', IdToken) then
                Id := IdToken.AsValue().AsText();
            if CallObj.Get('name', NameToken) then
                Name := NameToken.AsValue().AsText();
            Clear(ArgsObj);
            if CallObj.Get('arguments', ArgsToken) then
                if ArgsToken.IsObject() then
                    ArgsObj := ArgsToken.AsObject()
                else begin
                    ArgsText := ArgsToken.AsValue().AsText();
                    if not ArgsObj.ReadFrom(ArgsText) then
                        Clear(ArgsObj);
                end;
            Clear(CallCU);
            CallCU.SetCall(Id, Name, ArgsObj);
            Result.Add(CallCU);
        end;
        exit(Result);
    end;

    /// <summary>
    /// Writes tool calls from codeunit instances into the response blob.
    /// </summary>
    procedure SetToolCallsFromList(ToolCalls: List of [Codeunit "AIOS Tool Call"])
    var
        ToolCallsArr: JsonArray;
        CallObj: JsonObject;
        CallCU: Codeunit "AIOS Tool Call";
        Args: JsonObject;
        i: Integer;
    begin
        for i := 1 to ToolCalls.Count() do begin
            ToolCalls.Get(i, CallCU);
            Clear(CallObj);
            CallObj.Add('id', CallCU.GetId());
            CallObj.Add('name', CallCU.GetName());
            Args := CallCU.GetArguments();
            CallObj.Add('arguments', Args);
            ToolCallsArr.Add(CallObj);
        end;
        SetToolCallsJson(ToolCallsArr);
    end;

    /// <summary>
    /// Thinking/reasoning text from models that return reasoning_content (must be echoed on tool-loop turns).
    /// </summary>
    procedure SetReasoningContent(Value: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Reasoning Content");
        if Value = '' then
            exit;
        "Reasoning Content".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Value);
    end;

    /// <summary>
    /// Reasoning content from the last assistant message, when the provider returned it.
    /// </summary>
    procedure GetReasoningContent(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not "Reasoning Content".HasValue then
            exit('');
        "Reasoning Content".CreateInStream(InStream, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    local procedure SetWarnings(var WarningsArray: JsonArray)
    var
        OutStream: OutStream;
        Text: Text;
    begin
        Clear(Warnings);
        if WarningsArray.Count() = 0 then
            exit;
        WarningsArray.WriteTo(Text);
        Warnings.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;
}

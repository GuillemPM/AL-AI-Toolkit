namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

/// <summary>
/// Conversation history on "AIOS Chat Request" (system/user/assistant/tool roles).
/// </summary>
codeunit 87428 "AIOS Chat Messages"
{
    Access = Public;

    procedure GetMessages(var Request: Record "AIOS Chat Request"): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        MessagesArr: JsonArray;
        Text: Text;
    begin
        if not Request.Messages.HasValue then
            exit(MessagesArr);
        Request.Messages.CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(MessagesArr);
        if not MessagesArr.ReadFrom(Text) then
            Clear(MessagesArr);
        exit(MessagesArr);
    end;

    procedure HasMessages(var Request: Record "AIOS Chat Request"): Boolean
    begin
        exit(GetMessages(Request).Count() > 0);
    end;

    procedure ClearMessages(var Request: Record "AIOS Chat Request")
    begin
        Clear(Request.Messages);
    end;

    procedure SetMessages(var Request: Record "AIOS Chat Request"; MessagesArr: JsonArray)
    var
        OutStream: OutStream;
        Text: Text;
    begin
        Clear(Request.Messages);
        if MessagesArr.Count() = 0 then
            exit;
        MessagesArr.WriteTo(Text);
        Request.Messages.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    procedure AppendUserMessage(var Request: Record "AIOS Chat Request"; Content: Text)
    var
        MessagesArr: JsonArray;
        Msg: JsonObject;
    begin
        MessagesArr := GetMessages(Request);
        Msg.Add('role', 'user');
        Msg.Add('content', Content);
        MessagesArr.Add(Msg);
        SetMessages(Request, MessagesArr);
    end;

    procedure AppendAssistantMessage(var Request: Record "AIOS Chat Request"; Content: Text)
    var
        MessagesArr: JsonArray;
        Msg: JsonObject;
    begin
        MessagesArr := GetMessages(Request);
        Msg.Add('role', 'assistant');
        Msg.Add('content', Content);
        MessagesArr.Add(Msg);
        SetMessages(Request, MessagesArr);
    end;

    procedure AppendAssistantToolCalls(var Request: Record "AIOS Chat Request"; Content: Text; ToolCalls: List of [Codeunit "AIOS Tool Call"])
    begin
        AppendAssistantToolCalls(Request, Content, ToolCalls, '');
    end;

    procedure AppendAssistantToolCalls(var Request: Record "AIOS Chat Request"; Content: Text; ToolCalls: List of [Codeunit "AIOS Tool Call"]; ReasoningContent: Text)
    var
        MessagesArr: JsonArray;
        Msg: JsonObject;
        CallsArr: JsonArray;
        CallObj: JsonObject;
        CallCU: Codeunit "AIOS Tool Call";
        Args: JsonObject;
        i: Integer;
    begin
        MessagesArr := GetMessages(Request);
        for i := 1 to ToolCalls.Count() do begin
            ToolCalls.Get(i, CallCU);
            Clear(CallObj);
            CallObj.Add('id', CallCU.GetId());
            CallObj.Add('name', CallCU.GetName());
            Args := CallCU.GetArguments();
            CallObj.Add('arguments', Args);
            CallsArr.Add(CallObj);
        end;
        Msg.Add('role', 'assistant');
        Msg.Add('content', Content);
        Msg.Add('tool_calls', CallsArr);
        Msg.Add('reasoning_content', ReasoningContent);
        MessagesArr.Add(Msg);
        SetMessages(Request, MessagesArr);
    end;

    procedure AppendToolResult(var Request: Record "AIOS Chat Request"; ToolCallId: Text; ToolName: Text; Content: Text)
    var
        MessagesArr: JsonArray;
        Msg: JsonObject;
    begin
        MessagesArr := GetMessages(Request);
        Msg.Add('role', 'tool');
        Msg.Add('tool_call_id', ToolCallId);
        Msg.Add('name', ToolName);
        Msg.Add('content', Content);
        MessagesArr.Add(Msg);
        SetMessages(Request, MessagesArr);
    end;
}

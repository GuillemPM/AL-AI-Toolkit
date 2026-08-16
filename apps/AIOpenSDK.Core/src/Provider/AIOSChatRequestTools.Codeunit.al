namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

/// <summary>
/// Tool definition binding stored on "AIOS Chat Request" for provider HTTP.
/// </summary>
codeunit 87427 "AIOS Chat Request Tools"
{
    Access = Public;

    /// <summary>
    /// Stores tool definitions from ToolSet on the request for provider HTTP.
    /// </summary>
    procedure SetTools(var Request: Record "AIOS Chat Request"; ToolSet: Codeunit "AIOS Tool Set")
    begin
        SetToolDefinitions(Request, ToolSet.GetDefinitions());
    end;

    /// <summary>
    /// Stores a JSON array of tool definitions on the request.
    /// </summary>
    procedure SetToolDefinitions(var Request: Record "AIOS Chat Request"; Definitions: JsonArray)
    var
        OutStream: OutStream;
        Text: Text;
    begin
        Clear(Request.Tools);
        if Definitions.Count() = 0 then
            exit;
        Definitions.WriteTo(Text);
        Request.Tools.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(Text);
    end;

    /// <summary>
    /// Returns tool definitions stored on the request.
    /// </summary>
    procedure GetToolDefinitions(var Request: Record "AIOS Chat Request"): JsonArray
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
        Definitions: JsonArray;
        Text: Text;
    begin
        if not Request.Tools.HasValue then
            exit(Definitions);
        Request.Tools.CreateInStream(InStream, TextEncoding::UTF8);
        Text := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
        if Text = '' then
            exit(Definitions);
        if not Definitions.ReadFrom(Text) then
            Clear(Definitions);
        exit(Definitions);
    end;

    /// <summary>
    /// Returns true when the request has one or more tool definitions.
    /// </summary>
    procedure HasTools(var Request: Record "AIOS Chat Request"): Boolean
    begin
        exit(GetToolDefinitions(Request).Count() > 0);
    end;

    /// <summary>
    /// Clears tool definitions from the request.
    /// </summary>
    procedure ClearTools(var Request: Record "AIOS Chat Request")
    begin
        Clear(Request.Tools);
    end;
}

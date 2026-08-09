namespace PM.Guillem.AIOpenSDK.Core;

using System.Reflection;

/// <summary>
/// Tool definition binding stored on "AIOS Chat Request" for provider HTTP.
/// </summary>
codeunit 87427 "AIOS Chat Request Tools"
{
    Access = Public;

    procedure SetTools(var Request: Record "AIOS Chat Request"; ToolSet: Codeunit "AIOS Tool Set")
    begin
        SetToolDefinitions(Request, ToolSet.GetDefinitions());
    end;

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

    procedure HasTools(var Request: Record "AIOS Chat Request"): Boolean
    begin
        exit(GetToolDefinitions(Request).Count() > 0);
    end;

    procedure ClearTools(var Request: Record "AIOS Chat Request")
    begin
        Clear(Request.Tools);
    end;
}

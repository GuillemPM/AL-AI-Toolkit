namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Collection of tools for a chat request. Always pass this into GenerateText.
/// Add(Tool) — primary. Use(Handler) — secondary (once per ToolSet).
/// Add(Name, …) — escape hatch; execute via OnBeforeExecuteTool when no handler.
/// </summary>
codeunit 87417 "AIOS Tool Set"
{
    Access = Public;

    /// <summary>
    /// Primary: add one "AIOS Tool" (name, schema, and Execute on that codeunit).
    /// </summary>
    procedure Add(Tool: Interface "AIOS Tool")
    begin
        if Tool.Name() = '' then
            Error(ToolNameEmptyErr);
        if HasTool(Tool.Name()) then
            Error(DuplicateToolErr, Tool.Name());
        Tools.Add(Tool);
    end;

    /// <summary>
    /// Secondary: use a handler pack — registers GetDefinitions() and binds Execute (once per ToolSet).
    /// </summary>
    procedure Use(NewHandler: Interface "AIOS Tool Handler")
    var
        Definitions: JsonArray;
        DefToken: JsonToken;
        Definition: JsonObject;
        NameToken: JsonToken;
        DescToken: JsonToken;
        ParamsToken: JsonToken;
        Description: Text;
        Parameters: JsonObject;
        i: Integer;
    begin
        if HandlerIsSet then
            Error(HandlerAlreadySetErr);
        SetHandler(NewHandler);
        Definitions := NewHandler.GetDefinitions();
        for i := 0 to Definitions.Count() - 1 do begin
            Definitions.Get(i, DefToken);
            Definition := DefToken.AsObject();
            if not Definition.Get('name', NameToken) then
                Error(DefinitionMissingNameErr);
            Description := '';
            if Definition.Get('description', DescToken) then
                if DescToken.IsValue() then
                    Description := DescToken.AsValue().AsText();
            Clear(Parameters);
            if Definition.Get('parameters', ParamsToken) then
                if ParamsToken.IsObject() then
                    Parameters := ParamsToken.AsObject();
            AddNamedDefinition(NameToken.AsValue().AsText(), Description, Parameters);
        end;
    end;

    /// <summary>
    /// Escape hatch: named definition without an "AIOS Tool" codeunit. Prefer Add(Tool) or Use(Handler).
    /// Execute via Use handler if set, otherwise OnBeforeExecuteTool.
    /// </summary>
    procedure Add(Name: Text; Description: Text; Parameters: JsonObject)
    begin
        AddNamedDefinition(Name, Description, Parameters);
    end;

    /// <summary>
    /// Escape hatch: add from Schema.ToolDefinition (sugar for Add(Name, Description, Parameters)).
    /// </summary>
    procedure Add(Definition: JsonObject)
    var
        NameToken: JsonToken;
        DescToken: JsonToken;
        ParamsToken: JsonToken;
        Description: Text;
        Parameters: JsonObject;
    begin
        if not Definition.Get('name', NameToken) then
            Error(DefinitionMissingNameErr);
        Description := '';
        if Definition.Get('description', DescToken) then
            if DescToken.IsValue() then
                Description := DescToken.AsValue().AsText();
        Clear(Parameters);
        if Definition.Get('parameters', ParamsToken) then
            if ParamsToken.IsObject() then
                Parameters := ParamsToken.AsObject();
        AddNamedDefinition(NameToken.AsValue().AsText(), Description, Parameters);
    end;

    /// <summary>
    /// Removes all tools and any handler so the ToolSet can be rebuilt.
    /// </summary>
    procedure ClearTools()
    begin
        Clear(Tools);
        Clear(RegisteredDefinitions);
        Clear(Handler);
        HandlerIsSet := false;
    end;

    /// <summary>
    /// Number of tools (Add(Tool) + named Add/Use).
    /// </summary>
    procedure Count(): Integer
    begin
        exit(Tools.Count() + RegisteredDefinitions.Count());
    end;

    /// <summary>
    /// True when a tool with this name was added.
    /// </summary>
    procedure HasTool(Name: Text): Boolean
    var
        Tool: Interface "AIOS Tool";
    begin
        if FindInterfaceTool(Name, Tool) then
            exit(true);
        exit(FindNamedIndex(Name) >= 0);
    end;

    /// <summary>
    /// Runs a tool by name. Add(Tool) first; then handler from Use; otherwise OnBeforeExecuteTool.
    /// </summary>
    procedure Execute(Name: Text; Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Tool: Interface "AIOS Tool";
        Handled: Boolean;
        Succeeded: Boolean;
    begin
        if FindInterfaceTool(Name, Tool) then
            exit(Tool.Execute(Arguments, ResultText));

        if FindNamedIndex(Name) < 0 then
            Error(UnknownToolErr, Name);

        if HandlerIsSet then
            exit(Handler.Execute(Name, Arguments, ResultText));

        Clear(ResultText);
        Succeeded := false;
        Handled := false;
        OnBeforeExecuteTool(Name, Arguments, ResultText, Succeeded, Handled);
        if not Handled then
            Error(NoExecutorErr, Name);
        exit(Succeeded);
    end;

    /// <summary>
    /// Neutral tool definitions: name, description, parameters (JSON Schema).
    /// </summary>
    procedure GetDefinitions(): JsonArray
    var
        Schema: Codeunit "AIOS Schema";
        Definitions: JsonArray;
        DefToken: JsonToken;
        Tool: Interface "AIOS Tool";
        i: Integer;
    begin
        for i := 1 to Tools.Count() do begin
            Tools.Get(i, Tool);
            Definitions.Add(Schema.ToolDefinition(Tool.Name(), Tool.Description(), Tool.InputSchema()));
        end;
        for i := 0 to RegisteredDefinitions.Count() - 1 do begin
            RegisteredDefinitions.Get(i, DefToken);
            Definitions.Add(DefToken.AsObject());
        end;
        exit(Definitions);
    end;

    /// <summary>
    /// Raised when a named tool is executed and no handler was set via Use.
    /// Escape hatch only — prefer Add(Tool) or Use(Handler). Set Handled := true after handling.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeExecuteTool(Name: Text; Arguments: JsonObject; var ResultText: Text; var Succeeded: Boolean; var Handled: Boolean)
    begin
    end;

    local procedure SetHandler(NewHandler: Interface "AIOS Tool Handler")
    begin
        Handler := NewHandler;
        HandlerIsSet := true;
    end;

    local procedure AddNamedDefinition(Name: Text; Description: Text; Parameters: JsonObject)
    var
        Schema: Codeunit "AIOS Schema";
    begin
        if Name = '' then
            Error(ToolNameEmptyErr);
        if HasTool(Name) then
            Error(DuplicateToolErr, Name);
        RegisteredDefinitions.Add(Schema.ToolDefinition(Name, Description, Parameters));
    end;

    local procedure FindInterfaceTool(Name: Text; var Tool: Interface "AIOS Tool"): Boolean
    var
        Index: Integer;
    begin
        Index := FindInterfaceIndex(Name);
        if Index < 0 then
            exit(false);
        Tools.Get(Index, Tool);
        exit(true);
    end;

    local procedure FindInterfaceIndex(Name: Text): Integer
    var
        Tool: Interface "AIOS Tool";
        i: Integer;
    begin
        for i := 1 to Tools.Count() do begin
            Tools.Get(i, Tool);
            if Tool.Name() = Name then
                exit(i);
        end;
        exit(-1);
    end;

    local procedure FindNamedIndex(Name: Text): Integer
    var
        DefToken: JsonToken;
        NameToken: JsonToken;
        i: Integer;
    begin
        for i := 0 to RegisteredDefinitions.Count() - 1 do begin
            RegisteredDefinitions.Get(i, DefToken);
            if DefToken.AsObject().Get('name', NameToken) then
                if NameToken.AsValue().AsText() = Name then
                    exit(i);
        end;
        exit(-1);
    end;

    var
        Tools: List of [Interface "AIOS Tool"];
        RegisteredDefinitions: JsonArray;
        Handler: Interface "AIOS Tool Handler";
        HandlerIsSet: Boolean;
        ToolNameEmptyErr: Label 'Tool name cannot be empty.';
        DuplicateToolErr: Label 'Tool ''%1'' is already added.', Comment = '%1 = tool name';
        UnknownToolErr: Label 'Unknown tool ''%1''.', Comment = '%1 = tool name';
        NoExecutorErr: Label 'Tool ''%1'' has no executor. Call Use(Handler) or subscribe to OnBeforeExecuteTool.', Comment = '%1 = tool name';
        DefinitionMissingNameErr: Label 'Tool definition is missing a name.';
        HandlerAlreadySetErr: Label 'ToolSet.Use can only be called once. Combine tools in one handler, or use Add(Tool) / Add(Name, …).';
}

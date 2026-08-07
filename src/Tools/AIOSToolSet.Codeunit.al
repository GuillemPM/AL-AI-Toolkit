namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Collection of tools to register on a chat request and to Execute by name.
/// Prefer Register + SetHandler for app tools (one codeunit for many tools).
/// Use Add for reusable first-class "AIOS Tool" implementations.
/// </summary>
codeunit 87417 "AIOS Tool Set"
{
    Access = Public;

    /// <summary>
    /// Registers a reusable "AIOS Tool" codeunit (one object per tool).
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
    /// Registers a tool definition handled by SetHandler (no extra object ID per tool).
    /// </summary>
    procedure Register(Name: Text; Description: Text; Parameters: JsonObject)
    var
        Definition: JsonObject;
    begin
        if Name = '' then
            Error(ToolNameEmptyErr);
        if HasTool(Name) then
            Error(DuplicateToolErr, Name);
        Clear(Definition);
        Definition.Add('name', Name);
        Definition.Add('description', Description);
        Definition.Add('parameters', Parameters);
        RegisteredDefinitions.Add(Definition);
    end;

    /// <summary>
    /// Sets the handler used for tools added via Register.
    /// </summary>
    procedure SetHandler(NewHandler: Interface "AIOS Tool Handler")
    begin
        Handler := NewHandler;
        HandlerIsSet := true;
    end;

    /// <summary>
    /// True when SetHandler was called.
    /// </summary>
    procedure HasHandler(): Boolean
    begin
        exit(HandlerIsSet);
    end;

    /// <summary>
    /// Number of registered tools (Add + Register).
    /// </summary>
    procedure Count(): Integer
    begin
        exit(Tools.Count() + RegisteredDefinitions.Count());
    end;

    /// <summary>
    /// True when a tool with this name was added or registered.
    /// </summary>
    procedure HasTool(Name: Text): Boolean
    var
        Tool: Interface "AIOS Tool";
    begin
        if FindByName(Name, Tool) then
            exit(true);
        exit(FindRegisteredIndex(Name) >= 0);
    end;

    /// <summary>
    /// Returns an Add()'d tool at the given 1-based index (interface tools only).
    /// </summary>
    procedure Get(Index: Integer; var Tool: Interface "AIOS Tool"): Boolean
    begin
        if (Index < 1) or (Index > Tools.Count()) then
            exit(false);
        Tools.Get(Index, Tool);
        exit(true);
    end;

    /// <summary>
    /// Looks up an Add()'d "AIOS Tool" by Name() (does not resolve Register()'d names).
    /// </summary>
    procedure FindByName(Name: Text; var Tool: Interface "AIOS Tool"): Boolean
    var
        Index: Integer;
    begin
        Index := FindInterfaceIndex(Name);
        if Index < 0 then
            exit(false);
        Tools.Get(Index, Tool);
        exit(true);
    end;

    /// <summary>
    /// Runs a tool by name (Add or Register). Returns false when Execute reports failure.
    /// Raises an error when the name is unknown or a registered tool has no handler.
    /// </summary>
    procedure Execute(Name: Text; Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Tool: Interface "AIOS Tool";
    begin
        if FindByName(Name, Tool) then
            exit(Tool.Execute(Arguments, ResultText));

        if FindRegisteredIndex(Name) < 0 then
            Error(UnknownToolErr, Name);

        if not HandlerIsSet then
            Error(NoHandlerErr, Name);

        exit(Handler.Execute(Name, Arguments, ResultText));
    end;

    /// <summary>
    /// Neutral tool definitions: name, description, parameters (JSON Schema).
    /// </summary>
    procedure GetDefinitions(): JsonArray
    var
        Definitions: JsonArray;
        Definition: JsonObject;
        DefToken: JsonToken;
        Tool: Interface "AIOS Tool";
        i: Integer;
    begin
        for i := 1 to Tools.Count() do begin
            Tools.Get(i, Tool);
            Clear(Definition);
            Definition.Add('name', Tool.Name());
            Definition.Add('description', Tool.Description());
            Definition.Add('parameters', Tool.InputSchema());
            Definitions.Add(Definition);
        end;
        for i := 0 to RegisteredDefinitions.Count() - 1 do begin
            RegisteredDefinitions.Get(i, DefToken);
            Definitions.Add(DefToken.AsObject());
        end;
        exit(Definitions);
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

    local procedure FindRegisteredIndex(Name: Text): Integer
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
        DuplicateToolErr: Label 'Tool ''%1'' is already registered.', Comment = '%1 = tool name';
        UnknownToolErr: Label 'Unknown tool ''%1''.', Comment = '%1 = tool name';
        NoHandlerErr: Label 'Tool ''%1'' was registered but no tool handler was set. Call SetHandler before GenerateText.', Comment = '%1 = tool name';
}

namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Demo tool handler: get_customer_list (and room for more tools without new object IDs).
/// </summary>
codeunit 87499 "AIOS Get Customers Tool" implements "AIOS Tool Handler"
{
    Access = Public;

    /// <summary>
    /// Stable name for Register / model tool calls.
    /// </summary>
    procedure ToolName(): Text
    begin
        exit('get_customer_list');
    end;

    /// <summary>
    /// Description for Register (model tool selection).
    /// </summary>
    procedure ToolDescription(): Text
    begin
        exit('Returns a JSON array of customers from Business Central (number and name). Use when the user asks about customers or accounts.');
    end;

    /// <summary>
    /// Optional maxCount (1–100) and searchName filter on Customer.Name.
    /// </summary>
    procedure ToolInputSchema(): JsonObject
    var
        Schema: Codeunit "AIOS Schema";
        MaxCountSchema: JsonObject;
        Fields: List of [JsonObject];
    begin
        MaxCountSchema := Schema.Integer();
        MaxCountSchema.Add('minimum', 1);
        MaxCountSchema.Add('maximum', 100);
        Fields.Add(Schema.OptionalField('maxCount', MaxCountSchema));
        Fields.Add(Schema.OptionalField('searchName', Schema.String()));
        exit(Schema.Object(Fields));
    end;

    /// <summary>
    /// Dispatches registered demo tools by name.
    /// </summary>
    procedure Execute(Name: Text; Arguments: JsonObject; var ResultText: Text): Boolean
    begin
        case Name of
            'get_customer_list':
                exit(GetCustomerList(Arguments, ResultText));
            else begin
                ResultText := StrSubstNo(UnknownToolErr, Name);
                exit(false);
            end;
        end;
    end;

    local procedure GetCustomerList(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        CustomerRef: RecordRef;
        NameFieldRef: FieldRef;
        Customers: JsonArray;
        Entry: JsonObject;
        Token: JsonToken;
        SearchName: Text;
        MaxCount: Integer;
        Taken: Integer;
        CustomerNo: Code[20];
        CustomerName: Text[100];
    begin
        MaxCount := 25;
        if Arguments.Get('maxCount', Token) then
            if Token.IsValue() then
                MaxCount := Token.AsValue().AsInteger();
        if MaxCount < 1 then
            MaxCount := 25;
        if MaxCount > 100 then
            MaxCount := 100;

        if Arguments.Get('searchName', Token) then
            if Token.IsValue() then
                SearchName := Token.AsValue().AsText();

        // Customer table / No. / Name field ids (standard BC).
        CustomerRef.Open(18);
        if SearchName <> '' then begin
            NameFieldRef := CustomerRef.Field(2);
            NameFieldRef.SetFilter('@*' + SearchName + '*');
        end;

        Taken := 0;
        if CustomerRef.FindSet() then
            repeat
                CustomerNo := CustomerRef.Field(1).Value();
                CustomerName := CustomerRef.Field(2).Value();
                Clear(Entry);
                Entry.Add('no', CustomerNo);
                Entry.Add('name', CustomerName);
                Customers.Add(Entry);
                Taken += 1;
            until (Taken >= MaxCount) or (CustomerRef.Next() = 0);

        Clear(ResultText);
        Customers.WriteTo(ResultText);
        exit(true);
    end;

    var
        UnknownToolErr: Label 'Unknown tool %1.', Comment = '%1 = tool name';
}

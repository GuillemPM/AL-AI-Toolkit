namespace PM.Guillem.AIOpenSDK.Examples;

using PM.Guillem.AIOpenSDK.Core;
using Microsoft.Sales.Customer;

/// <summary>
/// Primary pattern: one codeunit implements "AIOS Tool", register with ToolSet.Add(Tool).
/// </summary>
codeunit 87499 "AIOS Get Customers Tool" implements "AIOS Tool"
{
    Access = Public;

    /// <summary>
    /// Returns the tool name sent to the model.
    /// </summary>
    procedure Name(): Text
    begin
        exit('get_customer_list');
    end;

    /// <summary>
    /// Returns the human-readable tool description used for tool selection.
    /// </summary>
    procedure Description(): Text
    begin
        exit('Returns a JSON array of customers from Business Central (number and name). Use when the user asks about customers or accounts.');
    end;

    /// <summary>
    /// Returns the JSON Schema for tool arguments.
    /// </summary>
    procedure InputSchema(): JsonObject
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
    /// Runs the customer lookup and writes the result into ResultText. Returns false on failure.
    /// </summary>
    procedure Execute(Arguments: JsonObject; var ResultText: Text): Boolean
    var
        Args: Codeunit "AIOS Tool Args";
        CustomerRef: RecordRef;
        NameFieldRef: FieldRef;
        Customers: JsonArray;
        Entry: JsonObject;
        SearchName: Text;
        MaxCount: Integer;
        Taken: Integer;
        CustomerNo: Code[20];
        CustomerName: Text[100];
    begin
        MaxCount := 25;
        if Args.TryGetInteger(Arguments, 'maxCount', MaxCount) then begin
            if MaxCount < 1 then
                MaxCount := 25;
            if MaxCount > 100 then
                MaxCount := 100;
        end else
            MaxCount := 25;

        SearchName := '';
        Args.TryGetText(Arguments, 'searchName', SearchName);

        CustomerRef.Open(Database::Customer);
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
}

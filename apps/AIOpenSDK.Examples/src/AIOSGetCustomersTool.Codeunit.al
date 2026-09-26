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
        Customer: Record Customer;
        Customers: JsonArray;
        Entry: JsonObject;
        SearchName: Text;
        MaxCount: Integer;
        Taken: Integer;
    begin
        if not Customer.ReadPermission() then begin
            ResultText := NoReadPermissionErr;
            exit(false);
        end;

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
        SearchName := CopyStr(SearchName.Trim(), 1, MaxStrLen(Customer.Name));

        Customer.SetLoadFields("No.", Name);
        if SearchName <> '' then
            Customer.SetFilter(Name, '@*' + EscapeFilterValue(SearchName) + '*');

        Taken := 0;
        if Customer.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('no', Customer."No.");
                Entry.Add('name', Customer.Name);
                Customers.Add(Entry);
                Taken += 1;
            until (Taken >= MaxCount) or (Customer.Next() = 0);

        Clear(ResultText);
        Customers.WriteTo(ResultText);
        exit(true);
    end;

    /// <summary>
    /// Model arguments are untrusted: replace every filter metacharacter with the single-character
    /// wildcard so the value can only match literally (for example "Smith &amp; Sons" still matches itself)
    /// and can never add OR/range/comparison clauses or break the filter syntax.
    /// </summary>
    local procedure EscapeFilterValue(Value: Text): Text
    begin
        exit(ConvertStr(Value, FilterMetaCharsTok, PadStr('', StrLen(FilterMetaCharsTok), '?')));
    end;

    var
        FilterMetaCharsTok: Label '|&<>=()''".*@%', Locked = true;
        NoReadPermissionErr: Label 'You do not have permission to read customers.';
}

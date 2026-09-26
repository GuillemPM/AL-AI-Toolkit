namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Examples;
using PM.Guillem.AIOpenSDK.Provider.Mock;
using Microsoft.Sales.Customer;

/// <summary>
/// Tests for Examples app samples: customer tool filtering, demo image history, lifecycle sample.
/// </summary>
codeunit 87502 "AIOS Examples Tests"
{

    Access = Internal;
    Subtype = Test;

    [Test]
    procedure GetCustomersTool_SearchName_MatchesLiterallyWithFilterCharacters()
    var
        ResultText: Text;
    begin
        InsertCustomer(AlphaNoTok, 'Alpha & Sons (UK)');
        InsertCustomer(BetaNoTok, 'Beta Trading');

        ResultText := RunGetCustomers('alpha & sons (uk)');
        AssertContains(ResultText, AlphaNoTok);
        AssertNotContains(ResultText, BetaNoTok);
    end;

    [Test]
    procedure GetCustomersTool_SearchName_CannotInjectOrClause()
    var
        ResultText: Text;
    begin
        InsertCustomer(BetaNoTok, 'Beta Trading');

        ResultText := RunGetCustomers('zzz|Beta');
        AssertNotContains(ResultText, BetaNoTok);
    end;

    [Test]
    procedure GetCustomersTool_SearchName_UnbalancedSyntaxDoesNotError()
    var
        Customers: JsonArray;
        ResultText: Text;
    begin
        InsertCustomer(GammaNoTok, 'Gamma (''..<) Ltd');

        ResultText := RunGetCustomers('Gamma (''..<)');
        if not Customers.ReadFrom(ResultText) then
            Error(ExpectedJsonArrayErr, ResultText);
        AssertContains(ResultText, GammaNoTok);
    end;

    [Test]
    procedure DemoHistory_ImportPicturesFromGeneratedImages_KeepsEveryBatch()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Image Request";
        Result: Codeunit "AIOS Generate Image Result";
        History: Record "AIOS Demo History";
        Imported: Integer;
    begin
        Request.SetPrompt('three images');
        Request.SetImageCount(3);
        Result := Client.GenerateImage(Mock.ImageModel('mock-image'), Request);

        History.Init();
        History.Insert(true);
        Imported := History.ImportPicturesFromGeneratedImages(Result.GetImages());
        if Imported <> 3 then
            Error(UnexpectedCountErr, 3, Imported);
        if History.Pictures.Count() <> 3 then
            Error(UnexpectedCountErr, 3, History.Pictures.Count());
    end;

    [Test]
    procedure LifecycleExample_Bound_TracesLastGenerateOnly()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        LifecycleExample: Codeunit "AIOS Lifecycle Example";
    begin
        Mock.SetNextResponse('ok');
        BindSubscription(LifecycleExample);
        Client.GenerateText(Mock.Model('demo-model'), 'first');
        Client.GenerateText(Mock.Model('demo-model'), 'second');
        UnbindSubscription(LifecycleExample);

        if LifecycleExample.GetLastEventTrace() <> OneGenerateTraceTok then
            Error(UnexpectedTextErr, OneGenerateTraceTok, LifecycleExample.GetLastEventTrace());
        if LifecycleExample.GetLastModelId() <> 'demo-model' then
            Error(UnexpectedTextErr, 'demo-model', LifecycleExample.GetLastModelId());
    end;

    [Test]
    procedure LifecycleExample_Unbound_DoesNotRecord()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        LifecycleExample: Codeunit "AIOS Lifecycle Example";
    begin
        Mock.SetNextResponse('ok');
        Client.GenerateText(Mock.Model('demo-model'), 'not observed');

        if LifecycleExample.GetLastEventTrace() <> '' then
            Error(UnexpectedTextErr, '', LifecycleExample.GetLastEventTrace());
    end;

    local procedure InsertCustomer(CustomerNo: Code[20]; CustomerName: Text[100])
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            Customer.Delete();
        Customer.Init();
        Customer."No." := CustomerNo;
        Customer.Name := CustomerName;
        Customer.Insert(false);
    end;

    local procedure RunGetCustomers(SearchName: Text): Text
    var
        GetCustomers: Codeunit "AIOS Get Customers Tool";
        Arguments: JsonObject;
        ResultText: Text;
    begin
        Arguments.Add('searchName', SearchName);
        Arguments.Add('maxCount', 100);
        if not GetCustomers.Execute(Arguments, ResultText) then
            Error(ToolFailedErr, ResultText);
        exit(ResultText);
    end;

    local procedure AssertContains(Value: Text; Expected: Text)
    begin
        if StrPos(Value, Expected) = 0 then
            Error(ExpectedContainsErr, Expected, Value);
    end;

    local procedure AssertNotContains(Value: Text; Unexpected: Text)
    begin
        if StrPos(Value, Unexpected) <> 0 then
            Error(UnexpectedContainsErr, Unexpected, Value);
    end;

    var
        AlphaNoTok: Label 'AIOSTSTALPHA', Locked = true;
        BetaNoTok: Label 'AIOSTSTBETA', Locked = true;
        GammaNoTok: Label 'AIOSTSTGAMMA', Locked = true;
        OneGenerateTraceTok: Label 'OnBeforeGenerate|OnBeforeLanguageModelCall|OnAfterLanguageModelCall|OnAfterGenerate', Locked = true;
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        ExpectedJsonArrayErr: Label 'Expected a JSON array, got ''%1''.', Comment = '%1 = tool result';
        ToolFailedErr: Label 'get_customer_list failed: %1', Comment = '%1 = tool result';
        ExpectedContainsErr: Label 'Expected ''%1'' in ''%2''.', Comment = '%1 = expected fragment, %2 = actual';
        UnexpectedContainsErr: Label 'Did not expect ''%1'' in ''%2''.', Comment = '%1 = unexpected fragment, %2 = actual';
}

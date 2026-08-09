namespace PM.Guillem.AIOpenSDK.Test;

using PM.Guillem.AIOpenSDK.Core;
using PM.Guillem.AIOpenSDK.Provider.Mock;

codeunit 87495 "AIOS Image Tests"
{

    Access = Internal;
    Subtype = Test;

    [Test]
    procedure GenerateImage_ReturnsBase64InList()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Image Request";
        Result: Codeunit "AIOS Generate Image Result";
        Images: List of [Codeunit "AIOS Generated Image"];
        ImageCU: Codeunit "AIOS Generated Image";
        Expected: Text;
    begin
        Expected := 'test-base64-payload';
        Mock.SetNextImageBase64(Expected, 'image/png');
        Request.SetPrompt('A red circle');

        Result := Client.GenerateImage(Mock.ImageModel('mock-image'), Request);
        Images := Result.GetImages();

        if Images.Count() <> 1 then
            Error(UnexpectedCountErr, 1, Images.Count());
        Images.Get(1, ImageCU);
        if ImageCU.Base64() <> Expected then
            Error(UnexpectedTextErr, Expected, ImageCU.Base64());
        if ImageCU.MediaType() <> 'image/png' then
            Error(UnexpectedTextErr, 'image/png', ImageCU.MediaType());
    end;

    [Test]
    procedure GenerateImage_GetImage_ReturnsFirstFile()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Result: Codeunit "AIOS Generate Image Result";
        ImageCU: Codeunit "AIOS Generated Image";
    begin
        Mock.SetNextImageBase64('abc', 'image/jpeg');
        Result := Client.GenerateImage(Mock.ImageModel('mock-image'), 'hello');
        ImageCU := Result.GetImage();
        if ImageCU.Base64() <> 'abc' then
            Error(UnexpectedTextErr, 'abc', ImageCU.Base64());
    end;

    [Test]
    procedure GenerateImage_MultipleBatches_MergesImagesAndUsage()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Image Request";
        Result: Codeunit "AIOS Generate Image Result";
        Usage: Codeunit "AIOS Image Usage";
        Calls: List of [Codeunit "AIOS Image Response Call"];
    begin
        Mock.SetNextImageBase64('img', 'image/png');
        Request.SetPrompt('batch');
        Request.SetImageCount(3);
        Request.SetMaxImagesPerCall(1);

        Result := Client.GenerateImage(Mock.ImageModel('mock-image'), Request);
        Usage := Result.GetUsage();
        Calls := Result.GetResponseCalls();

        if Result.GetImages().Count() <> 3 then
            Error(UnexpectedCountErr, 3, Result.GetImages().Count());
        if Usage.ImagesGenerated() <> 3 then
            Error(UnexpectedCountErr, 3, Usage.ImagesGenerated());
        if Calls.Count() <> 3 then
            Error(UnexpectedCountErr, 3, Calls.Count());
    end;

    [Test]
    procedure GenerateImage_ErrorsOnMockFailure()
    var
        Mock: Codeunit "AIOS Mock";
        Client: Codeunit "AIOS Client";
        Request: Record "AIOS Image Request";
    begin
        Mock.SetNextError("AIOS Error Type"::ProviderUnavailable, 'simulated');
        Request.SetPrompt('fail');
        asserterror Client.GenerateImage(Mock.ImageModel('mock-image'), Request);
        if StrPos(GetLastErrorText(), 'simulated') = 0 then
            Error(ExpectedFailureErr);
    end;

    var
        UnexpectedCountErr: Label 'Expected count %1, got %2.', Comment = '%1 = expected, %2 = actual';
        UnexpectedTextErr: Label 'Expected ''%1'', got ''%2''.', Comment = '%1 = expected, %2 = actual';
        ExpectedFailureErr: Label 'GenerateImage should error with the mock failure message.';
}

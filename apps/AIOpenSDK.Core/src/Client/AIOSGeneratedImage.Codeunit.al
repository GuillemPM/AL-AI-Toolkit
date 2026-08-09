namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// One generated image file (base64 payload and media type).
/// </summary>
codeunit 87407 "AIOS Generated Image"
{
    Access = Public;

    internal procedure SetContent(NewBase64: Text; NewMediaType: Text; NewRevisedPrompt: Text)
    begin
        Base64Text := NewBase64;
        MediaTypeText := NewMediaType;
        RevisedPromptText := NewRevisedPrompt;
    end;

    /// <summary>
    /// Base64-encoded image bytes.
    /// </summary>
    procedure Base64(): Text
    begin
        exit(Base64Text);
    end;

    /// <summary>
    /// MIME type of the image (e.g. image/png).
    /// </summary>
    procedure MediaType(): Text
    begin
        exit(MediaTypeText);
    end;

    /// <summary>
    /// Provider revised prompt when returned.
    /// </summary>
    procedure RevisedPrompt(): Text
    begin
        exit(RevisedPromptText);
    end;

    trigger OnRun()
    begin
        Error(OnRunErr);
    end;

    var
        Base64Text: Text;
        MediaTypeText: Text;
        RevisedPromptText: Text;
        OnRunErr: Label 'Use AIOS Client.GenerateImage, not Codeunit.Run, on AIOS Generated Image.';
}

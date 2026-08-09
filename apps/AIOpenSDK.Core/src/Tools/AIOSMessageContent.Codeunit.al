namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Neutral media-type helpers for AIOS FileParts. Provider wire mapping lives in provider format codeunits.
/// </summary>
codeunit 87421 "AIOS Message Content"
{
    Access = Public;

    /// <summary>
    /// True when media type is an image (image/* or bare "image").
    /// </summary>
    procedure IsImageMediaType(MediaType: Text): Boolean
    var
        Lower: Text;
    begin
        Lower := LowerCase(MediaType);
        exit((Lower = 'image') or (CopyStr(Lower, 1, 6) = 'image/'));
    end;

    /// <summary>
    /// True when media type is PDF.
    /// </summary>
    procedure IsPdfMediaType(MediaType: Text): Boolean
    begin
        exit(LowerCase(MediaType) = 'application/pdf');
    end;

    /// <summary>
    /// True when media type is text/* (stored/sent as text, not binary file).
    /// </summary>
    procedure IsTextMediaType(MediaType: Text): Boolean
    var
        Lower: Text;
    begin
        Lower := LowerCase(MediaType);
        exit((Lower = 'text') or (CopyStr(Lower, 1, 5) = 'text/'));
    end;
}

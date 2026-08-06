namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Maps HTTP status codes from provider responses to AIOS Error Type.
/// </summary>
codeunit 87464 "AIOS Http Error Mapper"
{
    Access = Internal;

    /// <summary>
    /// Maps a provider HTTP status code to the toolkit error enum.
    /// </summary>
    procedure FromHttpStatus(StatusCode: Integer): Enum "AIOS Error Type"
    begin
        case StatusCode of
            401, 403:
                exit("AIOS Error Type"::AuthenticationFailed);
            429:
                exit("AIOS Error Type"::RateLimited);
            400, 404, 422:
                exit("AIOS Error Type"::InvalidRequest);
            408, 504:
                exit("AIOS Error Type"::Timeout);
            500, 502, 503:
                exit("AIOS Error Type"::ProviderUnavailable);
            else
                exit("AIOS Error Type"::Unknown);
        end;
    end;

    /// <summary>
    /// Truncates a response body for storage on Error Message fields.
    /// </summary>
    procedure PreviewBody(ResponseText: Text): Text[250]
    begin
        exit(CopyStr(ResponseText, 1, 250));
    end;

    /// <summary>
    /// Sets Parse/provider error on a chat response from HTTP status + body.
    /// </summary>
    procedure Apply(StatusCode: Integer; ResponseText: Text; var Response: Record "AIOS Chat Response")
    begin
        Response.SetError(FromHttpStatus(StatusCode), PreviewBody(ResponseText));
    end;

    /// <summary>
    /// Sets provider error on an image response from HTTP status + body.
    /// </summary>
    procedure Apply(StatusCode: Integer; ResponseText: Text; var Response: Record "AIOS Image Response")
    begin
        Response.SetError(FromHttpStatus(StatusCode), PreviewBody(ResponseText));
    end;
}

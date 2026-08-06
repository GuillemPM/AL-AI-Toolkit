namespace PM.Guillem.AIOpenSDK.Core;

/// <summary>
/// Aggregated token and image counts for a GenerateImage operation.
/// </summary>
codeunit 87414 "AIOS Image Usage"
{
    Access = Public;

    procedure ClearUsage()
    begin
        ImagesGeneratedCount := 0;
        InputTokenCount := 0;
        OutputTokenCount := 0;
        TotalTokenCount := 0;
    end;

    internal procedure Add(Other: Codeunit "AIOS Image Usage")
    begin
        InputTokenCount += Other.InputTokens();
        OutputTokenCount += Other.OutputTokens();
        TotalTokenCount += Other.TotalTokens();
    end;

    internal procedure SetImagesGenerated(Count: Integer)
    begin
        ImagesGeneratedCount := Count;
    end;

    internal procedure SetInputTokens(Count: Integer)
    begin
        InputTokenCount := Count;
    end;

    internal procedure SetOutputTokens(Count: Integer)
    begin
        OutputTokenCount := Count;
    end;

    internal procedure SetTotalTokens(Count: Integer)
    begin
        TotalTokenCount := Count;
    end;

    procedure ImagesGenerated(): Integer
    begin
        exit(ImagesGeneratedCount);
    end;

    procedure InputTokens(): Integer
    begin
        exit(InputTokenCount);
    end;

    procedure OutputTokens(): Integer
    begin
        exit(OutputTokenCount);
    end;

    procedure TotalTokens(): Integer
    begin
        exit(TotalTokenCount);
    end;

    trigger OnRun()
    begin
        Error(OnRunErr);
    end;

    var
        ImagesGeneratedCount: Integer;
        InputTokenCount: Integer;
        OutputTokenCount: Integer;
        TotalTokenCount: Integer;
        OnRunErr: Label 'Use GenerateImage result GetUsage, not Codeunit.Run.';
}

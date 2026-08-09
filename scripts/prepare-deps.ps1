# Package Core (+ ProviderUtils) into the shared .alpackages cache so you can
# work on a single provider app without compiling the whole stack.
# Usage (PowerShell):  .\scripts\prepare-deps.ps1
# Optional:            $env:ALC = 'C:\path\to\alc.exe'

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Cache = Join-Path $Root '.alpackages'

function Find-Alc {
    if ($env:ALC -and (Test-Path -LiteralPath $env:ALC)) {
        return $env:ALC
    }

    $roots = @(
        (Join-Path $env:USERPROFILE '.vscode\extensions'),
        (Join-Path $env:USERPROFILE '.vscode-server\extensions'),
        (Join-Path $env:USERPROFILE '.cursor\extensions'),
        (Join-Path $env:USERPROFILE '.cursor-server\extensions')
    )

    $candidates = foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r)) { continue }
        Get-ChildItem -Path $r -Directory -Filter 'ms-dynamics-smb.al-*' -ErrorAction SilentlyContinue |
            ForEach-Object {
                $win = Join-Path $_.FullName 'bin\win32\alc.exe'
                if (Test-Path -LiteralPath $win) { $win }
            }
    }

    if (-not $candidates) {
        throw "alc.exe not found. Install the AL Language extension or set `$env:ALC to alc.exe."
    }

    # Prefer newest extension folder name
    return ($candidates | Sort-Object -Descending | Select-Object -First 1)
}

function Invoke-PackageApp([string]$Project) {
    $name = Split-Path -Leaf $Project
    Write-Host "==> Packaging $name"
    & $script:Alc `
        "/project:$Project" `
        "/packagecachepath:$Cache" `
        "/outfolder:$Cache" `
        "/errorsonlyinconsole"
    if ($LASTEXITCODE -ne 0) {
        throw "alc failed for $name (exit $LASTEXITCODE)"
    }
}

New-Item -ItemType Directory -Force -Path $Cache | Out-Null
$script:Alc = Find-Alc
Write-Host "Using alc: $script:Alc"
Write-Host "Package cache: $Cache"

$msApps = Get-ChildItem -Path $Cache -Filter 'Microsoft_Application_*.app' -ErrorAction SilentlyContinue
if (-not $msApps) {
    throw @"
No Microsoft Application symbols in $Cache.
Open apps\AIOpenSDK.Core, run AL: Download Symbols, then re-run this script.
"@
}

Invoke-PackageApp (Join-Path $Root 'apps\AIOpenSDK.Core')
Invoke-PackageApp (Join-Path $Root 'apps\AIOpenSDK.ProviderUtils')

Write-Host ""
Write-Host "Done. Core + ProviderUtils are in $Cache."
Write-Host "You can open a single provider under apps\ and Package/Publish it."
Write-Host "Docs: docs\DEVELOPMENT.md"

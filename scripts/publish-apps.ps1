# Package and publish AI Open SDK apps to Business Central (dev endpoint).
# Same deployment path VS Code uses for F5 / AL: Publish.
#
# Usage (from repo root):
#   .\scripts\publish-apps.ps1
#   .\scripts\publish-apps.ps1 -Set all
#   .\scripts\publish-apps.ps1 -Apps AIOpenSDK.Core,AIOpenSDK.Provider.OpenAI
#   .\scripts\publish-apps.ps1 -PackageOnly
#
# Target (first match wins):
#   1) -Server / -ServerInstance / -Port / -Authentication parameters
#   2) BC_SERVER, BC_SERVER_INSTANCE, BC_PORT, BC_AUTHENTICATION env vars
#   3) launch.json (default: apps/AIOpenSDK.Core/.vscode/launch.json)
#
# Credentials (UserPassword):
#   -Credential, or BC_USERNAME + BC_PASSWORD, or interactive prompt
# Bearer (optional, SaaS / AAD token you already have):
#   BC_ACCESS_TOKEN
#
# Optional: $env:ALC = path to alc.exe

[CmdletBinding()]
param(
    [ValidateSet('runtime', 'all', 'core', 'providers')]
    [string]$Set = 'runtime',

    [string[]]$Apps,

    [string]$LaunchJson = '',

    [ValidateSet('Synchronize', 'Recreate', 'ForceSync')]
    [string]$SchemaUpdateMode = 'Synchronize',

    [ValidateSet('Default', 'Ignore', 'Strict')]
    [string]$DependencyPublishingOption = 'Default',

    [string]$Server = '',
    [string]$ServerInstance = '',
    [int]$Port = 0,
    [ValidateSet('', 'UserPassword', 'Windows', 'AAD')]
    [string]$Authentication = '',

    [string]$EnvironmentType = '',
    [string]$EnvironmentName = '',
    [string]$Tenant = '',

    [pscredential]$Credential,

    [switch]$PackageOnly,
    [switch]$SkipPackage
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Cache = Join-Path $Root '.alpackages'

$AllApps = @(
    'AIOpenSDK.Core'
    'AIOpenSDK.ProviderUtils'
    'AIOpenSDK.Provider.OpenAI'
    'AIOpenSDK.Provider.Anthropic'
    'AIOpenSDK.Provider.OpenAICompatible'
    'AIOpenSDK.Provider.OpenCodeZen'
    'AIOpenSDK.Examples'
    'AIOpenSDK.Test'
)

$RuntimeApps = @(
    'AIOpenSDK.Core'
    'AIOpenSDK.ProviderUtils'
    'AIOpenSDK.Provider.OpenAI'
    'AIOpenSDK.Provider.Anthropic'
    'AIOpenSDK.Provider.OpenAICompatible'
    'AIOpenSDK.Provider.OpenCodeZen'
)

function Resolve-AppList {
    if ($Apps -and $Apps.Count -gt 0) {
        return @($Apps | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    switch ($Set) {
        'all' { return $AllApps }
        'core' { return @('AIOpenSDK.Core') }
        'providers' {
            return @(
                'AIOpenSDK.Provider.OpenAI'
                'AIOpenSDK.Provider.Anthropic'
                'AIOpenSDK.Provider.OpenAICompatible'
                'AIOpenSDK.Provider.OpenCodeZen'
            )
        }
        default { return $RuntimeApps }
    }
}

function Find-Alc {
    if ($env:ALC -and (Test-Path -LiteralPath $env:ALC)) {
        return $env:ALC
    }

    $roots = @(
        (Join-Path $env:USERPROFILE '.vscode\extensions')
        (Join-Path $env:USERPROFILE '.vscode-server\extensions')
        (Join-Path $env:USERPROFILE '.cursor\extensions')
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

    return ($candidates | Sort-Object -Descending | Select-Object -First 1)
}

function Get-AppManifest([string]$Project) {
    $path = Join-Path $Project 'app.json'
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing app.json: $path"
    }
    return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function Get-AppOutPath([string]$Project) {
    $m = Get-AppManifest $Project
    $fileName = '{0}_{1}_{2}.app' -f $m.publisher, $m.name, $m.version
    return Join-Path $Cache $fileName
}

function Invoke-PackageApp([string]$Project) {
    $name = Split-Path -Leaf $Project
    $outPath = Get-AppOutPath $Project
    Write-Host "==> Packaging $name"
    & $script:Alc `
        "/project:$Project" `
        "/packagecachepath:$Cache" `
        "/out:$outPath" `
        "/errorsonlyinconsole"
    if ($LASTEXITCODE -ne 0) {
        throw "alc failed for $name (exit $LASTEXITCODE)"
    }
    if (-not (Test-Path -LiteralPath $outPath)) {
        throw "Expected package not found: $outPath"
    }
    return $outPath
}

function Get-LaunchConfig([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "launch.json not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw
    # Strip // comments so ConvertFrom-Json works
    $json = ($raw -replace '(?m)^\s*//.*$', '') | ConvertFrom-Json
    if (-not $json.configurations -or $json.configurations.Count -eq 0) {
        throw "No configurations in $Path"
    }
    $preferred = $json.configurations |
        Where-Object { $_.environmentType -eq 'OnPrem' } |
        Select-Object -First 1
    if (-not $preferred) {
        $preferred = $json.configurations[0]
    }
    return $preferred
}

function Resolve-PublishTarget {
    $target = [ordered]@{
        EnvironmentType = 'OnPrem'
        EnvironmentName = ''
        Server          = ''
        ServerInstance  = ''
        Port            = 7049
        Authentication  = 'UserPassword'
        Tenant          = 'default'
    }

    if (-not $LaunchJson) {
        $LaunchJson = Join-Path $Root 'apps\AIOpenSDK.Core\.vscode\launch.json'
    }

    if ((-not $Server) -and (-not $env:BC_SERVER) -and (Test-Path -LiteralPath $LaunchJson)) {
        $cfg = Get-LaunchConfig $LaunchJson
        Write-Host "Using launch config: $($cfg.name) ($LaunchJson)"
        if ($cfg.environmentType) { $target.EnvironmentType = [string]$cfg.environmentType }
        if ($cfg.environmentName) { $target.EnvironmentName = [string]$cfg.environmentName }
        if ($cfg.server) { $target.Server = [string]$cfg.server }
        if ($cfg.serverInstance) { $target.ServerInstance = [string]$cfg.serverInstance }
        if ($cfg.port) { $target.Port = [int]$cfg.port }
        if ($cfg.authentication) { $target.Authentication = [string]$cfg.authentication }
        if ($cfg.tenant) { $target.Tenant = [string]$cfg.tenant }
    }

    if ($env:BC_SERVER) { $target.Server = $env:BC_SERVER }
    if ($env:BC_SERVER_INSTANCE) { $target.ServerInstance = $env:BC_SERVER_INSTANCE }
    if ($env:BC_PORT) { $target.Port = [int]$env:BC_PORT }
    if ($env:BC_AUTHENTICATION) { $target.Authentication = $env:BC_AUTHENTICATION }
    if ($env:BC_TENANT) { $target.Tenant = $env:BC_TENANT }
    if ($env:BC_ENVIRONMENT_TYPE) { $target.EnvironmentType = $env:BC_ENVIRONMENT_TYPE }
    if ($env:BC_ENVIRONMENT_NAME) { $target.EnvironmentName = $env:BC_ENVIRONMENT_NAME }

    if ($Server) { $target.Server = $Server }
    if ($ServerInstance) { $target.ServerInstance = $ServerInstance }
    if ($Port -gt 0) { $target.Port = $Port }
    if ($Authentication) { $target.Authentication = $Authentication }
    if ($EnvironmentType) { $target.EnvironmentType = $EnvironmentType }
    if ($EnvironmentName) { $target.EnvironmentName = $EnvironmentName }
    if ($Tenant) { $target.Tenant = $Tenant }

    return [pscustomobject]$target
}

function Get-DevAppsUrl($Target) {
    $mode = $SchemaUpdateMode.ToLowerInvariant()
    $dep = $DependencyPublishingOption.ToLowerInvariant()
    $query = "SchemaUpdateMode=$mode&DependencyPublishingOption=$dep"
    if ($Target.Tenant) {
        $query += "&tenant=$([uri]::EscapeDataString($Target.Tenant))"
    }

    if ($Target.EnvironmentType -eq 'Sandbox' -or $Target.EnvironmentType -eq 'Production') {
        if (-not $Target.EnvironmentName) {
            throw "Cloud publish requires EnvironmentName (launch.json or -EnvironmentName / BC_ENVIRONMENT_NAME)."
        }
        $tenant = if ($Target.Tenant) { $Target.Tenant } else { 'common' }
        return "https://api.businesscentral.dynamics.com/v2.0/$tenant/$($Target.EnvironmentName)/dev/apps?$query"
    }

    if (-not $Target.Server -or -not $Target.ServerInstance) {
        throw "OnPrem publish requires Server and ServerInstance (launch.json or -Server / BC_SERVER)."
    }

    $base = $Target.Server.TrimEnd('/')
    if ($base -notmatch '^https?://') {
        $base = "http://$base"
    }
    return "${base}:$($Target.Port)/$($Target.ServerInstance)/dev/apps?$query"
}

function Resolve-Credential($Target) {
    if ($env:BC_ACCESS_TOKEN) {
        return @{ Kind = 'Bearer'; Token = $env:BC_ACCESS_TOKEN }
    }

    if ($Target.Authentication -eq 'Windows') {
        return @{ Kind = 'Windows' }
    }

    if ($Target.Authentication -eq 'AAD' -and -not $env:BC_ACCESS_TOKEN) {
        throw @"
AAD / cloud publish needs a bearer token in BC_ACCESS_TOKEN (or use VS Code Publish for interactive login).
OnPrem UserPassword: set BC_USERNAME / BC_PASSWORD, pass -Credential, or allow the prompt.
"@
    }

    if ($Credential) {
        return @{ Kind = 'Basic'; Credential = $Credential }
    }

    if ($env:BC_USERNAME -and $env:BC_PASSWORD) {
        $sec = ConvertTo-SecureString $env:BC_PASSWORD -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($env:BC_USERNAME, $sec)
        return @{ Kind = 'Basic'; Credential = $cred }
    }

    $cred = Get-Credential -Message 'Business Central credentials (UserPassword)'
    return @{ Kind = 'Basic'; Credential = $cred }
}

function Publish-AppFile([string]$AppPath, [string]$Url, $Auth) {
    # Dev endpoint expects multipart/form-data (same as VS Code / BcContainerHelper).
    $name = Split-Path -Leaf $AppPath
    Write-Host "==> Publishing $name"
    Write-Host "    $Url"

    $handler = [System.Net.Http.HttpClientHandler]::new()
    if ($Auth.Kind -eq 'Windows') {
        $handler.UseDefaultCredentials = $true
    }

    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromMinutes(10)
    $client.DefaultRequestHeaders.ExpectContinue = $false

    $fileStream = $null
    $multipart = $null
    try {
        if ($Auth.Kind -eq 'Bearer') {
            $client.DefaultRequestHeaders.Authorization =
                [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $Auth.Token)
        }
        elseif ($Auth.Kind -eq 'Basic') {
            $pair = '{0}:{1}' -f $Auth.Credential.UserName, $Auth.Credential.GetNetworkCredential().Password
            $bytes = [Text.Encoding]::ASCII.GetBytes($pair)
            $b64 = [Convert]::ToBase64String($bytes)
            $client.DefaultRequestHeaders.Authorization =
                [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Basic', $b64)
        }

        $fileStream = [System.IO.FileStream]::new($AppPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $multipart = [System.Net.Http.MultipartFormDataContent]::new()
        $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
        $disposition = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
        $disposition.Name = $name
        $disposition.FileName = $name
        $disposition.FileNameStar = $name
        $fileContent.Headers.ContentDisposition = $disposition
        $multipart.Add($fileContent)

        $response = $client.PostAsync($Url, $multipart).GetAwaiter().GetResult()
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if (-not $response.IsSuccessStatusCode) {
            throw "Publish failed for $name ($([int]$response.StatusCode) $($response.ReasonPhrase)): $body"
        }
        Write-Host "    OK ($([int]$response.StatusCode))"
    }
    finally {
        if ($multipart) { $multipart.Dispose() }
        if ($fileStream) { $fileStream.Dispose() }
        $client.Dispose()
        $handler.Dispose()
    }
}

# --- main ---

$appList = Resolve-AppList
foreach ($a in $appList) {
    $project = Join-Path $Root "apps\$a"
    if (-not (Test-Path -LiteralPath (Join-Path $project 'app.json'))) {
        throw "Unknown app folder: $a (expected $project)"
    }
}

New-Item -ItemType Directory -Force -Path $Cache | Out-Null

if (-not $SkipPackage) {
    $msApps = Get-ChildItem -Path $Cache -Filter 'Microsoft_Application_*.app' -ErrorAction SilentlyContinue
    if (-not $msApps) {
        throw @"
No Microsoft Application symbols in $Cache.
Open apps\AIOpenSDK.Core, run AL: Download Symbols, then re-run this script.
"@
    }

    $script:Alc = Find-Alc
    Write-Host "Using alc: $script:Alc"
    Write-Host "Package cache: $Cache"
    Write-Host "Apps: $($appList -join ', ')"
    Write-Host ""

    $packaged = @()
    foreach ($a in $appList) {
        $packaged += Invoke-PackageApp (Join-Path $Root "apps\$a")
    }
}
else {
    Write-Host "SkipPackage: using existing .app files in $Cache"
    $packaged = @()
    foreach ($a in $appList) {
        $path = Get-AppOutPath (Join-Path $Root "apps\$a")
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Missing package for $a. Run without -SkipPackage first. Expected: $path"
        }
        $packaged += $path
    }
}

if ($PackageOnly) {
    Write-Host ""
    Write-Host "PackageOnly: done. Apps are in $Cache"
    $packaged | ForEach-Object { Write-Host "  $_" }
    exit 0
}

$target = Resolve-PublishTarget
$url = Get-DevAppsUrl $target
$auth = Resolve-Credential $target

Write-Host ""
Write-Host "Publish target: $($target.EnvironmentType)  auth=$($target.Authentication)"
Write-Host ""

foreach ($appPath in $packaged) {
    Publish-AppFile -AppPath $appPath -Url $url -Auth $auth
}

Write-Host ""
Write-Host "Done. Published $($packaged.Count) app(s)."
Write-Host "Docs: docs\DEVELOPMENT.md"

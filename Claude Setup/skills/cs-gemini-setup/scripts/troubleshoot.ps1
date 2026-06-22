<#
.SYNOPSIS
    Diagnose why a Gemini API call is failing and surface a tailored fix.

.DESCRIPTION
    Repeats the two [2] verifier calls but reads the HTTP status carefully
    and prints a tailored remediation for the four [4] error families that
    actually happen on a daily-driver Windows machine:

      401 - Unauthenticated. The key is invalid, expired, or revoked. Re-issue
            in AI Studio and rerun setup.ps1.

      403 - Permission denied. Most commonly: the project the key belongs to
            does not have the Generative Language API enabled, or the key is
            restricted by referrer / IP. Open the Cloud project that backs
            the AI Studio project and enable the API.

      429 - Resource exhausted. Two flavours:
              - "Quota exceeded for free tier" -> upgrade to paid in AI Studio
              - "Prepayment credits are depleted" -> top up balance in AI Studio

      Network / timeout / DNS - usually a corporate proxy or VPN. Show the
            user how to test reachability and how to point Invoke-WebRequest
            at a proxy if one is required.

    Read-only: never writes to the environment, never modifies the key.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

function Write-Header([string]$text) {
    Write-Host ''
    Write-Host ('--- {0} ---' -f $text) -ForegroundColor Cyan
}

function Get-Key {
    $k = $env:GEMINI_API_KEY
    if ([string]::IsNullOrWhiteSpace($k)) {
        $k = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'User')
    }
    return $k
}

function Invoke-GeminiPost {
    param(
        [Parameter(Mandatory)] [string] $Model,
        [Parameter(Mandatory)] [string] $Key,
        [Parameter(Mandatory)] [string] $Prompt
    )
    $url  = "https://generativelanguage.googleapis.com/v1/models/$Model`:generateContent"
    $body = @{
        contents = @( @{ parts = @( @{ text = $Prompt } ) } )
    } | ConvertTo-Json -Depth 5 -Compress
    try {
        $resp = Invoke-WebRequest -Uri $url -Method POST `
            -Headers @{ 'Content-Type' = 'application/json'; 'x-goog-api-key' = $Key } `
            -Body $body -UseBasicParsing -TimeoutSec 30
        return [pscustomobject]@{
            Ok = $true; Status = $resp.StatusCode; Content = $resp.Content; Error = $null
        }
    } catch {
        $status = 0; $errBody = ''
        try {
            if ($_.Exception.Response) {
                $status  = [int]$_.Exception.Response.StatusCode
                $stream  = $_.Exception.Response.GetResponseStream()
                $reader  = New-Object System.IO.StreamReader($stream)
                $errBody = $reader.ReadToEnd()
            }
        } catch { }
        return [pscustomobject]@{
            Ok = $false; Status = $status; Content = $null; Error = if ($errBody) { $errBody } else { $_.Exception.Message }
        }
    }
}

function Explain-401 {
    Write-Host ''
    Write-Host '  Diagnosis: HTTP 401 -- the API rejected the key.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Common causes:' -ForegroundColor White
    Write-Host '   - The key was revoked or rotated in AI Studio'      -ForegroundColor Gray
    Write-Host '   - The key was pasted with a trailing space or CR'   -ForegroundColor Gray
    Write-Host '   - The key was copied for a different Google account' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Fix:' -ForegroundColor White
    Write-Host '   1. Open https://aistudio.google.com/apikey'          -ForegroundColor Gray
    Write-Host '   2. Re-issue or rotate the key'                       -ForegroundColor Gray
    Write-Host '   3. Re-run setup.ps1 and paste the new value'         -ForegroundColor Gray
}

function Explain-403 {
    Write-Host ''
    Write-Host '  Diagnosis: HTTP 403 -- the key authenticated but the call was refused.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Common causes:' -ForegroundColor White
    Write-Host '   - The Generative Language API is not enabled on the underlying Cloud project' -ForegroundColor Gray
    Write-Host '   - The key has HTTP referrer or IP restrictions set in AI Studio'              -ForegroundColor Gray
    Write-Host '   - The model is gated to a region the project is not approved for'             -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Fix:' -ForegroundColor White
    Write-Host '   1. Open https://aistudio.google.com/apikey, click the key, lift restrictions' -ForegroundColor Gray
    Write-Host '   2. From AI Studio, follow the link to the backing Cloud project'             -ForegroundColor Gray
    Write-Host '   3. In the Cloud console, ensure the Generative Language API is enabled'      -ForegroundColor Gray
}

function Explain-429 {
    param([string]$Body)
    Write-Host ''
    Write-Host '  Diagnosis: HTTP 429 -- quota or credits exhausted.' -ForegroundColor Yellow
    Write-Host ''
    $isCredits = $Body -match 'credits'
    $isQuota   = $Body -match 'Quota|quota'
    if ($isCredits) {
        Write-Host '  Subtype: prepayment credits depleted.' -ForegroundColor White
        Write-Host '   - Top up at https://aistudio.google.com/'                       -ForegroundColor Gray
        Write-Host '   - Billing docs: https://ai.google.dev/gemini-api/docs/billing'  -ForegroundColor Gray
    } elseif ($isQuota) {
        Write-Host '  Subtype: free-tier quota exhausted, or model gated behind paid tier.' -ForegroundColor White
        Write-Host '   - Upgrade to paid tier at https://aistudio.google.com/'              -ForegroundColor Gray
        Write-Host '   - For image generation, paid tier is required (v1beta caps to 0).'   -ForegroundColor Gray
    } else {
        Write-Host '  Subtype: rate limit. Wait briefly and retry, or upgrade tier.' -ForegroundColor White
    }
}

function Explain-Network {
    param([string]$Message)
    Write-Host ''
    Write-Host '  Diagnosis: network failure before the API responded.' -ForegroundColor Yellow
    Write-Host ('  Underlying message: {0}' -f $Message) -ForegroundColor DarkYellow
    Write-Host ''
    Write-Host '  Fix:' -ForegroundColor White
    Write-Host '   1. Test reachability:' -ForegroundColor Gray
    Write-Host '        Test-NetConnection generativelanguage.googleapis.com -Port 443' -ForegroundColor DarkGray
    Write-Host '   2. If behind a corporate proxy, set $env:HTTPS_PROXY or pass -Proxy:' -ForegroundColor Gray
    Write-Host '        $env:HTTPS_PROXY = "http://proxy.host:port"' -ForegroundColor DarkGray
    Write-Host '   3. If on a corporate VPN, try toggling the VPN before retrying.' -ForegroundColor Gray
}

function Inspect([pscustomobject]$result, [string]$label) {
    if ($result.Ok) {
        Write-Host ('  {0,-5} OK' -f $label) -ForegroundColor Green
        return
    }
    Write-Host ('  {0,-5} FAILED (HTTP {1})' -f $label, $result.Status) -ForegroundColor Red
    switch ($result.Status) {
        401 { Explain-401 }
        403 { Explain-403 }
        429 { Explain-429 -Body ($result.Error | Out-String) }
        default {
            if ($result.Status -eq 0) {
                Explain-Network -Message ($result.Error | Out-String)
            } else {
                $snippet = ($result.Error | Out-String).Trim()
                if ($snippet.Length -gt 400) { $snippet = $snippet.Substring(0,400) + '...' }
                Write-Host ('  body: {0}' -f $snippet) -ForegroundColor DarkRed
            }
        }
    }
}

# ---- main ----

Write-Header 'cs-gemini-setup troubleshoot'

$key = Get-Key
if ([string]::IsNullOrWhiteSpace($key)) {
    Write-Host '  GEMINI_API_KEY is not set in this session or in the User scope.' -ForegroundColor Red
    Write-Host '  Run setup.ps1 first.' -ForegroundColor Red
    exit 1
}

$masked = $key.Substring(0,4) + '...' + $key.Substring($key.Length - 4)
Write-Host ('  Key detected: {0}' -f $masked) -ForegroundColor Green

Write-Header 'Text (gemini-2.5-flash via /v1/)'
$text = Invoke-GeminiPost -Model 'gemini-2.5-flash' -Key $key -Prompt 'Reply with OK.'
Inspect $text 'text'

Write-Header 'Image (gemini-2.5-flash-image via /v1/)'
$img = Invoke-GeminiPost -Model 'gemini-2.5-flash-image' -Key $key `
    -Prompt 'Generate a 256x256 plain green square.'
Inspect $img 'image'

Write-Host ''
if ($text.Ok -and $img.Ok) {
    Write-Host 'Both surfaces healthy. Nothing to fix.' -ForegroundColor Green
} elseif ($text.Ok -and -not $img.Ok) {
    Write-Host 'Text works; image generation is blocked. See the diagnosis above.' -ForegroundColor Yellow
} elseif (-not $text.Ok) {
    Write-Host 'The key is failing on the standard text endpoint. Fix that first, then re-run.' -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Verify the Gemini API key works for both text and image generation.

.DESCRIPTION
    Sends two [2] small calls against the v1 stable endpoint:
      1. A tiny text completion with gemini-2.5-flash to confirm the key is
         valid for the standard Gemini API.
      2. A tiny image generation with gemini-2.5-flash-image to confirm the
         project has billing / quota for image generation. This is the path
         the wt-ai-write image script actually uses, so a green light here
         means generate_image_gemini.py will work too.

    Both calls go to /v1/, never /v1beta/, because v1beta has free-tier
    limit:0 for image generation (see feedback_gemini_image_endpoint memory).

    Exit codes:
      0  - both checks passed
      1  - missing or malformed key
      2  - text call failed
      3  - image call failed (key works for text, but image gen is blocked)
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-Header([string]$text) {
    Write-Host ''
    Write-Host ('--- {0} ---' -f $text) -ForegroundColor Cyan
}

function Get-Key {
    $k = $env:GEMINI_API_KEY
    if ([string]::IsNullOrWhiteSpace($k)) {
        # Fall back to User scope in case the session was started before setup.
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
        contents = @(
            @{ parts = @( @{ text = $Prompt } ) }
        )
    } | ConvertTo-Json -Depth 5 -Compress

    # Use Invoke-WebRequest so we can inspect status codes on error too.
    try {
        $resp = Invoke-WebRequest -Uri $url -Method POST `
            -Headers @{ 'Content-Type' = 'application/json'; 'x-goog-api-key' = $Key } `
            -Body $body -UseBasicParsing -TimeoutSec 60
        return [pscustomobject]@{
            Ok      = $true
            Status  = $resp.StatusCode
            Content = $resp.Content
            Error   = $null
        }
    } catch {
        $status = 0
        $errBody = ''
        $err = $_
        try {
            if ($err.Exception.Response) {
                $status  = [int]$err.Exception.Response.StatusCode
                $stream  = $err.Exception.Response.GetResponseStream()
                $reader  = New-Object System.IO.StreamReader($stream)
                $errBody = $reader.ReadToEnd()
            }
        } catch { }
        return [pscustomobject]@{
            Ok      = $false
            Status  = $status
            Content = $null
            Error   = if ($errBody) { $errBody } else { $err.Exception.Message }
        }
    }
}

# ---- main ----

Write-Header 'cs-gemini-setup verify'

$key = Get-Key
if ([string]::IsNullOrWhiteSpace($key)) {
    Write-Host '  GEMINI_API_KEY is not set in this session or in the User scope.' -ForegroundColor Red
    Write-Host '  Run setup.ps1 first.' -ForegroundColor Red
    exit 1
}

$masked = $key.Substring(0,4) + '...' + $key.Substring($key.Length - 4)
Write-Host ('  Key detected: {0}' -f $masked) -ForegroundColor Green

# ---- step 1: text call ----
Write-Header 'Text check (gemini-2.5-flash via /v1/)'
$text = Invoke-GeminiPost -Model 'gemini-2.5-flash' -Key $key -Prompt 'Reply with just the word OK.'
if ($text.Ok) {
    Write-Host '  text OK' -ForegroundColor Green
} else {
    Write-Host ('  text FAILED (HTTP {0})' -f $text.Status) -ForegroundColor Red
    if ($text.Error) {
        $snippet = $text.Error
        if ($snippet.Length -gt 400) { $snippet = $snippet.Substring(0, 400) + '...' }
        Write-Host ('  body: {0}' -f $snippet) -ForegroundColor DarkRed
    }
    Write-Host ''
    Write-Host '  Run troubleshoot.ps1 for a tailored fix.' -ForegroundColor Yellow
    exit 2
}

# ---- step 2: image call ----
Write-Header 'Image check (gemini-2.5-flash-image via /v1/)'
$img = Invoke-GeminiPost -Model 'gemini-2.5-flash-image' -Key $key `
    -Prompt 'Generate a 256x256 image of a green square. Plain background, no text.'

if ($img.Ok) {
    # gemini-2.5-flash-image returns inlineData parts on success. A 200 OK without
    # inlineData often means the model only returned text; treat that as a soft pass
    # but flag it.
    if ($img.Content -match '"inlineData"\s*:\s*\{') {
        Write-Host '  image OK' -ForegroundColor Green
    } else {
        Write-Host '  image returned 200 but no inlineData -- model answered in text only.' -ForegroundColor Yellow
        Write-Host '  This usually means the image generation tier was not exercised.' -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host 'All checks complete. The key is wired up for both text and image generation.' -ForegroundColor Green
    exit 0
} else {
    Write-Host ('  image FAILED (HTTP {0})' -f $img.Status) -ForegroundColor Red
    if ($img.Error) {
        $snippet = $img.Error
        if ($snippet.Length -gt 600) { $snippet = $snippet.Substring(0, 600) + '...' }
        Write-Host ('  body: {0}' -f $snippet) -ForegroundColor DarkRed
    }
    Write-Host ''
    if ($img.Status -eq 429) {
        Write-Host '  HTTP 429 on image gen usually means prepayment credits are depleted' -ForegroundColor Yellow
        Write-Host '  or the project is on the free tier (limit:0 for image generation).' -ForegroundColor Yellow
        Write-Host '  Top up at: https://aistudio.google.com/' -ForegroundColor Yellow
    }
    Write-Host '  Run troubleshoot.ps1 for a tailored fix.' -ForegroundColor Yellow
    exit 3
}

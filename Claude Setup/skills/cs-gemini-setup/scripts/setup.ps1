<#
.SYNOPSIS
    Install or rotate GEMINI_API_KEY on Windows so local Gemini-using scripts
    (e.g. wt-ai-write's generate_image_gemini.py) work first time.

.DESCRIPTION
    Interactive flow:
      1. Detect any existing key in the User scope. Ask before overwriting.
      2. Print where to fetch a new key from AI Studio.
      3. Prompt for the key with hidden input (Read-Host -AsSecureString).
      4. Validate the AIza... shape and length.
      5. Write to User scope (persists across shells), set in current session.
      6. Call verify.ps1 so the user sees text + image checks before exit.

    Windows-only. Powershell 5.1 or PowerShell 7+ both work.
#>

[CmdletBinding()]
param(
    [switch]$NonInteractive,
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'

function Write-Header([string]$text) {
    Write-Host ''
    Write-Host ('=' * 64) -ForegroundColor DarkGreen
    Write-Host (' {0}' -f $text) -ForegroundColor Green
    Write-Host ('=' * 64) -ForegroundColor DarkGreen
}

function Confirm-WindowsHost {
    $isWin = $false
    try { $isWin = $IsWindows } catch { $isWin = $false }
    if (-not $isWin -and $PSVersionTable.PSEdition -ne 'Desktop') {
        Write-Error 'cs-gemini-setup is Windows-only. Detected non-Windows host.'
    }
}

function Get-ExistingKey {
    $userKey = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'User')
    $sessKey = $env:GEMINI_API_KEY
    [pscustomobject]@{
        User    = $userKey
        Session = $sessKey
    }
}

function Show-FetchInstructions {
    Write-Host ''
    Write-Host 'To get a Gemini API key:' -ForegroundColor White
    Write-Host '  1. Open https://aistudio.google.com/apikey in your browser' -ForegroundColor Gray
    Write-Host '  2. Sign in with the Google account that owns the project to bill' -ForegroundColor Gray
    Write-Host '  3. Click "Create API key" and copy the value (starts with AIza...)' -ForegroundColor Gray
    Write-Host '  4. Paste it at the prompt below. Input is hidden.' -ForegroundColor Gray
    Write-Host ''
}

function Read-KeyInteractive {
    $secure = Read-Host -Prompt 'Paste your Gemini API key (input hidden)' -AsSecureString
    if (-not $secure -or $secure.Length -eq 0) {
        Write-Error 'No key was entered. Aborting.'
    }
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr).Trim()
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Test-KeyShape([string]$key) {
    if ([string]::IsNullOrWhiteSpace($key)) { return $false }
    # Two [2] shapes are accepted:
    #   - Classic AI Studio key: starts with "AIza", ~39 chars total.
    #   - Vertex / Express mode key: starts with "AQ.", longer payload.
    # Both forms use URL-safe base64-ish characters. Allow dots in the prefix.
    if ($key -match '^AIza[0-9A-Za-z_\-]{20,80}$')           { return $true }
    if ($key -match '^AQ\.[0-9A-Za-z_\-\.]{20,200}$')         { return $true }
    return $false
}

function Save-Key([string]$key) {
    [Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $key, 'User')
    $env:GEMINI_API_KEY = $key
    Write-Host ''
    Write-Host '  -> Saved to User-scope environment (persists across shells).' -ForegroundColor Green
    Write-Host '  -> Available in this session as $env:GEMINI_API_KEY.'        -ForegroundColor Green
}

function Invoke-Verify {
    $here = Split-Path -Parent $PSCommandPath
    $verify = Join-Path $here 'verify.ps1'
    if (-not (Test-Path $verify)) {
        Write-Warning "verify.ps1 not found beside setup.ps1; skipping verification."
        return
    }
    Write-Header 'Running verify.ps1'
    & $verify
}

# ---- main ----

Confirm-WindowsHost
Write-Header 'cs-gemini-setup'

$existing = Get-ExistingKey
if ($existing.User) {
    $masked = $existing.User.Substring(0,4) + '...' + $existing.User.Substring($existing.User.Length - 4)
    Write-Host ('A User-scope GEMINI_API_KEY is already set: {0}' -f $masked) -ForegroundColor Yellow
    if ($NonInteractive) {
        Write-Host 'NonInteractive mode: keeping existing key.' -ForegroundColor Green
        if (-not $SkipVerify) { Invoke-Verify }
        return
    }
    $reply = Read-Host 'Replace it? [y/N]'
    if ($reply -notmatch '^(y|Y)') {
        Write-Host 'Keeping existing key.' -ForegroundColor Green
        if (-not $SkipVerify) { Invoke-Verify }
        return
    }
} else {
    Write-Host 'No GEMINI_API_KEY found in the User scope.' -ForegroundColor Yellow
    if ($NonInteractive) {
        Write-Error 'No existing key and NonInteractive mode requested. Set GEMINI_API_KEY in the User scope before calling, or omit -NonInteractive.'
    }
}

Show-FetchInstructions

if ($NonInteractive) {
    Write-Error 'NonInteractive mode requested but no key was supplied. Set $env:GEMINI_API_KEY before calling, or omit -NonInteractive.'
}

$key = Read-KeyInteractive
if (-not (Test-KeyShape $key)) {
    Write-Host ''
    Write-Host 'The pasted value does not match the expected AIza... shape.' -ForegroundColor Red
    Write-Host 'A genuine AI Studio key starts with "AIza" and is around 39 characters long.' -ForegroundColor Red
    Write-Error 'Aborting without saving.'
}

Save-Key $key

if (-not $SkipVerify) {
    Invoke-Verify
} else {
    Write-Host ''
    Write-Host 'Skipping verify.ps1 (--SkipVerify). Run it manually when ready.' -ForegroundColor Yellow
}

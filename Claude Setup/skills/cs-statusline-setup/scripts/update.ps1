# ============================================================================
# cs-statusline-setup — update
# Replaces ~/.claude/statusline-sparklines.ps1 with the latest baseline from
# the Sam-Plugin-Marketplace repo. WIPES any customisations applied at install
# time (palette, bar width, hidden lines).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File update.ps1
#
# To re-apply customisations after update, re-run install.ps1 with the same
# parameters you used originally.
# ============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-Step($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "    $msg" -ForegroundColor Yellow }
function Write-Fail($msg)  { Write-Host "    $msg" -ForegroundColor Red }

$CanonicalUrl  = 'https://raw.githubusercontent.com/Sampi314/Sam-Plugin-Marketplace/refs/heads/main/Claude%20Setup/skills/cs-statusline-setup/statusline-sparklines.ps1'
$ClaudeDir     = Join-Path $env:USERPROFILE '.claude'
$TargetScript  = Join-Path $ClaudeDir 'statusline-sparklines.ps1'
$Stamp         = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not (Test-Path $ClaudeDir)) {
    Write-Fail "$ClaudeDir does not exist. Run install.ps1 first."
    exit 1
}

Write-Step "Fetching latest statusline from $CanonicalUrl"
try {
    $latest = Invoke-WebRequest -Uri $CanonicalUrl -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
} catch {
    Write-Fail "Download failed: $($_.Exception.Message)"
    Write-Fail "Check your internet connection, or that the URL is still valid."
    exit 1
}

if (-not $latest.Content -or $latest.Content.Length -lt 1000) {
    Write-Fail "Downloaded content is suspiciously short ($($latest.Content.Length) bytes). Aborting."
    exit 1
}

if ($latest.Content -notmatch 'Claude Code Statusline') {
    Write-Fail "Downloaded content does not look like the statusline script. Aborting."
    exit 1
}

Write-Ok "Downloaded $([math]::Round($latest.Content.Length / 1KB, 1)) KB"

if (Test-Path $TargetScript) {
    $backup = "$TargetScript.bak.$Stamp"
    Write-Step "Backing up current script -> $(Split-Path $backup -Leaf)"
    Write-Warn2 "If you had customised palette/width/lines, they are in this backup file."
    Copy-Item -Path $TargetScript -Destination $backup -Force
    Write-Ok "Backup created"
}

Write-Step "Writing updated script"
Set-Content -Path $TargetScript -Value $latest.Content -Encoding UTF8
Write-Ok "Update complete"

Write-Host ""
Write-Host "Restart Claude Code to pick up the new statusline." -ForegroundColor Green
Write-Host ""
Write-Host "To re-apply your customisations, re-run install.ps1 with the same flags." -ForegroundColor Yellow

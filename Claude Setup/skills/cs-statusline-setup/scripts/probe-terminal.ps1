# ============================================================================
# scripts/probe-terminal.ps1 — one-time terminal capability probe
# ============================================================================
#
# Detects current terminal's capabilities (truecolor, OSC 8, sixel, etc.) and
# writes ~/.claude/terminal-capabilities.json. Run on install or whenever you
# switch terminals.
# ============================================================================

[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'

$ClaudeDir = Join-Path $env:USERPROFILE '.claude'
$LibPath = Join-Path $ClaudeDir 'lib\terminal-probe.ps1'

# Fall back to bundled copy if not installed yet
if (-not (Test-Path $LibPath)) {
    $here = Split-Path -Parent $PSCommandPath
    $LibPath = Join-Path (Split-Path $here -Parent) 'lib\terminal-probe.ps1'
}

if (-not (Test-Path $LibPath)) {
    Write-Host "Could not locate lib/terminal-probe.ps1. Aborting." -ForegroundColor Red
    exit 1
}

. $LibPath
$caps = Probe-TerminalCapabilities -Force:$Force

Write-Host "Terminal capabilities probed:" -ForegroundColor Cyan
$caps | Format-List | Out-String | Write-Host
Write-Host ""
Write-Host "Written to: $(Join-Path $ClaudeDir 'terminal-capabilities.json')" -ForegroundColor Green

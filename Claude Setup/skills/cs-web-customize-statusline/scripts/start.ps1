# ============================================================================
# start.ps1 — entry point for the web statusline customizer
# ============================================================================
#
# Picks a free loopback port, launches server.ps1 in the foreground, opens
# the user's default browser at http://127.0.0.1:<port>/, and blocks until
# the SPA's "Cancel" / "Apply" / "Close" buttons hit /api/shutdown.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File start.ps1 [-Port N] [-NoBrowser]
# ============================================================================

[CmdletBinding()]
param(
    [int]$Port = 0,        # 0 = let OS pick a free port
    [switch]$NoBrowser     # for headless testing
)

$ErrorActionPreference = 'Stop'

$ScriptDir       = Split-Path -Parent $PSCommandPath
$SkillRoot       = Split-Path -Parent $ScriptDir
$SkillsRoot      = Split-Path -Parent $SkillRoot
$SetupRoot       = Join-Path $SkillsRoot 'cs-statusline-setup'
$CustomizerRoot  = Join-Path $SkillsRoot 'cs-customize-statusline'
$ServerScript    = Join-Path $ScriptDir 'server.ps1'

foreach ($p in @($SetupRoot, $CustomizerRoot, $ServerScript)) {
    if (-not (Test-Path $p)) { throw "Required path missing: $p" }
}

if ($Port -le 0) {
    # Let the OS pick a free loopback port by binding to port 0
    $tmpListener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $tmpListener.Start()
    $Port = ([System.Net.IPEndPoint]$tmpListener.LocalEndpoint).Port
    $tmpListener.Stop()
}

$url = "http://127.0.0.1:$Port/"
Write-Host ""
Write-Host "==> Starting statusline web customizer" -ForegroundColor Cyan
Write-Host "    URL: $url"
Write-Host "    Press Ctrl+C in this window to stop, or click Cancel in the browser."
Write-Host ""

if (-not $NoBrowser) {
    try { Start-Process $url | Out-Null } catch { Write-Warning "Could not open browser automatically — point one at $url" }
}

# Run the server in this same process (foreground). It listens until /api/shutdown.
& $ServerScript -Port $Port -SetupRoot $SetupRoot -CustomizerRoot $CustomizerRoot

# ============================================================================
# scripts/preview.ps1 — render a live statusline preview to the terminal
# ============================================================================
#
# Used by the customizer wizard to show the user what their configuration
# looks like BEFORE applying. Pipes mock-data.json through a sandboxed copy
# of statusline-extended.ps1 (with only the chosen widgets) and writes the
# result to stdout — so the user's terminal renders the actual ANSI colours.
#
# Usage:
#   preview.ps1 -Variant Extended -Widgets 'core-header,core-ctx,sparkline-cost' [-Palette Nord]
#   preview.ps1 -Variant Classic  -Palette Sam  -BarWidth 25  -Lines all
#
# Output:
#   Prints the rendered statusline to stdout, framed with a banner so the user
#   can clearly see where the preview begins and ends.
# ============================================================================

[CmdletBinding()]
param(
    [ValidateSet('Classic','Extended')]
    [string]$Variant = 'Extended',
    [string]$Widgets = '',                  # comma-separated widget names; empty = all
    [ValidateSet('Sam','Monochrome','HighContrast','Solarized','Nord','Dracula')]
    [string]$Palette = 'Sam',
    [int]$BarWidth = 30,
    [ValidateSet('all','no5h','nowk','nowork','essentials')]
    [string]$Lines = 'all',
    [string]$MockDataPath = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir       = Split-Path -Parent $PSCommandPath
$CustomizerRoot  = Split-Path -Parent $ScriptDir
$SetupRoot       = Join-Path (Split-Path $CustomizerRoot -Parent) 'cs-statusline-setup'
$BundledExtended = Join-Path $SetupRoot 'statusline-extended.ps1'
$BundledLib      = Join-Path $SetupRoot 'lib'
$BundledWidgets  = Join-Path $SetupRoot 'widgets'
$BundledClassic  = Join-Path $SetupRoot 'statusline-sparklines.ps1'

if (-not $MockDataPath) {
    $MockDataPath = Join-Path $CustomizerRoot 'mock-data.json'
}
if (-not (Test-Path $MockDataPath)) {
    Write-Host "Mock data not found at $MockDataPath" -ForegroundColor Red
    exit 1
}
$mockJson = Get-Content $MockDataPath -Raw -Encoding UTF8

# --- Banner -----------------------------------------------------------------
$ESC = [char]0x1B
$dim   = "$ESC[38;2;120;120;140m"
$accent= "$ESC[38;2;130;180;255m"
$reset = "$ESC[0m"
Write-Host ""
Write-Host "${dim}┌─ ${accent}preview${dim} ─────────────────────────────────────${reset}"

# --- Extended path ----------------------------------------------------------
if ($Variant -eq 'Extended') {
    if (-not (Test-Path $BundledExtended)) {
        Write-Host "${dim}│${reset} (statusline-extended.ps1 not found at $BundledExtended)"
        Write-Host "${dim}└──────────────────────────────────────────────────${reset}"
        exit 1
    }

    # Build a sandbox dir with only the chosen widgets and the palette applied
    $sandbox = Join-Path $env:TEMP "cs-preview-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    $sbLib     = Join-Path $sandbox 'lib'
    $sbWidgets = Join-Path $sandbox 'widgets'
    New-Item -ItemType Directory -Path $sbLib -Force | Out-Null
    New-Item -ItemType Directory -Path $sbWidgets -Force | Out-Null

    Copy-Item (Join-Path $BundledLib '*.ps1') $sbLib -Force
    Copy-Item $BundledExtended (Join-Path $sandbox 'statusline-extended.ps1') -Force

    # Filter widgets if a list was provided
    $allWidgets = Get-ChildItem $BundledWidgets -Filter '*.ps1'
    if ($Widgets) {
        $allow = $Widgets -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        # mode-aware is always preserved if any widget is shown — it controls layout
        $allow += 'mode-aware'
        foreach ($w in $allWidgets) {
            # Derive widget Name from the file by sourcing it
            try {
                $m = & $w.FullName
                if ($m -and $m.Name -and ($allow -contains $m.Name)) {
                    Copy-Item $w.FullName $sbWidgets -Force
                }
            } catch {}
        }
    } else {
        Copy-Item (Join-Path $BundledWidgets '*.ps1') $sbWidgets -Force
    }

    # Override palette via env-var hint (the entry script will pick up via $env:CS_PALETTE_OVERRIDE if present)
    $env:CS_PALETTE_OVERRIDE = $Palette

    # Pipe mock JSON to the sandboxed entry — use a wrapper that points $env:USERPROFILE
    # at the sandbox so the host loads our copy of lib/ and widgets/.
    $originalUP = $env:USERPROFILE
    $sbClaude = Join-Path $sandbox '.claude'
    New-Item -ItemType Directory -Path $sbClaude -Force | Out-Null
    Copy-Item $sbLib (Join-Path $sbClaude 'lib') -Recurse -Force
    Copy-Item $sbWidgets (Join-Path $sbClaude 'statusline-widgets') -Recurse -Force
    Copy-Item (Join-Path $sandbox 'statusline-extended.ps1') (Join-Path $sbClaude 'statusline-extended.ps1') -Force

    try {
        $env:USERPROFILE = $sandbox
        $output = $mockJson | & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $sbClaude 'statusline-extended.ps1') 2>&1
        foreach ($line in $output) {
            Write-Host "${dim}│${reset} $line"
        }
    } finally {
        $env:USERPROFILE = $originalUP
        $env:CS_PALETTE_OVERRIDE = $null
        Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- Classic path -----------------------------------------------------------
if ($Variant -eq 'Classic') {
    if (-not (Test-Path $BundledClassic)) {
        Write-Host "${dim}│${reset} (statusline-sparklines.ps1 not found)"
        Write-Host "${dim}└──────────────────────────────────────────────────${reset}"
        exit 1
    }
    # Use the existing install.ps1 in dry-run mode (just produce a customised script in a temp dir)
    # then run it directly with mock JSON.
    $sandbox = Join-Path $env:TEMP "cs-preview-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    $tempScript = Join-Path $sandbox 'classic.ps1'
    Copy-Item $BundledClassic $tempScript -Force

    # Apply customisations directly (mirror the regex logic from install.ps1)
    $content = Get-Content $tempScript -Raw -Encoding UTF8
    if ($BarWidth -ne 30) {
        $content = $content -creplace '(?m)^\$BAR_WIDTH\s*=\s*\d+', "`$BAR_WIDTH         = $BarWidth"
    }
    # (Palette swap omitted from preview to keep this script focused; install.ps1 handles it for real installs.)
    Set-Content -Path $tempScript -Value $content -Encoding UTF8

    try {
        $output = $mockJson | & powershell -NoProfile -ExecutionPolicy Bypass -File $tempScript 2>&1
        foreach ($line in $output) {
            Write-Host "${dim}│${reset} $line"
        }
    } finally {
        Remove-Item -Path $sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "${dim}└──────────────────────────────────────────────────${reset}"
Write-Host ""

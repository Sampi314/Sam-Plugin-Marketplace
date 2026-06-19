# ============================================================================
# scripts/apply.ps1 — finalize a wizard configuration to ~/.claude/
# ============================================================================
#
# Takes the chosen variant, palette, widget allowlist, and bar width, then:
#   - For Extended: copies statusline-extended.ps1 + lib + only the chosen
#     widgets to ~/.claude/, patches settings.json, runs terminal probe
#   - For Classic: delegates to the existing cs-statusline-setup install.ps1
#     with the chosen palette/lines/bar-width flags
#
# Usage (Extended):
#   apply.ps1 -Variant Extended -Widgets 'core-header,core-ctx,sparkline-cost' [-Palette Nord]
#
# Usage (Classic):
#   apply.ps1 -Variant Classic -Palette Nord -BarWidth 25 -Lines all
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Classic','Extended')]
    [string]$Variant,
    [string]$Widgets = '',
    [ValidateSet('Sam','Monochrome','HighContrast','Solarized','Nord','Dracula')]
    [string]$Palette = 'Sam',
    [int]$BarWidth = 30,
    [ValidateSet('all','no5h','nowk','nowork','essentials')]
    [string]$Lines = 'all',
    [string]$InstancesJson = '',     # Array of {id, name, line, position, priority, ...state}
    [string]$CustomPaletteJson = ''  # Object {C_MODEL: "R G B", ...}
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "    $msg" -ForegroundColor Red }

# Resolve paths to sibling skill
$ScriptDir       = Split-Path -Parent $PSCommandPath
$CustomizerRoot  = Split-Path -Parent $ScriptDir
$SetupRoot       = Join-Path (Split-Path $CustomizerRoot -Parent) 'cs-statusline-setup'
$SetupInstall    = Join-Path $SetupRoot 'scripts\install.ps1'

# --- Classic path: delegate to the existing installer ----------------------
if ($Variant -eq 'Classic') {
    Write-Step "Delegating to cs-statusline-setup/install.ps1 (Classic variant)"
    if (-not (Test-Path $SetupInstall)) {
        Write-Fail "Setup installer not found at $SetupInstall"
        exit 1
    }
    & $SetupInstall -Variant Classic -BarWidth $BarWidth -Palette $Palette -Lines $Lines
    exit $LASTEXITCODE
}

# --- Extended path ---------------------------------------------------------
$BundledExtended = Join-Path $SetupRoot 'statusline-extended.ps1'
$BundledLib      = Join-Path $SetupRoot 'lib'
$BundledWidgets  = Join-Path $SetupRoot 'widgets'
$ClaudeDir       = Join-Path $env:USERPROFILE '.claude'
$TargetLib       = Join-Path $ClaudeDir 'lib'
$TargetWidgets   = Join-Path $ClaudeDir 'statusline-widgets'
$TargetExtended  = Join-Path $ClaudeDir 'statusline-extended.ps1'
$SettingsFile    = Join-Path $ClaudeDir 'settings.json'
$Stamp           = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($p in @($BundledExtended, $BundledLib, $BundledWidgets)) {
    if (-not (Test-Path $p)) {
        Write-Fail "Required bundled path missing: $p"
        exit 1
    }
}

if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }

# Backup existing
foreach ($t in @($TargetExtended, $TargetLib, $TargetWidgets)) {
    if (Test-Path $t) {
        $bk = "$t.bak.$Stamp"
        if ((Get-Item $t).PSIsContainer) {
            Copy-Item $t $bk -Recurse -Force
        } else {
            Copy-Item $t $bk -Force
        }
        Write-Ok "Backed up $(Split-Path $t -Leaf) -> $(Split-Path $bk -Leaf)"
    }
}

# Install entry script
Copy-Item $BundledExtended $TargetExtended -Force
Write-Ok "statusline-extended.ps1 installed"

# Install lib/
if (-not (Test-Path $TargetLib)) { New-Item -ItemType Directory -Path $TargetLib -Force | Out-Null }
Copy-Item (Join-Path $BundledLib '*.ps1') $TargetLib -Force
Write-Ok "lib/ installed ($((Get-ChildItem $TargetLib -Filter '*.ps1').Count) files)"

# Install only the chosen widgets
if (-not (Test-Path $TargetWidgets)) { New-Item -ItemType Directory -Path $TargetWidgets -Force | Out-Null }
# Clear existing user-managed widgets that came from a prior install so the wizard's
# selection becomes the new source of truth. User-added custom widgets in the dir
# that aren't part of our bundled pack are preserved.
$bundledNames = @(Get-ChildItem $BundledWidgets -Filter '*.ps1' | ForEach-Object { $_.Name })
foreach ($existing in (Get-ChildItem $TargetWidgets -Filter '*.ps1' -ErrorAction SilentlyContinue)) {
    if ($bundledNames -contains $existing.Name) {
        Remove-Item $existing.FullName -Force
    }
}

$copied = 0
# When instances are provided, install ALL bundled widget files so any instance
# can reference any base widget. The instance list (written below) controls
# what renders. The legacy $Widgets allowlist is only used when no instances
# are provided (single-instance-per-name path).
$useInstances = -not [string]::IsNullOrEmpty($InstancesJson)
$allow = if (-not $useInstances -and $Widgets) {
    @($Widgets -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
} else { @() }
if (-not $useInstances -and $allow.Count -gt 0) { $allow += 'mode-aware' }

foreach ($w in (Get-ChildItem $BundledWidgets -Filter '*.ps1')) {
    $name = $null
    try { $m = & $w.FullName; $name = $m.Name } catch {}
    if (-not $name) { continue }
    if ($useInstances -or $allow.Count -eq 0 -or ($allow -contains $name)) {
        Copy-Item $w.FullName $TargetWidgets -Force
        $copied++
    }
}
Write-Ok "Widgets installed ($copied total)"

# Write the instance config sidecar — statusline-extended.ps1 reads this at
# runtime when CS_LAYOUT_OVERRIDE isn't set. Always overwrite (no merge with
# any prior file — the customizer is the source of truth at install time).
$InstancesFile = Join-Path $ClaudeDir 'statusline-instances.json'
if ($useInstances) {
    if (Test-Path $InstancesFile) {
        Copy-Item $InstancesFile "$InstancesFile.bak.$Stamp" -Force
    }
    Set-Content -Path $InstancesFile -Value $InstancesJson -Encoding UTF8
    Write-Ok "statusline-instances.json written"
} else {
    # Remove a stale sidecar if a previous install wrote one
    if (Test-Path $InstancesFile) {
        Move-Item $InstancesFile "$InstancesFile.bak.$Stamp" -Force
        Write-Ok "statusline-instances.json (legacy install) moved to backup"
    }
}

# Write the custom palette sidecar (read by the extended script via env var
# at preview time and from this file at runtime).
$PaletteFile = Join-Path $ClaudeDir 'statusline-palette.json'
if ($CustomPaletteJson) {
    if (Test-Path $PaletteFile) { Copy-Item $PaletteFile "$PaletteFile.bak.$Stamp" -Force }
    Set-Content -Path $PaletteFile -Value $CustomPaletteJson -Encoding UTF8
    Write-Ok "statusline-palette.json written"
} elseif (Test-Path $PaletteFile) {
    Move-Item $PaletteFile "$PaletteFile.bak.$Stamp" -Force
    Write-Ok "statusline-palette.json (no custom colours) moved to backup"
}

# Terminal probe
try {
    . (Join-Path $TargetLib 'terminal-probe.ps1')
    $caps = Probe-TerminalCapabilities -Force
    Write-Ok "Terminal probed: trueColor=$($caps.trueColor) osc8=$($caps.osc8Hyperlinks) braille=$($caps.braille) term=$($caps.termProgram)"
} catch {
    Write-Warn "Terminal probe failed: $_"
}

# Patch settings.json
$extCommand = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + $TargetExtended + '"'
$statusLineBlock = [PSCustomObject]@{
    type            = 'command'
    command         = $extCommand
    padding         = 0
    refreshInterval = 30
}

if (Test-Path $SettingsFile) {
    $bk = "$SettingsFile.bak.$Stamp"
    Copy-Item $SettingsFile $bk -Force
    Write-Ok "Backed up settings.json -> $(Split-Path $bk -Leaf)"
    try {
        $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Fail "Could not parse settings.json — backup at $bk"
        exit 1
    }
} else {
    $settings = [PSCustomObject]@{}
}

if ($settings.PSObject.Properties.Match('statusLine').Count -gt 0) {
    $settings.statusLine = $statusLineBlock
} else {
    $settings | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue $statusLineBlock -Force
}
$settings | ConvertTo-Json -Depth 20 | Set-Content -Path $SettingsFile -Encoding UTF8
Write-Ok "settings.json patched"

Write-Host ""
Write-Host "Customization applied. Restart Claude Code to see the new statusline." -ForegroundColor Green

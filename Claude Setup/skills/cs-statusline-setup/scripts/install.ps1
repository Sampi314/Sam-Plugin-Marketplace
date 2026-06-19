# ============================================================================
# cs-statusline-setup — installer
# Installs Sam's multi-line statusline into ~/.claude/ and patches settings.json
# ============================================================================
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 `
#       [-Variant Classic|Extended] `
#       [-BarWidth 30] `
#       [-Palette Sam|Monochrome|HighContrast|Solarized|Nord|Dracula] `
#       [-Lines all|no5h|nowk|nowork|essentials]
#
# -Variant Classic (default) installs the original single-script statusline.
# -Variant Extended installs the new widget-host platform with:
#   * Built-in rate_limits (with OAuth fallback for old Claude Code)
#   * Adaptive layout via $env:COLUMNS
#   * Braille-density sparklines
#   * Mode-aware layout switching
#   * Skill-aware overlays for SumProduct stack
#   * NDJSON events stream
#   * Pluggable widget pack at ~/.claude/statusline-widgets/
# When -Variant Extended is used, -BarWidth and -Lines are ignored;
# -Palette still applies.
# ============================================================================

[CmdletBinding()]
param(
    [ValidateSet('Classic','Extended')]
    [string]$Variant = 'Classic',
    [int]$BarWidth = 30,
    [ValidateSet('Sam','Monochrome','HighContrast','Solarized','Nord','Dracula')]
    [string]$Palette = 'Sam',
    [ValidateSet('all','no5h','nowk','nowork','essentials')]
    [string]$Lines = 'all'
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg)   { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)     { Write-Host "    $msg" -ForegroundColor Green }
function Write-Warn2($msg)  { Write-Host "    $msg" -ForegroundColor Yellow }
function Write-Fail($msg)   { Write-Host "    $msg" -ForegroundColor Red }

# --- Platform check ----------------------------------------------------------
if (-not $IsWindows -and $PSVersionTable.PSEdition -ne 'Desktop') {
    Write-Fail "This statusline is Windows-only — it uses Windows Credential Manager (advapi32.dll) and %USERPROFILE% paths."
    Write-Fail "Install aborted. Port the script for macOS/Linux first, or use a different statusline."
    exit 1
}

# --- Resolve paths -----------------------------------------------------------
$ScriptDir       = Split-Path -Parent $PSCommandPath
$SkillRoot       = Split-Path -Parent $ScriptDir
$BundledScript   = Join-Path $SkillRoot 'statusline-sparklines.ps1'
$ClaudeDir       = Join-Path $env:USERPROFILE '.claude'
$TargetScript    = Join-Path $ClaudeDir 'statusline-sparklines.ps1'
$SettingsFile    = Join-Path $ClaudeDir 'settings.json'
$Stamp           = Get-Date -Format 'yyyyMMdd-HHmmss'

# Extended variant paths
$BundledLib       = Join-Path $SkillRoot 'lib'
$BundledWidgets   = Join-Path $SkillRoot 'widgets'
$BundledExtended  = Join-Path $SkillRoot 'statusline-extended.ps1'
$TargetLib        = Join-Path $ClaudeDir 'lib'
$TargetWidgets    = Join-Path $ClaudeDir 'statusline-widgets'
$TargetExtended   = Join-Path $ClaudeDir 'statusline-extended.ps1'

# --- Extended variant branch -------------------------------------------------
if ($Variant -eq 'Extended') {
    Write-Step "Installing Extended variant (widget-host platform)"
    if (-not (Test-Path $BundledExtended)) {
        Write-Fail "Bundled statusline-extended.ps1 not found at $BundledExtended"
        exit 1
    }
    if (-not (Test-Path $BundledLib)) {
        Write-Fail "Bundled lib/ folder not found at $BundledLib"
        exit 1
    }
    if (-not (Test-Path $BundledWidgets)) {
        Write-Fail "Bundled widgets/ folder not found at $BundledWidgets"
        exit 1
    }

    if (-not (Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null }

    # Backup existing Extended install if present
    if (Test-Path $TargetExtended) {
        Copy-Item $TargetExtended "$TargetExtended.bak.$Stamp" -Force
        Write-Ok "Backed up existing statusline-extended.ps1"
    }
    if (Test-Path $TargetLib) {
        $backupLib = "$TargetLib.bak.$Stamp"
        Copy-Item $TargetLib $backupLib -Recurse -Force
        Write-Ok "Backed up existing lib/ -> $(Split-Path $backupLib -Leaf)"
    }
    if (Test-Path $TargetWidgets) {
        $backupWid = "$TargetWidgets.bak.$Stamp"
        Copy-Item $TargetWidgets $backupWid -Recurse -Force
        Write-Ok "Backed up existing statusline-widgets/ -> $(Split-Path $backupWid -Leaf)"
    }

    # Copy entry, lib, widgets
    Copy-Item $BundledExtended $TargetExtended -Force
    Write-Ok "statusline-extended.ps1 installed"

    if (-not (Test-Path $TargetLib)) { New-Item -ItemType Directory -Path $TargetLib -Force | Out-Null }
    Copy-Item (Join-Path $BundledLib '*.ps1') $TargetLib -Force
    Write-Ok "lib/ installed ($((Get-ChildItem $TargetLib -Filter '*.ps1').Count) files)"

    if (-not (Test-Path $TargetWidgets)) { New-Item -ItemType Directory -Path $TargetWidgets -Force | Out-Null }
    Copy-Item (Join-Path $BundledWidgets '*.ps1') $TargetWidgets -Force
    Write-Ok "widgets/ installed ($((Get-ChildItem $TargetWidgets -Filter '*.ps1').Count) widgets)"

    # Probe terminal
    Write-Step "Probing terminal capabilities"
    try {
        . (Join-Path $TargetLib 'terminal-probe.ps1')
        $caps = Probe-TerminalCapabilities -Force
        Write-Ok "Capabilities: trueColor=$($caps.trueColor), osc8=$($caps.osc8Hyperlinks), braille=$($caps.braille), term=$($caps.termProgram)"
    } catch {
        Write-Warn2 "Terminal probe failed: $_ (widgets will fall back to safe defaults)"
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
        $settingsBackup = "$SettingsFile.bak.$Stamp"
        Copy-Item $SettingsFile $settingsBackup -Force
        Write-Ok "Backed up settings.json -> $(Split-Path $settingsBackup -Leaf)"
        try {
            $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        } catch {
            Write-Fail "Could not parse $SettingsFile as JSON. Backup at $settingsBackup. Fix the file and re-run."
            exit 1
        }
    } else {
        $settings = [PSCustomObject]@{}
    }

    if ($settings.PSObject.Properties.Match('statusLine').Count -gt 0) {
        Write-Warn2 "Overwriting existing statusLine entry"
        $settings.statusLine = $statusLineBlock
    } else {
        $settings | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue $statusLineBlock -Force
    }

    $settings | ConvertTo-Json -Depth 20 | Set-Content -Path $SettingsFile -Encoding UTF8
    Write-Ok "settings.json patched (statusLine + refreshInterval: 30)"

    Write-Host ""
    Write-Host "Extended statusline installed successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "Restart Claude Code to see the new statusline."
    Write-Host ""
    Write-Host "User widgets: drop additional *.ps1 files into:"
    Write-Host "  $TargetWidgets"
    Write-Host ""
    Write-Host "Sparklines and rate-limit bars need a few minutes of activity"
    Write-Host "before they show data — first tick seeds the sample log."
    Write-Host ""
    Write-Host "To roll back to the Classic variant, re-run:"
    Write-Host "  install.ps1 -Variant Classic"
    exit 0
}

if (-not (Test-Path $BundledScript)) {
    Write-Fail "Bundled script not found at $BundledScript — skill folder is incomplete."
    exit 1
}

if (-not (Test-Path $ClaudeDir)) {
    Write-Step "Creating $ClaudeDir"
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

# --- Load the bundled script as text -----------------------------------------
Write-Step "Loading bundled statusline (baseline v3.1)"
$content = Get-Content $BundledScript -Raw -Encoding UTF8

# --- Customisation 1: bar width ----------------------------------------------
if ($BarWidth -ne 30) {
    Write-Step "Setting bar width to $BarWidth"
    $content = $content -creplace '(?m)^\$BAR_WIDTH\s*=\s*\d+', "`$BAR_WIDTH         = $BarWidth"
    Write-Ok "Bar width applied"
}

# --- Customisation 2: colour palette -----------------------------------------
# Each palette redefines the 10 named colours used by the statusline. Keys
# match the original variable names; values are 'R G B' triplets substituted
# directly into the `Fg R G B` calls on lines ~51-67 of statusline-sparklines.ps1.
#
# Six palettes ship by default — see PALETTES.md in this skill folder (browse
# it on GitHub for colour swatches) for visual previews and the colour theory
# behind each choice.

$palettes = @{
    # Sam's original — purple/gold/teal designed for dark terminals.
    'Sam' = @{
        'C_MODEL'   = '180 140 255'   # purple — model name
        'C_SKILL'   = '130 220 200'   # teal — skill name
        'C_COST'    = '255 220 80'    # gold — session $
        'C_PROJCST' = '255 160 100'   # orange — project $
        'C_ADD'     = '130 220 130'   # green — lines added
        'C_DEL'     = '255 100 100'   # red — lines removed
        'C_TIME'    = '130 180 255'   # blue — duration
        'C_COUNT'   = '200 170 255'   # lavender — session count
        'C_CYAN'    = '80 220 220'    # cyan — effort level
        'C_GOLD'    = '255 200 60'    # gold — burn rate
    }
    # Greyscale — minimal visual noise. Brighter shades reserved for the things
    # you scan for (cost, lines added/removed), dimmer for time/duration.
    'Monochrome' = @{
        'C_MODEL'   = '220 220 220'
        'C_SKILL'   = '180 180 180'
        'C_COST'    = '240 240 240'
        'C_PROJCST' = '200 200 200'
        'C_ADD'     = '200 200 200'
        'C_DEL'     = '160 160 160'
        'C_TIME'    = '170 170 170'
        'C_COUNT'   = '180 180 180'
        'C_CYAN'    = '200 200 200'
        'C_GOLD'    = '220 220 220'
    }
    # Saturated primaries — for bright terminals or colour-vision accessibility.
    # No pastels; every colour is maximally distinct from its neighbours.
    'HighContrast' = @{
        'C_MODEL'   = '255 0 255'    # magenta
        'C_SKILL'   = '0 255 255'    # cyan
        'C_COST'    = '255 255 0'    # yellow
        'C_PROJCST' = '255 128 0'    # orange
        'C_ADD'     = '0 255 0'      # green
        'C_DEL'     = '255 0 0'      # red
        'C_TIME'    = '0 128 255'    # blue
        'C_COUNT'   = '255 0 255'    # magenta
        'C_CYAN'    = '0 255 255'    # cyan
        'C_GOLD'    = '255 255 0'    # yellow
    }
    # Ethan Schoonover's Solarized Dark — muted, warm, 16-colour balanced palette.
    # https://ethanschoonover.com/solarized/
    'Solarized' = @{
        'C_MODEL'   = '108 113 196'  # violet  #6c71c4
        'C_SKILL'   = '42 161 152'   # cyan    #2aa198
        'C_COST'    = '181 137 0'    # yellow  #b58900
        'C_PROJCST' = '203 75 22'    # orange  #cb4b16
        'C_ADD'     = '133 153 0'    # green   #859900
        'C_DEL'     = '220 50 47'    # red     #dc322f
        'C_TIME'    = '38 139 210'   # blue    #268bd2
        'C_COUNT'   = '211 54 130'   # magenta #d33682
        'C_CYAN'    = '42 161 152'   # cyan    #2aa198
        'C_GOLD'    = '181 137 0'    # yellow  #b58900
    }
    # Nord — Arctic-inspired cool/pastel theme.
    # https://www.nordtheme.com/
    'Nord' = @{
        'C_MODEL'   = '180 142 173'  # nord15 purple  #b48ead
        'C_SKILL'   = '143 188 187'  # nord7  teal    #8fbcbb
        'C_COST'    = '235 203 139'  # nord13 yellow  #ebcb8b
        'C_PROJCST' = '208 135 112'  # nord12 orange  #d08770
        'C_ADD'     = '163 190 140'  # nord14 green   #a3be8c
        'C_DEL'     = '191 97 106'   # nord11 red     #bf616a
        'C_TIME'    = '129 161 193'  # nord9  blue    #81a1c1
        'C_COUNT'   = '180 142 173'  # nord15 purple  #b48ead
        'C_CYAN'    = '136 192 208'  # nord8  cyan    #88c0d0
        'C_GOLD'    = '235 203 139'  # nord13 yellow  #ebcb8b
    }
    # Dracula — saturated dark theme; very popular.
    # https://draculatheme.com/
    'Dracula' = @{
        'C_MODEL'   = '189 147 249'  # purple  #bd93f9
        'C_SKILL'   = '139 233 253'  # cyan    #8be9fd
        'C_COST'    = '241 250 140'  # yellow  #f1fa8c
        'C_PROJCST' = '255 184 108'  # orange  #ffb86c
        'C_ADD'     = '80 250 123'   # green   #50fa7b
        'C_DEL'     = '255 85 85'    # red     #ff5555
        'C_TIME'    = '139 233 253'  # cyan    #8be9fd
        'C_COUNT'   = '255 121 198'  # pink    #ff79c6
        'C_CYAN'    = '139 233 253'  # cyan    #8be9fd
        'C_GOLD'    = '241 250 140'  # yellow  #f1fa8c
    }
}

if ($Palette -ne 'Sam') {
    Write-Step "Applying palette: $Palette"
    $p = $palettes[$Palette]
    foreach ($name in $p.Keys) {
        # Match lines like:  $C_MODEL   = Fg 180 140 255      # purple
        # Note: `$ escapes the literal $ in the regex; $name then interpolates the colour name.
        $pattern = "(?m)^\`$$name\s*=\s*Fg\s+\d+\s+\d+\s+\d+"
        $replacement = "`$$name = Fg $($p[$name])"
        $content = $content -creplace $pattern, $replacement
    }
    Write-Ok "Palette applied ($($p.Keys.Count) colours)"
}

# --- Customisation 3: line toggles -------------------------------------------
# Lines we can hide (1 and 2 are essential — model+cost header and CTX bar):
#   3 = 5H usage
#   4 = WK usage
#   5 = WORK duration + diff stats
#
# Strategy: wrap the try block's `Write-Host` calls in `if ($false)` so the
# line is silently suppressed. Easy to flip back by hand-editing.

$lineMap = @{
    'no5h'        = @(3)
    'nowk'        = @(4)
    'nowork'      = @(5)
    'essentials'  = @(3,4,5)   # show only line 1 (header) and line 2 (CTX)
    'all'         = @()
}

$linesToHide = $lineMap[$Lines]
if ($linesToHide.Count -gt 0) {
    Write-Step "Hiding line(s): $($linesToHide -join ', ')"
    foreach ($n in $linesToHide) {
        # Match the `LINE N` comment header through to the closing catch
        $pattern = "(?ms)(# LINE $n.*?\r?\ntry \{)(.*?)(\} catch \{ Write-Host ""\`$\{C_DIM\}\[line$n error\]\`$\{C_RESET\}"" \})"
        $replacement = '$1' + "`r`n    if (`$false) {" + '$2' + "}`r`n" + '$3'
        $content = $content -creplace $pattern, $replacement
    }
    Write-Ok "Lines hidden"
}

# --- Backup existing script if present ---------------------------------------
if (Test-Path $TargetScript) {
    $backup = "$TargetScript.bak.$Stamp"
    Write-Step "Backing up existing script -> $(Split-Path $backup -Leaf)"
    Copy-Item -Path $TargetScript -Destination $backup -Force
    Write-Ok "Backup created"
}

# --- Write the customised script ---------------------------------------------
Write-Step "Writing statusline to $TargetScript"
Set-Content -Path $TargetScript -Value $content -Encoding UTF8
Write-Ok "Script installed ($([math]::Round((Get-Item $TargetScript).Length / 1KB, 1)) KB)"

# --- Patch settings.json -----------------------------------------------------
$statusLineCommand = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + $TargetScript + '"'
$statusLineBlock = [PSCustomObject]@{
    type    = 'command'
    command = $statusLineCommand
    padding = 0
}

if (Test-Path $SettingsFile) {
    $settingsBackup = "$SettingsFile.bak.$Stamp"
    Write-Step "Backing up settings.json -> $(Split-Path $settingsBackup -Leaf)"
    Copy-Item -Path $SettingsFile -Destination $settingsBackup -Force

    try {
        $settings = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Fail "Could not parse $SettingsFile as JSON. Backup at $settingsBackup. Fix the file and re-run."
        exit 1
    }
} else {
    Write-Step "No settings.json found — creating a new one"
    $settings = [PSCustomObject]@{}
}

# PSCustomObject doesn't auto-create missing properties — use Add-Member -Force
if ($settings.PSObject.Properties.Match('statusLine').Count -gt 0) {
    Write-Warn2 "Overwriting existing statusLine entry (old value backed up)"
    $settings.statusLine = $statusLineBlock
} else {
    $settings | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue $statusLineBlock -Force
}

# Write back, preserving everything else
$settings | ConvertTo-Json -Depth 20 | Set-Content -Path $SettingsFile -Encoding UTF8
Write-Ok "settings.json patched"

# --- Done --------------------------------------------------------------------
Write-Host ""
Write-Host "Statusline installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Next step: restart Claude Code to see the new statusline."
Write-Host ""
Write-Host "Want a different colour palette? Six are available — see swatches on GitHub:"
Write-Host "  https://github.com/Sampi314/Sam-Plugin-Marketplace/blob/main/Claude%20Setup/skills/cs-statusline-setup/PALETTES.md"
Write-Host "Then re-run install.ps1 with -Palette <name>."
Write-Host ""
Write-Host "If anything looks wrong, your originals are backed up with the timestamp ${Stamp}:"
Write-Host "  $TargetScript.bak.$Stamp"
Write-Host "  $SettingsFile.bak.$Stamp"

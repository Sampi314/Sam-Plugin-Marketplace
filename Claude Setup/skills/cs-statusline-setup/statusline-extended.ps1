# ============================================================================
# statusline-extended.ps1 — Widget-host entry point (Phase 1)
# ============================================================================
#
# This is the Extended-variant entry point installed at
# ~/.claude/statusline-extended.ps1. It reads JSON on stdin, loads the lib
# modules + widget pack, invokes the widget host, and prints the rendered
# statusline to stdout.
#
# Bundled widgets live in: ~/.claude/statusline-widgets/
# User widgets (override bundled by name): same directory; user-managed
# ============================================================================

$ErrorActionPreference = 'Continue'

# --- Resolve paths -----------------------------------------------------------
$ClaudeDir   = Join-Path $env:USERPROFILE '.claude'
$LibDir      = Join-Path $ClaudeDir 'lib'
$WidgetsDir  = Join-Path $ClaudeDir 'statusline-widgets'

# Optional override (env: CS_BUNDLE_ROOT) — point lib and widgets at a non-default
# root. Used by the web customizer to invoke the bundled (not-yet-installed)
# version directly without copying files into a sandbox dir.
if ($env:CS_BUNDLE_ROOT -and (Test-Path $env:CS_BUNDLE_ROOT)) {
    $LibDir     = Join-Path $env:CS_BUNDLE_ROOT 'lib'
    $WidgetsDir = Join-Path $env:CS_BUNDLE_ROOT 'widgets'
} elseif (-not (Test-Path $LibDir)) {
    # Allow running uninstalled: detect bundled location if libs aren't installed yet
    $here = Split-Path -Parent $PSCommandPath
    $LibDir = Join-Path $here 'lib'
    $WidgetsDir = Join-Path $here 'widgets'
}

# --- Load libs ---------------------------------------------------------------
foreach ($lib in @('ansi.ps1','braille.ps1','credential-helper.ps1','terminal-probe.ps1','sample-log.ps1','events-emitter.ps1','skill-detector.ps1','widget-host.ps1')) {
    $p = Join-Path $LibDir $lib
    if (Test-Path $p) { . $p }
}

# --- Read stdin --------------------------------------------------------------
$inputJson = $null
try {
    $pipeLines = @($input)
    if ($pipeLines.Count -gt 0) { $inputJson = $pipeLines -join "`n" }
} catch {}
if (-not $inputJson) {
    try { $inputJson = [Console]::In.ReadToEnd() } catch {}
}
if (-not $inputJson) {
    Write-Host 'Claude Code -- waiting for data'
    exit 0
}

try { $ctx = $inputJson | ConvertFrom-Json -ErrorAction Stop }
catch {
    Write-Host 'statusline-extended: stdin not valid JSON'
    exit 0
}

# --- Terminal capabilities + ANSI ctx ----------------------------------------
$caps = Get-TerminalCapabilities
$ansi = New-AnsiContext -Capabilities @{
    trueColor      = $caps.trueColor
    osc8Hyperlinks = $caps.osc8Hyperlinks
}

# --- Palette (default: Sam) --------------------------------------------------
# Widgets accept colour values from this hashtable. Future enhancement: load
# palette from settings.json or a per-user override file.
$colors = @{
    C_LABEL   = $ansi.Fg(140,140,160)
    C_MODEL   = $ansi.Fg(180,140,255)
    C_SKILL   = $ansi.Fg(130,220,200)
    C_COST    = $ansi.Fg(255,220,80)
    C_PROJCST = $ansi.Fg(255,160,100)
    C_ADD     = $ansi.Fg(130,220,130)
    C_DEL     = $ansi.Fg(255,100,100)
    C_TIME    = $ansi.Fg(130,180,255)
    C_COUNT   = $ansi.Fg(200,170,255)
    C_DIM     = $ansi.Fg(80,80,100)
    C_DIVIDER = $ansi.Fg(90,90,110)
    C_CYAN    = $ansi.Fg(80,220,220)
    C_GREEN   = $ansi.Fg(130,220,130)
    C_YELLOW  = $ansi.Fg(255,220,80)
    C_RED     = $ansi.Fg(255,80,80)
    C_GOLD    = $ansi.Fg(255,200,60)
    C_RESET   = $ansi.Reset()
    C_BOLD    = $ansi.Bold()
    C_ITALIC  = $ansi.Italic()
}

# --- Optional palette override (env: CS_PALETTE_OVERRIDE) --------------------
# Lets a customizer (web UI, wizard) preview alternative palettes without
# rewriting this script. No-op unless the env var matches a known name.
if ($env:CS_PALETTE_OVERRIDE) {
    $paletteOverrides = @{
        'Sam'          = @{ C_MODEL='180 140 255'; C_SKILL='130 220 200'; C_COST='255 220 80'; C_PROJCST='255 160 100'; C_ADD='130 220 130'; C_DEL='255 100 100'; C_TIME='130 180 255'; C_COUNT='200 170 255'; C_CYAN='80 220 220'; C_GOLD='255 200 60' }
        'Monochrome'   = @{ C_MODEL='220 220 220'; C_SKILL='180 180 180'; C_COST='240 240 240'; C_PROJCST='200 200 200'; C_ADD='200 200 200'; C_DEL='160 160 160'; C_TIME='170 170 170'; C_COUNT='180 180 180'; C_CYAN='200 200 200'; C_GOLD='220 220 220' }
        'HighContrast' = @{ C_MODEL='255 0 255';   C_SKILL='0 255 255';   C_COST='255 255 0';   C_PROJCST='255 128 0';   C_ADD='0 255 0';     C_DEL='255 0 0';     C_TIME='0 128 255';   C_COUNT='255 0 255';   C_CYAN='0 255 255';   C_GOLD='255 255 0' }
        'Solarized'    = @{ C_MODEL='108 113 196'; C_SKILL='42 161 152';  C_COST='181 137 0';   C_PROJCST='203 75 22';   C_ADD='133 153 0';   C_DEL='220 50 47';   C_TIME='38 139 210';  C_COUNT='211 54 130';  C_CYAN='42 161 152';  C_GOLD='181 137 0' }
        'Nord'         = @{ C_MODEL='180 142 173'; C_SKILL='143 188 187'; C_COST='235 203 139'; C_PROJCST='208 135 112'; C_ADD='163 190 140'; C_DEL='191 97 106';  C_TIME='129 161 193'; C_COUNT='180 142 173'; C_CYAN='136 192 208'; C_GOLD='235 203 139' }
        'Dracula'      = @{ C_MODEL='189 147 249'; C_SKILL='139 233 253'; C_COST='241 250 140'; C_PROJCST='255 184 108'; C_ADD='80 250 123';  C_DEL='255 85 85';   C_TIME='139 233 253'; C_COUNT='255 121 198'; C_CYAN='139 233 253'; C_GOLD='241 250 140' }
    }
    if ($paletteOverrides.ContainsKey($env:CS_PALETTE_OVERRIDE)) {
        $pal = $paletteOverrides[$env:CS_PALETTE_OVERRIDE]
        foreach ($key in $pal.Keys) {
            $t = $pal[$key] -split '\s+'
            $colors[$key] = $ansi.Fg([int]$t[0], [int]$t[1], [int]$t[2])
        }
    }
}

# --- Optional custom palette (env: CS_PALETTE_CUSTOM_JSON) -------------------
# Lets a customizer hand-pick individual colours via JSON like
# {"C_MODEL":"200 100 250", "C_COST":"255 220 80", ...}
# Applied after the named-palette override, so individual roles override the base.
if ($env:CS_PALETTE_CUSTOM_JSON) {
    try {
        $custom = $env:CS_PALETTE_CUSTOM_JSON | ConvertFrom-Json -ErrorAction Stop
        foreach ($prop in $custom.PSObject.Properties) {
            $key = $prop.Name
            if ($colors.ContainsKey($key)) {
                $t = ([string]$prop.Value) -split '\s+'
                if ($t.Count -ge 3) {
                    $colors[$key] = $ansi.Fg([int]$t[0], [int]$t[1], [int]$t[2])
                }
            }
        }
    } catch {}
}

# --- Terminal width (Bundle B foundation) ------------------------------------
$termWidth = 100
if ($env:COLUMNS) {
    $w = 0
    if ([int]::TryParse($env:COLUMNS, [ref]$w) -and $w -gt 20) { $termWidth = $w }
}

# --- Sample the current tick (Bundle C foundation) ---------------------------
$sessionId  = if ($ctx.session_id) { $ctx.session_id } else { 'unknown' }
$costPerMin = 0.0
if ($ctx.cost -and $ctx.cost.total_cost_usd -and $ctx.cost.total_duration_ms -and $ctx.cost.total_duration_ms -gt 0) {
    $costPerMin = ([double]$ctx.cost.total_cost_usd) / (([double]$ctx.cost.total_duration_ms) / 60000.0)
}
$ctxPct = 0
if ($ctx.context_window -and $null -ne $ctx.context_window.used_percentage) {
    $ctxPct = [double]$ctx.context_window.used_percentage
}

if (-not $env:CS_PREVIEW_MODE -and (Get-Command Add-StatuslineSample -ErrorAction SilentlyContinue)) {
    Add-StatuslineSample -SessionId $sessionId -Metrics @{
        cost_per_min = $costPerMin
        ctx_pct      = $ctxPct
        cost_total   = if ($ctx.cost) { [double]$ctx.cost.total_cost_usd } else { 0 }
    }
}

# --- Emit baseline tick event (Layer 32) -------------------------------------
if (-not $env:CS_PREVIEW_MODE -and (Get-Command Emit-Event -ErrorAction SilentlyContinue)) {
    Emit-Event -Type 'tick' -Payload @{
        session_id   = $sessionId
        ctx_pct      = $ctxPct
        cost_per_min = $costPerMin
    }

    # Threshold tracking
    Test-AndEmit-Threshold -Key 'ctx' -Value $ctxPct
    if ($ctx.rate_limits) {
        if ($ctx.rate_limits.five_hour -and $null -ne $ctx.rate_limits.five_hour.used_percentage) {
            Test-AndEmit-Threshold -Key '5h' -Value ([double]$ctx.rate_limits.five_hour.used_percentage)
        }
        if ($ctx.rate_limits.seven_day -and $null -ne $ctx.rate_limits.seven_day.used_percentage) {
            Test-AndEmit-Threshold -Key 'wk' -Value ([double]$ctx.rate_limits.seven_day.used_percentage)
        }
    }
}

# --- Discover widgets and render ---------------------------------------------
# Discover base widget manifests from the install/widgets dir. These are the
# *templates*; the actual render set is determined by the instance list below.
$baseManifests = @{}
foreach ($w in (Get-WidgetManifests -BundledDirs @() -UserDirs @($WidgetsDir))) {
    if ($w.Name) { $baseManifests[$w.Name] = $w }
}

# Helper: clone a base manifest so per-instance State overrides don't bleed
# back into the template. Render is reference-shared (it's pure code).
function Clone-WidgetForInstance($base, $instanceId) {
    $clone = @{}
    foreach ($k in $base.Keys) {
        if ($k -eq 'State') {
            $sc = @{}
            if ($base.State) { foreach ($sk in $base.State.Keys) { $sc[$sk] = $base.State[$sk] } }
            $clone[$k] = $sc
        } else { $clone[$k] = $base[$k] }
    }
    $clone._InstanceId = $instanceId
    return $clone
}

# Resolve the instance list. Source precedence:
#   1. $env:CS_LAYOUT_OVERRIDE  (set by the web customizer for preview)
#   2. ~/.claude/statusline-instances.json  (written by apply.ps1 for production)
#   3. fall back to one instance per base manifest at its declared defaults
$instanceSource = $null
if ($env:CS_LAYOUT_OVERRIDE) {
    try { $instanceSource = $env:CS_LAYOUT_OVERRIDE | ConvertFrom-Json -ErrorAction Stop } catch {}
}
if (-not $instanceSource) {
    $instancesFile = Join-Path $ClaudeDir 'statusline-instances.json'
    if (Test-Path $instancesFile) {
        try { $instanceSource = Get-Content $instancesFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch {}
    }
}

# Build the render set. Three input shapes accepted:
#   - Array of {id, name, line, position, priority, ...state}  (instance list)
#   - Object {name: {line,position,priority,...state}}         (legacy, one instance per key)
#   - $null                                                    (one instance per base, defaults)
$reservedLayoutKeys = @('id','name','line','position','priority')
$widgets = @()
if ($instanceSource -is [System.Collections.IList]) {
    foreach ($entry in $instanceSource) {
        if (-not $entry.name) { continue }
        $base = $baseManifests[[string]$entry.name]
        if (-not $base) { continue }
        $id = if ($entry.id) { [string]$entry.id } else { "$($entry.name)-$([guid]::NewGuid().ToString('N').Substring(0,4))" }
        $w = Clone-WidgetForInstance $base $id
        if ($null -ne $entry.line)     { $w.Line     = [int]$entry.line }
        if ($entry.position)           { $w.Position = [string]$entry.position }
        if ($null -ne $entry.priority) { $w.Priority = [int]$entry.priority }
        foreach ($prop in $entry.PSObject.Properties) {
            if ($reservedLayoutKeys -contains $prop.Name) { continue }
            $w.State[$prop.Name] = $prop.Value
        }
        $widgets += ,$w
    }
    # The layout host is structural — always include even if the SPA forgot it
    if (-not ($widgets | Where-Object { $_.Name -eq 'mode-aware' })) {
        if ($baseManifests.ContainsKey('mode-aware')) {
            $widgets += ,(Clone-WidgetForInstance $baseManifests['mode-aware'] 'mode-aware-host')
        }
    }
} elseif ($instanceSource) {
    # Legacy object form — one instance per key
    foreach ($prop in $instanceSource.PSObject.Properties) {
        $base = $baseManifests[$prop.Name]
        if (-not $base) { continue }
        $entry = $prop.Value
        $w = Clone-WidgetForInstance $base $prop.Name
        if ($null -ne $entry.line)     { $w.Line     = [int]$entry.line }
        if ($entry.position)           { $w.Position = [string]$entry.position }
        if ($null -ne $entry.priority) { $w.Priority = [int]$entry.priority }
        foreach ($sp in $entry.PSObject.Properties) {
            if ($reservedLayoutKeys -contains $sp.Name) { continue }
            $w.State[$sp.Name] = $sp.Value
        }
        $widgets += ,$w
    }
    # Add any base widget not in the override (keeps "all-widgets" production behaviour)
    foreach ($name in $baseManifests.Keys) {
        if (-not ($widgets | Where-Object { $_.Name -eq $name })) {
            $widgets += ,(Clone-WidgetForInstance $baseManifests[$name] $name)
        }
    }
} else {
    # No override anywhere — one instance per base at its declared defaults
    foreach ($name in $baseManifests.Keys) {
        $widgets += ,(Clone-WidgetForInstance $baseManifests[$name] $name)
    }
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$lines = Render-Statusline -Ctx $ctx -Caps $caps -Colors $colors -Ansi $ansi -Widgets $widgets -TerminalWidth $termWidth

foreach ($line in $lines) { Write-Host $line }

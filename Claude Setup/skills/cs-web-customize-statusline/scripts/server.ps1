# ============================================================================
# server.ps1 — loopback HTTP server backing the web customizer SPA
# ============================================================================
#
# Routes:
#   GET  /                       -> www/index.html
#   GET  /styles.css             -> www/styles.css
#   GET  /app.js                 -> www/app.js
#   GET  /api/manifest           -> JSON of widgets + palettes + variants
#   POST /api/preview            -> body: {variant,widgets[],palette,barWidth,lines}
#                                   resp: {html: "<pre>...</pre>"}
#   POST /api/apply              -> body: same as preview
#                                   resp: {ok: bool, output: string, stamp: string}
#   POST /api/shutdown           -> resp: {ok: true}, then halts the loop
#
# Binds 127.0.0.1 only. Single-threaded GetContext() loop — fine for a
# single-user local UI.
# ============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory)] [int]$Port,
    [Parameter(Mandatory)] [string]$SetupRoot,        # plugin's cs-statusline-setup folder
    [Parameter(Mandatory)] [string]$CustomizerRoot    # plugin's cs-customize-statusline folder
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $PSCommandPath
$WwwDir    = Join-Path (Split-Path $ScriptDir -Parent) 'www'
. (Join-Path $ScriptDir 'ansi-to-html.ps1')

$BundledExtended = Join-Path $SetupRoot 'statusline-extended.ps1'
$BundledLib      = Join-Path $SetupRoot 'lib'
$BundledWidgets  = Join-Path $SetupRoot 'widgets'
$MockDataPath    = Join-Path $CustomizerRoot 'mock-data.json'
$ApplyScript     = Join-Path $CustomizerRoot 'scripts\apply.ps1'

if (-not (Test-Path $BundledExtended)) { throw "statusline-extended.ps1 missing at $BundledExtended" }
if (-not (Test-Path $MockDataPath))    { throw "mock-data.json missing at $MockDataPath" }

# Palette table — duplicated from install.ps1 so the SPA can show colour swatches
# without having to grep the install script over the wire. If install.ps1's palette
# table changes, update this too.
$PaletteTable = @{
    'Sam' = @{
        'C_MODEL' = '180 140 255'; 'C_SKILL' = '130 220 200'; 'C_COST' = '255 220 80'
        'C_PROJCST' = '255 160 100'; 'C_ADD' = '130 220 130'; 'C_DEL' = '255 100 100'
        'C_TIME' = '130 180 255'; 'C_COUNT' = '200 170 255'; 'C_CYAN' = '80 220 220'
        'C_GOLD' = '255 200 60'
    }
    'Monochrome' = @{
        'C_MODEL' = '220 220 220'; 'C_SKILL' = '180 180 180'; 'C_COST' = '240 240 240'
        'C_PROJCST' = '200 200 200'; 'C_ADD' = '200 200 200'; 'C_DEL' = '160 160 160'
        'C_TIME' = '170 170 170'; 'C_COUNT' = '180 180 180'; 'C_CYAN' = '200 200 200'
        'C_GOLD' = '220 220 220'
    }
    'HighContrast' = @{
        'C_MODEL' = '255 0 255'; 'C_SKILL' = '0 255 255'; 'C_COST' = '255 255 0'
        'C_PROJCST' = '255 128 0'; 'C_ADD' = '0 255 0'; 'C_DEL' = '255 0 0'
        'C_TIME' = '0 128 255'; 'C_COUNT' = '255 0 255'; 'C_CYAN' = '0 255 255'
        'C_GOLD' = '255 255 0'
    }
    'Solarized' = @{
        'C_MODEL' = '108 113 196'; 'C_SKILL' = '42 161 152'; 'C_COST' = '181 137 0'
        'C_PROJCST' = '203 75 22'; 'C_ADD' = '133 153 0'; 'C_DEL' = '220 50 47'
        'C_TIME' = '38 139 210'; 'C_COUNT' = '211 54 130'; 'C_CYAN' = '42 161 152'
        'C_GOLD' = '181 137 0'
    }
    'Nord' = @{
        'C_MODEL' = '180 142 173'; 'C_SKILL' = '143 188 187'; 'C_COST' = '235 203 139'
        'C_PROJCST' = '208 135 112'; 'C_ADD' = '163 190 140'; 'C_DEL' = '191 97 106'
        'C_TIME' = '129 161 193'; 'C_COUNT' = '180 142 173'; 'C_CYAN' = '136 192 208'
        'C_GOLD' = '235 203 139'
    }
    'Dracula' = @{
        'C_MODEL' = '189 147 249'; 'C_SKILL' = '139 233 253'; 'C_COST' = '241 250 140'
        'C_PROJCST' = '255 184 108'; 'C_ADD' = '80 250 123'; 'C_DEL' = '255 85 85'
        'C_TIME' = '139 233 253'; 'C_COUNT' = '255 121 198'; 'C_CYAN' = '139 233 253'
        'C_GOLD' = '241 250 140'
    }
}

function Convert-RgbTripleToHex([string]$triple) {
    $parts = $triple -split '\s+'
    return ('#{0:x2}{1:x2}{2:x2}' -f [int]$parts[0], [int]$parts[1], [int]$parts[2])
}

function Get-WidgetManifest {
    # Source each bundled widget file and surface its Name/Line/Position.
    # The widgets are pure manifest hashtables — sourcing them is safe (no side effects).
    $widgets = @()
    foreach ($f in (Get-ChildItem $BundledWidgets -Filter '*.ps1' | Sort-Object Name)) {
        try {
            $m = & $f.FullName
            if ($m -and $m.Name) {
                $widgets += [PSCustomObject]@{
                    file        = $f.Name
                    name        = $m.Name
                    line        = $m.Line
                    position    = $m.Position
                    priority    = $m.Priority
                    capability  = @($m.Capability)
                    description = Get-WidgetDescription $m.Name
                }
            }
        } catch {}
    }
    return $widgets
}

function Get-WidgetDescription([string]$name) {
    switch ($name) {
        'core-header'                { 'Model + effort + session cost + project (link) + version' }
        'thinking'                   { 'Brain icon when extended thinking is on' }
        'output-style'               { 'Current output-style name when non-default' }
        'session-fingerprint'        { 'Stable emoji that uniquely identifies this session' }
        'core-ctx'                   { 'Context-window fill bar; colour escalates against the real window size' }
        'core-rate-5h'               { '5-hour Anthropic rate-limit bar (built-in or OAuth fallback)' }
        'core-rate-wk'               { 'Weekly Anthropic rate-limit bar' }
        'core-work'                  { 'Session duration + lines added/removed + active/idle ratio' }
        'git-status'                 { 'Branch + porcelain status + age of last commit' }
        'pr-badge'                   { 'Open PR with colour-coded review state, links to PR' }
        'sparkline-cost'             { 'Braille mini-chart of $/min over recent ticks' }
        'sparkline-ctx'              { 'Braille mini-chart of context % over recent ticks' }
        'mode-aware'                 { 'Layout switcher (emergency / agent / compact / learning / default)' }
        'skill-audit-general'        { 'Audit progress overlay when audit-general skill is active' }
        'skill-financial-modelling'  { 'Financial-modelling phase indicator when active' }
        'skill-writing-tools'        { 'Writing-tools progress overlay when active' }
        'clock'                      { 'Current local time (HH:MM, optionally with seconds or 12h)' }
        'date'                       { 'Current local date (default yyyy-MM-dd, format configurable)' }
        'cwd'                        { 'Current working directory with smart truncation' }
        'token-breakdown'            { 'Current-tick input / output / cache tokens explicit' }
        'spacer'                     { 'User-customisable text widget (dividers, mottos, badges)' }
        default                      { '' }
    }
}

function Get-PaletteManifest {
    $palettes = @()
    foreach ($name in @('Sam','Monochrome','HighContrast','Solarized','Nord','Dracula')) {
        $p = $PaletteTable[$name]
        $palettes += [PSCustomObject]@{
            name    = $name
            colors  = @{
                model   = Convert-RgbTripleToHex $p['C_MODEL']
                skill   = Convert-RgbTripleToHex $p['C_SKILL']
                cost    = Convert-RgbTripleToHex $p['C_COST']
                project = Convert-RgbTripleToHex $p['C_PROJCST']
                added   = Convert-RgbTripleToHex $p['C_ADD']
                removed = Convert-RgbTripleToHex $p['C_DEL']
                time    = Convert-RgbTripleToHex $p['C_TIME']
                count   = Convert-RgbTripleToHex $p['C_COUNT']
                cyan    = Convert-RgbTripleToHex $p['C_CYAN']
                gold    = Convert-RgbTripleToHex $p['C_GOLD']
            }
        }
    }
    return $palettes
}

# Cache the mock JSON once at server startup — re-reading on every preview is wasteful.
$script:CachedMockJson = Get-Content $MockDataPath -Raw -Encoding UTF8

# Probe for pwsh (PowerShell 7+) at startup. It's noticeably faster than
# powershell.exe (Windows PowerShell 5.1) for our workload, so prefer it.
$script:PsExecutable = $null
try {
    $pwshCmd = Get-Command 'pwsh' -ErrorAction Stop
    if ($pwshCmd) { $script:PsExecutable = $pwshCmd.Source }
} catch {
    $script:PsExecutable = 'powershell'
}

function Render-Preview {
    param(
        [string]$Variant,
        [object]$Instances = $null,       # Array of {id,name,line,column,position,priority,...state}
        [string]$Palette,
        [int]$BarWidth,
        [string]$Lines,
        [int]$Columns = 3,
        [object]$CustomPalette = $null    # PSCustomObject: role -> "R G B"
    )

    if ($Variant -eq 'Classic') {
        return '<pre class="statusline classic-notice">' +
               'Live preview for the Classic variant is not implemented yet. ' +
               'Apply will still work — the installer customises the script directly.' +
               '</pre>'
    }

    # Snapshot env so we restore cleanly even on error
    $prev = @{
        CS_BUNDLE_ROOT          = $env:CS_BUNDLE_ROOT
        CS_PALETTE_OVERRIDE     = $env:CS_PALETTE_OVERRIDE
        CS_PALETTE_CUSTOM_JSON  = $env:CS_PALETTE_CUSTOM_JSON
        CS_LAYOUT_OVERRIDE      = $env:CS_LAYOUT_OVERRIDE
        CS_LAYOUT_COLUMNS       = $env:CS_LAYOUT_COLUMNS
        CS_PREVIEW_MODE         = $env:CS_PREVIEW_MODE
    }

    try {
        $env:CS_BUNDLE_ROOT      = $SetupRoot
        $env:CS_PALETTE_OVERRIDE = $Palette
        $env:CS_LAYOUT_COLUMNS   = [string]$Columns
        $env:CS_PREVIEW_MODE     = '1'

        # Instances are the single source of truth. The bundled script accepts
        # CS_LAYOUT_OVERRIDE as either an array (instance list) or an object
        # (legacy keyed-by-name). The SPA always sends the array form.
        $instanceList = @()
        if ($Instances) {
            foreach ($i in $Instances) { $instanceList += ,$i }
        }

        # Apply the global BarWidth as a state default for bar instances that
        # don't already have one. Lets the "Bar width" slider still affect bars
        # when the user hasn't tweaked them individually.
        if ($BarWidth -gt 0 -and $BarWidth -ne 24) {
            foreach ($inst in $instanceList) {
                if (@('core-ctx','core-rate-5h','core-rate-wk') -contains [string]$inst.name) {
                    if (-not $inst.PSObject.Properties['barWidth']) {
                        $inst | Add-Member -NotePropertyName 'barWidth' -NotePropertyValue $BarWidth -Force
                    }
                }
            }
        }

        if ($instanceList.Count -gt 0) {
            # Force array form regardless of length (PS 5.1's ConvertTo-Json
            # unrolls single-element arrays). Manually wrap with brackets so
            # the bundled script sees [{...}] for 1 instance too.
            $itemJsons = @($instanceList | ForEach-Object { $_ | ConvertTo-Json -Depth 5 -Compress })
            $env:CS_LAYOUT_OVERRIDE = '[' + ($itemJsons -join ',') + ']'
        } else {
            $env:CS_LAYOUT_OVERRIDE = $null
        }

        if ($CustomPalette) {
            $env:CS_PALETTE_CUSTOM_JSON = ($CustomPalette | ConvertTo-Json -Depth 4 -Compress)
        } else {
            $env:CS_PALETTE_CUSTOM_JSON = $null
        }

        # Direct invocation — no sandbox, no copies. Mock JSON piped on stdin.
        # pwsh (7+) renders the statusline ~2x faster than powershell (5.1) for this
        # workload, so prefer it when available; fall back to powershell otherwise.
        $ps = if ($script:PsExecutable) { $script:PsExecutable } else { 'powershell' }
        $stdout = $script:CachedMockJson | & $ps -NoProfile -ExecutionPolicy Bypass -File $BundledExtended 2>&1
        $raw = ($stdout | Out-String).TrimEnd("`r","`n")
        return ConvertFrom-AnsiToHtml -Text $raw
    } catch {
        return '<pre class="statusline error">Preview error: ' + ([string]$_).Replace('<','&lt;').Replace('>','&gt;') + '</pre>'
    } finally {
        foreach ($k in $prev.Keys) { Set-Item "env:$k" $prev[$k] -ErrorAction SilentlyContinue }
    }
}

function Invoke-Apply {
    param(
        [string]$Variant,
        [string[]]$Widgets,
        [string]$Palette,
        [int]$BarWidth,
        [string]$Lines
    )
    if (-not (Test-Path $ApplyScript)) {
        return @{ ok = $false; output = "apply.ps1 missing at $ApplyScript" }
    }
    $args = @('-Variant', $Variant, '-Palette', $Palette, '-BarWidth', $BarWidth, '-Lines', $Lines)
    if ($Widgets -and $Widgets.Count -gt 0) {
        $args += '-Widgets'
        $args += ($Widgets -join ',')
    }
    try {
        $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $ApplyScript @args 2>&1
        $text = ($out | Out-String)
        return @{ ok = ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE); output = $text }
    } catch {
        return @{ ok = $false; output = ([string]$_) }
    }
}

# --- HTTP plumbing --------------------------------------------------------

$mimeMap = @{
    '.html' = 'text/html; charset=utf-8'
    '.css'  = 'text/css; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.json' = 'application/json; charset=utf-8'
    '.svg'  = 'image/svg+xml'
}

function Send-StringResponse {
    param($Response, [string]$Body, [string]$ContentType = 'text/plain; charset=utf-8', [int]$Status = 200)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
    $Response.StatusCode = $Status
    $Response.ContentType = $ContentType
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}

function Send-FileResponse {
    param($Response, [string]$Path)
    if (-not (Test-Path $Path)) {
        Send-StringResponse -Response $Response -Body 'Not found' -Status 404
        return
    }
    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    $ct = if ($mimeMap.ContainsKey($ext)) { $mimeMap[$ext] } else { 'application/octet-stream' }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $Response.StatusCode = 200
    $Response.ContentType = $ct
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}

function Read-RequestBody {
    param($Request)
    if ($Request.ContentLength64 -le 0) { return '' }
    $reader = [System.IO.StreamReader]::new($Request.InputStream, [System.Text.Encoding]::UTF8)
    try { return $reader.ReadToEnd() } finally { $reader.Close() }
}

$listener = [System.Net.HttpListener]::new()
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()

Write-Host "Server listening on $prefix" -ForegroundColor Cyan

$shouldStop = $false
while (-not $shouldStop) {
    try {
        $ctx = $listener.GetContext()
    } catch {
        break
    }
    $req = $ctx.Request
    $res = $ctx.Response
    $route = "$($req.HttpMethod) $($req.Url.AbsolutePath)"

    try {
        switch -Regex ($route) {
            '^GET /$' {
                Send-FileResponse -Response $res -Path (Join-Path $WwwDir 'index.html')
            }
            '^GET /(styles\.css|app\.js)$' {
                $file = $req.Url.AbsolutePath.TrimStart('/')
                Send-FileResponse -Response $res -Path (Join-Path $WwwDir $file)
            }
            '^GET /api/manifest$' {
                $manifest = @{
                    variants = @('Extended','Classic')
                    palettes = Get-PaletteManifest
                    widgets  = Get-WidgetManifest
                    lineOpts = @('all','no5h','nowk','nowork','essentials')
                }
                Send-StringResponse -Response $res -Body ($manifest | ConvertTo-Json -Depth 10 -Compress) -ContentType 'application/json; charset=utf-8'
            }
            '^POST /api/widget-previews$' {
                $bodyText = Read-RequestBody -Request $req
                $body = $bodyText | ConvertFrom-Json
                # Render every widget on its own line, prefixed with a marker
                # spacer (invisible-coloured text "##name##"). One statusline
                # invocation, then per-line: grep the marker, strip prefix,
                # return clean HTML per widget.
                $widgetNames = @((Get-WidgetManifest | Where-Object { $_.name -ne 'mode-aware' }).name)
                $instanceArr = @()
                $lineNo = 1
                foreach ($n in $widgetNames) {
                    $instanceArr += ,@{ id="m-$lineNo"; name='spacer'; line=$lineNo; position='left'; priority=1; text="##$n##"; color='#000001' }
                    $instanceArr += ,@{ id="w-$lineNo"; name=$n;     line=$lineNo; position='left'; priority=10 }
                    if ($n -eq 'spacer') {
                        # The widget itself is a spacer — give it actual text so the demo line is non-empty
                        $instanceArr[-1].text = '|'
                        $instanceArr[-1].color = '#888888'
                    }
                    $lineNo++
                }
                $instanceArr += ,@{ id='mode-aware'; name='mode-aware'; line=999; position='left'; priority=99 }

                $html = Render-Preview `
                    -Variant 'Extended' `
                    -Instances $instanceArr `
                    -Palette ([string]$body.palette) `
                    -BarWidth 24 `
                    -Lines 'all' `
                    -CustomPalette $body.customPalette

                $previews = @{}
                foreach ($n in $widgetNames) { $previews[$n] = '' }
                if ($html -match '(?s)<pre class="statusline">(.*?)</pre>') {
                    $inner = $Matches[1]
                    foreach ($lineHtml in ($inner -split "`n")) {
                        if ($lineHtml -match '##([\w-]+)##') {
                            $wn = $Matches[1]
                            # Strip the marker span + the host's ` | ` separator span.
                            $stripped = $lineHtml -replace '<span[^>]*>##[\w-]+##</span>\s*<span[^>]*>\s*\|\s*</span>\s*', ''
                            $previews[$wn] = '<pre class="statusline">' + $stripped + '</pre>'
                        }
                    }
                }
                $payload = @{ previews = $previews } | ConvertTo-Json -Depth 5 -Compress
                Send-StringResponse -Response $res -Body $payload -ContentType 'application/json; charset=utf-8'
            }
            '^POST /api/preview$' {
                $bodyText = Read-RequestBody -Request $req
                $body = $bodyText | ConvertFrom-Json
                $instances = if ($body.instances) { @($body.instances) } else { @() }
                $cols = if ($body.columns) { [int]$body.columns } else { 3 }
                $html = Render-Preview `
                    -Variant        ([string]$body.variant) `
                    -Instances      $instances `
                    -Palette        ([string]$body.palette) `
                    -BarWidth       ([int]($body.barWidth)) `
                    -Lines          ([string]$body.lines) `
                    -Columns        $cols `
                    -CustomPalette  $body.customPalette
                $payload = @{ html = $html } | ConvertTo-Json -Depth 4 -Compress
                Send-StringResponse -Response $res -Body $payload -ContentType 'application/json; charset=utf-8'
            }
            '^POST /api/apply$' {
                $bodyText = Read-RequestBody -Request $req
                $body = $bodyText | ConvertFrom-Json
                $widgets = if ($body.widgets) { @($body.widgets) } else { @() }
                $result = Invoke-Apply `
                    -Variant  ([string]$body.variant) `
                    -Widgets  $widgets `
                    -Palette  ([string]$body.palette) `
                    -BarWidth ([int]($body.barWidth)) `
                    -Lines    ([string]$body.lines)
                $payload = $result | ConvertTo-Json -Depth 4 -Compress
                Send-StringResponse -Response $res -Body $payload -ContentType 'application/json; charset=utf-8'
            }
            '^POST /api/shutdown$' {
                Send-StringResponse -Response $res -Body '{"ok":true}' -ContentType 'application/json; charset=utf-8'
                $shouldStop = $true
            }
            default {
                Send-StringResponse -Response $res -Body 'Not found' -Status 404
            }
        }
    } catch {
        $err = ([string]$_).Replace('<','&lt;').Replace('>','&gt;')
        try { Send-StringResponse -Response $res -Body "Server error: $err" -Status 500 } catch {}
    }
}

$listener.Stop()
$listener.Close()
Write-Host "Server stopped" -ForegroundColor Cyan

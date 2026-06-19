# ============================================================================
# lib/widget-host.ps1 — Widget discovery, scheduling, and layout engine
# ============================================================================
#
# Widgets are PowerShell scripts that dot-source-evaluate to a manifest hash:
#   @{
#       Name        = 'core-header'
#       Line        = 1
#       Position    = 'left'             # left | right | full
#       Priority    = 10                 # within (Line,Position), lower first
#       RefreshEvery = 0                 # 0 = every tick; N = cache N seconds
#       Capability  = @()                # required capability flags from probe
#       Render      = { param($ctx,$caps,$colors,$ansi,$state) ... return string }
#   }
#
# Discovery order: bundled widgets first (./widgets/), then user widgets
# (~/.claude/statusline-widgets/). User widgets with the same Name OVERRIDE
# bundled — that's how users replace built-in widgets.
#
# Layout:
#   - Group widgets by Line, then by Position
#   - 'left' widgets joined with ' | '; 'right' widgets right-aligned in
#     remaining width; 'full' takes the whole line alone
# ============================================================================

$script:WIDGET_CACHE = @{}        # in-process per-widget result cache

function Get-WidgetManifests {
    [CmdletBinding()]
    param(
        [string[]]$BundledDirs,
        [string[]]$UserDirs
    )

    $manifests = @{}   # keyed by Name; user dirs OVERRIDE bundled

    foreach ($dir in (@($BundledDirs) + @($UserDirs))) {
        if (-not $dir -or -not (Test-Path $dir)) { continue }
        $files = Get-ChildItem -Path $dir -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
                 Sort-Object Name
        foreach ($f in $files) {
            try {
                # Widget scripts evaluate to their manifest hash as the last expression.
                # We dot-source via & call operator to keep their helper functions visible
                # without polluting our scope.
                $m = & $f.FullName
                if ($m -is [hashtable] -and $m.Name -and $m.Render) {
                    # Default values
                    if (-not $m.ContainsKey('Line'))         { $m.Line = 1 }
                    if (-not $m.ContainsKey('Position'))     { $m.Position = 'left' }
                    if (-not $m.ContainsKey('Priority'))     { $m.Priority = 100 }
                    if (-not $m.ContainsKey('RefreshEvery')) { $m.RefreshEvery = 0 }
                    if (-not $m.ContainsKey('Capability'))   { $m.Capability = @() }
                    if (-not $m.ContainsKey('State'))        { $m.State = @{} }
                    $m._SourcePath = $f.FullName
                    $manifests[$m.Name] = $m
                }
            } catch {
                # Bad widget — skip silently; the host should never blow up.
            }
        }
    }

    return @($manifests.Values)
}

function Test-WidgetCapabilities {
    param($Widget, $Caps)
    if (-not $Widget.Capability -or $Widget.Capability.Count -eq 0) { return $true }
    foreach ($req in $Widget.Capability) {
        if ($req -eq 'any') { continue }
        if (-not $Caps.$req) { return $false }
    }
    return $true
}

function Invoke-WidgetRender {
    param($Widget, $Ctx, $Caps, $Colors, $Ansi)

    # Per-widget caching by RefreshEvery — keyed by instance id (set by the
    # entry script when cloning a base manifest) so duplicate instances of the
    # same widget Name don't share a cache slot.
    $widgetId = if ($Widget._InstanceId) { $Widget._InstanceId } else { $Widget.Name }
    if ($Widget.RefreshEvery -gt 0) {
        $cacheKey = "$widgetId|$($Ctx.session_id)"
        $entry = $script:WIDGET_CACHE[$cacheKey]
        if ($entry) {
            $age = ((Get-Date) - $entry.Stamp).TotalSeconds
            if ($age -lt $Widget.RefreshEvery) { return $entry.Output }
        }
    }

    # Merge per-instance colour overrides on top of the global $Colors. Each
    # instance can carry $state.colors = {C_MODEL: 'R G B' or '#xxx', ...}
    # which lets duplicate instances render in different colours.
    $effectiveColors = $Colors
    if ($Widget.State -and $Widget.State.colors) {
        $effectiveColors = @{}
        foreach ($k in $Colors.Keys) { $effectiveColors[$k] = $Colors[$k] }
        foreach ($prop in $Widget.State.colors.PSObject.Properties) {
            $key = $prop.Name
            if (-not $effectiveColors.ContainsKey($key)) { continue }
            $v = [string]$prop.Value
            $rgb = $null
            if ($v -match '^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$') {
                $rgb = @([Convert]::ToInt32($Matches[1],16), [Convert]::ToInt32($Matches[2],16), [Convert]::ToInt32($Matches[3],16))
            } elseif ($v -match '^\s*(\d+)\s+(\d+)\s+(\d+)\s*$') {
                $rgb = @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3])
            }
            if ($rgb) { $effectiveColors[$key] = $Ansi.Fg($rgb[0], $rgb[1], $rgb[2]) }
        }
    }

    $output = ''
    try {
        $output = & $Widget.Render $Ctx $Caps $effectiveColors $Ansi $Widget.State
        if ($null -eq $output) { $output = '' }
        $output = [string]$output
    } catch {
        # Bad widget — log to a side file, return empty
        try {
            $logPath = Join-Path $env:USERPROFILE '.claude\statusline-widget-errors.log'
            "$([DateTime]::Now.ToString('o')) [$($Widget.Name)] $_" |
                Add-Content -Path $logPath -Encoding UTF8 -ErrorAction SilentlyContinue
        } catch {}
        $output = ''
    }

    if ($Widget.RefreshEvery -gt 0) {
        $cacheKey = "$widgetId|$($Ctx.session_id)"
        $script:WIDGET_CACHE[$cacheKey] = @{ Stamp = Get-Date; Output = $output }
    }

    return $output
}

function Render-Statusline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Ctx,
        [Parameter(Mandatory)]$Caps,
        [Parameter(Mandatory)]$Colors,
        [Parameter(Mandatory)]$Ansi,
        [Parameter(Mandatory)]$Widgets,
        [int]$TerminalWidth = 100,
        [int]$Columns = 3
    )
    if ($Columns -lt 1) { $Columns = 1 }
    if ($Columns -gt 12) { $Columns = 12 }

    # First pass: invoke renders, capture outputs
    $rendered = @()
    foreach ($w in $Widgets) {
        if (-not (Test-WidgetCapabilities $w $Caps)) { continue }
        $out = Invoke-WidgetRender -Widget $w -Ctx $Ctx -Caps $Caps -Colors $Colors -Ansi $Ansi
        if ([string]::IsNullOrEmpty($out)) { continue }
        $rendered += [pscustomobject]@{
            Widget   = $w
            Output   = $out
        }
    }

    # Second pass: let any widget with a Mutate callback rewrite the rendered set.
    # We iterate over $Widgets (not $rendered) so that mutation-only widgets like
    # mode-aware (whose Render returns '') still get their Mutate called.
    foreach ($w in $Widgets) {
        if ($w.Mutate) {
            try { & $w.Mutate $rendered $Ctx $Caps } catch {}
        }
    }

    # Drop any rendered entries that Mutate cleared to empty
    $rendered = @($rendered | Where-Object { -not [string]::IsNullOrEmpty($_.Output) })

    # Group widgets per line, then per line lay them out across K columns.
    # Each widget has a Column index (1-indexed). Legacy Position values
    # ('left' | 'center' | 'right') map to columns: left=1, center=ceil(K/2),
    # right=K. 'full' still wins the line. Within a column, widgets are joined
    # with ' | '. Column c starts at floor((c-1) * TerminalWidth / K).
    $byLine = $rendered | Group-Object { $_.Widget.Line } | Sort-Object { [int]$_.Name }
    $sep = "$($Ansi.Fg(80,80,100)) | $($Ansi.Reset())"
    $lines = @()
    foreach ($lineGroup in $byLine) {
        $full = @($lineGroup.Group | Where-Object { $_.Widget.Position -eq 'full' -or $_.Widget.Column -eq 'full' } | Sort-Object { $_.Widget.Priority })
        if ($full.Count -gt 0) {
            $lines += ($full[0].Output)
            continue
        }

        # Resolve each widget's column index (1..K)
        $byColumn = @{}
        foreach ($entry in $lineGroup.Group) {
            $col = $null
            if ($null -ne $entry.Widget.Column -and "$($entry.Widget.Column)" -match '^\d+$') {
                $col = [int]$entry.Widget.Column
            } else {
                # Map legacy Position string
                switch ([string]$entry.Widget.Position) {
                    'left'   { $col = 1 }
                    'center' { $col = [math]::Ceiling($Columns / 2.0) }
                    'right'  { $col = $Columns }
                    default  { $col = 1 }
                }
            }
            if ($col -lt 1) { $col = 1 }
            if ($col -gt $Columns) { $col = $Columns }
            if (-not $byColumn.ContainsKey($col)) { $byColumn[$col] = @() }
            $byColumn[$col] += $entry
        }

        # Build per-column rendered strings (priority-sorted, joined with ' | ')
        $colStrings = @{}
        foreach ($c in $byColumn.Keys) {
            $colStrings[$c] = ($byColumn[$c] | Sort-Object { $_.Widget.Priority } | ForEach-Object { $_.Output }) -join $sep
        }

        # Lay columns out at fixed grid positions
        $line = ''
        $cursorX = 0
        for ($c = 1; $c -le $Columns; $c++) {
            if (-not $colStrings.ContainsKey($c)) { continue }
            $slotStart = [math]::Floor(($c - 1) * $TerminalWidth / $Columns)
            $padBefore = [math]::Max(0, $slotStart - $cursorX)
            if ($cursorX -gt 0 -and $padBefore -lt 1) { $padBefore = 1 }
            $line += (' ' * $padBefore)
            $line += $colStrings[$c]
            $cursorX += $padBefore + ($Ansi.Width($colStrings[$c]))
        }
        $lines += $line
    }

    return $lines
}

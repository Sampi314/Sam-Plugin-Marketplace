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

    # Per-widget caching by RefreshEvery
    if ($Widget.RefreshEvery -gt 0) {
        $cacheKey = "$($Widget.Name)|$($Ctx.session_id)"
        $entry = $script:WIDGET_CACHE[$cacheKey]
        if ($entry) {
            $age = ((Get-Date) - $entry.Stamp).TotalSeconds
            if ($age -lt $Widget.RefreshEvery) { return $entry.Output }
        }
    }

    $output = ''
    try {
        $output = & $Widget.Render $Ctx $Caps $Colors $Ansi $Widget.State
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
        $cacheKey = "$($Widget.Name)|$($Ctx.session_id)"
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
        [int]$TerminalWidth = 100
    )

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

    # Group by line and lay out. Positions: left | center | right | full.
    # 'full' wins the line. Otherwise: left is left-edge, right is right-edge,
    # center is positioned at terminal midpoint. Padding between bands is at
    # least one space; if widgets don't fit, padding collapses to one space.
    $byLine = $rendered | Group-Object { $_.Widget.Line } | Sort-Object Name
    $sep = "$($Ansi.Fg(80,80,100)) | $($Ansi.Reset())"
    $lines = @()
    foreach ($lineGroup in $byLine) {
        $left   = @($lineGroup.Group | Where-Object { $_.Widget.Position -eq 'left'   } | Sort-Object { $_.Widget.Priority })
        $center = @($lineGroup.Group | Where-Object { $_.Widget.Position -eq 'center' } | Sort-Object { $_.Widget.Priority })
        $right  = @($lineGroup.Group | Where-Object { $_.Widget.Position -eq 'right'  } | Sort-Object { $_.Widget.Priority })
        $full   = @($lineGroup.Group | Where-Object { $_.Widget.Position -eq 'full'   } | Sort-Object { $_.Widget.Priority })

        if ($full.Count -gt 0) {
            $lines += ($full[0].Output)
            continue
        }

        $leftStr   = ($left   | ForEach-Object { $_.Output }) -join $sep
        $centerStr = ($center | ForEach-Object { $_.Output }) -join $sep
        $rightStr  = ($right  | ForEach-Object { $_.Output }) -join $sep

        $leftW   = if ($leftStr)   { $Ansi.Width($leftStr)   } else { 0 }
        $centerW = if ($centerStr) { $Ansi.Width($centerStr) } else { 0 }
        $rightW  = if ($rightStr)  { $Ansi.Width($rightStr)  } else { 0 }

        if ($centerStr -and $rightStr) {
            $centerStart = [math]::Floor(($TerminalWidth - $centerW) / 2)
            $padBefore   = [math]::Max(1, $centerStart - $leftW)
            $padAfter    = [math]::Max(1, $TerminalWidth - $leftW - $padBefore - $centerW - $rightW)
            $line = $leftStr + (' ' * $padBefore) + $centerStr + (' ' * $padAfter) + $rightStr
        } elseif ($centerStr) {
            $centerStart = [math]::Floor(($TerminalWidth - $centerW) / 2)
            $padBefore   = [math]::Max(1, $centerStart - $leftW)
            $line = $leftStr + (' ' * $padBefore) + $centerStr
        } elseif ($rightStr) {
            $padW = $TerminalWidth - $leftW - $rightW
            if ($padW -lt 1) { $padW = 1 }
            $line = $leftStr + (' ' * $padW) + $rightStr
        } else {
            $line = $leftStr
        }
        $lines += $line
    }

    return $lines
}

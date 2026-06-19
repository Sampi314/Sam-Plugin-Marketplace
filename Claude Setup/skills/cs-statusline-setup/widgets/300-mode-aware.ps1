# ----------------------------------------------------------------------------
# widgets/300-mode-aware.ps1 — adaptive layout switcher (must-have #2)
# Mutates other widgets' Line/Position after first-pass renders to deliver
# mode-specific layouts.
#
# Modes:
#   emergency  — rate_limits.five_hour > 90% → strip everything except cost+rate
#   agent      — subagent running → hide weekly bar
#   learning   — output_style.name = 'learning' → add tip line
#   compact    — terminal narrower than 80 cols → squash to 2 lines
#   default    — full 5-line layout
# ----------------------------------------------------------------------------

@{
    Name        = 'mode-aware'
    Line        = 99      # arbitrary; never renders directly
    Position    = 'left'
    Priority    = 99999
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)
        return ''   # mutation-only widget
    }
    Mutate      = {
        param($rendered, $ctx, $caps)

        # Detect mode
        $mode = 'default'
        $cols = if ($env:COLUMNS) { [int]$env:COLUMNS } else { 100 }
        $rate5h = 0
        if ($ctx.rate_limits -and $ctx.rate_limits.five_hour -and $null -ne $ctx.rate_limits.five_hour.used_percentage) {
            $rate5h = [double]$ctx.rate_limits.five_hour.used_percentage
        }
        if ($rate5h -ge 90) { $mode = 'emergency' }
        elseif ($ctx.agent -and $ctx.agent.name) { $mode = 'agent' }
        elseif ($ctx.output_style -and $ctx.output_style.name -eq 'learning') { $mode = 'learning' }
        elseif ($cols -lt 80) { $mode = 'compact' }

        switch ($mode) {
            'emergency' {
                # Only show: core-header, core-rate-5h, sparkline-cost
                foreach ($r in $rendered) {
                    if ($r.Widget.Name -notin @('core-header','core-rate-5h','sparkline-cost')) {
                        $r.Output = ''
                    }
                }
            }
            'agent' {
                # Hide weekly bar to free space for subagent context
                foreach ($r in $rendered) {
                    if ($r.Widget.Name -eq 'core-rate-wk') {
                        $r.Output = ''
                    }
                }
            }
            'compact' {
                # Move everything to lines 1-2; drop sparklines
                foreach ($r in $rendered) {
                    if ($r.Widget.Name -in @('sparkline-cost','sparkline-ctx')) {
                        $r.Output = ''
                    } elseif ($r.Widget.Line -ge 3) {
                        $r.Widget.Line = 2
                    }
                }
            }
            'learning' {
                # No layout changes; widget for tip-of-the-day would render normally
            }
        }
    }
}

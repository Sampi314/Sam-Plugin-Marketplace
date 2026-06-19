# ----------------------------------------------------------------------------
# widgets/200-sparkline-cost.ps1 — Braille sparkline of $/min over recent ticks
# ----------------------------------------------------------------------------

@{
    Name        = 'sparkline-cost'
    Line        = 2
    Position    = 'right'
    Priority    = 10
    RefreshEvery = 0
    Capability  = @('braille')
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)
        if (-not $ctx.session_id) { return '' }

        $samples = @(Read-StatuslineSamples -SessionId $ctx.session_id -Metric 'cost_per_min' -Count 24)
        if ($samples.Count -lt 2) { return '' }

        $spark = Render-BrailleSparkline -Values $samples -Width 8
        $latest = $samples[-1]
        $fmt = if ($latest -ge 1) { '${0:N2}/min' -f $latest } else { '${0:N3}/min' -f $latest }
        return "$($colors.C_GOLD)$fmt$($colors.C_RESET) $($colors.C_COST)$spark$($colors.C_RESET)"
    }
}

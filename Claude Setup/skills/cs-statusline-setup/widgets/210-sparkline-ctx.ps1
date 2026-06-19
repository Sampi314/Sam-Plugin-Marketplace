# ----------------------------------------------------------------------------
# widgets/210-sparkline-ctx.ps1 — Braille sparkline of CTX % over recent ticks
# ----------------------------------------------------------------------------

@{
    Name        = 'sparkline-ctx'
    Line        = 5
    Position    = 'left'
    Priority    = 50
    RefreshEvery = 0
    Capability  = @('braille')
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)
        if (-not $ctx.session_id) { return '' }

        $samples = @(Read-StatuslineSamples -SessionId $ctx.session_id -Metric 'ctx_pct' -Count 24)
        if ($samples.Count -lt 2) { return '' }

        # Pin Y range to 0..100 so the sparkline reads as absolute %, not relative shape
        $spark = Render-BrailleSparkline -Values $samples -Width 8 -Min 0 -Max 100
        return "$($colors.C_LABEL)CTX$($colors.C_RESET) $($colors.C_CYAN)$spark$($colors.C_RESET)"
    }
}

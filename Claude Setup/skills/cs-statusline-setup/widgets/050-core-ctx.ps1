# ----------------------------------------------------------------------------
# widgets/050-core-ctx.ps1 — context window bar with exceeds-200k warning
# ----------------------------------------------------------------------------

@{
    Name        = 'core-ctx'
    Line        = 2
    Position    = 'left'
    Priority    = 10
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $pct = 0
        if ($ctx.context_window -and $null -ne $ctx.context_window.used_percentage) {
            $pct = [double]$ctx.context_window.used_percentage
        }

        $exceedsWarn = ''
        if ($ctx.exceeds_200k_tokens) {
            $exceedsWarn = "$($colors.C_RED)$($colors.C_BOLD)$([char]0x26A0) 200K!$($colors.C_RESET) "
        }

        # Adaptive bar width based on terminal — capped at 30, min 15
        $barWidth = 24
        $width = 0
        if ($pct -lt 50)      { $col = $ansi.Fg(130,220,130) }
        elseif ($pct -lt 70)  { $col = $ansi.Fg(255,220,80)  }
        elseif ($pct -lt 85)  { $col = $ansi.Fg(255,160,60)  }
        else                  { $col = $ansi.Fg(255,80,80)   }

        $filled = [math]::Round(($pct / 100.0) * $barWidth)
        $filled = [math]::Max(0, [math]::Min($barWidth, $filled))
        $bar = ''
        for ($i = 0; $i -lt $filled; $i++) { $bar += $col + [char]0x2588 }
        for ($i = $filled; $i -lt $barWidth; $i++) { $bar += $ansi.Fg(60,60,75) + [char]0x2591 }
        $bar += $colors.C_RESET

        $size = if ($ctx.context_window -and $ctx.context_window.context_window_size) {
            $kb = [int]$ctx.context_window.context_window_size
            if ($kb -ge 1000000) { '1M' } else { "${kb}k" -replace '000k$','k' }
        } else { '?' }

        $pctStr = '{0,5:N1}%' -f $pct
        return "$exceedsWarn$($colors.C_LABEL)CTX:$($colors.C_RESET) $bar $col$pctStr$($colors.C_RESET) $($colors.C_DIM)/$size$($colors.C_RESET)"
    }
}

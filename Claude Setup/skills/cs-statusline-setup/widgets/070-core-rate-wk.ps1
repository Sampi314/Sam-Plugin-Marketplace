# ----------------------------------------------------------------------------
# widgets/070-core-rate-wk.ps1 — weekly rate-limit bar (Bundle A)
# ----------------------------------------------------------------------------

@{
    Name        = 'core-rate-wk'
    Line        = 4
    Position    = 'left'
    Priority    = 10
    RefreshEvery = 15
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $rl = Get-RateLimits $ctx
        if (-not $rl.seven_day) {
            return "$($colors.C_DIM)WK : (no data)$($colors.C_RESET)"
        }
        $pct = [double]$rl.seven_day.used_percentage

        $barWidth = if ($state -and $state.barWidth) { [int]$state.barWidth } else { 24 }
        $segments = 7
        $dividers = $segments - 1
        $totalBlocks = $barWidth - $dividers
        $blocksPerSeg = [math]::Floor($totalBlocks / $segments)
        $remainder = $totalBlocks - ($blocksPerSeg * $segments)
        $filled = [math]::Round(($pct / 100.0) * $totalBlocks)
        $filled = [math]::Max(0, [math]::Min($totalBlocks, $filled))

        $bar = ''
        $pos = 0
        for ($seg = 0; $seg -lt $segments; $seg++) {
            $segLen = $blocksPerSeg + $(if ($seg -lt $remainder) { 1 } else { 0 })
            for ($b = 0; $b -lt $segLen; $b++) {
                $posPct = ($pos / $totalBlocks) * 100
                if ($pos -lt $filled) {
                    if ($posPct -lt 50) { $c = $ansi.Fg(130,220,130) }
                    elseif ($posPct -lt 70) { $c = $ansi.Fg(255,220,80) }
                    elseif ($posPct -lt 85) { $c = $ansi.Fg(255,160,60) }
                    else { $c = $ansi.Fg(255,80,80) }
                    $bar += $c + [char]0x2588
                } else {
                    $bar += $ansi.Fg(60,60,75) + [char]0x2591
                }
                $pos++
            }
            if ($seg -lt $dividers) { $bar += $colors.C_DIVIDER + [char]0x2502 }
        }
        $bar += $colors.C_RESET

        # Reset countdown + absolute local-time clock (e.g. '↻ 5d 12h | @Mon 09:00')
        # The clock shows whenever we can parse a target; the countdown only
        # shows when the target is still in the future.
        $resetStr = '--'
        $resetClock = ''
        if ($rl.seven_day.resets_at) {
            try {
                $target = $null
                $s = "$($rl.seven_day.resets_at)".Trim()
                if ($s -match '^\d{9,13}$') {
                    $sec = if ($s.Length -ge 13) { [long]$s / 1000 } else { [long]$s }
                    $target = [DateTimeOffset]::FromUnixTimeSeconds($sec)
                } else {
                    $target = [DateTimeOffset]::Parse($s)
                }
                if ($target) {
                    $resetClock = "$($colors.C_DIM) | @$($target.ToLocalTime().ToString('ddd HH:mm'))$($colors.C_RESET)"
                    $diff = $target - [DateTimeOffset]::UtcNow
                    if ($diff.TotalSeconds -gt 0) {
                        $days = [math]::Floor($diff.TotalDays)
                        $resetStr = "${days}d $($diff.Hours)h"
                    }
                }
            } catch {}
        }

        $pctStr = '{0,5:N1}%' -f $pct
        $srcTag = if ($rl.source -eq 'oauth-fallback') { "$($colors.C_DIM)*$($colors.C_RESET)" } else { '' }
        return "$($colors.C_LABEL)WK :$($colors.C_RESET) $bar $pctStr$srcTag $($colors.C_DIM)$([char]0x21BB) $resetStr$($colors.C_RESET)$resetClock"
    }
}

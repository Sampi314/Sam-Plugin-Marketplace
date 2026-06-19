# ----------------------------------------------------------------------------
# widgets/080-core-work.ps1 — session duration + diff stats + active/idle ratio
# ----------------------------------------------------------------------------

@{
    Name        = 'core-work'
    Line        = 5
    Position    = 'left'
    Priority    = 10
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        if (-not $ctx.cost) { return '' }

        $dur = if ($null -ne $ctx.cost.total_duration_ms) { [long]$ctx.cost.total_duration_ms } else { 0 }
        $apiDur = if ($null -ne $ctx.cost.total_api_duration_ms) { [long]$ctx.cost.total_api_duration_ms } else { 0 }
        $added = if ($null -ne $ctx.cost.total_lines_added) { [int]$ctx.cost.total_lines_added } else { 0 }
        $removed = if ($null -ne $ctx.cost.total_lines_removed) { [int]$ctx.cost.total_lines_removed } else { 0 }

        function _FormatDur($ms) {
            if ($ms -le 0) { return '0m' }
            $ts = [TimeSpan]::FromMilliseconds($ms)
            if ($ts.TotalDays -ge 1) { return "$([math]::Floor($ts.TotalDays))d $($ts.Hours)h $($ts.Minutes)m" }
            elseif ($ts.TotalHours -ge 1) { return "$([math]::Floor($ts.TotalHours))h $($ts.Minutes)m" }
            else { return "$($ts.Minutes)m $($ts.Seconds)s" }
        }

        $durStr = _FormatDur $dur
        $diffStr = "$($colors.C_ADD)+$added$($colors.C_RESET)$($colors.C_DIM)/$($colors.C_RESET)$($colors.C_DEL)-$removed$($colors.C_RESET)"

        # Active/idle ratio (Layer 1 / Bundle D bonus)
        $actStr = ''
        if ($dur -gt 0 -and $apiDur -gt 0) {
            $pct = [math]::Round(($apiDur / [double]$dur) * 100, 0)
            $actStr = " $($colors.C_DIM)|$($colors.C_RESET) $($colors.C_LABEL)ACT:$($colors.C_RESET) $($colors.C_CYAN)$pct%$($colors.C_RESET)"
        }

        return "$($colors.C_LABEL)WORK:$($colors.C_RESET) $($colors.C_TIME)$durStr$($colors.C_RESET) $($colors.C_DIM)|$($colors.C_RESET) $diffStr$actStr"
    }
}

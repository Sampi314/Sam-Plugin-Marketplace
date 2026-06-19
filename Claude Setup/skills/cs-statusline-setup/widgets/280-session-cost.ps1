# ----------------------------------------------------------------------------
# widgets/280-session-cost.ps1 - just the session cost, standalone
# ----------------------------------------------------------------------------
#
# Extracted from core-header for users who want the session $ on its own.
# Auto-scales the format: $0.123 below $1, $1.23 below $100, $123 above.
#
# State knobs:
#   $state.prefix  visual prefix (default 'S:')
#   $state.precision  override decimal precision (default auto)
# ----------------------------------------------------------------------------

@{
    Name        = 'session-cost'
    Line        = 1
    Position    = 'left'
    Priority    = 25
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $usd = 0.0
        if ($ctx.cost -and $null -ne $ctx.cost.total_cost_usd) {
            $usd = [double]$ctx.cost.total_cost_usd
        }
        if ($usd -le 0) { return '' }

        $prefix = if ($state -and $null -ne $state.prefix) { [string]$state.prefix } else { 'S:' }

        $precision = if ($state -and $state.precision) { [int]$state.precision } else {
            if ($usd -ge 100) { 0 } elseif ($usd -ge 1) { 2 } else { 3 }
        }
        $fmt = "`${0:N$precision}"
        $cost = $fmt -f $usd

        return "$($colors.C_DIM)$prefix$($colors.C_RESET) $($colors.C_COST)$cost$($colors.C_RESET)"
    }
}

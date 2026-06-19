# ----------------------------------------------------------------------------
# widgets/190-tokens-total.ps1 - total tokens for the current tick (single num)
# ----------------------------------------------------------------------------
#
# Sums input + output tokens from $ctx.context_window.current_usage. Use this
# when you want one number ('9.7k tok'), not the input/output/cache breakdown.
#
# State knobs:
#   $state.includeCache  $true to also fold cache_read into the sum (default $false)
#   $state.label         '' (no label) | 'tok' (default) | 'TOK'
# ----------------------------------------------------------------------------

@{
    Name        = 'tokens-total'
    Line        = 1
    Position    = 'right'
    Priority    = 42
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $cu = if ($ctx.context_window) { $ctx.context_window.current_usage } else { $null }
        if (-not $cu) { return '' }

        $inT  = if ($null -ne $cu.input_tokens)  { [int]$cu.input_tokens }  else { 0 }
        $outT = if ($null -ne $cu.output_tokens) { [int]$cu.output_tokens } else { 0 }
        $includeCache = if ($state -and $null -ne $state.includeCache) { [bool]$state.includeCache } else { $false }
        $cacheT = if ($includeCache -and $null -ne $cu.cache_read_input_tokens) { [int]$cu.cache_read_input_tokens } else { 0 }

        $total = $inT + $outT + $cacheT
        if ($total -le 0) { return '' }

        $fmt = {
            param([int]$n)
            if ($n -ge 1000000) { return ('{0:N1}M' -f ($n / 1000000.0)) }
            if ($n -ge 1000)    { return ('{0:N1}k' -f ($n / 1000.0)) }
            return [string]$n
        }
        $numStr = & $fmt $total

        $label = if ($state -and $null -ne $state.label) { [string]$state.label } else { 'tok' }
        if ($label) {
            return "$($colors.C_COST)$numStr$($colors.C_RESET) $($colors.C_DIM)$label$($colors.C_RESET)"
        }
        return "$($colors.C_COST)$numStr$($colors.C_RESET)"
    }
}

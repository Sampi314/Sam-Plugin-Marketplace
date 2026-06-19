# ----------------------------------------------------------------------------
# widgets/150-token-breakdown.ps1 - input / output / cache tokens explicit
# ----------------------------------------------------------------------------
#
# Reads $ctx.context_window.current_usage. Shows current-tick breakdown:
#   "8.5k in . 1.2k out . 70k cache"
#
# The cache number is cache_read_input_tokens, which is where Claude Code's
# prompt caching savings actually show up - surfacing it explicitly makes the
# savings legible.
# ----------------------------------------------------------------------------

@{
    Name        = 'token-breakdown'
    Line        = 1
    Position    = 'right'
    Priority    = 40
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        # Inline formatter — defining as a script-level function breaks scope
        # when the host invokes Render from outside the widget file's scope.
        $fmt = {
            param([int]$n)
            if ($n -ge 1000000) { return ('{0:N1}M' -f ($n / 1000000.0)) }
            if ($n -ge 1000)    { return ('{0:N1}k' -f ($n / 1000.0)) }
            return [string]$n
        }

        $cu = $null
        if ($ctx.context_window -and $ctx.context_window.current_usage) {
            $cu = $ctx.context_window.current_usage
        }
        if (-not $cu) { return '' }

        $inT  = if ($null -ne $cu.input_tokens)                 { [int]$cu.input_tokens } else { 0 }
        $outT = if ($null -ne $cu.output_tokens)                { [int]$cu.output_tokens } else { 0 }
        $cacheRead = if ($null -ne $cu.cache_read_input_tokens) { [int]$cu.cache_read_input_tokens } else { 0 }

        $parts = @()
        if ($inT -gt 0)       { $parts += "$($colors.C_TIME)$(& $fmt $inT)$($colors.C_DIM) in$($colors.C_RESET)" }
        if ($outT -gt 0)      { $parts += "$($colors.C_COST)$(& $fmt $outT)$($colors.C_DIM) out$($colors.C_RESET)" }
        if ($cacheRead -gt 0) { $parts += "$($colors.C_ADD)$(& $fmt $cacheRead)$($colors.C_DIM) cache$($colors.C_RESET)" }

        if ($parts.Count -eq 0) { return '' }
        return ($parts -join "$($colors.C_DIM) . $($colors.C_RESET)")
    }
}

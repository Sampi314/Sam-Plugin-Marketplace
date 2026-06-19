# ----------------------------------------------------------------------------
# widgets/020-thinking.ps1 — 🧠 indicator when extended thinking enabled
# ----------------------------------------------------------------------------

@{
    Name        = 'thinking'
    Line        = 1
    Position    = 'right'
    Priority    = 30
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)
        if (-not $ctx.thinking -or -not $ctx.thinking.enabled) { return '' }
        return "$($colors.C_CYAN)$([char]::ConvertFromUtf32(0x1F9E0))$($colors.C_RESET)"
    }
}

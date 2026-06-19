# ----------------------------------------------------------------------------
# widgets/030-output-style.ps1 — output style tag when non-default
# ----------------------------------------------------------------------------

@{
    Name        = 'output-style'
    Line        = 1
    Position    = 'right'
    Priority    = 20
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)
        if (-not $ctx.output_style -or -not $ctx.output_style.name) { return '' }
        $name = $ctx.output_style.name
        if ($name -eq 'default') { return '' }
        return "$($colors.C_ITALIC)$($colors.C_LABEL)$name$($colors.C_RESET)"
    }
}

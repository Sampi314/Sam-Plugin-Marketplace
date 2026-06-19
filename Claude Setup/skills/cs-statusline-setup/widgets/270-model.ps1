# ----------------------------------------------------------------------------
# widgets/270-model.ps1 - just the model name, standalone
# ----------------------------------------------------------------------------
#
# Extracted from core-header for users who want the model name on its own
# line/column without the header's effort + cost + project bundle.
#
# State knobs:
#   $state.showEffort  $true to append the effort level (default $false)
# ----------------------------------------------------------------------------

@{
    Name        = 'model'
    Line        = 1
    Position    = 'left'
    Priority    = 20
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $name = if ($ctx.model -and $ctx.model.display_name) { [string]$ctx.model.display_name }
                elseif ($ctx.model -and $ctx.model.id) { [string]$ctx.model.id }
                else { '--' }

        $out = "$($colors.C_MODEL)$($colors.C_BOLD)$name$($colors.C_RESET)"

        if ($state -and $state.showEffort -and $ctx.effort -and $ctx.effort.level) {
            $effort = ([string]$ctx.effort.level).ToLower()
            $out += " $($colors.C_DIM)|$($colors.C_RESET) $($colors.C_CYAN)$effort$($colors.C_RESET)"
        }
        return $out
    }
}

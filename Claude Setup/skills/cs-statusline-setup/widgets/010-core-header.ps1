# ----------------------------------------------------------------------------
# widgets/010-core-header.ps1 — model + effort + session $ + project + version
# ----------------------------------------------------------------------------

@{
    Name        = 'core-header'
    Line        = 1
    Position    = 'left'
    Priority    = 10
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $model = if ($ctx.model -and $ctx.model.display_name) { $ctx.model.display_name } else { '--' }
        $effort = if ($ctx.effort -and $ctx.effort.level) { $ctx.effort.level.ToLower() } else { '' }
        $version = if ($ctx.version) { "v$($ctx.version)" } else { 'v?' }

        $sessionCost = 0.0
        if ($ctx.cost -and $null -ne $ctx.cost.total_cost_usd) { $sessionCost = [double]$ctx.cost.total_cost_usd }

        $projectName = '--'
        if ($ctx.workspace -and $ctx.workspace.repo -and $ctx.workspace.repo.name) {
            $projectName = "$($ctx.workspace.repo.owner)/$($ctx.workspace.repo.name)"
            if ($ctx.workspace.repo.host) {
                $url = "https://$($ctx.workspace.repo.host)/$projectName"
                $projectName = $ansi.Link($url, $projectName)
            }
        } elseif ($ctx.workspace -and $ctx.workspace.project_dir) {
            $projectName = Split-Path $ctx.workspace.project_dir -Leaf
        }

        $sessionLabel = if ($ctx.session_name) { "$($colors.C_LABEL)[$($ctx.session_name)]$($colors.C_RESET) " } else { '' }

        $fmtCost = if ($sessionCost -ge 100) { '${0:N0}' -f $sessionCost }
                   elseif ($sessionCost -ge 1) { '${0:N2}' -f $sessionCost }
                   else { '${0:N3}' -f $sessionCost }

        $parts = @()
        $parts += "${sessionLabel}$($colors.C_MODEL)$($colors.C_BOLD)$model$($colors.C_RESET)"
        if ($effort) { $parts += "$($colors.C_CYAN)$effort$($colors.C_RESET)" }
        $parts += "$($colors.C_LABEL)Session:$($colors.C_RESET) $($colors.C_COST)$fmtCost$($colors.C_RESET)"
        $parts += "$($colors.C_LABEL)$projectName$($colors.C_RESET)"
        $parts += "$($colors.C_LABEL)$version$($colors.C_RESET)"

        return ($parts -join " $($colors.C_DIM)|$($colors.C_RESET) ")
    }
}

# ----------------------------------------------------------------------------
# widgets/220-commit-hash.ps1 - last git commit SHA (short form)
# ----------------------------------------------------------------------------
#
# Runs 'git log -1 --format=%h' in the current workspace. Caches for 120s so
# the git call doesn't fire every tick. Hidden when not in a git repo.
#
# State knobs:
#   $state.length  short SHA digit count (default 7)
#   $state.prefix  visual prefix (default '@')
# ----------------------------------------------------------------------------

@{
    Name        = 'commit-hash'
    Line        = 1
    Position    = 'right'
    Priority    = 65
    RefreshEvery = 120
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $cwd = if ($ctx.workspace -and $ctx.workspace.current_dir) {
            [string]$ctx.workspace.current_dir
        } else { '' }
        if (-not $cwd) { return '' }

        $length = if ($state -and $state.length) { [int]$state.length } else { 7 }
        $prefix = if ($state -and $null -ne $state.prefix) { [string]$state.prefix } else { '@' }

        $sha = ''
        try {
            $sha = (& git -C $cwd log -1 --format=%h --abbrev=$length 2>$null)
            $sha = ([string]$sha).Trim()
        } catch {}

        if (-not $sha) { return '' }

        return "$($colors.C_DIM)$prefix$($colors.C_RESET)$($colors.C_SKILL)$sha$($colors.C_RESET)"
    }
}

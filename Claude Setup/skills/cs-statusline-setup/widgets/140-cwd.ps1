# ----------------------------------------------------------------------------
# widgets/140-cwd.ps1 - current working directory with smart truncation
# ----------------------------------------------------------------------------
#
# Reads $ctx.workspace.current_dir. Strategy:
#   - Drop the user-home prefix (~/...)
#   - If the path is short enough (under $state.maxLen, default 40), return as-is
#   - Otherwise: keep the first segment, ellipsis, last two segments
#     e.g.  C:/Users/Sam/Documents/GitHub/very/deep/nested/dir  ->  Sam/.../nested/dir
#
# State knobs:
#   $state.maxLen   integer; longer paths get collapsed (default 40)
# ----------------------------------------------------------------------------

@{
    Name        = 'cwd'
    Line        = 1
    Position    = 'right'
    Priority    = 30
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $cwd = $null
        if ($ctx.workspace -and $ctx.workspace.current_dir) {
            $cwd = [string]$ctx.workspace.current_dir
        }
        if (-not $cwd) { return '' }

        $maxLen = if ($state -and $state.maxLen) { [int]$state.maxLen } else { 40 }

        # Normalise to forward slashes for display
        $display = $cwd -replace '\\','/'

        # Strip $HOME/$USERPROFILE prefix
        $homeDirs = @($env:USERPROFILE, $env:HOME) | Where-Object { $_ } | ForEach-Object { $_ -replace '\\','/' }
        foreach ($h in $homeDirs) {
            if ($display -like "$h*") {
                $display = '~' + $display.Substring($h.Length)
                break
            }
        }

        if ($display.Length -gt $maxLen) {
            $segments = $display -split '/' | Where-Object { $_ }
            if ($segments.Count -gt 3) {
                $first = $segments[0]
                $tail  = $segments[-2..-1] -join '/'
                $ell = [char]0x2026
                $display = "$first/$ell/$tail"
            }
        }

        $icon = [char]::ConvertFromUtf32(0x1F4C2)   # open folder
        return "$($colors.C_DIM)$icon$($colors.C_RESET) $($colors.C_SKILL)$display$($colors.C_RESET)"
    }
}

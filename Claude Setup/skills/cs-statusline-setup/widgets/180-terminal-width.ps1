# ----------------------------------------------------------------------------
# widgets/180-terminal-width.ps1 - current terminal column count
# ----------------------------------------------------------------------------
#
# Reads $env:COLUMNS (set by Claude Code) and displays the terminal width.
# Useful when authoring widgets that need to know the available canvas.
#
# State knobs:
#   $state.format  '120c' (default) | '120 cols' | 'w:120'
# ----------------------------------------------------------------------------

@{
    Name        = 'terminal-width'
    Line        = 1
    Position    = 'right'
    Priority    = 80
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $w = 0
        if ($env:COLUMNS) { [int]::TryParse($env:COLUMNS, [ref]$w) | Out-Null }
        if ($w -le 0) { return '' }

        $fmt = if ($state -and $state.format) { [string]$state.format } else { '120c' }
        $display = switch ($fmt) {
            '120 cols' { "$w cols" }
            'w:120'    { "w:$w" }
            default    { "${w}c" }
        }
        return "$($colors.C_DIM)$display$($colors.C_RESET)"
    }
}

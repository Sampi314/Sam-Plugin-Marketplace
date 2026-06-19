# ----------------------------------------------------------------------------
# widgets/130-date.ps1 - current local date
# ----------------------------------------------------------------------------
#
# State knobs:
#   $state.format  .NET date format string (default 'yyyy-MM-dd')
#                  Useful values: 'ddd dd MMM', 'dd/MM', 'MMM d', 'yyyy-MM-dd'
# ----------------------------------------------------------------------------

@{
    Name        = 'date'
    Line        = 1
    Position    = 'right'
    Priority    = 4
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $fmt = if ($state -and $state.format) { [string]$state.format } else { 'yyyy-MM-dd' }
        try { $today = (Get-Date).ToString($fmt) } catch { $today = (Get-Date).ToString('yyyy-MM-dd') }

        $icon = [char]::ConvertFromUtf32(0x1F4C5)   # calendar
        return "$($colors.C_DIM)$icon$($colors.C_RESET) $($colors.C_TIME)$today$($colors.C_RESET)"
    }
}

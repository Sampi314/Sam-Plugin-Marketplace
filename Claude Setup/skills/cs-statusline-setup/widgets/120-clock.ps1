# ----------------------------------------------------------------------------
# widgets/120-clock.ps1 - current local time
# ----------------------------------------------------------------------------
#
# State knobs (set via CS_LAYOUT_OVERRIDE):
#   $state.showSeconds  $true to render HH:MM:SS instead of HH:MM
#   $state.use24h       $false to render 12-hour clock with am/pm
# ----------------------------------------------------------------------------

@{
    Name        = 'clock'
    Line        = 1
    Position    = 'right'
    Priority    = 5
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $use24h      = if ($state -and $null -ne $state.use24h) { [bool]$state.use24h } else { $true }
        $showSeconds = if ($state -and $null -ne $state.showSeconds) { [bool]$state.showSeconds } else { $false }

        $fmt = if ($use24h) {
            if ($showSeconds) { 'HH:mm:ss' } else { 'HH:mm' }
        } else {
            if ($showSeconds) { 'h:mm:ss tt' } else { 'h:mm tt' }
        }
        $now = (Get-Date).ToString($fmt)

        $icon = [char]::ConvertFromUtf32(0x1F551)   # clock face
        return "$($colors.C_DIM)$icon$($colors.C_RESET) $($colors.C_TIME)$now$($colors.C_RESET)"
    }
}

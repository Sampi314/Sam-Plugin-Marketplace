# ----------------------------------------------------------------------------
# widgets/250-uptime.ps1 - system uptime since last boot
# ----------------------------------------------------------------------------
#
# Reads Win32_OperatingSystem.LastBootUpTime via CIM. Renders '5d 12h' or
# '3h 42m' depending on magnitude. Distinct from core-work (current session)
# and session-time (across sessions) — this is the OS uptime.
#
# State knobs:
#   $state.label  'UP' (default) | 'BOOT' | '' (omit)
# ----------------------------------------------------------------------------

@{
    Name        = 'uptime'
    Line        = 1
    Position    = 'right'
    Priority    = 85
    RefreshEvery = 60
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $boot = $null
        try {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $boot = $os.LastBootUpTime
        } catch {}
        if (-not $boot) { return '' }

        $diff = (Get-Date) - $boot
        $up = if ($diff.TotalDays -ge 1) {
            "{0}d {1}h" -f [int]$diff.Days, [int]$diff.Hours
        } elseif ($diff.TotalHours -ge 1) {
            "{0}h {1}m" -f [int]$diff.Hours, [int]$diff.Minutes
        } else {
            "{0}m" -f [int]$diff.TotalMinutes
        }

        $label = if ($state -and $null -ne $state.label) { [string]$state.label } else { 'UP' }
        if ($label) {
            return "$($colors.C_DIM)$label$($colors.C_RESET) $($colors.C_TIME)$up$($colors.C_RESET)"
        }
        return "$($colors.C_TIME)$up$($colors.C_RESET)"
    }
}

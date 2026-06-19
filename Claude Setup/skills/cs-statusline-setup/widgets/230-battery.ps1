# ----------------------------------------------------------------------------
# widgets/230-battery.ps1 - laptop battery level via Win32_Battery
# ----------------------------------------------------------------------------
#
# Reads the first Win32_Battery instance via CIM. Renders 'BAT 87%' green
# above 60%, yellow 30-60%, red below, plus a charging indicator when the
# battery status reports charging. Hidden when no battery is present
# (desktop / VM).
#
# State knobs:
#   $state.icon  $true to prefix with a unicode battery glyph (default $false)
# ----------------------------------------------------------------------------

@{
    Name        = 'battery'
    Line        = 1
    Position    = 'right'
    Priority    = 70
    RefreshEvery = 60
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $batt = $null
        try {
            $batt = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop | Select-Object -First 1
        } catch {}
        if (-not $batt) { return '' }

        $pct = [int]$batt.EstimatedChargeRemaining
        if ($pct -le 0) { return '' }

        # BatteryStatus codes: 1 = Discharging, 2 = AC connected, 3 = Fully charged,
        # 4 = Low, 5 = Critical, 6 = Charging, 7 = Charging and high, 8 = Charging and low,
        # 9 = Charging and critical, 11 = Partially charged
        $status = [int]$batt.BatteryStatus
        $isCharging = ($status -in @(2, 3, 6, 7, 8, 9, 11))

        $col = if ($pct -ge 60) { $colors.C_GREEN }
               elseif ($pct -ge 30) { $colors.C_YELLOW }
               else { $colors.C_RED }

        $useIcon = $state -and $null -ne $state.icon -and [bool]$state.icon
        $prefix = if ($useIcon) {
            if ($isCharging) { [char]::ConvertFromUtf32(0x1F50C) } else { [char]::ConvertFromUtf32(0x1F50B) }
        } else {
            if ($isCharging) { '~BAT' } else { 'BAT' }
        }

        return "$($colors.C_DIM)$prefix$($colors.C_RESET) $col$pct%$($colors.C_RESET)"
    }
}

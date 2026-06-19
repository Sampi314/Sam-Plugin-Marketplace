# ----------------------------------------------------------------------------
# widgets/170-session-time.ps1 - accumulated work time across sessions
# ----------------------------------------------------------------------------
#
# Surfaces work time aggregated across Claude Code sessions, sourced from
# ~/.claude/events.ndjson which the Extended host writes one line per tick.
#
# Strategy:
#   - Walk events from the lookback window (default: today)
#   - Group by session_id; each session's duration = max(ts) - min(ts)
#   - Sum durations across sessions = total active time in the window
#
# State knobs (via CS_LAYOUT_OVERRIDE):
#   $state.period   'today' (default) | 'week' | 'all'
#   $state.maxDays  integer cap on lookback (default 7 for week, 30 for all)
#   $state.label    optional override for the prefix (default depends on period)
#
# Falls back to '--' if no events file exists or no events match the window.
# ----------------------------------------------------------------------------

@{
    Name        = 'session-time'
    Line        = 1
    Position    = 'right'
    Priority    = 45
    RefreshEvery = 60
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $period = if ($state -and $state.period) { [string]$state.period } else { 'today' }
        $maxDays = if ($state -and $state.maxDays) { [int]$state.maxDays } else {
            switch ($period) { 'week' { 7 } 'all' { 30 } default { 1 } }
        }
        $label = if ($state -and $state.label) { [string]$state.label } else {
            switch ($period) { 'week'  { 'WK ACT' } 'all' { 'ACT' } default { 'TODAY' } }
        }

        $eventsFile = Join-Path $env:USERPROFILE '.claude\events.ndjson'
        if (-not (Test-Path $eventsFile)) {
            return "$($colors.C_DIM)$label$($colors.C_RESET) $($colors.C_TIME)--$($colors.C_RESET)"
        }

        # Window: include events newer than ($now - maxDays days), or for
        # 'today' the start of the local day
        $now = Get-Date
        $cutoff = if ($period -eq 'today') { $now.Date } else { $now.AddDays(-$maxDays) }

        $sessions = @{}
        # Read last N lines for performance — the file grows ~120/hr at 30s
        # ticks, so 100k lines is months of data. Cap at 200k lines.
        try {
            $lines = Get-Content $eventsFile -Tail 200000 -ErrorAction Stop
        } catch {
            return "$($colors.C_DIM)$label$($colors.C_RESET) $($colors.C_TIME)--$($colors.C_RESET)"
        }

        foreach ($line in $lines) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            try {
                $e = $line | ConvertFrom-Json -ErrorAction Stop
                if (-not $e.ts -or -not $e.session_id) { continue }
                $ts = $null
                try { $ts = [DateTimeOffset]::Parse($e.ts).LocalDateTime } catch { continue }
                if ($ts -lt $cutoff) { continue }
                $sid = [string]$e.session_id
                if (-not $sessions.ContainsKey($sid)) {
                    $sessions[$sid] = [ordered]@{ min = $ts; max = $ts }
                } else {
                    if ($ts -lt $sessions[$sid].min) { $sessions[$sid].min = $ts }
                    if ($ts -gt $sessions[$sid].max) { $sessions[$sid].max = $ts }
                }
            } catch {}
        }

        $totalSecs = 0.0
        foreach ($s in $sessions.Values) {
            $totalSecs += ($s.max - $s.min).TotalSeconds
        }
        $sessionCount = $sessions.Count

        if ($totalSecs -le 0) {
            return "$($colors.C_DIM)$label$($colors.C_RESET) $($colors.C_TIME)--$($colors.C_RESET)"
        }

        $h = [math]::Floor($totalSecs / 3600)
        $m = [math]::Floor(($totalSecs % 3600) / 60)
        $timeStr = if ($h -gt 0) { "${h}h ${m}m" } else { "${m}m" }

        $sessionSuffix = ''
        if ($sessionCount -gt 1) {
            $sessionSuffix = " $($colors.C_DIM)($sessionCount sessions)$($colors.C_RESET)"
        }

        return "$($colors.C_DIM)$label$($colors.C_RESET) $($colors.C_TIME)$timeStr$($colors.C_RESET)$sessionSuffix"
    }
}

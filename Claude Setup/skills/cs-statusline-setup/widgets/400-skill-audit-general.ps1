# ----------------------------------------------------------------------------
# widgets/400-skill-audit-general.ps1 — audit-general overlay (must-have #3)
#
# Reads ~/.claude/skill-state/audit-general.json (if present + fresh) and
# renders progress. The skill is responsible for writing this sidecar; the
# widget gracefully no-renders when the file is missing.
#
# Expected sidecar format:
#   { "active_auditor": "logic", "completed": ["sentry","stylist"], "total": 12 }
# ----------------------------------------------------------------------------

@{
    Name        = 'skill-audit-general'
    Line        = 1
    Position    = 'right'
    Priority    = 10
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $st = Get-SkillState -Plugin 'audit-general'
        if (-not $st) { return '' }

        $done = if ($st.completed) { $st.completed.Count } else { 0 }
        $total = if ($st.total) { $st.total } else { 12 }
        $active = $st.active_auditor

        $glyph = [char]::ConvertFromUtf32(0x1F50D)   # magnifying glass
        $progressStr = "${done}/${total}"
        $activeStr = if ($active) { " $($colors.C_YELLOW)$([char]0x23F3) $active$($colors.C_RESET)" } else { '' }

        return "$($colors.C_LABEL)$glyph audit$($colors.C_RESET) $($colors.C_GREEN)$progressStr$($colors.C_RESET)$activeStr"
    }
}

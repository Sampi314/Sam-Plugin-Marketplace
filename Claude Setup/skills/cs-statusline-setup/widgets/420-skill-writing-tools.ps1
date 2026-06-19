# ----------------------------------------------------------------------------
# widgets/420-skill-writing-tools.ps1 — wt-* progress overlay (must-have #3)
#
# Sidecar: ~/.claude/skill-state/writing-tools.json
#   { "active": "wt-ai-write", "word_count": 420, "section": "drafting" }
# ----------------------------------------------------------------------------

@{
    Name        = 'skill-writing-tools'
    Line        = 1
    Position    = 'right'
    Priority    = 12
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $st = Get-SkillState -Plugin 'writing-tools'
        if (-not $st) { return '' }

        $active = $st.active
        if (-not $active) { return '' }

        $shortName = $active -replace '^wt-', ''
        $glyph = [char]0x270D   # writing hand
        $wcStr = ''
        if ($st.word_count) {
            $wcStr = " $($colors.C_COUNT)$($st.word_count)w$($colors.C_RESET)"
        }

        return "$($colors.C_LABEL)$glyph $shortName$($colors.C_RESET)$wcStr"
    }
}

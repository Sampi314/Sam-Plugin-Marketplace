# ----------------------------------------------------------------------------
# widgets/410-skill-financial-modelling.ps1 — fm-* phase overlay (must-have #3)
#
# Sidecar: ~/.claude/skill-state/financial-modelling.json
#   { "phase": "fm-3-design", "subprogress": 0.6 }
# ----------------------------------------------------------------------------

@{
    Name        = 'skill-financial-modelling'
    Line        = 1
    Position    = 'right'
    Priority    = 11
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $st = Get-SkillState -Plugin 'financial-modelling'
        if (-not $st) { return '' }

        $phase = $st.phase
        if (-not $phase) { return '' }

        $phaseLabel = switch -Regex ($phase) {
            'fm-1' { 'Scope' }
            'fm-2' { 'Plan' }
            'fm-3' { 'Design' }
            'fm-4' { 'Build' }
            'fm-5' { 'Test' }
            'fm-6' { 'Implement' }
            default { $phase }
        }

        $glyph = [char]::ConvertFromUtf32(0x1F4CA)   # bar chart
        $pctStr = ''
        if ($st.subprogress) {
            $pct = [int]([double]$st.subprogress * 100)
            $pctStr = " $($colors.C_CYAN)$pct%$($colors.C_RESET)"
        }

        return "$($colors.C_LABEL)$glyph FM$($colors.C_RESET) $($colors.C_MODEL)$phaseLabel$($colors.C_RESET)$pctStr"
    }
}

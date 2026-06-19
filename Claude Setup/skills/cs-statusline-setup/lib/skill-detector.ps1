# ============================================================================
# lib/skill-detector.ps1 — detect active SumProduct skills via sidecar files
# ============================================================================
#
# Each SumProduct plugin (audit-general, financial-modelling, writing-tools)
# can write a tiny JSON sidecar to ~/.claude/skill-state/<plugin>.json that
# the statusline reads for overlay rendering.
#
# This file is the READ side only. The skills don't yet write these sidecars;
# Phase 1 ships read-side infrastructure so skill-aware overlays work as soon
# as the skills add the write side (one-line `Set-Content` per state change).
#
# Sidecar formats (proposed for the skills to adopt):
#
#   audit-general / state.json:
#     { "active_auditor": "logic", "completed": ["sentry","stylist"], "total": 12 }
#
#   financial-modelling / state.json:
#     { "phase": "fm-3-design", "subprogress": 0.6 }
#
#   writing-tools / state.json:
#     { "active": "wt-ai-write", "word_count": 420, "section": "drafting" }
# ============================================================================

$script:SKILL_STATE_DIR = Join-Path $env:USERPROFILE '.claude\skill-state'

function Get-SkillState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Plugin)

    $path = Join-Path $script:SKILL_STATE_DIR "$Plugin.json"
    if (-not (Test-Path $path)) { return $null }

    # Treat sidecars as stale after 5 minutes — skills should refresh while active.
    $age = (Get-Date) - (Get-Item $path).LastWriteTime
    if ($age.TotalMinutes -gt 5) { return $null }

    try { return Get-Content $path -Raw | ConvertFrom-Json } catch { return $null }
}

function Get-ActiveSkillFromAgent {
    [CmdletBinding()]
    param($Ctx)
    if (-not $Ctx.agent) { return $null }
    $name = $Ctx.agent.name
    if (-not $name) { return $null }
    # Map agent names to plugins
    if ($name -match '^ag-')   { return 'audit-general' }
    if ($name -match '^fm-')   { return 'financial-modelling' }
    if ($name -match '^wt-')   { return 'writing-tools' }
    if ($name -match '^cs-')   { return 'claude-setup' }
    return $null
}

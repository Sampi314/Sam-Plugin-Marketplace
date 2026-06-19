# ============================================================================
# lib/events-emitter.ps1 — NDJSON event stream (Layer 32)
# ============================================================================
#
# Appends structured events to ~/.claude/events.ndjson.
# Format is forward-compatible with Grafana/Datadog/Honeycomb ingestion.
#
# Event types:
#   tick              — per-statusline-invocation snapshot
#   threshold_5h_*    — 5h rate-limit crossed N% (e.g. threshold_5h_90)
#   threshold_wk_*    — weekly rate-limit crossed N%
#   threshold_ctx_*   — context-window crossed N%
#   activity_state    — idle <-> active transition
#   skill_invoked     — SumProduct skill becomes active
# ============================================================================

$script:EVENTS_FILE = Join-Path $env:USERPROFILE '.claude\events.ndjson'
$script:STATE_FILE  = Join-Path $env:USERPROFILE '.claude\events-state.json'
$script:MAX_LINES   = 50000   # ~30 days at 300s refresh ≈ 8k/day

function Emit-Event {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Type,
        [Parameter(Mandatory)][hashtable]$Payload
    )

    $entry = [ordered]@{
        ts   = (Get-Date).ToString('o')
        type = $Type
    }
    foreach ($k in $Payload.Keys) { $entry[$k] = $Payload[$k] }

    try {
        $dir = Split-Path $script:EVENTS_FILE -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ($entry | ConvertTo-Json -Compress) | Add-Content -Path $script:EVENTS_FILE -Encoding UTF8
    } catch { return }

    try {
        $lines = @(Get-Content $script:EVENTS_FILE -Encoding UTF8 -ErrorAction SilentlyContinue)
        if ($lines.Count -gt $script:MAX_LINES) {
            $lines[-$script:MAX_LINES..-1] | Set-Content -Path $script:EVENTS_FILE -Encoding UTF8
        }
    } catch {}
}

# Track threshold crossings so we only emit once per crossing per session
function Get-EventState {
    if (Test-Path $script:STATE_FILE) {
        try { return Get-Content $script:STATE_FILE -Raw | ConvertFrom-Json -AsHashtable } catch {}
    }
    return @{}
}

function Set-EventState {
    param([hashtable]$State)
    try {
        $State | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $script:STATE_FILE -Encoding UTF8
    } catch {}
}

function Test-AndEmit-Threshold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Key,        # e.g. "5h" or "wk" or "ctx"
        [Parameter(Mandatory)][double]$Value,
        [int[]]$Bands = @(50, 75, 90, 95)
    )
    $state = Get-EventState
    foreach ($b in $Bands) {
        $bandKey = "${Key}_${b}_crossed"
        if ($Value -ge $b -and -not $state.$bandKey) {
            Emit-Event -Type "threshold_${Key}_${b}" -Payload @{ value = $Value }
            $state[$bandKey] = $true
        } elseif ($Value -lt ($b - 5) -and $state.$bandKey) {
            # Reset when we drop 5pp below the band (hysteresis)
            $state[$bandKey] = $false
        }
    }
    Set-EventState $state
}

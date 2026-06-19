# ============================================================================
# lib/sample-log.ps1 — Per-tick metric sampling for sparklines
# ============================================================================
#
# Appends one JSON line per statusline invocation with current metric values.
# Sparkline widgets read the last N samples for the current session and chart
# their history.
#
# File: ~/.claude/statusline-samples.jsonl
# Auto-pruned to last 1000 entries on every write.
# ============================================================================

$script:SAMPLES_FILE = Join-Path $env:USERPROFILE '.claude\statusline-samples.jsonl'
$script:MAX_LINES = 1000

function Add-StatuslineSample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SessionId,
        [Parameter(Mandatory)][hashtable]$Metrics
    )

    $entry = [ordered]@{
        ts  = (Get-Date).ToString('o')
        sid = $SessionId
    }
    foreach ($k in $Metrics.Keys) {
        $entry[$k] = $Metrics[$k]
    }

    try {
        $dir = Split-Path $script:SAMPLES_FILE -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        ($entry | ConvertTo-Json -Compress) | Add-Content -Path $script:SAMPLES_FILE -Encoding UTF8
    } catch { return }

    # Auto-prune
    try {
        $lines = @(Get-Content $script:SAMPLES_FILE -Encoding UTF8 -ErrorAction SilentlyContinue)
        if ($lines.Count -gt $script:MAX_LINES) {
            $lines[-$script:MAX_LINES..-1] | Set-Content -Path $script:SAMPLES_FILE -Encoding UTF8
        }
    } catch {}
}

function Read-StatuslineSamples {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SessionId,
        [string]$Metric,
        [int]$Count = 30
    )

    if (-not (Test-Path $script:SAMPLES_FILE)) { return @() }

    $samples = @()
    try {
        $lines = @(Get-Content $script:SAMPLES_FILE -Encoding UTF8 -ErrorAction SilentlyContinue)
        # Walk from the most recent backward, gathering session-matching entries
        for ($i = $lines.Count - 1; $i -ge 0 -and $samples.Count -lt $Count; $i--) {
            try {
                $e = $lines[$i] | ConvertFrom-Json -ErrorAction Stop
                if ($e.sid -ne $SessionId) { continue }
                if ($Metric -and $null -eq $e.$Metric) { continue }
                $samples = ,$e + $samples
            } catch { continue }
        }
    } catch { return @() }

    if ($Metric) {
        return $samples | ForEach-Object { [double]$_.$Metric }
    }
    return $samples
}

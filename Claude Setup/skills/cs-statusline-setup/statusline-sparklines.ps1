# ============================================================================
# Claude Code Statusline v3.1 — PS 5.1+ Compatible
# ============================================================================
# Line 1: Model | effort | Session $cost | Project $total | version
# Line 2: CTX fill bar | % | $/hr burn rate
# Line 3: 5H usage (segmented) | % | ↻ Xd YYh ZZm | @HH:mm
# Line 4: WK usage (segmented) | % | ↻ Xd YYh ZZm | @HH:mm
# Line 5: WORK session duration | session +/- | project +/- | project duration
#
# PERSISTENT TRACKING:
#   All session data (cost, duration, lines) is logged to a JSONL file per
#   project. On terminal restart, project totals are rebuilt from the log.
#
# INSTALL:
#   1. Copy to %USERPROFILE%\.claude\statusline-sparklines.ps1
#   2. In %USERPROFILE%\.claude\settings.json:
#      {
#        "statusLine": {
#          "type": "command",
#          "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\statusline-sparklines.ps1\"",
#          "padding": 0
#        }
#      }
#   3. Restart Claude Code
# ============================================================================

$ESC = [char]0x1B

# --- Configuration -----------------------------------------------------------
$BAR_WIDTH         = 30
$USAGE_CACHE_FILE  = Join-Path $env:TEMP "claude-statusline-usage.json"
$USAGE_CACHE_SEC   = 15
$COST_LOG_DIR      = Join-Path $env:USERPROFILE ".claude"
$COST_LOG_FILE     = Join-Path $COST_LOG_DIR "project-costs.jsonl"
$MCP_CACHE_FILE    = Join-Path $env:TEMP "claude-statusline-mcp-cache.txt"
$MCP_CACHE_SEC     = 120
$MSG_CACHE_FILE    = Join-Path $env:TEMP "claude-statusline-msg-cache.json"
$MSG_CACHE_SEC     = 10
$ACTIVITY_FILE     = Join-Path $env:TEMP "claude-statusline-activity.json"
$ACTIVITY_IDLE_SEC = 30

# --- ANSI helpers ------------------------------------------------------------
function Fg($r,$g,$b) { return "${ESC}[38;2;${r};${g};${b}m" }
function FgDim($r,$g,$b) {
    $dr = [math]::Round($r * 0.4); $dg = [math]::Round($g * 0.4); $db = [math]::Round($b * 0.4)
    return "${ESC}[38;2;${dr};${dg};${db}m"
}
function Rst   { return "${ESC}[0m" }
function Bold  { return "${ESC}[1m" }

$C_LABEL   = Fg 140 140 160
$C_MODEL   = Fg 180 140 255      # purple
$C_SKILL   = Fg 130 220 200      # teal
$C_COST    = Fg 255 220 80       # gold
$C_PROJCST = Fg 255 160 100      # orange
$C_ADD     = Fg 130 220 130      # green — lines added
$C_DEL     = Fg 255 100 100      # red — lines removed
$C_TIME    = Fg 130 180 255      # blue — duration
$C_COUNT   = Fg 200 170 255      # lavender — session count
$C_DIM     = Fg 80 80 100
$C_DIVIDER = Fg 90 90 110
$C_RESET   = Rst
$C_CYAN    = Fg 80 220 220       # cyan — effort level
$C_GREEN   = Fg 130 220 130      # green — git clean / staged
$C_YELLOW  = Fg 255 220 80       # yellow — git modified
$C_RED     = Fg 255 80 80        # red — git untracked / warnings
$C_GOLD    = Fg 255 200 60       # gold — burn rate

# =============================================================================
# CREDENTIAL & USAGE API
# =============================================================================

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WinCred {
    [DllImport("advapi32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool CredRead(string target, int type, int flags, out IntPtr credential);

    [DllImport("advapi32.dll")]
    public static extern void CredFree(IntPtr buffer);

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public long LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetCredential(string target) {
        IntPtr credPtr;
        if (!CredRead(target, 1, 0, out credPtr)) return null;
        try {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            if (cred.CredentialBlobSize > 0) {
                return Marshal.PtrToStringUni(cred.CredentialBlob, cred.CredentialBlobSize / 2);
            }
            return null;
        } finally {
            CredFree(credPtr);
        }
    }
}
"@ -ErrorAction SilentlyContinue

function Get-OAuthToken {
    # Try all known Windows Credential Manager key names that Claude Code may use
    foreach ($t in @(
        "Claude Code-credentials",
        "claude-code-credentials",
        "Claude Code",
        "claude-code",
        "Claude",
        "Anthropic Claude Code"
    )) {
        try {
            $raw = [WinCred]::GetCredential($t)
            if ($raw) {
                $p = $raw | ConvertFrom-Json -ErrorAction Stop
                if ($p.claudeAiOauth -and $p.claudeAiOauth.accessToken) { return $p.claudeAiOauth.accessToken }
                # Some versions store the token directly as a string
                if ($p.accessToken) { return $p.accessToken }
            }
        } catch { continue }
    }
    # Fall back to credential files on disk
    foreach ($fp in @(
        (Join-Path (Join-Path $env:USERPROFILE ".claude") ".credentials.json"),
        (Join-Path (Join-Path $env:USERPROFILE ".claude") "credentials.json"),
        (Join-Path (Join-Path $env:APPDATA "Claude Code") "credentials.json"),
        (Join-Path (Join-Path $env:LOCALAPPDATA "Claude Code") "credentials.json"),
        (Join-Path (Join-Path $env:APPDATA "Anthropic") "credentials.json")
    )) {
        if (Test-Path $fp) {
            try {
                $p = Get-Content $fp -Raw | ConvertFrom-Json -ErrorAction Stop
                if ($p.claudeAiOauth -and $p.claudeAiOauth.accessToken) { return $p.claudeAiOauth.accessToken }
                if ($p.accessToken) { return $p.accessToken }
            } catch { continue }
        }
    }
    return $null
}

function Get-UsageData {
    # Helper: read stale cache (any age) as last resort
    function Read-CacheFile {
        if (Test-Path $USAGE_CACHE_FILE) {
            try { return (Get-Content $USAGE_CACHE_FILE -Raw | ConvertFrom-Json -ErrorAction Stop) } catch {}
        }
        return $null
    }

    # Return fresh cache if within TTL
    if (Test-Path $USAGE_CACHE_FILE) {
        $age = (Get-Date) - (Get-Item $USAGE_CACHE_FILE).LastWriteTime
        if ($age.TotalSeconds -lt $USAGE_CACHE_SEC) {
            $cached = Read-CacheFile
            if ($cached) { return $cached }
        }
    }

    # Try to get a token; if none available fall back to stale cache rather than
    # returning nulls — this prevents the bars from disappearing when the cache
    # is older than the TTL but we cannot reach the API.
    $token = Get-OAuthToken
    if (-not $token) {
        # Serve stale cache up to 30 minutes; after that, show blank rather than ancient data
        if (Test-Path $USAGE_CACHE_FILE) {
            $staleAge = (Get-Date) - (Get-Item $USAGE_CACHE_FILE).LastWriteTime
            if ($staleAge.TotalMinutes -lt 30) {
                $stale = Read-CacheFile
                if ($stale) { return $stale }
            }
        }
        return @{ five_hour = $null; seven_day = $null }
    }

    try {
        $headers = @{
            "Accept"="application/json"; "Content-Type"="application/json"
            "Authorization"="Bearer $token"; "anthropic-beta"="oauth-2025-04-20"
            "User-Agent"="claude-code/2.1.0"
        }
        $resp = Invoke-RestMethod -Uri "https://api.anthropic.com/api/oauth/usage" `
                    -Method GET -Headers $headers -TimeoutSec 5 -ErrorAction Stop
        $result = @{ five_hour = $null; seven_day = $null }
        if ($null -ne $resp.five_hour) {
            $result.five_hour = @{
                utilization = [double]$resp.five_hour.utilization
                resets_at   = if ($resp.five_hour.resets_at) { $resp.five_hour.resets_at } else { $null }
            }
        }
        if ($null -ne $resp.seven_day) {
            $result.seven_day = @{
                utilization = [double]$resp.seven_day.utilization
                resets_at   = if ($resp.seven_day.resets_at) { $resp.seven_day.resets_at } else { $null }
            }
        }
        $result | ConvertTo-Json -Depth 4 -Compress |
            Set-Content $USAGE_CACHE_FILE -Encoding UTF8 -ErrorAction SilentlyContinue
        return $result
    } catch {
        # API call failed — serve stale cache rather than showing blank bars
        $stale = Read-CacheFile
        if ($stale) { return $stale }
        return @{ five_hour = $null; seven_day = $null }
    }
}

# =============================================================================
# PERSISTENT PROJECT TRACKING
# =============================================================================
# Logs one entry per statusline update. On read, deduplicates by session_id
# (keeps latest per session) to compute accurate project totals.
# Survives terminal restarts, session handoffs, and multi-session work.
# =============================================================================

function Update-ProjectLog($projectDir, $sessionId, $sessionCost, $durationMs, $linesAdded, $linesRemoved) {
    if (-not $projectDir -or -not $sessionId) { return }
    if (-not (Test-Path $COST_LOG_DIR)) {
        New-Item -ItemType Directory -Path $COST_LOG_DIR -Force -ErrorAction SilentlyContinue | Out-Null
    }
    $entry = @{
        proj = $projectDir
        sid  = $sessionId
        cost = $sessionCost
        dur  = $durationMs
        add  = $linesAdded
        del  = $linesRemoved
        ts   = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    } | ConvertTo-Json -Compress
    Add-Content -Path $COST_LOG_FILE -Value $entry -Encoding UTF8 -ErrorAction SilentlyContinue

    # Auto-prune: keep last 5000 lines
    if (Test-Path $COST_LOG_FILE) {
        $allLines = @(Get-Content $COST_LOG_FILE -Encoding UTF8 -ErrorAction SilentlyContinue)
        if ($allLines.Count -gt 5000) {
            $allLines[-5000..-1] | Set-Content $COST_LOG_FILE -Encoding UTF8 -ErrorAction SilentlyContinue
        }
    }
}

function Get-ProjectStats($projectDir) {
    $stats = @{
        TotalCost     = 0.0
        TotalDuration = 0.0    # milliseconds
        TotalAdded    = 0
        TotalRemoved  = 0
        SessionCount  = 0
    }
    if (-not $projectDir -or -not (Test-Path $COST_LOG_FILE)) { return $stats }

    $sessions = @{}
    foreach ($line in @(Get-Content $COST_LOG_FILE -Encoding UTF8 -ErrorAction SilentlyContinue)) {
        if (-not $line) { continue }
        try {
            $e = $line | ConvertFrom-Json -ErrorAction Stop
            if ($e.proj -eq $projectDir) {
                # Keep latest entry per session (overwrites previous)
                $sessions[$e.sid] = $e
            }
        } catch { continue }
    }

    $stats.SessionCount = $sessions.Count
    foreach ($s in $sessions.Values) {
        $stats.TotalCost     += [double]$s.cost
        $stats.TotalDuration += [double]$s.dur
        $stats.TotalAdded    += [int]$s.add
        $stats.TotalRemoved  += [int]$s.del
    }
    return $stats
}

# =============================================================================
# RENDERING
# =============================================================================

function Render-SegmentedBar($pct, $visualWidth, $segments, $projectedPct) {
    if (-not $projectedPct) { $projectedPct = 0 }
    $dividers     = $segments - 1
    $totalBlocks  = $visualWidth - $dividers
    $blocksPerSeg = [math]::Floor($totalBlocks / $segments)
    $remainder    = $totalBlocks - ($blocksPerSeg * $segments)
    $filled = [math]::Round(($pct / 100.0) * $totalBlocks)
    $filled = [math]::Max(0, [math]::Min($totalBlocks, $filled))
    $projFilled = [math]::Round((($pct + $projectedPct) / 100.0) * $totalBlocks)
    $projFilled = [math]::Max($filled, [math]::Min($totalBlocks, $projFilled))
    $bar = ""; $pos = 0
    for ($seg = 0; $seg -lt $segments; $seg++) {
        $segLen = $blocksPerSeg + $(if ($seg -lt $remainder) { 1 } else { 0 })
        for ($b = 0; $b -lt $segLen; $b++) {
            $posPct = ($pos / $totalBlocks) * 100
            if ($pos -lt $filled) {
                if     ($posPct -lt 50) { $c = Fg 130 220 130 }
                elseif ($posPct -lt 70) { $c = Fg 255 220 80  }
                elseif ($posPct -lt 85) { $c = Fg 255 160 60  }
                else                    { $c = Fg 255 80 80   }
                $bar += "${c}$([char]0x2588)"
            } elseif ($pos -lt $projFilled) {
                if     ($posPct -lt 50) { $c = FgDim 130 220 130 }
                elseif ($posPct -lt 70) { $c = FgDim 255 220 80  }
                elseif ($posPct -lt 85) { $c = FgDim 255 160 60  }
                else                    { $c = FgDim 255 80 80   }
                $bar += "${c}$([char]0x2592)"
            } else { $bar += "$(Fg 60 60 75)$([char]0x2591)" }
            $pos++
        }
        if ($seg -lt $dividers) { $bar += "${C_DIVIDER}$([char]0x2502)" }
    }
    return "${bar}${C_RESET}"
}

function Render-FillBar($pct, $width) {
    $filled = [math]::Round(($pct / 100.0) * $width)
    $filled = [math]::Max(0, [math]::Min($width, $filled))
    $bar = ""
    for ($i = 0; $i -lt $filled; $i++) {
        $posPct = ($i / $width) * 100
        if     ($posPct -lt 50) { $c = Fg 130 220 130 }
        elseif ($posPct -lt 70) { $c = Fg 255 220 80  }
        elseif ($posPct -lt 85) { $c = Fg 255 160 60  }
        else                    { $c = Fg 255 80 80   }
        $bar += "${c}$([char]0x2588)"
    }
    for ($i = $filled; $i -lt $width; $i++) {
        $bar += "$(Fg 60 60 75)$([char]0x2591)"
    }
    return "${bar}${C_RESET}"
}

function Colour-Pct($pct) {
    if     ($pct -lt 50) { $c = Fg 130 220 130 }
    elseif ($pct -lt 70) { $c = Fg 255 220 80  }
    elseif ($pct -lt 85) { $c = Fg 255 160 60  }
    else                 { $c = Fg 255 80 80   }
    return "${c}$("{0,5:N1}%" -f $pct)${C_RESET}"
}

function Format-ResetTime($resetsAt) {
    # Fixed-width countdown: "Xd YYh ZZm" — same shape for 5H and WK lines so
    # they line up vertically. Days are 1-7 (no padding); hours/minutes are 2.
    if (-not $resetsAt) { return "${C_DIM}--d --h --m${C_RESET}" }
    try {
        # Handle both Unix epoch integers/strings and ISO 8601 strings
        $target = $null
        $asStr = "$resetsAt".Trim()
        if ($asStr -match '^\d{9,13}$') {
            # Unix epoch — seconds (9-10 digits) or milliseconds (13 digits)
            $epochSec = if ($asStr.Length -ge 13) { [long]$asStr / 1000 } else { [long]$asStr }
            $target = [DateTimeOffset]::FromUnixTimeSeconds($epochSec)
        } else {
            $target = [DateTimeOffset]::Parse($asStr)
        }
        $diff = $target - [DateTimeOffset]::UtcNow
        if ($diff.TotalSeconds -le 0) { return "$(Fg 130 220 130)0d 00h 00m${C_RESET}" }
        $days = [math]::Floor($diff.TotalDays)
        return "${C_LABEL}$($days)d $("{0:D2}" -f $diff.Hours)h $("{0:D2}" -f $diff.Minutes)m${C_RESET}"
    } catch { return "${C_DIM}--d --h --m${C_RESET}" }
}

function Format-Duration($ms) {
    if ($ms -le 0) { return "${C_DIM}0m${C_RESET}" }
    $ts = [TimeSpan]::FromMilliseconds($ms)
    if ($ts.TotalDays -ge 1) {
        return "${C_TIME}$([math]::Floor($ts.TotalDays))d $($ts.Hours)h $($ts.Minutes)m${C_RESET}"
    } elseif ($ts.TotalHours -ge 1) {
        return "${C_TIME}$([math]::Floor($ts.TotalHours))h $($ts.Minutes)m${C_RESET}"
    } else {
        return "${C_TIME}$($ts.Minutes)m $($ts.Seconds)s${C_RESET}"
    }
}

function Format-Cost($val) {
    if ($val -ge 100)   { return "`${0:N0}"  -f $val }
    elseif ($val -ge 1) { return "`${0:N2}"  -f $val }
    else                { return "`${0:N3}"  -f $val }
}

function Get-ProjectedPct($utilizationPct, $resetsAt, $blockDurationSec) {
    if (-not $resetsAt -or $utilizationPct -le 0) { return 0 }
    try {
        $asStr = "$resetsAt".Trim()
        $target = $null
        if ($asStr -match '^\d{9,13}$') {
            $epochSec = if ($asStr.Length -ge 13) { [long]$asStr / 1000 } else { [long]$asStr }
            $target = [DateTimeOffset]::FromUnixTimeSeconds($epochSec)
        } else {
            $target = [DateTimeOffset]::Parse($asStr)
        }
        $diff = $target - [DateTimeOffset]::UtcNow
        $timeRemaining = $diff.TotalSeconds
        if ($timeRemaining -le 0) { return 0 }
        $timeElapsed = $blockDurationSec - $timeRemaining
        if ($timeElapsed -le 0) { return 0 }

        # Require at least 2% of the window to have elapsed before projecting.
        # A tiny timeElapsed causes an inflated rate and spurious 100% projections.
        $elapsedFraction = $timeElapsed / $blockDurationSec
        if ($elapsedFraction -lt 0.02) { return 0 }

        $rate = $utilizationPct / $timeElapsed
        $projectedTotal = $utilizationPct + ($rate * $timeRemaining)
        $projectedTotal = [math]::Min(100.0, $projectedTotal)
        return [math]::Round($projectedTotal - $utilizationPct, 1)
    } catch { return 0 }
}

function Format-AbsResetTime($resetsAt) {
    # Returns the reset moment as HH:mm in the local timezone.
    if (-not $resetsAt) { return "--:--" }
    try {
        $asStr = "$resetsAt".Trim()
        $target = $null
        if ($asStr -match '^\d{9,13}$') {
            $epochSec = if ($asStr.Length -ge 13) { [long]$asStr / 1000 } else { [long]$asStr }
            $target = [DateTimeOffset]::FromUnixTimeSeconds($epochSec).ToLocalTime()
        } else {
            $target = [DateTimeOffset]::Parse($asStr).ToLocalTime()
        }
        return $target.ToString("HH:mm")
    } catch { return "--:--" }
}

# =============================================================================
# GIT HELPERS
# =============================================================================

function Get-GitLine($cwd) {
    # Returns a formatted git status string, or $null if not a git repo
    if (-not $cwd -or -not (Test-Path $cwd)) { return $null }
    try {
        # Check if inside a git repo
        $gitCheck = & git --no-optional-locks -C $cwd rev-parse --is-inside-work-tree 2>&1
        if ($LASTEXITCODE -ne 0) { return $null }

        # Branch name
        $branch = (& git --no-optional-locks -C $cwd rev-parse --abbrev-ref HEAD 2>&1) -join ""
        if (-not $branch -or $branch -match "^fatal") { $branch = "?" }

        # Porcelain status
        $statusLines = @(& git --no-optional-locks -C $cwd status --porcelain 2>&1)
        $staged    = 0
        $modified  = 0
        $untracked = 0
        foreach ($line in $statusLines) {
            if (-not $line -or $line.Length -lt 2) { continue }
            $x = $line[0]   # index (staged) state
            $y = $line[1]   # worktree state
            if ($line -match "^\?\?") { $untracked++; continue }
            if ($x -ne ' ' -and $x -ne '?') { $staged++ }
            if ($y -ne ' ' -and $y -ne '?') { $modified++ }
        }

        # Last commit time
        $lastCommitRaw = (& git --no-optional-locks -C $cwd log -1 --format="%ct" 2>&1) -join ""
        $commitAgo = ""
        if ($lastCommitRaw -match "^\d+$") {
            $epochNow  = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            $diffSec   = $epochNow - [long]$lastCommitRaw
            if     ($diffSec -lt 60)       { $commitAgo = "${C_GREEN}just now${C_RESET}" }
            elseif ($diffSec -lt 3600)     { $commitAgo = "${C_LABEL}$([math]::Floor($diffSec/60))m ago${C_RESET}" }
            elseif ($diffSec -lt 86400)    { $commitAgo = "${C_LABEL}$([math]::Floor($diffSec/3600))h ago${C_RESET}" }
            elseif ($diffSec -lt 2592000)  { $commitAgo = "${C_LABEL}$([math]::Floor($diffSec/86400))d ago${C_RESET}" }
            else                           { $commitAgo = "${C_LABEL}$([math]::Floor($diffSec/2592000))mo ago${C_RESET}" }
        } else { $commitAgo = "${C_DIM}--${C_RESET}" }

        # Build parts
        $branchStr = "${C_GREEN}${branch}${C_RESET}"
        $D = $C_DIM; $R = $C_RESET
        $parts = @($branchStr)

        if ($staged -eq 0 -and $modified -eq 0 -and $untracked -eq 0) {
            $parts += "${C_GREEN}clean $(([char]0x2713))${C_RESET}"
        } else {
            if ($staged    -gt 0) { $parts += "${C_GREEN}+${staged}${C_RESET}" }
            if ($modified  -gt 0) { $parts += "${C_YELLOW}~${modified}${C_RESET}" }
            if ($untracked -gt 0) { $parts += "${C_RED}?${untracked}${C_RESET}" }
        }
        $parts += $commitAgo

        $sep = " ${D}|${R} "
        return ($parts -join $sep)
    } catch { return $null }
}

# =============================================================================
# MCP COUNT (cached)
# =============================================================================

function Get-McpCount {
    # Count MCP servers by reading settings files directly — never spawn `claude`
    # which can hang or deadlock when called from inside the statusline script.
    $count = 0
    $settingsPaths = @(
        (Join-Path $env:USERPROFILE ".claude\settings.json"),
        (Join-Path $env:USERPROFILE ".claude\settings.local.json"),
        (Join-Path (Get-Location) ".claude\settings.json"),
        (Join-Path (Get-Location) ".claude\settings.local.json")
    )
    $seen = @{}
    foreach ($sp in $settingsPaths) {
        if (-not (Test-Path $sp)) { continue }
        try {
            $s = Get-Content $sp -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if ($s.mcpServers) {
                foreach ($key in ($s.mcpServers | Get-Member -MemberType NoteProperty).Name) {
                    if (-not $seen[$key]) { $seen[$key] = $true; $count++ }
                }
            }
        } catch { continue }
    }
    return $count
}

# =============================================================================
# MESSAGE COUNT (cached, reads transcript JSONL)
# =============================================================================

function Get-MsgCount($transcriptPath) {
    if (-not $transcriptPath) { return 0 }

    # Cache key = path; serve if fresh enough
    if (Test-Path $MSG_CACHE_FILE) {
        $cacheAge = (Get-Date) - (Get-Item $MSG_CACHE_FILE).LastWriteTime
        if ($cacheAge.TotalSeconds -lt $MSG_CACHE_SEC) {
            try {
                $c = Get-Content $MSG_CACHE_FILE -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                if ($c.path -eq $transcriptPath) { return [int]$c.count }
            } catch {}
        }
    }

    if (-not (Test-Path $transcriptPath)) { return 0 }
    try {
        $count = 0
        foreach ($line in @(Get-Content $transcriptPath -Encoding UTF8 -ErrorAction SilentlyContinue)) {
            if (-not $line) { continue }
            try {
                $entry = $line | ConvertFrom-Json -ErrorAction Stop
                if ($entry.type -eq "human") { $count++ }
            } catch { continue }
        }
        @{ path = $transcriptPath; count = $count } |
            ConvertTo-Json -Compress |
            Set-Content $MSG_CACHE_FILE -Encoding UTF8 -ErrorAction SilentlyContinue
        return $count
    } catch { return 0 }
}

# =============================================================================
# READ STDIN
# =============================================================================

# Read stdin: try PowerShell pipeline first, then Console.In
$inputJson = $null
try {
    $pipeLines = @($input)
    if ($pipeLines.Count -gt 0) { $inputJson = $pipeLines -join "`n" }
} catch {}
if (-not $inputJson) {
    try { $inputJson = [Console]::In.ReadToEnd() } catch {}
}
if (-not $inputJson) {
    Write-Host "${C_DIM}Claude Code ${C_RESET}${C_LABEL}-- waiting for data${C_RESET}"
    exit 0
}
try { $data = $inputJson | ConvertFrom-Json -ErrorAction Stop }
catch { Write-Host "statusline: parse error"; exit 0 }

$model          = if ($data.model -and $data.model.display_name) { $data.model.display_name } else { "--" }
$agentName      = if ($data.agent -and $data.agent.name) { $data.agent.name } else { "" }
$agentType      = if ($data.agent -and $data.agent.type) { $data.agent.type } else { "" }
$agentActive    = ($agentName -ne "")
$skill          = if ($agentActive) { $agentName } else { "--" }
$sessionId      = if ($data.session_id) { $data.session_id } else { "" }
$projectDir     = if ($data.workspace -and $data.workspace.project_dir) { $data.workspace.project_dir } else { "" }
$currentDir     = if ($data.workspace -and $data.workspace.current_dir) { $data.workspace.current_dir } `
                  elseif ($data.cwd) { $data.cwd } else { "" }
$transcriptPath = if ($data.transcript_path) { $data.transcript_path } else { "" }
$appVersion     = if ($data.version) { $data.version } else { "" }
$outputStyle    = if ($data.output_style -and $data.output_style.name) { $data.output_style.name } else { "" }
$effortLevel    = if ($data.effort -and $data.effort.level) { $data.effort.level } `
                  elseif ($data.effortLevel) { $data.effortLevel } `
                  elseif ($data.effort_level) { $data.effort_level } else { "" }
$ctxPct         = if ($data.context_window -and ($null -ne $data.context_window.used_percentage)) {
                      [math]::Round($data.context_window.used_percentage, 1) } else { 0 }

# The statusline JSON does not include cost/duration/lines fields.
# Estimate session cost from cumulative token counts using typical pricing.
# Claude 3.5 Sonnet: $3/M input, $15/M output, $0.30/M cache-read, $3.75/M cache-write
$sessionCost      = 0.0
$sessionDur       = 0       # populated from cost.total_duration_ms if present
$linesAdded       = 0       # populated from cost.total_lines_added if present
$linesRemoved     = 0       # populated from cost.total_lines_removed if present
$totalCostUsd     = 0.0     # from cost.total_cost_usd if present
$totalDurationMs  = 0.0     # from cost.total_duration_ms if present
$hasCostData      = $false

if ($data.cost) {
    $hasCostData     = $true
    $totalCostUsd    = if ($null -ne $data.cost.total_cost_usd)      { [double]$data.cost.total_cost_usd }      else { 0.0 }
    $totalDurationMs = if ($null -ne $data.cost.total_duration_ms)   { [double]$data.cost.total_duration_ms }   else { 0.0 }
    $linesAdded      = if ($null -ne $data.cost.total_lines_added)   { [int]$data.cost.total_lines_added }      else { 0 }
    $linesRemoved    = if ($null -ne $data.cost.total_lines_removed) { [int]$data.cost.total_lines_removed }    else { 0 }
    $sessionCost     = $totalCostUsd
    $sessionDur      = [long]$totalDurationMs
}

$curIn = 0; $curCacheRead = 0; $curCacheWrite = 0
if ($data.context_window) {
    $cw = $data.context_window
    $inTok     = if ($null -ne $cw.total_input_tokens)   { [double]$cw.total_input_tokens }   else { 0 }
    $outTok    = if ($null -ne $cw.total_output_tokens)  { [double]$cw.total_output_tokens }  else { 0 }
    if ($cw.current_usage) {
        $curIn        = if ($null -ne $cw.current_usage.input_tokens)               { [double]$cw.current_usage.input_tokens }               else { 0 }
        $curCacheRead = if ($null -ne $cw.current_usage.cache_read_input_tokens)    { [double]$cw.current_usage.cache_read_input_tokens }    else { 0 }
        $curCacheWrite= if ($null -ne $cw.current_usage.cache_creation_input_tokens){ [double]$cw.current_usage.cache_creation_input_tokens } else { 0 }
    }
    if (-not $hasCostData) {
        # Approximate cost from token counts with standard Sonnet pricing
        $sessionCost = ($inTok / 1e6 * 3.0) + ($outTok / 1e6 * 15.0) +
                       ($curCacheRead / 1e6 * 0.30) + ($curCacheWrite / 1e6 * 3.75)
    }
}

# --- Burn rate: $/hr ----------------------------------------------------------
$burnRateStr = "--"
if ($totalDurationMs -gt 0) {
    $hrs = $totalDurationMs / 3600000.0
    $burnRate = if ($hrs -gt 0) { $totalCostUsd / $hrs } else { 0 }
    $burnRateStr = "`${0:N2}/hr" -f $burnRate
}

# --- Cache hit rate -----------------------------------------------------------
$cacheHitStr   = "--"
$cacheHitColor = $C_LABEL
$hasCacheData  = ($data.context_window -and $data.context_window.current_usage -and
                  $data.context_window.current_usage -ne $null)
if ($hasCacheData) {
    $cacheTotal = $curIn + $curCacheRead + $curCacheWrite
    if ($cacheTotal -gt 0) {
        $cacheHitPct = ($curCacheRead / $cacheTotal) * 100
        $cacheHitStr = "$([math]::Round($cacheHitPct, 0))%"
        if     ($cacheHitPct -ge 70) { $cacheHitColor = $C_GREEN  }
        elseif ($cacheHitPct -ge 40) { $cacheHitColor = $C_YELLOW }
        else                         { $cacheHitColor = $C_RED    }
    } else { $cacheHitStr = "0%" ; $cacheHitColor = $C_RED }
}

# --- Activity detection -------------------------------------------------------
$totalTokens = 0
if ($data.context_window) {
    if ($null -ne $data.context_window.total_input_tokens)  { $totalTokens += [double]$data.context_window.total_input_tokens }
    if ($null -ne $data.context_window.total_output_tokens) { $totalTokens += [double]$data.context_window.total_output_tokens }
}
$isActive = $false
$nowEpoch = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
try {
    $activityState = $null
    if (Test-Path $ACTIVITY_FILE) {
        $activityState = Get-Content $ACTIVITY_FILE -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    if ($activityState -and $activityState.token_count -ne $totalTokens) {
        $isActive = $true
        @{ token_count = $totalTokens; last_changed_ts = $nowEpoch } |
            ConvertTo-Json -Compress |
            Set-Content $ACTIVITY_FILE -Encoding UTF8 -ErrorAction SilentlyContinue
    } elseif ($activityState) {
        $idleSec = $nowEpoch - [long]$activityState.last_changed_ts
        if ($idleSec -lt $ACTIVITY_IDLE_SEC) { $isActive = $true }
    } else {
        $isActive = $true
        @{ token_count = $totalTokens; last_changed_ts = $nowEpoch } |
            ConvertTo-Json -Compress |
            Set-Content $ACTIVITY_FILE -Encoding UTF8 -ErrorAction SilentlyContinue
    }
} catch { $isActive = $false }

# --- Persist session data to project log -------------------------------------
if ($projectDir -and $sessionId) {
    Update-ProjectLog $projectDir $sessionId $sessionCost $sessionDur $linesAdded $linesRemoved
}

# --- Get cumulative project stats (all previous + current sessions) ----------
$projStats   = Get-ProjectStats $projectDir
$projectName = if ($projectDir) { Split-Path $projectDir -Leaf } else { "--" }

# --- Git line -----------------------------------------------------------------
$gitCwd    = if ($currentDir) { $currentDir } elseif ($projectDir) { $projectDir } else { "" }
$gitLine   = Get-GitLine $gitCwd

# --- ENV: hooks count ---------------------------------------------------------
$hooksCount = 0
foreach ($hooksDir in @(
    (Join-Path $projectDir ".claude\hooks"),
    (Join-Path $env:USERPROFILE ".claude\hooks")
)) {
    if (Test-Path $hooksDir) {
        $hooksCount += @(Get-ChildItem $hooksDir -Filter "*.hooks" -ErrorAction SilentlyContinue).Count
    }
}

# --- ENV: MCP server count ---------------------------------------------------
$mcpCount = Get-McpCount

# --- ENV: Skills count -------------------------------------------------------
$skillsCount = 0
$skillsDir   = Join-Path $projectDir ".claude\skills"
if (Test-Path $skillsDir) {
    $skillsCount = @(Get-ChildItem $skillsDir -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue).Count
}

# --- ENV: CLAUDE.md indicator ------------------------------------------------
$claudeMdPath    = Join-Path $projectDir "CLAUDE.md"
$claudeMdExists  = Test-Path $claudeMdPath

# --- ENV: Message count from transcript --------------------------------------
$msgCount = Get-MsgCount $transcriptPath

# =============================================================================
# FETCH USAGE
# =============================================================================

$usage = Get-UsageData
# Normalise utilization: API may return 0.22 (fraction) or 22 (integer percent)
function Normalise-Pct($val) {
    if ($null -eq $val) { return 0 }
    $v = [double]$val
    # API returns integer percentages (0-100). Values below 1 are sub-1% usage, not fractions.
    if ($v -ge 1.0) { return [math]::Round($v, 1) }
    else             { return [math]::Round($v, 2) }
}

function Is-ResetPast($resetsAt) {
    if (-not $resetsAt) { return $false }
    try {
        $asStr = "$resetsAt".Trim()
        if ($asStr -match '^\d{9,13}$') {
            $epochSec = if ($asStr.Length -ge 13) { [long]$asStr / 1000 } else { [long]$asStr }
            return ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -ge $epochSec)
        } else {
            return ([DateTimeOffset]::UtcNow -ge [DateTimeOffset]::Parse($asStr))
        }
    } catch { return $false }
}

$pct5H   = if ($usage.five_hour -and -not (Is-ResetPast $usage.five_hour.resets_at)) { Normalise-Pct $usage.five_hour.utilization } else { 0 }
$reset5H = if ($usage.five_hour) { $usage.five_hour.resets_at } else { $null }
$pctWK   = if ($usage.seven_day -and -not (Is-ResetPast $usage.seven_day.resets_at)) { Normalise-Pct $usage.seven_day.utilization } else { 0 }
$resetWK = if ($usage.seven_day) { $usage.seven_day.resets_at } else { $null }

# =============================================================================
# BUILD + OUTPUT
# =============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Projection calculation ---------------------------------------------------
$proj5H = 0; $projWK = 0
if ($isActive) {
    $proj5H = Get-ProjectedPct $pct5H $reset5H 18000    # 5 hours = 18000s
    $projWK = Get-ProjectedPct $pctWK $resetWK 604800   # 7 days  = 604800s
}

$ctxBar = Render-FillBar $ctxPct $BAR_WIDTH
$bar5H  = Render-SegmentedBar $pct5H $BAR_WIDTH 5 $proj5H
$barWK  = Render-SegmentedBar $pctWK $BAR_WIDTH 7 $projWK

$fmtSessionCost = Format-Cost $sessionCost
$fmtProjectCost = Format-Cost $projStats.TotalCost
$reset5Hfmt     = Format-ResetTime $reset5H
$resetWKfmt     = Format-ResetTime $resetWK
$fmtSessionDur  = Format-Duration $sessionDur
$fmtProjectDur  = Format-Duration $projStats.TotalDuration

# New: absolute reset times for 5H/WK lines
$abs5HReset   = Format-AbsResetTime $reset5H
$absWKReset   = Format-AbsResetTime $resetWK

$L = $C_LABEL; $D = $C_DIM; $R = $C_RESET
$PIPE  = [char]0x251C   # ├
$FLOOR = [char]0x2514   # └
$SEP   = " ${D}|${R} "

# ---------------------------------------------------------------------------
# LINE 1 — HEADER: Model | effort | Session $ | Project $ | version
# ---------------------------------------------------------------------------
try {
    $modelStr = "${C_MODEL}$(Bold)${model}${R}"
    if ($effortLevel) {
        $modelStr += " ${D}|${R} ${C_CYAN}$($effortLevel.ToLower())${R}"
    }
    $versionStr = if ($appVersion) { "${L}v${appVersion}${R}" } else { "${D}v?${R}" }
    $line1  = "${modelStr}"
    $line1 += " ${D}|${R} ${L}Session:${R} ${C_COST}${fmtSessionCost}${R}"
    $line1 += " ${D}|${R} ${L}${projectName}:${R} ${C_PROJCST}${fmtProjectCost}${R}"
    $line1 += " ${D}|${R} ${versionStr}"
    Write-Host $line1
} catch { Write-Host "${C_DIM}[line1 error]${C_RESET}" }

# ---------------------------------------------------------------------------
# LINE 2 — CTX: fill bar | % [warn] | used/max | burn rate
# ---------------------------------------------------------------------------
try {
    $ctxWarnPrefix = ""
    if ($ctxPct -ge 90) {
        $ctxWarnPrefix = "${C_RED}$([char]0x26A0) ${R}"
        $ctxLabel = "${ESC}[1;91mCTX:${R}"
    } elseif ($ctxPct -ge 75) {
        $ctxWarnPrefix = "${C_RED}$([char]0x26A0) ${R}"
        $ctxLabel = "${L}CTX:${R}"
    } else {
        $ctxLabel = "${L}CTX:${R}"
    }
    $ctxPctStr   = Colour-Pct $ctxPct
    $line2 = "${D}${PIPE}${R} ${ctxWarnPrefix}${ctxLabel} $ctxBar ${ctxPctStr}${SEP}${C_GOLD}${burnRateStr}${R}"
    Write-Host $line2
} catch { Write-Host "${C_DIM}[line2 error]${C_RESET}" }

# ---------------------------------------------------------------------------
# LINE 3 — 5H: bar | % | ↻ relative | @absolute
# ---------------------------------------------------------------------------
try {
    $pct5HDisplay  = Colour-Pct $pct5H
    $absReset5HStr = "${L}@${abs5HReset}${R}"
    Write-Host "${D}${PIPE}${R} ${L}5H :${R} $bar5H $pct5HDisplay${SEP}${D}$([char]0x21BB)${R} $reset5Hfmt${SEP}${absReset5HStr}"
} catch { Write-Host "${C_DIM}[line3 error]${C_RESET}" }

# ---------------------------------------------------------------------------
# LINE 4 — WK: bar | % | ↻ relative | @absolute
# ---------------------------------------------------------------------------
try {
    $pctWKDisplay  = Colour-Pct $pctWK
    $absResetWKStr = "${L}@${absWKReset}${R}"
    Write-Host "${D}${PIPE}${R} ${L}WK :${R} $barWK $pctWKDisplay${SEP}${D}$([char]0x21BB)${R} $resetWKfmt${SEP}${absResetWKStr}"
} catch { Write-Host "${C_DIM}[line4 error]${C_RESET}" }

# ---------------------------------------------------------------------------
# LINE 5 — WORK: session duration | session diff | project diff | project duration
# ---------------------------------------------------------------------------
try {
    $diffStr     = "${C_ADD}+${linesAdded}${R}${D}/${R}${C_DEL}-${linesRemoved}${R}"
    $projAdded   = $projStats.TotalAdded
    $projRemoved = $projStats.TotalRemoved
    $projDiffStr = "${C_ADD}+${projAdded}${R}${D}/${R}${C_DEL}-${projRemoved}${R}"
    $line5 = "${D}${FLOOR}${R} ${L}WORK:${R} ${fmtSessionDur}${SEP}${diffStr}${SEP}${projDiffStr}${SEP}${fmtProjectDur}"
    Write-Host $line5
} catch { Write-Host "${C_DIM}[line5 error]${C_RESET}" }

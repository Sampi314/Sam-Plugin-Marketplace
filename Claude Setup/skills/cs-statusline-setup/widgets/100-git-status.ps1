# ----------------------------------------------------------------------------
# widgets/100-git-status.ps1 — git branch + porcelain status + last commit age
# ----------------------------------------------------------------------------

@{
    Name        = 'git-status'
    Line        = 5
    Position    = 'right'
    Priority    = 10
    RefreshEvery = 5
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $cwd = if ($ctx.workspace -and $ctx.workspace.current_dir) { $ctx.workspace.current_dir }
               elseif ($ctx.cwd) { $ctx.cwd } else { $null }
        if (-not $cwd -or -not (Test-Path $cwd)) { return '' }

        try {
            $gitCheck = & git --no-optional-locks -C $cwd rev-parse --is-inside-work-tree 2>&1
            if ($LASTEXITCODE -ne 0) { return '' }
        } catch { return '' }

        $branch = (& git --no-optional-locks -C $cwd rev-parse --abbrev-ref HEAD 2>&1) -join ''
        if (-not $branch -or $branch -match '^fatal') { $branch = '?' }

        $statusLines = @(& git --no-optional-locks -C $cwd status --porcelain 2>&1)
        $staged = 0; $modified = 0; $untracked = 0
        foreach ($line in $statusLines) {
            if (-not $line -or $line.Length -lt 2) { continue }
            $x = $line[0]; $y = $line[1]
            if ($line -match '^\?\?') { $untracked++; continue }
            if ($x -ne ' ' -and $x -ne '?') { $staged++ }
            if ($y -ne ' ' -and $y -ne '?') { $modified++ }
        }

        $lastCommitRaw = (& git --no-optional-locks -C $cwd log -1 --format='%ct' 2>&1) -join ''
        $commitAgo = ''
        if ($lastCommitRaw -match '^\d+$') {
            $diffSec = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - [long]$lastCommitRaw
            if ($diffSec -lt 60) { $commitAgo = "$($colors.C_GREEN)just now$($colors.C_RESET)" }
            elseif ($diffSec -lt 3600) { $commitAgo = "$($colors.C_LABEL)$([math]::Floor($diffSec/60))m ago$($colors.C_RESET)" }
            elseif ($diffSec -lt 86400) { $commitAgo = "$($colors.C_LABEL)$([math]::Floor($diffSec/3600))h ago$($colors.C_RESET)" }
            elseif ($diffSec -lt 2592000) { $commitAgo = "$($colors.C_LABEL)$([math]::Floor($diffSec/86400))d ago$($colors.C_RESET)" }
            else { $commitAgo = "$($colors.C_LABEL)$([math]::Floor($diffSec/2592000))mo ago$($colors.C_RESET)" }
        }

        $parts = @("$($colors.C_GREEN)$branch$($colors.C_RESET)")
        if ($staged -eq 0 -and $modified -eq 0 -and $untracked -eq 0) {
            $parts += "$($colors.C_GREEN)clean $([char]0x2713)$($colors.C_RESET)"
        } else {
            if ($staged -gt 0) { $parts += "$($colors.C_GREEN)+$staged$($colors.C_RESET)" }
            if ($modified -gt 0) { $parts += "$($colors.C_YELLOW)~$modified$($colors.C_RESET)" }
            if ($untracked -gt 0) { $parts += "$($colors.C_RED)?$untracked$($colors.C_RESET)" }
        }
        if ($commitAgo) { $parts += $commitAgo }

        return ($parts -join " $($colors.C_DIM)|$($colors.C_RESET) ")
    }
}

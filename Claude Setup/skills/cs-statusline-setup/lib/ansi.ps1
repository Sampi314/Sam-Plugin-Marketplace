# ============================================================================
# lib/ansi.ps1 — ANSI escape helpers (truecolor, OSC 8, BG pills, modifiers)
# ============================================================================
#
# Returns an object via New-AnsiContext that widgets receive as $ansi.
# All helpers are capability-aware: when $caps.* flags are false, helpers
# silently degrade to plain text instead of leaking escape codes.
#
# Usage in widgets:
#   $ansi.Fg(180,140,255) + 'Opus 4.7' + $ansi.Reset()
#   $ansi.Bold() + 'critical' + $ansi.Reset()
#   $ansi.Pill(255,220,80, 0,0,0, '$1.23')             # gold pill, black text
#   $ansi.Link('https://github.com/foo/bar', 'foo/bar')
# ============================================================================

$script:ESC = [char]0x1B

function New-AnsiContext {
    [CmdletBinding()]
    param(
        [hashtable]$Capabilities = @{ trueColor = $true; osc8Hyperlinks = $true }
    )

    $caps = $Capabilities

    $ctx = [pscustomobject]@{
        Caps = $caps
    }

    # --- Foreground colour (24-bit truecolor) -----------------------------
    $ctx | Add-Member -MemberType ScriptMethod -Name Fg -Value {
        param([int]$r,[int]$g,[int]$b)
        if (-not $this.Caps.trueColor) { return '' }
        return "$script:ESC[38;2;${r};${g};${b}m"
    }

    # --- Foreground at reduced brightness (dim variant) -------------------
    $ctx | Add-Member -MemberType ScriptMethod -Name FgDim -Value {
        param([int]$r,[int]$g,[int]$b)
        if (-not $this.Caps.trueColor) { return '' }
        $dr = [math]::Round($r * 0.4)
        $dg = [math]::Round($g * 0.4)
        $db = [math]::Round($b * 0.4)
        return "$script:ESC[38;2;${dr};${dg};${db}m"
    }

    # --- Background colour (24-bit truecolor) — used for pill backgrounds -
    $ctx | Add-Member -MemberType ScriptMethod -Name Bg -Value {
        param([int]$r,[int]$g,[int]$b)
        if (-not $this.Caps.trueColor) { return '' }
        return "$script:ESC[48;2;${r};${g};${b}m"
    }

    # --- "Pill" — coloured block with contrasting text on top -------------
    $ctx | Add-Member -MemberType ScriptMethod -Name Pill -Value {
        param(
            [int]$bgR,[int]$bgG,[int]$bgB,
            [int]$fgR,[int]$fgG,[int]$fgB,
            [string]$text
        )
        if (-not $this.Caps.trueColor) { return " $text " }
        $bg = "$script:ESC[48;2;${bgR};${bgG};${bgB}m"
        $fg = "$script:ESC[38;2;${fgR};${fgG};${fgB}m"
        return "${bg}${fg} $text $script:ESC[0m"
    }

    # --- SGR modifiers ----------------------------------------------------
    $ctx | Add-Member -MemberType ScriptMethod -Name Bold      -Value { return "$script:ESC[1m" }
    $ctx | Add-Member -MemberType ScriptMethod -Name Italic    -Value { return "$script:ESC[3m" }
    $ctx | Add-Member -MemberType ScriptMethod -Name Underline -Value { return "$script:ESC[4m" }
    $ctx | Add-Member -MemberType ScriptMethod -Name Reverse   -Value { return "$script:ESC[7m" }
    $ctx | Add-Member -MemberType ScriptMethod -Name Strike    -Value { return "$script:ESC[9m" }
    $ctx | Add-Member -MemberType ScriptMethod -Name Reset     -Value { return "$script:ESC[0m" }

    # --- OSC 8 hyperlinks (clickable text in capable terminals) -----------
    # Format: \e]8;;URL\a TEXT \e]8;;\a
    $ctx | Add-Member -MemberType ScriptMethod -Name Link -Value {
        param([string]$url, [string]$text)
        if (-not $this.Caps.osc8Hyperlinks) { return $text }
        if ([string]::IsNullOrWhiteSpace($url)) { return $text }
        return "$script:ESC]8;;${url}$([char]0x07)${text}$script:ESC]8;;$([char]0x07)"
    }

    # --- Strip ANSI codes (for width calculations in the layout engine) ---
    $ctx | Add-Member -MemberType ScriptMethod -Name Strip -Value {
        param([string]$s)
        if ([string]::IsNullOrEmpty($s)) { return '' }
        # Remove CSI sequences (colours, modifiers)
        $stripped = $s -replace "$script:ESC\[[0-9;]*[a-zA-Z]", ''
        # Remove OSC 8 hyperlink sequences (URL part and terminator)
        $stripped = $stripped -replace "$script:ESC\]8;;[^$([char]0x07)]*$([char]0x07)", ''
        return $stripped
    }

    # --- Visible width of a string after stripping ANSI -------------------
    # Accounts for double-wide CJK / emoji approximately (cheap heuristic)
    $ctx | Add-Member -MemberType ScriptMethod -Name Width -Value {
        param([string]$s)
        $stripped = $this.Strip($s)
        $width = 0
        foreach ($ch in $stripped.GetEnumerator()) {
            $code = [int][char]$ch
            # Surrogate halves + emoji + CJK roughly double-wide; treat as 2
            if ($code -ge 0x1100 -and (
                ($code -le 0x115F) -or                     # Hangul Jamo
                ($code -ge 0x2E80 -and $code -le 0x9FFF) -or   # CJK
                ($code -ge 0xAC00 -and $code -le 0xD7A3) -or   # Hangul syllables
                ($code -ge 0xF900 -and $code -le 0xFAFF) -or   # CJK compat
                ($code -ge 0xFE30 -and $code -le 0xFE4F) -or   # CJK compat forms
                ($code -ge 0xFF00 -and $code -le 0xFF60) -or   # Fullwidth
                ($code -ge 0x1F000 -and $code -le 0x1FFFF)     # Emoji blocks
            )) {
                $width += 2
            } else {
                $width += 1
            }
        }
        return $width
    }

    return $ctx
}

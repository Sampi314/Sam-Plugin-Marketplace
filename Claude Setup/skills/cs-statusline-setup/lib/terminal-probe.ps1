# ============================================================================
# lib/terminal-probe.ps1 — Detect terminal capabilities from env vars
# ============================================================================
#
# PowerShell can't interactively query the terminal during a statusline
# invocation (no stdin round-trip), but env vars leak everything we need.
# This module probes them once and writes ~/.claude/terminal-capabilities.json.
#
# Re-probe annually or via explicit ~/.claude/probe-terminal.ps1 invocation.
# ============================================================================

$script:CAPS_FILE = Join-Path $env:USERPROFILE '.claude\terminal-capabilities.json'
$script:CAPS_TTL_DAYS = 30

function Probe-TerminalCapabilities {
    [CmdletBinding()]
    param([switch]$Force)

    if (-not $Force -and (Test-Path $script:CAPS_FILE)) {
        $age = (Get-Date) - (Get-Item $script:CAPS_FILE).LastWriteTime
        if ($age.TotalDays -lt $script:CAPS_TTL_DAYS) {
            try { return Get-Content $script:CAPS_FILE -Raw | ConvertFrom-Json } catch {}
        }
    }

    $termProg = $env:TERM_PROGRAM
    $colorTerm = $env:COLORTERM
    $term      = $env:TERM
    $wtSession = $env:WT_SESSION
    $kittyId   = $env:KITTY_WINDOW_ID
    $konsole   = $env:KONSOLE_VERSION
    $vte       = $env:VTE_VERSION
    $tmux      = $env:TMUX
    $screen    = $env:STY
    $sshConn   = $env:SSH_CONNECTION
    $forceLink = $env:FORCE_HYPERLINK

    # Truecolor detection
    $trueColor = $false
    if ($colorTerm -match 'truecolor|24bit') { $trueColor = $true }
    elseif ($termProg -in @('iTerm.app','vscode','WezTerm','Hyper','Tabby')) { $trueColor = $true }
    elseif ($wtSession) { $trueColor = $true }
    elseif ($kittyId) { $trueColor = $true }
    elseif ($konsole) { $trueColor = $true }
    elseif ($term -match 'truecolor|direct|kitty') { $trueColor = $true }
    elseif ($term -match '256color') { $trueColor = $true }   # close enough

    # OSC 8 hyperlink detection — generally well-supported in modern terminals,
    # but tmux/screen and Terminal.app (Apple) strip the sequences.
    $osc8 = $false
    if ($forceLink) { $osc8 = $true }
    elseif ($termProg -eq 'Apple_Terminal') { $osc8 = $false }
    elseif ($tmux) { $osc8 = $false }
    elseif ($screen) { $osc8 = $false }
    elseif ($termProg -in @('iTerm.app','vscode','WezTerm','Hyper','Tabby','mintty')) { $osc8 = $true }
    elseif ($wtSession) { $osc8 = $true }
    elseif ($kittyId) { $osc8 = $true }
    elseif ($konsole) { $osc8 = $true }
    elseif ($vte) { $osc8 = $true }

    # Unicode block characters — basically always available in modern terminals
    $unicodeBlocks = $true

    # Braille characters — same; rare not to support
    $braille = $true

    # Sixel — limited support
    $sixel = $false
    if ($termProg -eq 'WezTerm') { $sixel = $true }
    elseif ($termProg -eq 'iTerm.app') { $sixel = $true }
    elseif ($termProg -eq 'mintty') { $sixel = $true }
    # Windows Terminal Preview has sixel; can't reliably detect version from here

    # Kitty graphics — only Kitty itself
    $kittyGraphics = [bool]$kittyId

    # iTerm2 inline images — only iTerm
    $iterm2Images = ($termProg -eq 'iTerm.app')

    # BurntToast / Windows toast notifications
    $windowsToast = $false
    try {
        if (Get-Module -ListAvailable -Name BurntToast -ErrorAction SilentlyContinue) {
            $windowsToast = $true
        }
    } catch {}

    # Audio — Console.Beep is usually available on Windows
    $audio = ($env:OS -eq 'Windows_NT')

    $caps = [pscustomobject]@{
        trueColor       = $trueColor
        osc8Hyperlinks  = $osc8
        unicodeBlocks   = $unicodeBlocks
        braille         = $braille
        sixel           = $sixel
        kittyGraphics   = $kittyGraphics
        iterm2Images    = $iterm2Images
        windowsToast    = $windowsToast
        audio           = $audio
        termProgram     = if ($termProg) { $termProg } elseif ($wtSession) { 'WindowsTerminal' } elseif ($kittyId) { 'Kitty' } else { 'Unknown' }
        insideTmux      = [bool]$tmux
        insideSsh       = [bool]$sshConn
        lastProbed      = (Get-Date).ToString('o')
    }

    try {
        $dir = Split-Path $script:CAPS_FILE -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $caps | ConvertTo-Json -Depth 5 | Set-Content -Path $script:CAPS_FILE -Encoding UTF8
    } catch { }

    return $caps
}

function Get-TerminalCapabilities {
    # Convenience: returns cached caps, probes if missing.
    if (Test-Path $script:CAPS_FILE) {
        try { return Get-Content $script:CAPS_FILE -Raw | ConvertFrom-Json } catch {}
    }
    return (Probe-TerminalCapabilities)
}

# ============================================================================
# ansi-to-html.ps1 — convert ANSI-escaped text emitted by the statusline to HTML
# ============================================================================
#
# Recognised escape sequences (the narrow set the statusline actually emits):
#   - Truecolor foreground   ESC [ 38 ; 2 ; R ; G ; B m
#   - Truecolor background   ESC [ 48 ; 2 ; R ; G ; B m
#   - Bold                   ESC [ 1 m
#   - Reset                  ESC [ 0 m   (and the empty ESC [ m form)
#   - Default fg / bg        ESC [ 39 m / ESC [ 49 m
#   - OSC 8 hyperlink        ESC ] 8 ; ; URL ESC \ TEXT ESC ] 8 ; ; ESC \
#
# Anything outside that set is silently dropped. Literal characters are
# HTML-escaped. Output is wrapped in <pre class="statusline">...</pre>.
#
# Dot-source this file then call:  ConvertFrom-AnsiToHtml -Text $ansiString
# ============================================================================

function ConvertFrom-AnsiToHtml {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text
    )

    $ESC = [char]0x1B
    $sb  = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<pre class="statusline">')

    # All mutable state lives in this single hashtable so helpers can mutate it
    # by reference without script-scope leakage between calls.
    $st = @{
        fg     = $null
        bg     = $null
        bold   = $false
        inSpan = $false
        inLink = $false
    }

    $htmlEscape = {
        param([string]$s)
        $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
    }

    $closeSpan = {
        if ($st.inSpan) {
            [void]$sb.Append('</span>')
            $st.inSpan = $false
        }
    }

    $openSpan = {
        if ($st.inSpan) { & $closeSpan }
        if (-not $st.fg -and -not $st.bg -and -not $st.bold) { return }
        $parts = @()
        if ($st.fg)   { $parts += "color:$($st.fg)" }
        if ($st.bg)   { $parts += "background:$($st.bg)" }
        if ($st.bold) { $parts += 'font-weight:bold' }
        [void]$sb.Append('<span style="' + ($parts -join ';') + '">')
        $st.inSpan = $true
    }

    $applySgr = {
        param([string]$params)
        if ([string]::IsNullOrEmpty($params) -or $params -eq '0') {
            $st.fg = $null; $st.bg = $null; $st.bold = $false
            & $closeSpan
            return
        }
        $codes = $params -split ';'
        $idx = 0
        while ($idx -lt $codes.Length) {
            $code = 0
            [void][int]::TryParse($codes[$idx], [ref]$code)
            switch ($code) {
                0  { $st.fg = $null; $st.bg = $null; $st.bold = $false; $idx++ }
                1  { $st.bold = $true; $idx++ }
                22 { $st.bold = $false; $idx++ }
                38 {
                    $sub = 0
                    if ($idx + 4 -lt $codes.Length -and [int]::TryParse($codes[$idx + 1], [ref]$sub) -and $sub -eq 2) {
                        $r = [int]$codes[$idx + 2]; $g = [int]$codes[$idx + 3]; $b = [int]$codes[$idx + 4]
                        $st.fg = ('#{0:x2}{1:x2}{2:x2}' -f $r, $g, $b)
                        $idx += 5
                    } else { $idx++ }
                }
                48 {
                    $sub = 0
                    if ($idx + 4 -lt $codes.Length -and [int]::TryParse($codes[$idx + 1], [ref]$sub) -and $sub -eq 2) {
                        $r = [int]$codes[$idx + 2]; $g = [int]$codes[$idx + 3]; $b = [int]$codes[$idx + 4]
                        $st.bg = ('#{0:x2}{1:x2}{2:x2}' -f $r, $g, $b)
                        $idx += 5
                    } else { $idx++ }
                }
                39 { $st.fg = $null; $idx++ }
                49 { $st.bg = $null; $idx++ }
                default { $idx++ }
            }
        }
        & $closeSpan
    }

    $i = 0
    $len = $Text.Length

    while ($i -lt $len) {
        $c = $Text[$i]

        if ($c -eq $ESC -and $i + 1 -lt $len) {
            $next = $Text[$i + 1]

            # CSI: ESC [ ... m
            if ($next -eq '[') {
                $j = $i + 2
                while ($j -lt $len -and $Text[$j] -ne 'm') { $j++ }
                if ($j -lt $len) {
                    & $applySgr ($Text.Substring($i + 2, $j - $i - 2))
                    $i = $j + 1
                    continue
                }
            }

            # OSC 8 hyperlink
            if ($next -eq ']') {
                $j = $i + 2
                while ($j -lt $len) {
                    if ($Text[$j] -eq $ESC -and $j + 1 -lt $len -and $Text[$j + 1] -eq '\') { break }
                    if ($Text[$j] -eq [char]0x07) { break }
                    $j++
                }
                if ($j -lt $len) {
                    $payload = $Text.Substring($i + 2, $j - $i - 2)
                    $skip = if ($Text[$j] -eq $ESC) { 2 } else { 1 }
                    if ($payload -match '^8;[^;]*;(.*)$') {
                        $url = $Matches[1]
                        if ($url) {
                            & $closeSpan
                            $st.inLink = $true
                            [void]$sb.Append('<a href="' + (& $htmlEscape $url) + '" target="_blank" rel="noopener">')
                        } else {
                            & $closeSpan
                            if ($st.inLink) {
                                [void]$sb.Append('</a>')
                                $st.inLink = $false
                            }
                        }
                    }
                    $i = $j + $skip
                    continue
                }
            }

            $i++
            continue
        }

        if (-not $st.inSpan -and ($st.fg -or $st.bg -or $st.bold)) {
            & $openSpan
        }
        if ($c -eq "`n") {
            & $closeSpan
            [void]$sb.Append("`n")
        } else {
            [void]$sb.Append((& $htmlEscape ([string]$c)))
        }
        $i++
    }

    & $closeSpan
    if ($st.inLink) { [void]$sb.Append('</a>') }
    [void]$sb.Append('</pre>')
    return $sb.ToString()
}

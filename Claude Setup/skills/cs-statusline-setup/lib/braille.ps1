# ============================================================================
# lib/braille.ps1 — Braille sparkline renderer (high-density mini-charts)
# ============================================================================
#
# Each Braille glyph U+2800..U+28FF encodes a 2-column × 4-row dot grid.
# A sparkline rendered as Braille is effectively 2× wider and 4× taller
# than a block-char sparkline of the same character width — you get a
# real line shape, not a bar approximation.
#
# Usage:
#   Render-BrailleSparkline -Values @(1,2,3,4,5,4,3,2) -Width 4
#   → ⢀⠔⢊⡢   (four Braille chars showing the sequence)
#
# Dot bit layout (Unicode Braille):
#   col-left | col-right
#   ---------+----------
#   dot 1    | dot 4       (top)
#   dot 2    | dot 5
#   dot 3    | dot 6
#   dot 7    | dot 8       (bottom)
# ============================================================================

# Bit values for each column from bottom-up.
# Index 0 = bottom dot, index 3 = top dot.
$script:LeftBits  = @(0x40, 0x04, 0x02, 0x01)   # dot 7, 3, 2, 1
$script:RightBits = @(0x80, 0x20, 0x10, 0x08)   # dot 8, 6, 5, 4

<#
.SYNOPSIS
Renders a numeric array as a single line of Braille sparkline characters.

.PARAMETER Values
The numeric series. Length should be >= 2; longer arrays get sub-sampled
or compressed to fit Width.

.PARAMETER Width
Number of Braille characters wide. Each char encodes 2 values, so
useful samples = 2 * Width.

.PARAMETER Min
Optional explicit minimum for the value range. If unspecified, uses
min(Values).

.PARAMETER Max
Optional explicit maximum. If unspecified, uses max(Values).

.OUTPUTS
A string of Width Braille glyphs.
#>
function Render-BrailleSparkline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][double[]]$Values,
        [Parameter(Mandatory)][int]$Width,
        [Nullable[double]]$Min = $null,
        [Nullable[double]]$Max = $null
    )

    if ($Width -lt 1) { return '' }
    if ($Values.Count -eq 0) { return ' ' * $Width }

    # Each Braille cell shows 2 columns; total columns we plot is 2 * Width.
    $totalCols = 2 * $Width

    # Resample Values to exactly $totalCols entries (linear nearest-neighbour).
    $samples = New-Object 'double[]' $totalCols
    if ($Values.Count -eq 1) {
        for ($i = 0; $i -lt $totalCols; $i++) { $samples[$i] = $Values[0] }
    } else {
        for ($i = 0; $i -lt $totalCols; $i++) {
            $srcIdx = [math]::Round(($i / [double]($totalCols - 1)) * ($Values.Count - 1))
            if ($srcIdx -lt 0) { $srcIdx = 0 }
            if ($srcIdx -ge $Values.Count) { $srcIdx = $Values.Count - 1 }
            $samples[$i] = $Values[$srcIdx]
        }
    }

    # Determine the value range.
    $lo = if ($Min -ne $null) { [double]$Min } else { ($Values | Measure-Object -Minimum).Minimum }
    $hi = if ($Max -ne $null) { [double]$Max } else { ($Values | Measure-Object -Maximum).Maximum }
    if ($hi -le $lo) { $hi = $lo + 1.0 }   # avoid divide-by-zero on flat lines

    # Map each sample to a row count (0..4 dots filled from the bottom).
    $heights = New-Object 'int[]' $totalCols
    for ($i = 0; $i -lt $totalCols; $i++) {
        $norm = ($samples[$i] - $lo) / ($hi - $lo)
        if ($norm -lt 0) { $norm = 0 }
        if ($norm -gt 1) { $norm = 1 }
        # 0..1 → 0..4 inclusive
        $heights[$i] = [int][math]::Round($norm * 4)
    }

    # Build the glyph string.
    $sb = New-Object System.Text.StringBuilder
    for ($w = 0; $w -lt $Width; $w++) {
        $leftH  = $heights[$w * 2]
        $rightH = $heights[$w * 2 + 1]
        $bits = 0
        for ($d = 0; $d -lt $leftH; $d++)  { $bits = $bits -bor $script:LeftBits[$d] }
        for ($d = 0; $d -lt $rightH; $d++) { $bits = $bits -bor $script:RightBits[$d] }
        $glyph = [char](0x2800 + $bits)
        [void]$sb.Append($glyph)
    }
    return $sb.ToString()
}

<#
.SYNOPSIS
Convenience wrapper: render a series and prefix with a coloured label.

.EXAMPLE
$line = Render-BrailleSparklineLabeled `
    -Label '$/min' -Values $costs -Width 12 `
    -LabelFg "$($a.Fg(255,220,80))" -BarFg "$($a.Fg(255,200,60))" `
    -Reset "$($a.Reset())"
#>
function Render-BrailleSparklineLabeled {
    [CmdletBinding()]
    param(
        [string]$Label,
        [double[]]$Values,
        [int]$Width = 12,
        [string]$LabelFg = '',
        [string]$BarFg = '',
        [string]$Reset = ''
    )
    $spark = Render-BrailleSparkline -Values $Values -Width $Width
    return "${LabelFg}${Label}${Reset} ${BarFg}${spark}${Reset}"
}

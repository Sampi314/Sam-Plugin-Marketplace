# ----------------------------------------------------------------------------
# widgets/160-spacer.ps1 - user-customisable text widget
# ----------------------------------------------------------------------------
#
# Renders the user's text with a chosen colour. Useful as:
#   - Section divider:    state.text = '|'  state.color = 'C_DIM'
#   - Motto / branding:   state.text = '<3 claude'  state.color = 'C_COST'
#   - Emoji separator:    state.text = '->'  state.color = 'C_CYAN'
#
# State knobs:
#   $state.text   string to render (default '|')
#   $state.color  palette role name like 'C_GOLD', or a hex colour '#aabbcc'
# ----------------------------------------------------------------------------

@{
    Name        = 'spacer'
    Line        = 1
    Position    = 'center'
    Priority    = 50
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        $text = if ($state -and $state.text)  { [string]$state.text }  else { '|' }
        if ([string]::IsNullOrEmpty($text)) { return '' }

        # Colour can be either a palette role name ('C_GOLD') or a hex value ('#aabbcc')
        $colourEsc = $colors.C_DIM
        if ($state -and $state.color) {
            $c = [string]$state.color
            if ($colors.ContainsKey($c)) {
                $colourEsc = $colors[$c]
            } elseif ($c -match '^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$') {
                $r = [Convert]::ToInt32($Matches[1], 16)
                $g = [Convert]::ToInt32($Matches[2], 16)
                $b = [Convert]::ToInt32($Matches[3], 16)
                $colourEsc = $ansi.Fg($r, $g, $b)
            }
        }

        return "$colourEsc$text$($colors.C_RESET)"
    }
}

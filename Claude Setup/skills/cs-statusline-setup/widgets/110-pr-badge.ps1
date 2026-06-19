# ----------------------------------------------------------------------------
# widgets/110-pr-badge.ps1 — open PR + review state (Bundle A)
# OSC 8 link to pr.url for click-to-open.
# ----------------------------------------------------------------------------

@{
    Name        = 'pr-badge'
    Line        = 5
    Position    = 'right'
    Priority    = 5
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)

        if (-not $ctx.pr -or -not $ctx.pr.number) { return '' }

        $num = $ctx.pr.number
        $review = $ctx.pr.review_state
        $url = $ctx.pr.url

        $reviewColor = $colors.C_DIM
        $reviewMark = ''
        switch ($review) {
            'approved'          { $reviewColor = $colors.C_GREEN;  $reviewMark = ' ' + [char]0x2713 }
            'pending'           { $reviewColor = $colors.C_YELLOW; $reviewMark = ' ' + [char]0x25CB }
            'changes_requested' { $reviewColor = $colors.C_RED;    $reviewMark = ' ' + [char]0x2717 }
            'draft'             { $reviewColor = $colors.C_DIM;    $reviewMark = ' draft' }
        }

        $text = "PR#$num$reviewMark"
        if ($url) { $text = $ansi.Link($url, $text) }

        return "$reviewColor$text$($colors.C_RESET)"
    }
}

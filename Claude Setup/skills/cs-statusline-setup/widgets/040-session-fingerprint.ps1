# ----------------------------------------------------------------------------
# widgets/040-session-fingerprint.ps1 — stable emoji from session_id hash
# Parallel sessions get visually distinct markers without manual naming.
# ----------------------------------------------------------------------------

@{
    Name        = 'session-fingerprint'
    Line        = 1
    Position    = 'left'
    Priority    = 5
    RefreshEvery = 0
    Capability  = @()
    State       = @{}
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)
        if (-not $ctx.session_id) { return '' }
        # Supplementary-plane code points need ConvertFromUtf32 — .NET char is 16-bit.
        $codepoints = @(
            0x1F98A, 0x1F419, 0x1F338, 0x1F680, 0x1F98B, 0x1F341, 0x1F347, 0x1F363,
            0x1F30A, 0x1F31E, 0x1F40C, 0x1F40D, 0x1F423, 0x1F43A, 0x1F436, 0x1F434,
            0x1F407, 0x1F413, 0x1F41D, 0x1F422, 0x1F427, 0x1F438, 0x1F43C, 0x1F981,
            0x1F984, 0x1F993, 0x1F995, 0x1F996
        )
        $hash = 0
        foreach ($c in $ctx.session_id.ToCharArray()) {
            $hash = ($hash * 31 + [int][char]$c) -band 0x7FFFFFFF
        }
        $idx = $hash % $codepoints.Count
        return [char]::ConvertFromUtf32($codepoints[$idx])
    }
}

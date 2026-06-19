---
name: cs-statusline-setup
description: >
  Install Sam's multi-line PowerShell statusline into the user's Claude Code setup. The statusline shows model + effort + session cost + project cost + version (line 1), context fill bar + burn rate (line 2), 5-hour usage bar with reset countdown (line 3), weekly usage bar with reset countdown (line 4), and work duration + lines added/removed (line 5). Bundles a frozen v3.1 baseline and offers an update command to fetch the latest from this marketplace. Customisable at install time — bar width, colour palette (six presets: Sam / Monochrome / HighContrast / Solarized / Nord / Dracula — see PALETTES.md on GitHub for visual swatches), and which lines to show (all / no5h / nowk / nowork / essentials). Windows-only — the script uses Windows Credential Manager via advapi32.dll P/Invoke and assumes %USERPROFILE% paths. Use this skill whenever the user wants to "install Sam's statusline", "set up the colourful statusline", "get the multi-line statusline", "install statusline-sparklines", "copy your statusline", "set up the usage bars in my statusline", "show 5H and weekly usage in the prompt", or any request to install, update, or customise the Claude Code statusline using Sam's PowerShell script.
---

# cs-statusline-setup — Install Sam's PowerShell Statusline

## Related — interactive customizer

If the user wants to **interactively pick widgets with live previews** instead of typing flags, point them at the sibling skill **`cs-customize-statusline`**. It walks them through every choice with terminal-rendered previews between questions, then runs the same install logic.

This skill (`cs-statusline-setup`) is the one-shot installer used directly when the user knows what they want. The customizer is the discoverable on-ramp for everyone else.

## Two variants

Since Phase 1 of the Extended platform, this skill ships **two distinct variants** of the statusline. Default install behaviour is unchanged from previous versions.

| Variant | What it is | Use when |
|---|---|---|
| **Classic** (default) | Original single-script statusline (~860 lines). Reliable, stable, well-tested. | You want the proven thing and don't need new features. |
| **Extended** | Widget-host platform: 8 lib files + 14 bundled widgets + plugin architecture. Adds built-in `rate_limits`, Braille sparklines, mode-aware layout, skill-aware overlays for the SumProduct stack, NDJSON events stream, terminal capability probing. | You want the new platform and are OK using freshly-shipped code. |

Pick one with `-Variant`:

```powershell
install.ps1 -Variant Classic    # default — original behaviour
install.ps1 -Variant Extended   # new widget-host platform
```

You can switch between variants by re-running the installer — each variant cleanly replaces the other in `settings.json`.

## What this skill installs

### Classic variant

Two artifacts are written:

1. **`%USERPROFILE%\.claude\statusline-sparklines.ps1`** — the PowerShell statusline script (~30 KB, 860 lines).
2. **A `statusLine` entry in `%USERPROFILE%\.claude\settings.json`** — wires the script to Claude Code's statusline hook. All other settings keys are preserved.

### Extended variant

Several artifacts written to `~/.claude/`:

1. **`statusline-extended.ps1`** — thin entry point that loads libs + widgets and prints the result.
2. **`lib/*.ps1`** — 8 shared library files (ANSI, Braille, OAuth fallback, terminal probe, sample log, events emitter, skill detector, widget host).
3. **`statusline-widgets/*.ps1`** — 14 bundled widgets. Users can drop their own `.ps1` widgets here to add to the statusline.
4. **`terminal-capabilities.json`** — written by the one-time probe; widgets gracefully degrade based on this.
5. **`statusline-samples.jsonl`** — append-only sample log feeding the sparklines.
6. **`events.ndjson`** — structured event stream (per tick + threshold crossings + activity changes). Format compatible with Grafana / Datadog / Honeycomb ingest.
7. **A `statusLine` entry in `settings.json`** with `refreshInterval: 30` so sparklines and burn-rate stay live during idle.

After install, Claude Code shows five lines below the prompt:

```
Opus 4.7 | high | Session: $1.23 | my-project: $45.67 | v2.1.0
├ CTX: ███████░░░ 42%  |  $2.10/hr
├ 5H : █████│██░░│░░░░│░░░░│░░░░  41%  |  ↻ 2d 03h 15m  |  @18:30
├ WK : ██│██│░░│░░│░░│░░│░░  17%  |  ↻ 5d 12h 04m  |  @09:00
└ WORK: 1h 23m  |  +245/-87  |  +12450/-3920  |  3d 4h 17m
```

## When to invoke this skill

Trigger phrases: "install Sam's statusline", "set up the multi-line statusline", "give me your statusline", "show usage bars in Claude Code", "install statusline-sparklines", "set up the cost / context / usage bars".

Also invoke when the user wants to **update** the installed statusline to the latest version, or **re-customise** an existing install (different palette, narrower bar, hide a line).

## Pre-flight checks

Before running anything, verify:

1. **Platform** — `$IsWindows` must be true, OR `$PSVersionTable.PSEdition` must be `'Desktop'`. The installer aborts on non-Windows; tell the user up front rather than letting them hit the error.
2. **Claude Code is installed** — check that `%USERPROFILE%\.claude\` exists (or can be created).
3. **Existing statusline** — if `%USERPROFILE%\.claude\statusline-sparklines.ps1` already exists, mention this and confirm before overwriting. The installer auto-backs up, but a heads-up is polite.
4. **Existing settings.json** — same logic; the installer preserves other keys but the user should know their file will be modified.

## Customisation choices to offer

Before running the installer, ask the user which presets they want (skip with sensible defaults if they say "just install it"):

### Bar width — `-BarWidth <int>`
Default: `30`. Narrow terminals (split panes, laptops) read better at `20` or `25`. Very wide terminals can go to `40`.

### Colour palette — `-Palette <Sam|Monochrome|HighContrast|Solarized|Nord|Dracula>`
Default: `Sam` (purple/gold/teal/orange — designed for dark terminals).
- `Monochrome` — greyscale only, for users who want minimal visual noise.
- `HighContrast` — saturated primaries, for bright terminals or colour-vision accessibility.
- `Solarized` — Ethan Schoonover's classic muted-warm 16-colour palette.
- `Nord` — Arctic-inspired cool pastels (nordtheme.com).
- `Dracula` — vivid saturated dark theme (draculatheme.com).

**Before suggesting a palette, point the user to the visual previews on GitHub:**
`https://github.com/Sampi314/Sam-Plugin-Marketplace/blob/main/Claude%20Setup/skills/cs-statusline-setup/PALETTES.md`

That page shows colour swatches for every role in every palette so the user can pick by eye rather than by guessing from a name. They can also browse `PALETTES.md` locally if they've cloned the marketplace.

### Lines to show — `-Lines <all|no5h|nowk|nowork|essentials>`
Default: `all`. Other options:
- `no5h` — hide the 5-hour usage line (line 3).
- `nowk` — hide the weekly usage line (line 4).
- `nowork` — hide the work duration + diff line (line 5).
- `essentials` — show only the header + CTX bar (lines 1 and 2).

Lines 1 (header) and 2 (CTX) cannot be hidden — they're the core read.

## How to run the installer

The installer lives at `scripts/install.ps1` inside this skill. Run it from PowerShell:

```powershell
$skill = "$env:USERPROFILE\.claude\plugins\claude-setup\skills\cs-statusline-setup"
# Or wherever the plugin is installed.

powershell -NoProfile -ExecutionPolicy Bypass -File "$skill\scripts\install.ps1" `
    -BarWidth 30 `
    -Palette Sam `
    -Lines all
```

Quote any user-supplied paths. The installer:
1. Verifies platform.
2. Loads the bundled `statusline-sparklines.ps1` as text.
3. Applies the bar-width, palette, and line-toggle customisations via regex substitution.
4. Backs up any existing `statusline-sparklines.ps1` and `settings.json` to `.bak.<timestamp>` files.
5. Writes the customised script to `%USERPROFILE%\.claude\statusline-sparklines.ps1`.
6. Patches `settings.json` to add the `statusLine` block, preserving every other key.

After it finishes, tell the user to restart Claude Code.

## How to run the updater

For users who installed previously and want the latest baseline:

```powershell
$skill = "$env:USERPROFILE\.claude\plugins\claude-setup\skills\cs-statusline-setup"
powershell -NoProfile -ExecutionPolicy Bypass -File "$skill\scripts\update.ps1"
```

`update.ps1` fetches the latest script from the marketplace's GitHub raw URL and overwrites the installed copy. **This wipes any customisations** — if the user customised at install time, warn them, then re-run `install.ps1` with the same flags after the update.

## Verifying the install

After the installer reports success, verify two things:

1. **Script exists and is non-empty:**
   ```powershell
   Test-Path "$env:USERPROFILE\.claude\statusline-sparklines.ps1"
   (Get-Item "$env:USERPROFILE\.claude\statusline-sparklines.ps1").Length
   ```
   Should be roughly 30 KB.

2. **`settings.json` has the statusLine block:**
   ```powershell
   (Get-Content "$env:USERPROFILE\.claude\settings.json" -Raw | ConvertFrom-Json).statusLine
   ```
   Should print `type`, `command`, and `padding` properties.

If both check out, tell the user: "Restart Claude Code to see the new statusline."

## Rollback

If anything goes wrong, the installer's backups make rollback one command:

```powershell
$stamp = "YYYYMMDD-HHMMSS"  # from the install timestamp
Copy-Item "$env:USERPROFILE\.claude\statusline-sparklines.ps1.bak.$stamp" `
          "$env:USERPROFILE\.claude\statusline-sparklines.ps1" -Force
Copy-Item "$env:USERPROFILE\.claude\settings.json.bak.$stamp" `
          "$env:USERPROFILE\.claude\settings.json" -Force
```

The installer prints the timestamp on completion — capture it in the message you send the user.

## Extended variant — widget pack & architecture

The Extended variant turns the statusline into a widget host. Each widget is a small PowerShell file in `~/.claude/statusline-widgets/` that returns a manifest hashtable describing what it renders and where. Users can write their own widgets without touching the host.

### Bundled widgets (Phase 1)

| File | What it shows |
|---|---|
| `010-core-header.ps1` | Model + effort + session $ + project (OSC 8 link to GitHub) + version |
| `020-thinking.ps1` | 🧠 indicator when `thinking.enabled` |
| `030-output-style.ps1` | Output style name when non-default |
| `040-session-fingerprint.ps1` | Stable emoji per session — distinguishes parallel sessions |
| `050-core-ctx.ps1` | CTX bar with exceeds-200k warning, shows context-window size |
| `060-core-rate-5h.ps1` | 5-hour rate-limit bar (built-in `rate_limits` or OAuth fallback) |
| `070-core-rate-wk.ps1` | Weekly rate-limit bar |
| `080-core-work.ps1` | Session duration + diff + active/idle ratio |
| `100-git-status.ps1` | Branch + porcelain status + last commit age |
| `110-pr-badge.ps1` | Open PR with colour-coded review state, OSC 8 link to PR |
| `200-sparkline-cost.ps1` | Braille sparkline of $/min history |
| `210-sparkline-ctx.ps1` | Braille sparkline of context % history |
| `300-mode-aware.ps1` | Layout switcher — emergency / agent / compact / learning / default |
| `400-skill-audit-general.ps1` | Audit progress overlay when audit-general is active |
| `410-skill-financial-modelling.ps1` | FM phase indicator when financial-modelling is active |
| `420-skill-writing-tools.ps1` | Writing progress overlay when writing-tools is active |

### Writing your own widget

Drop a `.ps1` file in `~/.claude/statusline-widgets/`. The file's last expression must be a manifest hashtable:

```powershell
@{
    Name        = 'my-widget'
    Line        = 1                # which statusline row (1-based)
    Position    = 'right'          # 'left' | 'right' | 'full'
    Priority    = 50               # lower = earlier within the (Line,Position) slot
    RefreshEvery = 30              # cache for N seconds; 0 = render every tick
    Capability  = @()              # required terminal caps ('braille','osc8Hyperlinks','sixel',etc.)
    Render      = {
        param($ctx, $caps, $colors, $ansi, $state)
        # $ctx     — full statusline JSON
        # $caps    — terminal-capabilities.json
        # $colors  — palette hashtable (C_MODEL, C_COST, etc.)
        # $ansi    — ANSI helper (Fg, Bold, Pill, Link, ...)
        # $state   — mutable per-widget state across ticks
        return "$($colors.C_GOLD)hello$($colors.C_RESET)"
    }
}
```

The host catches exceptions from individual widgets (logged to `~/.claude/statusline-widget-errors.log`) so a broken widget never crashes the statusline.

### Skill-aware overlays — sidecar protocol

The widgets at `4XX-skill-*.ps1` read sidecar JSON files at `~/.claude/skill-state/<plugin>.json`. To make a SumProduct skill light up its overlay, it should write its state file when active:

```powershell
# Inside audit-general
@{
    active_auditor = 'logic'
    completed      = @('sentry','stylist')
    total          = 12
} | ConvertTo-Json | Set-Content "$env:USERPROFILE\.claude\skill-state\audit-general.json"
```

The widget treats sidecars older than 5 minutes as stale and skips rendering. Phase 1 ships the READ side only — the SumProduct skills don't yet write these sidecars. Test the overlay manually by writing a sample state file.

### Events stream

Every statusline tick writes one JSON line to `~/.claude/events.ndjson`. Threshold crossings (5h ≥ 50/75/90/95%, weekly same bands, ctx same bands) emit additional one-shot events. Format:

```json
{"ts":"2026-06-19T08:30:14.123Z","type":"tick","session_id":"abc","ctx_pct":42,"cost_per_min":0.05}
{"ts":"2026-06-19T08:35:01.999Z","type":"threshold_5h_90","value":91.4}
```

This is forward-compatible with Phase 2's web companion app, Phase 3's multi-machine sync, and external observability ingest.

### Roadmap (Phase 2+)

- **Phase 2** — Web companion app (richer dashboard at localhost, mobile-friendly)
- **Phase 3** — Multi-machine sync (project totals across machines) + IPC mesh
- **Phase 4** — Subagent statusline + MCP-fed integrations + BurntToast notifier widget + Pomodoro overlay

## Adding a new palette

Six palettes ship by default. To add a seventh:

1. Open `scripts/install.ps1`.
2. Find the `$palettes` hashtable (around line 70).
3. Add a new sub-table with all 10 colour-role keys (`C_MODEL` through `C_GOLD`). Each value is a single-quoted `'R G B'` triplet.
4. Add the new palette name to the `[ValidateSet(...)]` attribute on the `-Palette` parameter near the top of the file.
5. Append a section to `PALETTES.md` with hex codes and swatch URLs so users can preview it on GitHub.
6. Bump `version` in `Claude Setup/.claude-plugin/plugin.json`.
7. Commit and push.

## What this skill does NOT do

- Does not install the statusline on macOS or Linux — the underlying script is Windows-only.
- Does not modify any settings.json key other than `statusLine`.
- Does not install or modify Claude Code itself.
- Does not register hooks, MCP servers, or plugins.
- Does not read your transcripts, project costs, or OAuth tokens — only the installed *script* does that, at runtime, after install.

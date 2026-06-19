---
name: cs-customize-statusline
description: >
  Interactive wizard that customises Sam's Claude Code statusline with live, in-terminal previews. The user picks a variant (Classic single-script or Extended widget platform), a colour palette (Sam, Monochrome, HighContrast, Solarized, Nord, Dracula), which widgets to show (header, CTX bar, 5-hour rate-limit bar, weekly bar, work duration, Braille sparklines, git status, PR badge, skill overlays, etc.), and optionally a bar width — and at every step Claude renders the actual coloured statusline output by piping mock data through the bundled script so the user SEES the result before applying. Final confirmation copies only the chosen widgets to ~/.claude/, patches settings.json, and tells the user to restart Claude Code. Windows-only — relies on the same PowerShell statusline as cs-statusline-setup. Use this skill whenever the user wants to "customize my statusline", "change the statusline colours", "pick which widgets to show", "configure the statusline interactively", "preview the statusline before applying", "make a custom statusline", "build my own statusline", "redesign the statusline", or any request to tailor the Claude Code statusline visually with live preview. Sits alongside cs-statusline-setup (one-shot installer) — this one is the interactive customisation layer over the same underlying script.
---

# cs-customize-statusline — Interactive Statusline Wizard

## Role

Conversational wizard that walks the user through statusline customisation with **live, in-terminal previews** between every decision. The user sees the actual coloured output of their choices before they commit.

Pipeline position:
- **`cs-statusline-setup`** — installer for the underlying statusline script
- **`cs-customize-statusline` — this skill** — interactive customiser on top of that script

## When to invoke

Trigger phrases: "customize my statusline", "change the colours", "configure statusline interactively", "preview statusline", "redesign statusline", "pick which widgets to show", "make a custom statusline".

Also invoke when the user has installed `cs-statusline-setup` and wants to switch palette, toggle widgets, or change variant without typing flags into PowerShell.

## How this skill works

Three components in this skill folder:

1. **`mock-data.json`** — synthetic statusline JSON exercising rate_limits, PR badge, thinking indicator, context_window size, repo info, session_name, costs, durations
2. **`scripts/preview.ps1`** — runs the bundled `statusline-extended.ps1` (or Classic) inside a temp sandbox with only the user's chosen widgets, pipes `mock-data.json` to it, prints the coloured output to the user's terminal between two banner lines
3. **`scripts/apply.ps1`** — when the user confirms, copies the chosen widgets + lib + entry script to `~/.claude/` and patches `settings.json`

## Wizard playbook — execute these steps in order

### Step 0 — Confirm prerequisites

Before starting, verify:

1. The user is on Windows (the statusline is Windows-only)
2. `Claude Setup/skills/cs-statusline-setup/statusline-extended.ps1` exists (the bundled platform). If missing, tell the user to install `cs-statusline-setup` first.

### Step 1 — Pick a variant

Use AskUserQuestion with these options:

- **Classic** — original single-script statusline. Stable, well-tested. Customisable via palette + bar width + which lines to show.
- **Extended (Recommended)** — widget platform. Pick exactly which widgets to render. Includes Braille sparklines, mode-aware layout, skill-aware overlays for SumProduct stack.

Use the AskUserQuestion `preview` field on each option to show a small ASCII mockup of what each variant looks like.

### Step 2 — Pick a palette

Use AskUserQuestion with the six palette options. For each, the `preview` field should show 3–4 lines of ASCII mockup using approximate ANSI colours so the user can visually compare. Reference: see `PALETTES.md` in `cs-statusline-setup/` for the canonical hex codes.

### Step 3 — Render a baseline preview

Before asking about widgets, render the user's choice so far with the FULL widget set so they can see what "everything on" looks like. Run:

```powershell
& "<path-to-this-skill>/scripts/preview.ps1" -Variant Extended -Palette <chosen>
```

The output goes straight to the user's terminal — they see the actual coloured statusline.

Tell them: "Here's the full statusline with every widget on. Next we'll pick which to keep."

### Step 4 — Pick widgets (Extended only)

For Extended variant, use AskUserQuestion with `multiSelect: true` to let them toggle widgets. Group the questions sensibly — don't ask 14 boolean questions; instead group:

**Question 4a — Core info widgets:**
- core-header — model, effort, cost, project, version (almost always wanted)
- core-ctx — context window bar
- core-work — duration + lines added/removed + active%

**Question 4b — Rate-limit bars:**
- core-rate-5h — 5-hour Anthropic rate limit
- core-rate-wk — weekly Anthropic rate limit

**Question 4c — Sparklines & signals:**
- sparkline-cost — Braille mini-chart of $/min over time
- sparkline-ctx — Braille mini-chart of context %
- thinking — 🧠 when extended thinking is on
- output-style — shows current output style when non-default
- session-fingerprint — emoji that uniquely identifies this session

**Question 4d — Git & PRs:**
- git-status — branch + porcelain status
- pr-badge — open PR with colour-coded review state

**Question 4e — Skill overlays (SumProduct-specific):**
- skill-audit-general — audit progress
- skill-financial-modelling — fm phase indicator
- skill-writing-tools — writing progress

For each question, AFTER the user answers, re-render the preview with the accumulated allowlist so they see the result update.

### Step 5 — Final preview + confirmation

Render one last preview with the final widget set and palette. Then ask:

- **Apply** — runs `scripts/apply.ps1` with the chosen flags
- **Restart wizard** — start over from Step 1
- **Cancel** — exit without changes

If Apply: run apply.ps1 with the accumulated flags, then tell the user to restart Claude Code.

## How to render a preview during the conversation

Use the Bash or PowerShell tool to invoke:

```powershell
& "<absolute-path-to-this-skill>/scripts/preview.ps1" `
    -Variant <Classic|Extended> `
    -Widgets "<comma-separated-widget-names>" `
    [-Palette <palette>]
```

The tool result will contain ANSI escape sequences in the output. **Claude Code's terminal renders these as colour** — so when you echo or display the preview output, the user sees the actual coloured statusline.

Important: the preview is rendered ONCE per question, after the user picks. Do not preview before they've made any choices (the default would just be the baseline, which is already shown in Step 3).

## How to render a preview INSIDE an AskUserQuestion preview field

AskUserQuestion's `preview` field renders markdown. For palette and variant questions, hand-craft ASCII previews using emoji and simple markdown — do NOT try to embed ANSI escapes into the preview field (it won't render the colours, it'll show the literal `\033[...]` codes).

Example palette preview field for Nord:
```
┌─ Nord palette preview ──────────────┐
│ 🐺 [preview] Opus 4.7 │ Session …  │
│ CTX: ████████░░ 42% │ ~$0.05/min   │
│ 5H:  ████│██  41% ↻ 1d 14h        │
│ WORK: 1h 23m │ +245/-87            │
│ → Cool Arctic pastels, low-sat     │
└─────────────────────────────────────┘
```

For actual coloured previews (the most impressive part), use Step 3/4's preview.ps1 invocation — the colours render in the user's real terminal.

## Apply flow

When the user confirms, run:

```powershell
& "<absolute-path-to-this-skill>/scripts/apply.ps1" `
    -Variant <Classic|Extended> `
    -Widgets "<comma-separated>" `
    [-Palette <palette>] [-BarWidth N] [-Lines <opt>]
```

Show the output of apply.ps1 to the user. Then say:
- "Restart Claude Code to see your customised statusline."
- "If anything looks off, your previous configuration is backed up to ~/.claude/*.bak.<timestamp> — copy any of those back to restore."

## What this skill does NOT do

- Does not modify the underlying statusline script — only chooses which pre-built widgets to install
- Does not work on macOS/Linux (statusline is Windows-only)
- Does not install plugins, hooks, or MCP servers
- Does not create new widgets — for that, the user writes a `.ps1` file in `~/.claude/statusline-widgets/` following the manifest contract documented in cs-statusline-setup's SKILL.md
- Does not preview Classic-variant palette changes (the regex-substitution approach can't be sandboxed for preview easily — palette previews in Classic require trial install)

## Rollback

Every apply backs up the previous `~/.claude/statusline-extended.ps1`, `lib/`, `statusline-widgets/`, and `settings.json` with timestamps. To roll back, copy the most recent `.bak.<timestamp>` versions back. The customizer should tell the user this timestamp on success.

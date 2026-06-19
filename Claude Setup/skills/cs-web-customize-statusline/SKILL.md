---
name: cs-web-customize-statusline
description: >
  Browser-based visual editor for Sam's Claude Code statusline. Spins up a loopback HTTP server, opens the default browser, and presents a click-to-edit UI where the user toggles widgets, picks a colour palette (Sam, Monochrome, HighContrast, Solarized, Nord, Dracula), adjusts bar width, and chooses which lines to show — with a live preview that re-renders on every change by piping mock data through the actual PowerShell statusline and converting its ANSI output to HTML. Apply writes the chosen widgets + lib to ~/.claude/, patches settings.json, and shuts the server down; prior configs are backed up with timestamps. Use this skill whenever the user wants a visual or web-based statusline customizer — phrases like "open the statusline editor", "web UI for the statusline", "browser editor for the statusline", "GUI to pick widgets", "click-to-customize statusline" — or whenever the user has rejected a Q&A wizard. Windows-only.
---

# cs-web-customize-statusline — Local Web UI Customizer

## Role

A real visual editor for the statusline — opens in the user's default browser, shows a live preview that re-renders on every toggle, and writes the result to `~/.claude/` when they hit Apply. Designed for users who don't want a Q&A wizard.

Pipeline position:
- `cs-statusline-setup` — installer for the underlying statusline script
- `cs-customize-statusline` — Q&A wizard with terminal ANSI previews (older)
- `cs-web-customize-statusline` — **this skill** — browser-based visual editor (preferred when the user wants click-to-edit rather than question-by-question)

## When to invoke

Trigger phrases: "open the statusline editor", "launch the web customizer", "web UI for the statusline", "browser editor for the statusline", "GUI to pick widgets", "click-to-customize statusline", "visual statusline editor", "drag-and-pick statusline".

Also invoke when the user asked for `/cs-customize-statusline` but rejected the Q&A flow in favour of "a real UI".

## What ships

```
cs-web-customize-statusline/
├── SKILL.md                     # this file
├── scripts/
│   ├── start.ps1                # entry point — pick port, spawn server, open browser
│   ├── server.ps1               # HttpListener loop with routing + sandbox preview + apply
│   └── ansi-to-html.ps1         # parse statusline ANSI → HTML <span> with inline colours
└── www/
    ├── index.html               # SPA shell
    ├── styles.css               # dark terminal-adjacent styling
    └── app.js                   # state + fetch + render
```

## How to invoke

```powershell
$skill = "$env:USERPROFILE\.claude\plugins\cache\sam\claude-setup\1.0.0\skills\cs-web-customize-statusline"
powershell -NoProfile -ExecutionPolicy Bypass -File "$skill\scripts\start.ps1"
```

`start.ps1` picks a free loopback port, prints the URL, opens the default browser, and blocks until the SPA hits `/api/shutdown` (via Apply or Cancel).

Useful flags:
- `-Port N` — pin a specific port instead of letting the OS pick.
- `-NoBrowser` — don't auto-open the browser (use when smoke-testing from CLI).

## Pre-flight checks

Before running anything, verify:

1. **Platform** — `$IsWindows` true (PowerShell HttpListener works on macOS/Linux but the bundled statusline script does not).
2. **Sibling skills present** — both `cs-statusline-setup` and `cs-customize-statusline` must live next to this skill so `start.ps1` can find `statusline-extended.ps1`, the widget pack, and `mock-data.json`.
3. **Port available** — the script picks one at runtime; manual `-Port` overrides this.

## How the live preview works

1. SPA POSTs `{variant, widgets[], palette, barWidth, lines}` to `/api/preview`.
2. Server builds a tempdir sandbox containing `statusline-extended.ps1`, the lib, and ONLY the selected widgets.
3. Server pipes `mock-data.json` to the sandboxed statusline.
4. Captured stdout is parsed by `ansi-to-html.ps1` — truecolor fg/bg, bold, and OSC 8 hyperlinks become `<span style="color:#..."` / `<a href="...">`.
5. HTML lands in `#preview-area` and replaces whatever was there.

Classic variant doesn't get a live preview yet (regex-rewriting the monolithic script is hard to sandbox); Apply still works for Classic — it delegates to `cs-statusline-setup/install.ps1`.

## Apply flow

The Apply button calls `cs-customize-statusline/scripts/apply.ps1` with the chosen flags. That script:

- Backs up `~/.claude/statusline-extended.ps1`, `lib/`, `statusline-widgets/`, and `settings.json` with a timestamp.
- Copies the chosen widgets + lib + entry script into `~/.claude/`.
- Runs the terminal-capability probe.
- Patches `settings.json` to point `statusLine.command` at the new script with `refreshInterval: 30`.

On success, the SPA waits 1.5s then hits `/api/shutdown` so the server exits cleanly.

## Security model

- HttpListener binds `http://127.0.0.1:PORT/` — loopback only. Not reachable from another machine.
- No auth token — anyone with shell access on this machine could hit the endpoints, but they already have shell access, so the threat model is the same as a local script.
- `/api/apply` runs the existing `apply.ps1` which writes only to `~/.claude/`.
- `/api/preview` writes to a tempdir under `$env:TEMP` and deletes it on exit.

## What this skill does NOT do

- Does not work on macOS/Linux.
- Does not modify the bundled statusline script or widget code — only chooses which widgets get installed.
- Does not stream live data — the preview is always rendered against the same `mock-data.json` scenario.
- Does not yet preview Classic-variant changes (Apply works, preview doesn't).
- Does not let the user write new widgets — for that, drop a `.ps1` widget file into `~/.claude/statusline-widgets/` per the manifest contract in `cs-statusline-setup/SKILL.md`.

## Rollback

Every apply backs up the prior `~/.claude/statusline-extended.ps1`, `lib/`, `statusline-widgets/`, and `settings.json` with timestamps. Copy the most recent `.bak.<timestamp>` versions back to restore.

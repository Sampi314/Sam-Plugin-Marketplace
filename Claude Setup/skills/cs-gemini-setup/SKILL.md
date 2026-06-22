---
name: cs-gemini-setup
description: >
  Set up the Google Gemini API on Sam's Windows machine so scripts that depend on `GEMINI_API_KEY` (e.g. the daily AI blog's image generator at `wt-ai-write/references/generate_image_gemini.py`) work first time. Walks the user through three [3] steps: obtain an API key from Google AI Studio, persist it as a User-scope environment variable, and verify it with a small text call plus a small image call against the v1 stable endpoint. Captures the v1-vs-v1beta image-gen gotcha (v1beta has free-tier `limit: 0` for image generation) so the key is tested on the same endpoint the scripts actually use. Bundles a standalone verifier and a troubleshooter for 401 / 403 / 429 errors. Windows-only. Does NOT manage billing — points the user at the AI Studio billing page when a 429 indicates credits are depleted. Trigger on "set up Gemini", "install Gemini API key", "configure GEMINI_API_KEY", "verify my Gemini key", "Gemini 429", "Gemini credits depleted", "test Gemini image generation", "Gemini SDK limit 0", or any request to wire Gemini into the local environment.
---

# cs-gemini-setup — Set up the Gemini API Key on Windows

## When to invoke this skill

- The user wants to install or update `GEMINI_API_KEY` so a local script (the AI-blog image generator, an MCP server, a sandbox project) can call Gemini.
- A Gemini-backed script just failed with HTTP 401 / 403 / 429 and the user wants a diagnosis.
- The user asks to verify the key works for **image generation** specifically — image gen has a separate path from text and trips on the v1-vs-v1beta gotcha.

For the v1-vs-v1beta back-story see [[feedback_gemini_image_endpoint]] in user memory; the verifier and troubleshooter here both hit the `/v1/` stable endpoint deliberately.

## The three [3] scripts

| Script | What it does | When to run |
|---|---|---|
| `scripts/setup.ps1` | Prompts for the key (input hidden), validates the `AIza…` shape, writes it to the User scope so it persists across shells, exports it into the current session, then calls `verify.ps1`. | First-time install or rotating the key. |
| `scripts/verify.ps1` | Reads `$env:GEMINI_API_KEY`, calls a tiny text completion, then a tiny image generation, both against `/v1/`. Reports `text OK / image OK` or the specific failure. | Anytime — quick health check. |
| `scripts/troubleshoot.ps1` | Re-runs the same calls but inspects the HTTP status and surfaces a tailored fix for 401 (bad key), 403 (region / project access), 429 (quota or billing). | After a script using Gemini has failed and the user wants to know which lever to pull. |

All three [3] scripts are self-contained PowerShell — no `google-genai` SDK, no Python — and use `Invoke-WebRequest` against the v1 endpoint directly so the test path matches what `generate_image_gemini.py` actually hits.

## How to run each script

```powershell
$skill = "$env:USERPROFILE\.claude\plugins\cache\sam\claude-setup\<version>\skills\cs-gemini-setup"

powershell -NoProfile -ExecutionPolicy Bypass -File "$skill\scripts\setup.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$skill\scripts\verify.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "$skill\scripts\troubleshoot.ps1"
```

`<version>` matches the currently-installed `claude-setup` plugin version (e.g. `1.10.0`). The skill is also resolvable through the marketplace path at `$env:USERPROFILE\.claude\plugins\marketplaces\sam\Claude Setup\skills\cs-gemini-setup\` when developing locally.

## What setup.ps1 will ask the user to do (out-of-band)

The skill does **not** open a browser or scrape AI Studio. It tells the user to:

1. Open `https://aistudio.google.com/apikey` in their browser.
2. Sign in with the Google account that owns the project they want to bill against.
3. Click **Create API key** and copy the generated value (a string starting `AIza…`).
4. Paste it into the PowerShell prompt — the input is hidden via `Read-Host -AsSecureString`.

The script writes the key with `[Environment]::SetEnvironmentVariable('GEMINI_API_KEY', $key, 'User')` so it persists, and also assigns `$env:GEMINI_API_KEY` so the current shell sees it without a restart.

## What this skill does NOT do

- Does not set up billing. If `verify.ps1` reports a 429 with "prepayment credits depleted", the troubleshooter prints the AI Studio billing URL (`https://aistudio.google.com/`) and the link to enable billing on the underlying Cloud project. Topping up is a manual web step.
- Does not install Python, the `google-genai` SDK, or any other client library — these scripts only need PowerShell 5.1+ and `Invoke-WebRequest`.
- Does not manage non-Gemini Google APIs (Drive, Calendar, Vertex AI). Scope is the Gemini API surface served from `generativelanguage.googleapis.com`.
- Does not run on macOS or Linux — the User-scope env var path uses `[Environment]::SetEnvironmentVariable(...,'User')`, which only writes the Windows User registry hive.

## Pre-flight checks

Before running `setup.ps1`, verify in one [1] PowerShell call:

```powershell
if (-not $IsWindows -and $PSVersionTable.PSEdition -ne 'Desktop') {
    Write-Error 'cs-gemini-setup is Windows-only.'
}
```

Mention to the user up front rather than letting the script die on the first SetEnvironmentVariable call.

## Verifying the install

After `setup.ps1` finishes, three [3] things should hold:

1. `$env:GEMINI_API_KEY` is set in the current session — `if ($env:GEMINI_API_KEY) { 'set' } else { 'missing' }`.
2. The User-scope env var persists — open a fresh PowerShell window and check `$env:GEMINI_API_KEY` again.
3. `verify.ps1` reports `text OK` and `image OK`. If `image` reports 429, see the troubleshooter.

## Related skills

- `wt-ai-write` consumes `GEMINI_API_KEY` via `references/generate_image_gemini.py`. After running this skill successfully, that script's image generations should land first try.
- `cs-statusline-setup` is the sibling installer for the Windows PowerShell statusline. The two are independent — installing one does not install the other.

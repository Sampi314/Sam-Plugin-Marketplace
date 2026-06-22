---
name: wt-screenshot-frames
description: >
  Batch-capture the screenshots called for by image placeholder blocks across a folder of blog markdown files. Built for series like "The Analyst's Guide to GitHub" (the 61-part series in `From Claude v3/`) where every post embeds blockquote placeholders naming a subject, a URL to capture, and the target filename. The skill provides three [3] scripts: a parser that turns the placeholders into a structured manifest, a checklist generator that produces a markdown to-do list grouped by part, and an interactive Playwright runner that opens each SCREENSHOT URL in Microsoft Edge, pauses for the user to set zoom, scroll, log in or otherwise prepare the page, and saves the captured PNG into the right per-part folder with the right filename. Skips GEMINI / MATPLOTLIB / MERMAID / PHOTO placeholders (handled by other tooling). Windows-first. Trigger on "screenshot all the placeholders", "batch capture the blog images", "run the screenshot helper", "automate screenshots for the GitHub series", or any request to generate screenshots in bulk for a blog series with placeholder blocks.
---

# wt-screenshot-frames — Batch Capture Screenshots from Placeholder Blocks

## When to invoke this skill

- The user has a folder of blog markdown files (typically the `From Claude v3/` GitHub series) containing **placeholder blocks** of the form:

  ```markdown
  > **[IMAGE 1 — SCREENSHOT]**
  > 
  > **Subject:** ...
  > **Capture / Generate:** open https://github.com/... in Edge at 125% zoom ...
  > **Save as:** `filename.png`
  ```

- The user wants to capture the SCREENSHOT-type placeholders in batch rather than one at a time.
- The user wants a checklist of every image still to be captured across the series.

The placeholder grammar is documented in [`references/placeholder-grammar.md`](references/placeholder-grammar.md).

## The three [3] scripts

| Script | What it does | When to run |
|---|---|---|
| `scripts/parse_placeholders.py` | Scans a folder of markdown files, extracts every placeholder block, and writes a JSON manifest with file path, image number, type, subject, instructions, URL (if found), and target save path. | Once after each writing pass. Regenerate when the markdown changes. |
| `scripts/generate_checklist.py` | Reads the manifest and writes `screenshots-checklist.md` — a per-part markdown checklist with tick boxes for every SCREENSHOT placeholder. Useful for tracking progress manually. | Anytime. |
| `scripts/screenshot_runner.py` | Interactive Playwright runner. Opens Microsoft Edge against each SCREENSHOT URL, sets zoom, pauses for the user to adjust scroll/login/crop, captures on Enter, saves with the named filename to the target part folder. | When the user is ready to actually capture. |

## How to run each script

From the series root folder (e.g. `From Claude v3/`):

```bash
# 1. Parse placeholders into a manifest
python "$env:USERPROFILE\.claude\plugins\cache\sam\writing-tools\<version>\skills\wt-screenshot-frames\scripts\parse_placeholders.py" --root .

# 2. Generate the checklist
python "$env:USERPROFILE\.claude\plugins\cache\sam\writing-tools\<version>\skills\wt-screenshot-frames\scripts\generate_checklist.py"

# 3. Run the interactive screenshot session
python "$env:USERPROFILE\.claude\plugins\cache\sam\writing-tools\<version>\skills\wt-screenshot-frames\scripts\screenshot_runner.py"
```

`<version>` matches the currently-installed writing-tools plugin version (e.g. `1.2.0`).

The skill resolves at the marketplace path as well, at `$env:USERPROFILE\.claude\plugins\marketplaces\sam\Writing Tools\skills\wt-screenshot-frames\`.

## Prerequisites

- **Python 3.10+** with `pip install playwright` and `playwright install msedge` (one-time setup).
- **Microsoft Edge** installed (Windows default).
- **A GitHub login session in Edge** if any placeholders ask for an authenticated view.

The runner uses Edge in **non-headless** mode so the user can sign in interactively the first time and reuse the browser profile thereafter.

## What this skill does NOT do

- Does not generate Gemini, matplotlib, mermaid or photo images. See `wt-ai-write/references/generate_image_gemini.py` and the per-post Mermaid / matplotlib helpers for those.
- Does not edit the markdown after capture. The user still replaces each placeholder block with `![alt](filename.png)` manually (or via the standard `markdown_to_docx.py` re-conversion).
- Does not crop, annotate or post-process the screenshot. The user controls scroll position, zoom and crop within Edge before pressing Enter.
- Does not work on macOS / Linux without changes (Edge channel availability differs).

## Related skills

- `wt-ai-write` writes the blog posts that contain the placeholders.
- `wt-ai-plan` decides which images each post should include.
- `wt-writing-auditor` reviews the prose around them.

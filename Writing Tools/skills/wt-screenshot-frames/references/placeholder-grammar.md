# Placeholder Block Grammar

Every image position in the blog markdown is marked with a placeholder block.
This file documents the exact syntax the parser expects.

## Block shape

A placeholder is a single markdown blockquote (every line starts with `> `).
The first non-empty line is the header. The remaining lines hold the metadata.

```markdown
> **[IMAGE N — TYPE]**
> 
> **Subject:** one [1] line describing what the image shows
> **Capture / Generate:** how to obtain it (may contain a URL for SCREENSHOT)
> **Save as:** `target-filename.png`
> 
> _Once obtained, replace this block with:_ `![alt text](target-filename.png)`
```

## Fields the parser reads

| Field | Required | Notes |
|---|---|---|
| `[IMAGE N — TYPE]` | Yes | `N` is the image number within the post; `TYPE` is one [1] of `SCREENSHOT`, `GEMINI`, `MATPLOTLIB`, `MERMAID`, `PHOTO` |
| `Subject:` | Yes | Free-text description |
| `Capture / Generate:` | Yes | Free-text instructions. The parser also extracts any `http(s)://...` URL it finds in this field. |
| `Save as:` | Yes | Filename with extension, surrounded by backticks |
| `_Once obtained..._` footer | Optional | Ignored by the parser |

## How types are handled

- **SCREENSHOT** — handled by `screenshot_runner.py`. The script opens the URL in Edge.
- **GEMINI** — recorded in the manifest but skipped by the runner. Use `wt-ai-write/references/generate_image_gemini.py` instead.
- **MATPLOTLIB** — recorded but skipped. Use per-post matplotlib scripts.
- **MERMAID** — recorded but skipped. Use Word's Mermaid render or `mmdc`.
- **PHOTO** — recorded but skipped. The user takes the photo manually.

## How target paths are derived

For a placeholder in:

```
From Claude v3/part-01-what-is-github/AI Blog 061 - ... .md
```

with `Save as: `cover.png``, the target path is:

```
From Claude v3/part-01-what-is-github/cover.png
```

i.e. the same folder as the markdown, with the filename from the placeholder.

## URL extraction

The parser uses a simple regex (`https?://[^\s`)]+`) against the
`Capture / Generate:` line. The first [1] matched URL is used by the runner.
Backticks, parentheses and trailing punctuation are stripped.

If the placeholder has multiple URLs (rare but allowed), only the first [1] is
used. The user can switch URLs manually in the Edge address bar before
capturing.

If the placeholder has no URL (some SCREENSHOT placeholders ask to capture an
already-open application like a code editor), the runner skips automatic
navigation and prompts the user to bring up the page themselves before
capturing.

## Worked example

Input (in a markdown file):

```markdown
> **[IMAGE 1 — SCREENSHOT]**
> 
> **Subject:** a real GitHub repository home page
> **Capture / Generate:** open `https://github.com/anthropics/claude-code` in Edge at 125% zoom. Include the green Code button.
> **Save as:** `cover.png`
```

Parsed manifest entry:

```json
{
  "source_md": "From Claude v3/part-01-what-is-github/AI Blog 061 - ... .md",
  "image_number": 1,
  "type": "SCREENSHOT",
  "subject": "a real GitHub repository home page",
  "instructions": "open `https://github.com/anthropics/claude-code` in Edge at 125% zoom. Include the green Code button.",
  "url": "https://github.com/anthropics/claude-code",
  "save_as": "cover.png",
  "target_path": "From Claude v3/part-01-what-is-github/cover.png"
}
```

---
name: wt-ai-write
description: >
  Write the final daily AI news blog post in our house editorial voice, complete with the brand-styled image (Gemini-generated, locked to a text style anchor) and the Mermaid flow chart that illustrates the topic's key idea. Use this skill whenever the user wants to draft today's AI blog, produce the daily AI article, write a punchy short-form AI piece in house style, or generate the article + visuals together. Trigger on "write today's AI blog", "draft today's daily AI post", "produce today's AI article", "make the AI write-up", "AI blog draft", "write the daily AI brief", "short AI post for the site". This skill owns the writing craft (voice, structure, headline, paragraph rhythm, UK English, fourth person, sourcing rules) AND the visual craft for this article series (Gemini image locked to a brand-aligned text descriptor, Mermaid flow chart with matplotlib fallback). It does NOT search for raw AI news (use `wt-ai-search`) and does NOT collect editorial decisions interactively (use `wt-ai-plan`). For the authoritative voice and style ruleset, defer to `wt-writing-auditor`.
---

# wt-ai-write — Daily AI Blog (Writing + Visuals)

## Role

The writing-and-visual-craft skill for the short-form daily AI blog. One run produces the final article in our voice, the brand-styled image, and the Mermaid flow chart. Takes either an agreed brief from `wt-ai-plan` or a topic the user has nominated directly; delivers prose + visuals as the final deliverable.

This is the **writing** end of the three-skill AI-blog pipeline:

- `wt-ai-search` — searches for AI news and tool updates (raw findings)
- `wt-ai-plan` — collects editorial decisions via tickable options (agreed brief)
- `wt-ai-write` — **this skill** — produces the article, image, and flow chart

For the deeper voice and house-style authority (banned phrases, UK English rules, punctuation conventions, editorial standards), the **`wt-writing-auditor`** skill is the source of truth. Its rules apply unchanged here.

For the brand visual language (colour palette, typography, imagery rules), `references/brand-spec.md` is the bundled source of truth. Read it before generating any image.

---

## Blog Identity

- **Audience**: business professionals, finance modellers, Excel/Power BI users curious about AI. No assumed technical background.
- **Tone**: neutral and analytical — factual, clear-eyed, grounded. Not promotional, not alarmist.
- **Language**: UK English throughout — "organise", "recognise", "colour", "favour", "whilst", "modelling", "analyse", "licence" (noun).
- **Person**: fourth person — use "we", never "I".
- **Length**: information-rich. Let the topic decide. Expand until the reader has what they need to act, not just understand. Do not trim for brevity's sake; the reader came for the substance.
- **Plagiarism policy**: paraphrase everything. Never reproduce verbatim text from builder posts, podcast transcripts, or any source.

---

## Topic-Selection Filter (Sanity Check)

`wt-ai-plan` usually owns topic choice. If you arrive here with a topic the user nominated directly, sanity-check it against these five editorial themes — a daily blog topic earns its place only if it fits one of:

1. **Finance, audit, or consulting sector news** — anything that touches our client base: finance teams, auditors, advisory firms, banks, insurers.
2. **New features in AI coding or agent tools** — Codex, Claude Code, Cursor, Windsurf, Replit Agent, OpenClaw, Aider, and their updates. Especially MCP server launches, subagent patterns, and CLI/IDE integrations.
3. **New concepts worth explaining to beginners** — MCP, CLI, sandbox, RAG, context window, context engineering, harness, agent loop, tool use, prompt caching, evals.
4. **New model releases** — Claude (e.g. Opus 4.7), Gemini, GPT series, ChatGPT Image releases, Sora, open-weight models.
5. **Beginner-friendly explainers** of any of the above.

**Reject** celebrity drama, lawsuits, burnout posts, personal-life updates, unrelated political content, startup funding rumours without product substance.

---

## Article Structure

The canonical reference is the Claude Skills 3-part series under `From Liam/` in the project root (Parts 054, 055, 056). Read at least Part 3 before drafting; its shape is what we aim for. Articles use this order (Markdown output):

1. **Headline** — `Topic – Part N: Subtitle` form when part of a series (en-dash, not em-dash; subtitle in Title Case). For a standalone post, a factual headline that names the thing and the audience benefit.
2. **`TBC`** — a single line under the headline. Placeholder for the publication date.
3. **Vivid scenario opener** — open with "Welcome back to our AI blog series." and then **a concrete scenario the reader recognises** ("Picture the workflow every modeller knows. A monthly variance report lands, the same house-style formatting must be applied..."). Land the reader in their own world before you bring in the topic.
4. **Recap + this-time framing** — one short paragraph naming what previous posts in the series covered, what this post does, and what the reader will come away with.
5. **Deep substantive sections** — multiple H2 headings, each one explaining the concept, not just naming it. Concrete examples on every page (a model audit Skill, a DAX style Skill, a Power Query convention Skill). Numbered lists for enumerable items (the four [4] steps, the five [5] sources, the six [6] lessons). Bracketed numerals throughout.
6. **Worked example with FULL code/config** — when the article describes a thing the reader could build, show it in full (a complete `plugin.json`, a complete `SKILL.md`, a complete `marketplace.json`). Then explain each part of what you showed. Snippets get skipped; full files get read.
7. **"Word to the wise"** — the reflective close. Three or four sentences naming the discipline the reader should take with them ("Treat the description as the product", "Build your own first", etc.). Cap with a forward-looking line: *"We will be testing X over the coming weeks and reporting back."*
8. **Series hook** — final line: *"Join us next time for Part N+1, where we ..."* or *"Join us next time for more updates on AI tools."*

**Do not append a "Sources" section.** The Liam blog never carries a bibliography at the end. Attributions, where they exist at all, sit inline in the prose (paraphrased, never quoted). The closer is the *Word to the wise* + series hook — full stop.

Three to five brand-illustrative images sit through the piece — see the *Illustrative Images* section below.

See `From Liam/AI Blog 054-056` for the worked reference; see `references/example-daily-post.md` only as a length-and-shape stand-in (it is short; the real-world articles are longer and deeper).

---

## Voice and Length Discipline

- **Short paragraphs.** One idea each.
- **Plain language.** Translate jargon on first use. If you use "MCP", give a brief inline gloss.
- **Fourth person ("we"), not "I".**
- **UK English.** Cross-check via `wt-writing-auditor`.
- **No clickbait, no hype, no doom.** State the fact, name the source, draw the implication.
- **Punctuation** — follow `wt-writing-auditor` (especially em-dash use).
- **Information-rich.** Expand topics with concrete examples, code snippets, and worked walkthroughs. The reader came for substance — give it to them. No trimming for trimming's sake.
- **Paraphrase always.** Never copy a builder post or transcript line verbatim.

---

## Illustrative Images — Gemini-Generated, Locked to a Text Style Anchor

Every post carries **three to four brand-illustrative images** — not one. Each is generated by `references/generate_image_gemini.py`, which reads the locked text descriptor from `references/style-anchor.md` and appends it to every per-post prompt so the whole article series sits inside one consistent visual family. The anchor is text; there is no anchor PNG.

**Visual direction (locked in the anchor):**

- **Bright** off-white / warm cream backgrounds — never dark, never moody, never black.
- **Technical-savvy editorial** aesthetic — think modern engineering documentation or contemporary design publication, not gallery still life.
- **SumProduct Green (`#007033`) dominant** on the subject — featured edges, key surfaces, the eye-catching colour. Lime (`#d2f7b1`) as secondary accent. Dark Green (`#1e3c3b`) only as fine line work or small shadow accents, never flooded.
- **Mathematical symbols** (Σ, ∫, ∇, ≈, ∂, =) at 10–15 % transparency in SumProduct Green across the background — the visual DNA, like a watermark on engineering graph paper.
- **No people, text, captions, logos, watermarks, neon, glowing orbs, or 3D-render spheres** inside the image.

**Per-post concept rule:** the `--concept` argument names the subject (what is in the picture); the anchor supplies the treatment (how it looks). Don't restate dark-vs-bright, palette, or symbol watermark in the concept — the anchor already locks those.

**Endpoint detail (important):** the script hits Gemini's **`/v1/` stable endpoint** with the `gemini-2.5-flash-image` model. Do not rebuild this on top of the `google-genai` SDK — that SDK defaults to `/v1beta/`, which gates image generation behind a paid tier (`limit: 0`). See `feedback_gemini_image_endpoint.md` in user memory if you need the back-story.

**Where the images land**

| Position | Purpose |
|---|---|
| After the lede, before the first section | **Cover** — the central visual metaphor for the whole post |
| Between two body sections (mid-article) | **Section transition** — a visual beat tied to what the next section unpacks |
| After a worked example or recipe | **Result beat** — the assembled or finished form of what was just walked through |
| Before the close | **Coda** — a quieter, reflective image carrying the takeaway |

Use three [3] or four [4] images per post — not one, not ten. Each must tie to a specific section it sits beside.

**Brand source of truth:** `references/brand-spec.md`. Defines colour palette, typography, imagery rules, voice. The text anchor is derived from it. If the upstream brand guidelines change, re-derive both files together.

**Prerequisites (one-time setup):**

1. **API key** — set `GEMINI_API_KEY` in your environment, or let the script prompt you on first run (hidden via `getpass`, not stored).
2. **Dependencies** — `pip install google-genai` (once per machine).

**Run it per image:**

```bash
python references/generate_image_gemini.py \
  --concept "macro shot of a folded paper structure suggesting recursion" \
  --output "daily-ai-blog-YYYY-MM-DD-[slug]-coverimage.png"
```

The `--concept` argument is the **only thing that varies per call**. Describe the central visual metaphor in one sentence — the script combines it with the locked anchor so the brand look stays identical across every image, every day.

Generate the images in parallel where possible (independent script calls) to keep the drafting loop tight.

If the API call fails or no key is provided, stop and tell the user what is missing. Do not silently fall back to a different image generator.

---

## Flow Chart — Only When the Article Genuinely Needs One

Most posts do **not** need a flow chart. Concept explainers, retrospectives, and audience-focused pieces are better served by illustrative images. Reach for a flow chart only when the article explains a process, decision tree, or technical mechanism that genuinely benefits from a node-and-arrow diagram — and where an illustration cannot carry the same information.

When a flow chart is justified:

1. **`mermaid-cli` (`mmdc`)** — preferred if available and Chrome/Chromium is installed. Apply the brand palette: Dark Green `#1e3c3b` for borders, Lime `#d2f7b1` for accent fills, Green `#007033` for action / final nodes.
2. **matplotlib fallback** — if `mmdc` fails, render directly with matplotlib using `FancyBboxPatch` and `FancyArrowPatch`. See `references/flowchart-fallback-template.py` — brand palette already wired in.

Embed the Mermaid source as a code block alongside the PNG so future editors can adjust the diagram without re-running the renderer.

---

## Quality Checklist — Run Before Hand-Off

- [ ] The piece is information-rich — concrete examples, code snippets, worked walkthroughs where they help. No trimming for brevity.
- [ ] UK English throughout (cross-check against `wt-writing-auditor`).
- [ ] Fourth person ("we"); no "I".
- [ ] Tone is neutral and analytical — no hype, no doom.
- [ ] Every factual claim has a paraphrased source with attribution.
- [ ] Headline names the thing and the audience benefit.
- [ ] **Three [3] to five [5] illustrative images generated via `generate_image_gemini.py`** — cover at the top, body images at substantive section transitions, coda image near the close. **Each image illustrates a specific concept from the section it sits beside, with text labels naming the things in the picture (folder names, file names, headers, before/after, callouts).** Abstract metaphors get rejected.
- [ ] Every image is **bright** (off-white background, not dark), with **SumProduct Green dominant** on the subject and a faint green math-symbol watermark behind.
- [ ] Vivid scenario in the opening — the reader recognises themselves in it before the topic arrives.
- [ ] "Why it matters" section is present and explicit about the audience (modellers / auditors / Excel users), with concrete use cases.
- [ ] Worked example shown in FULL (complete file content), not snippets. Each section of the worked example explained afterwards.
- [ ] *Word to the wise* close + series-hook line ("Join us next time for ...") at the end.
- [ ] **No sources section.** Inline paraphrased attributions only, where they appear at all.
- [ ] If a flow chart is included, it is justified by the topic; otherwise omitted in favour of illustrative images.

---

## Things to Avoid

- Do **not** pad to reach a target length. Short and sharp beats long and thin — and don't truncate substance either.
- Do **not** copy-paste any builder's post or transcript line verbatim. Paraphrase everything.
- Do **not** edit the text style anchor for a single post — the whole point is consistency across the series.
- Do **not** invent quotes, statistics, or capabilities. If unsure, cut the claim.
- Do **not** use em-dashes loosely — follow the punctuation rules in `wt-writing-auditor`.
- Do **not** write in the first person ("I"). Fourth person ("we") only.
- Do **not** adopt a promotional or alarmist tone. Neutral and analytical.
- Do **not** absorb feed-fetch or option-ticking into this skill — those live in `wt-ai-search` and `wt-ai-plan` respectively.
- Do **not** append a "Sources" section, a bibliography, or a reference list at the end. The Liam blog does not carry one. Attributions sit inline in the prose, paraphrased.
- Do **not** generate abstract still-life images (faceted glass cubes on dark backgrounds, ethereal floating shapes, gallery photography). Images must be concrete, content-grounded, and labelled — a folder named `SKILL.md`, a code editor showing actual code, a before/after comparison with headers, a flowchart with named nodes. If you cannot explain what the image teaches the reader, regenerate it.
- Do **not** open with "X this week released..." cold. Open with **a scenario the reader recognises** (the modeller running the same audit every month, the team copying the same prompt for the fiftieth time) and let the topic arrive *into* that world.

---

## Reference Files

- `references/brand-spec.md` — bundled brand spec: colour palette, typography, imagery rules, voice. The source of truth for every visual and editorial choice in this skill.
- `references/style-anchor.md` — the locked text descriptor sent with every image call. Derived from `brand-spec.md`; edit deliberately, because every shift propagates across the daily series.
- `references/generate_image_gemini.py` — generates the post image via Gemini 2.5 Flash Image. **Uses the `/v1/` stable endpoint, not `/v1beta/`** — v1beta has free-tier `limit: 0` for image gen and will fail.
- `references/flowchart-fallback-template.py` — matplotlib flow-chart renderer used when `mermaid-cli` cannot launch Chrome. Brand palette already baked in.
- `references/example-daily-post.md` — short shape stand-in. Not the canonical reference.

**Canonical writing + image references** — read these before drafting any post:

- `<project root>/From Liam/AI Blog 054 - Claude Skills Part 1.docx` — full Liam-edited Part 1 (the structure + voice + image style we target).
- `<project root>/From Liam/AI Blog 055 - Claude Skills Part 2.docx` — Part 2.
- `<project root>/From Liam/AI Blog 056 - Claude Skills Part 3.docx` — Part 3.
- `<project root>/From Sam/AI Blog 054-056 *.docx` — the unedited Sam drafts of the same posts. Compare the Sam → Liam delta to learn what gets fixed during editing (heading case, bracketed numerals, series-aware lede, removal of throat-clearing, removal of sources sections).

## See Also

- `wt-writing-auditor` — authoritative voice and style ruleset.
- `wt-ai-search` — fetches AI news + tool updates; returns raw findings.
- `wt-ai-plan` — turns findings into an agreed brief via tickable options.

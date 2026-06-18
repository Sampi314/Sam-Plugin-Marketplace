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

- **Audience**: business professionals, finance modellers, Excel/Power BI users curious about AI. No assumed technical background; assume the reader could be a marketer, a support lead or an audit partner.
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

There are **two canonical references**, and the post type decides which one leads:

1. **Daily AI blogs (most posts)**: read the Valentina-vs-Liam training pairs at `<user>/Sam/Blogs/Training/AI Blog 037-039 Valentina.docx` and `... Liam.docx`. Valentina writes the draft; Liam edits lightly. The Liam version is what gets published, and the delta between the two is the editing signal. The 037-039 pairs are the cleanest examples.
2. **Multi-part series (Claude Skills 054-056 and successors)**: read `<project root>/From Liam/AI Blog 054-056 - Claude Skills Part 1-3.docx`. Same author but in a specific series sub-style with sentence-case headings, an italic series-anchor teaser and a closing series hook that names Part N+1.

Both follow the order below; the *Two patterns by post type* notes inside each step say where the styles diverge.

### 1. Headline

- **Daily AI blog**: `AI Blog: [Topic]` form. Title Case throughout (every major word capitalised). Example: *AI Blog: NotebookLM Studio: Turning Text into Interactive Audio*.
- **Series post**: `Topic – Part N: Subtitle` (en-dash, not em-dash; subtitle in Title Case). Example: *Claude Skills – Part 4: From Skill to Plugin*.

### 2. Date placeholder

- **Daily AI blog**: real publication date on its own line, e.g. `6 March 2026`. Liam confirms at publication.
- **Series post**: `TBC` as placeholder.

### 3. Opening paragraph

**Daily AI blog** — **plain prose, NOT italic.** Opens with `Welcome back to our AI blog series!` (with the exclamation mark) then runs straight into a factual paragraph that names the topic and what the post will cover.

> Welcome back to our AI blog series! In the previous blog, we showed how NotebookLM can turn a written paper into a structured slide deck in minutes. ... We will go one step further and look at how to improve AI-generated slides, using practical examples from our own workflow.

**Series post** — **italic series-anchor teaser** wrapped in single asterisks so `markdown_to_docx.py` renders it italic. The teaser anchors the post in the series and announces the topic. **NOT a vivid scenario.** Pattern:

> *Welcome back to our AI blog series. [Position in series — e.g. "This time, we continue our X review", "Our X review concludes"]. This time, we [verb] [thing].*

Examples from Liam Skills 054-056:

- *Welcome back to our AI blog series. This time, we look at one of the more practical developments in AI tooling: Claude Skills, a way to turn a general-purpose assistant into something closer to a specialist.*
- *Welcome back to our AI blog series. This time, we continue our review of Claude Skills. This time, we focus on how they work.*
- *Welcome back to our AI blog series. Our Claude Skills review concludes. This time, we build a Skill.*

### 4. Recap-plus-this-time paragraph

A single non-italic paragraph that sits between the teaser and the first H2 heading. It names what previous posts in the series covered, what this post will do, and what the reader will come away with. No sub-heading above this paragraph.

> Over the last three [3] posts, we covered what Claude Skills are, where to find them and how to build one. This time, we look at how a team turns a personal Skills library into a shareable plugin: the install path in Claude Desktop and Claude on the web, what changes once a plugin is live, and the five [5] things to watch when adopting one.

### 5. Cover image

Sits between the recap paragraph and the first H2. Markdown: `![alt text](cover-image.png)`.

### 6. First body section — vivid scenario opens HERE

The vivid scenario lives in the first paragraph of the first H2 section, NOT in the teaser. The H2 heading names the problem the scenario raises (e.g. `## The sharing problem`, `## The distribution problem`, `## Why this needs solving`). The first paragraph opens with `Picture the [thing]...`:

> Picture the team that has been using Claude for a few months. Three [3] people use it daily, the work has settled into a rhythm, and the team has quietly assembled a small library of Skills along the way: a brand-voice Skill the marketing lead pinned down after a year of campaigns, a response-style Skill the support team trained on a thousand tickets, and a code-review Skill that captures the engineering team's pull-request conventions.

Then two or three more paragraphs flesh out the problem the article is about to solve.

### 7. Deep substantive H2 sections

Multiple H2 headings, each one explaining a concept rather than just naming it. Concrete examples on every page.

**Heading case:**
- **Daily AI blog**: Title Case throughout (every major word capitalised). Examples: *Improving Slide Quality Starts with Better Sources*, *Using More Detailed Prompts to Guide the Output*, *Why This Matters for Teams*, *Word to the Wise*.
- **Series post (Skills 054-056 and successors)**: sentence case is also accepted in this sub-style.

**Connect paragraphs explicitly.** Every paragraph after the first in a section should open with a linking phrase that ties it to the previous one. Common Valentina/Liam linkers:

| Connector | Used for |
|---|---|
| *Therefore*, *As a result* | Drawing the implication of what was just said |
| *However*, *By contrast* | Pivoting to a counter-point |
| *In our example*, *In our first pass*, *In practice*, *At this stage* | Grounding an abstract point in a concrete case |
| *From there*, *Once X*, *After X* | Sequencing in time |
| *What's more* | Stacking a related point |
| *This is particularly important when*, *This is especially useful for* | Naming an audience or use case |

Without these linkers, paragraphs read as a list of unconnected statements. With them, the post argues toward a conclusion.

Use **numbered lists** for ordered steps where sequence matters. Use **bulleted lists** for parallel items, alternatives, or any time three or more sentences share the same grammatical shape — those are a list pretending to be prose. See *List formatting* below.

### 8. Worked example shown in FULL

When the article describes something the reader could build, show it in full (a complete `plugin.json`, a complete `SKILL.md`, a complete `marketplace.json`). Then explain each part of what you showed. Snippets get skipped; full files get read.

### 9. The five-minute chat version

A short section (one paragraph and a blockquote) that gives the reader a single Claude prompt for the lazy path through the same task. Liam uses this in 056. Pattern: *"If we did not want to do any of that ourselves, we could open a Claude chat and say:"* then a blockquote with the actual prompt, then one paragraph saying what Claude does next and how long it takes.

### 10. Word to the Wise

**Present in every daily AI blog and every reflective post.** Title Case heading: `Word to the Wise`. Two or three short paragraphs in Valentina's reflective tone — NOT aphoristic punch lines. The shape is:

1. Reflect on what the topic enables in the wider context (what AI now makes possible that wasn't before, or the human role that remains).
2. Acknowledge what AI does NOT replace (judgment, proofreading, brand ownership, structure decisions). Then say what it CAN do (remove friction, save hours, change the workflow).

Pattern from the training pairs (Valentina/Liam 037):

> NotebookLM is already capable of producing high-quality presentation drafts. With a little extra care such as better sources, clearer prompts and a practical plan for final edits, it can become a reliable part of a professional presentation workflow.
>
> AI will not replace judgment, proofreading or brand ownership. However, it can remove hours of manual effort and allow us to focus on what matters most: clarity, insight and credibility.

**Avoid** aphoristic-only closes like *"Build your own first"* or *"Treat the description as the product"* without surrounding context. These punch lines work as bullets inside earlier sections; in Word to the Wise they read as flat. Use full reflective paragraphs.

### 11. Series hook (final line)

A single line on its own at the very end.

- **Daily AI blog**: `Join us next time for more exciting news of AI tools!` (with exclamation mark).
- **Series post**: name what Part N+1 covers — `Join us next time for Part 3: a four-step recipe and a full worked DAX example you can copy.` (no exclamation mark).
- **Final post of a series with no known follow-up topic**: generic line — `Join us next time for more updates on AI tools.`

**Do not append a "Sources" section.** The Liam blog never carries a bibliography at the end. Attributions, where they exist at all, sit inline in the prose, paraphrased.

See `From Liam/AI Blog 054-056` for the worked reference; see `references/example-daily-post.md` only as a length-and-shape stand-in.

---

## Voice and Length Discipline

- **Short paragraphs.** One idea each. But never staccato fragments. Each sentence must have a subject and a verb, and sentences within a paragraph connect with *so, but, while, because, and*. Avoid telegraphic patterns like *"A X Skill. A Y Skill. A Z Skill."* — merge into one connected sentence with a colon or *and*.
- **Plain language.** Translate jargon on first use. If you use "MCP", give a brief inline gloss.
- **UI-friendly framing.** When explaining how a feature works for a user (installing plugins, adding marketplaces, configuring settings), lead with what the user SEES (a tile, a panel, an Install button) and the click path (`Settings → Plugins / Connectors → Add marketplace`). Mention the implementation layer (JSON, folders, GitHub) only briefly and in plain terms. The reader could be a marketer or an audit partner; they should understand the section without prior technical context.
- **Fourth person ("we"), not "I".**
- **UK English.** Cross-check via `wt-writing-auditor`.
- **No em-dashes.** Liam does not use them. Replace with colons, full stops, parentheses, or commas. Hyphens are fine in compounds (`house-style`, `code-review`).
- **Bracketed numerals only for structurally important counts** — *the four [4] steps*, *the five [5] sources*, *two [2] parts of a file*, *ten [10] minutes*. Not for incidentals like "three people" or "day one".
- **No clickbait, no hype, no doom.** State the fact, name the source, draw the implication.
- **Information-rich, but coherent.** Expand topics with concrete examples and worked walkthroughs — the reader came for substance — but every paragraph delivers a fact or an argument. No setup paragraphs, no rhetorical preamble, no "now we will discuss X" sentences. Get to the point and stay there.
- **Paraphrase always.** Never copy a builder post or transcript line verbatim.

### List formatting

- **Bulleted lists** use a **bold lead phrase + colon + lowercase continuation + no terminal period**. The lead phrase names the item; the lowercase prose after the colon explains it.
  ```markdown
  - **Anthropic's official repository:** start with the official Anthropic Skills repository at https://github.com/anthropics/skills
  - **Third-party collections:** independent publishers also maintain Skills in their own GitHub repositories
  ```
- **Numbered lists** use **full sentences, no bold leads**. Each item can run for one or more sentences. Only the very last item ends with a terminal period; the others end without one.
  ```markdown
  1. Choose one [1] repeatable workflow the team handles often. Avoid broad goals; focus on a specific task such as drafting a DAX measure
  2. Write the description before the body. List five [5] or six [6] phrases the team would naturally use to request the task
  3. Test the trigger. Ask Claude using the same phrases the team would use. If the Skill activates only when appropriate, the description is working. If not, revise the description before changing the body.
  ```

### Sentences that earn their place

- **`Picture the [thing]...`** is the scenario-opener verb. Liam reaches for it whenever he wants the reader to see a familiar workflow before the topic arrives.
- **`In our experience, ...`** is allowed *only* when the next sentence names a specific lesson. *"In our experience, most plugins installed from a stranger's marketplace will sit unused after the first week"* is fine; *"In our experience, this matters"* is not.
- **`That is...`** is Liam's declarative cadence. *"That is the practical promise."*, *"That is where we turn next."*
- **`by hand`** is Liam's preferred phrasing over "manually".

---

## Illustrative Images — Gemini-Generated, Locked to a Text Style Anchor

Every post carries **three to four brand-illustrative images** — not one. Each is generated by `references/generate_image_gemini.py`, which reads the locked text descriptor from `references/style-anchor.md` and appends it to every per-post prompt so the whole article series sits inside one consistent visual family. The anchor is text; there is no anchor PNG.

**Visual direction (locked in the anchor):**

- **Bright** off-white / warm cream backgrounds — never dark, never moody, never black.
- **Technical-savvy editorial** aesthetic — think modern engineering documentation or contemporary design publication, not gallery still life.
- **SumProduct Green (`#007033`) dominant** on the subject — featured edges, key surfaces, the eye-catching colour. Lime (`#d2f7b1`) as secondary accent. Dark Green (`#1e3c3b`) only as fine line work or small shadow accents, never flooded.
- **Mathematical symbols** (Σ, ∫, ∇, ≈, ∂, =) at 10–15 % transparency in SumProduct Green across the background — the visual DNA, like a watermark on engineering graph paper.
- **No people, no faces, no third-party brand logos, no neon, no glowing orbs, no 3D-render spheres.** Concrete content-grounded subjects only.

**Per-post concept rule:** the `--concept` argument names the subject (what is in the picture); the anchor supplies the treatment (how it looks). Don't restate dark-vs-bright, palette, or symbol watermark in the concept — the anchor already locks those.

**Endpoint detail (important):** the script hits Gemini's **`/v1/` stable endpoint** with the `gemini-2.5-flash-image` model. Do not rebuild this on top of the `google-genai` SDK — that SDK defaults to `/v1beta/`, which gates image generation behind a paid tier (`limit: 0`). See `feedback_gemini_image_endpoint.md` in user memory if you need the back-story.

**Where the images land**

| Position | Purpose |
|---|---|
| Between the recap paragraph and the first H2 | **Cover** — the central visual metaphor for the whole post |
| Between two body sections (mid-article) | **Section transition** — a visual beat tied to what the next section unpacks |
| After a worked example or recipe | **Result beat** — the assembled or finished form of what was just walked through |
| Before the close | **Coda** — a quieter, reflective image carrying the takeaway |

Use four [4] to eight [8] images per post depending on density. Each must tie to a specific section it sits beside.

**Brand source of truth:** `references/brand-spec.md`. Defines colour palette, typography, imagery rules, voice. The text anchor is derived from it. If the upstream brand guidelines change, re-derive both files together.

**Prerequisites (one-time setup):**

1. **API key** — set `GEMINI_API_KEY` in your environment, or let the script prompt you on first run (hidden via `getpass`, not stored).
2. **Dependencies** — `pip install google-genai` (once per machine).

**Run it per image:**

```bash
python references/generate_image_gemini.py \
  --concept "A 3D-rendered close-up of a single plugin tile card with labelled callouts: NAME, DESCRIPTION, VERSION, INSTALL button." \
  --output "plugin-as-tile-image.png"
```

Generate the images in parallel where possible (independent script calls) to keep the drafting loop tight. Throttle to ~4 in parallel to stay under the free-tier burst rate-limit; sequential with a small pause works too.

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

- [ ] **At least one Valentina/Liam training pair read** from `<user>/Sam/Blogs/Training/` before drafting any daily AI blog.
- [ ] Title in correct form: `AI Blog: [Topic]` (Title Case) for daily posts, `Topic – Part N: Subtitle` (en-dash, Title Case subtitle) for series posts.
- [ ] Date placeholder correct: real date for daily, `TBC` for series posts.
- [ ] Opening correct: plain prose for daily posts (no italic, exclamation in `Welcome back ... AI blog series!`), italic series-anchor for series posts (full stop, wrapped in single asterisks).
- [ ] Recap-plus-this-time paragraph sits between teaser/opener and first H2.
- [ ] First H2 section opens with a **`Picture the [thing]...`** vivid scenario when the topic benefits from one.
- [ ] Cover image between recap paragraph and first H2.
- [ ] **Headings in Title Case** for daily AI blogs; sentence case accepted in series sub-styles like Skills 054-056.
- [ ] **Every paragraph after the first in a section starts with an explicit linking phrase** (*Therefore*, *However*, *In our example*, *In practice*, *From there*, *By contrast*, *As a result*, *What's more*). Without these the prose reads as disconnected statements.
- [ ] UK English throughout, including *whilst*, *based upon*, *especially* (cross-check against `wt-writing-auditor`).
- [ ] Fourth person ("we"); no "I".
- [ ] Tone is neutral and analytical — no hype, no doom.
- [ ] **No em-dashes anywhere.** Colons, parentheses, full stops, commas only. Hyphens in compounds only.
- [ ] Bracketed numerals on structurally important counts only.
- [ ] **Any three or more parallel sentences = a bulleted list, not prose.** If three sentences share the same grammatical shape, convert to a list.
- [ ] Bulleted lists for labelled items: bold-lead-colon-lowercase-no-period.
- [ ] Bulleted lists for steps (Valentina style): no bold leads, lowercase first word, full stop only on the last item.
- [ ] Numbered lists when sequence matters: full sentences, no bold leads, terminal period on the last item only.
- [ ] UI/feature explanations lead with what the user sees (tile, panel, button) and use click-path arrows (`Settings → X → Y`). Implementation layer mentioned briefly only.
- [ ] Worked example shown in FULL (complete file content), not snippets, with each part explained afterwards.
- [ ] **Word to the Wise present in every post.** Title Case heading. Two or three short reflective paragraphs in Valentina's voice (*"AI will not replace X. However, it can Y."*). NOT aphoristic punch lines alone.
- [ ] Series hook on its own line at the very end. Daily: `Join us next time for more exciting news of AI tools!`. Series with known next part: name the topic of Part N+1.
- [ ] **No Sources section.** Inline paraphrased attributions only.
- [ ] Three [3] to eight [8] illustrative images via `generate_image_gemini.py`, each tied to a specific section.
- [ ] Every image is bright (off-white background), with SumProduct Green dominant on the subject.

---

## Things to Avoid

- Do **not** put a vivid scenario in the teaser. The teaser is series-anchor only; the scenario opens the first body paragraph.
- Do **not** add a sub-heading between the teaser and the recap paragraph. Recap goes directly under the teaser, then the first H2.
- Do **not** use em-dashes. Liam does not use them; use colons, parentheses or full stops instead.
- Do **not** pad to reach a target length. Short and sharp beats long and thin — and don't truncate substance either.
- Do **not** copy-paste any builder's post or transcript line verbatim. Paraphrase everything.
- Do **not** edit the text style anchor for a single post — the whole point is consistency across the series.
- Do **not** invent quotes, statistics, or capabilities. If unsure, cut the claim.
- Do **not** write in the first person ("I"). Fourth person ("we") only.
- Do **not** adopt a promotional or alarmist tone. Neutral and analytical.
- Do **not** absorb feed-fetch or option-ticking into this skill — those live in `wt-ai-search` and `wt-ai-plan` respectively.
- Do **not** append a "Sources" section, a bibliography, or a reference list at the end.
- Do **not** generate abstract still-life images. Images must be concrete, content-grounded, and labelled — a folder named `SKILL.md`, a labelled plugin tile, a before/after comparison with headers, a click-path diagram. If you cannot explain what the image teaches the reader, regenerate it.
- Do **not** open the first body paragraph with "X this week released..." cold. Open with `Picture the [thing]...` so the reader recognises themselves in the scenario before the topic arrives.
- Do **not** write staccato fragments. *"A brand-voice Skill the marketing lead built. A response-style Skill the support team trained. A code-review Skill engineering uses."* is three fragments without verbs. Merge with *"a brand-voice Skill the marketing lead pinned down, a response-style Skill the support team trained, and a code-review Skill the engineering team captured."*
- Do **not** pad with throat-clearing connectors. Banned phrases: *"As a practical example..."*, *"It is worth noting..."*, *"It is also worth mentioning..."*, *"What is more..."*, *"Time to get busy"*, *"Think of X as a Y"* (metaphor padding), *"In our experience..."* when the next sentence does not name a specific lesson.
- Do **not** include a Word to the wise section on mid-series posts. Reserve it for series finales and standalone reflective pieces.
- Do **not** restate the point in different words. Liam's signature is two beats: state the fact, draw the implication. Three beats means one is filler.
- Do **not** dump JSON manifests in articles aimed at non-technical readers. Lead with the UI — the tile, the panel, the click path — and mention the implementation only when it directly supports the reader's task.

---

## Reference Files

- `references/brand-spec.md` — bundled brand spec: colour palette, typography, imagery rules, voice. The source of truth for every visual and editorial choice in this skill.
- `references/style-anchor.md` — the locked text descriptor sent with every image call. Derived from `brand-spec.md`; edit deliberately, because every shift propagates across the daily series.
- `references/generate_image_gemini.py` — generates the post image via Gemini 2.5 Flash Image. **Uses the `/v1/` stable endpoint, not `/v1beta/`** — v1beta has free-tier `limit: 0` for image gen and will fail.
- `references/article-template.docx` — Liam's exact docx format, derived from `From Liam/AI Blog 054 - Claude Skills Part 1.docx` with the body content stripped. Carries his page size, margins, default fonts (Calibri 11 pt), section properties and style table. Every article's docx output inherits from this template.
- `references/markdown_to_docx.py` — converts the finished markdown draft into a publication-ready `.docx` that matches Liam's format exactly. Uses `article-template.docx` as the base. Renders the title at 12 pt bold and section headings at 11 pt bold (Normal paragraphs, not Word's Heading styles — Liam does not use them). Inserts a blank paragraph before each H2 heading for visual breathing room. List items use `List Paragraph` style. Code blocks: monospace with light-grey shading. Blockquotes: italic and indented. Images: inline centred at ~70 % page width. Run as `python markdown_to_docx.py --input article.md --output article.docx`.
- `references/flowchart-fallback-template.py` — matplotlib flow-chart renderer used when `mermaid-cli` cannot launch Chrome. Brand palette already baked in.
- `references/example-daily-post.md` — short shape stand-in. Not the canonical reference.

**Canonical writing + image references** — read these before drafting any post:

- **Daily AI blog voice (Valentina/Liam training pairs)** at `<user home>/Sam/Blogs/Training/`:
  - `AI Blog 037 - Create Slide deck with NotebookLM Part 2 Valentina.docx` vs `... Liam.docx` — clearest 037 delta.
  - `AI Blog 038 - NotebookLM Studio Valentina.docx` vs `... Liam.docx`.
  - `AI Blog 039 - Turn text to video with AI tools Valentina.docx` vs `... Liam.docx`.
  - DAX 250, 251, 46b Sam/Liam pairs — show the same edit-delta for the DAX series.

  Read at least one pair before drafting any daily AI blog. The Liam version is what gets published; the delta from Valentina is the editing signal.

- **Multi-part series sub-style (Claude Skills 054-056)** at `<project root>/From Liam/`:
  - `AI Blog 054 - Claude Skills Part 1.docx`
  - `AI Blog 055 - Claude Skills Part 2.docx`
  - `AI Blog 056 - Claude Skills Part 3.docx`

## See Also

- `wt-writing-auditor` — authoritative voice and style ruleset.
- `wt-ai-search` — fetches AI news + tool updates; returns raw findings.
- `wt-ai-plan` — turns findings into an agreed brief via tickable options.

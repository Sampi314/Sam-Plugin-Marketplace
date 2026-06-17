---
name: wt-ai-plan
description: >
  Plan the structure of a daily AI blog interactively. Runs in two modes — (a) if the user has no topic, calls `wt-ai-search` for a shortlist of findings to pick from; (b) if the user already has a topic, INVESTIGATES it first (web search for recent and authoritative sources, predecessor articles, source material the user pointed at) so the writer has enough to draft from. In either case, walks the user through editorial decisions one at a time — topic, theme fit, angle, headline shape, structural cut, image concept, flow-chart concept — and lets them tick the choice that fits. Every question includes built-in options to "find more relevant info" and "show more options" so the user is never stuck with a thin shortlist. Output is an agreed brief that `wt-ai-write` then turns into prose + visuals. Use this skill whenever the user wants to "plan today's AI blog", "let's write about X", "let me pick the angle", "structure the AI blog", "tick the brief", "what should we cover today", "build the blog brief", or any request to make editorial decisions before drafting. Does NOT fetch from the curated builder digest itself (that is `wt-ai-search`) and does NOT write prose or generate visuals (that is `wt-ai-write`).
---

# wt-ai-plan — Planning Skill for Daily AI Blog

## Role

The editorial-decision end of the AI-blog pipeline. Two responsibilities, depending on what the user has nominated:

1. **Mode A — No topic yet.** Pull findings from `wt-ai-search`, walk the user through topic + structural decisions.
2. **Mode B — Topic given.** Investigate the topic first so the writer has source material to draft from, then walk the user through structural decisions with options informed by the investigation.

Pipeline position:

- `wt-ai-search` — gather raw findings (Mode A only)
- **`wt-ai-plan` — this skill** — investigate (Mode B) or process shortlist (Mode A), then collect editorial decisions
- `wt-ai-write` — turn the brief into the final article + visuals

## Decide which mode this run is

- If the user invoked with no topic, or said "what should we write about today?" → **Mode A**
- If the user supplied a topic at invocation, or said "let's write about X" / "plan today's blog about X" → **Mode B**

## Mode A — no topic yet

1. Call `wt-ai-search` to fetch today's digest shortlist.
2. Present the shortlist to the user as topic options.
3. Once a topic is chosen, proceed to **Editorial decisions** below.

## Mode B — topic given (the case where this skill must investigate)

`wt-ai-search` is for topic *discovery* from the curated digest. When a topic is already nominated, the discovery step is skipped — but the writer still needs material to draft from. **This skill must do that investigation.** Do not jump straight to editorial questions when only a topic name is in hand.

Investigation steps:

1. **Web search** — one or two focused queries on the topic to find authoritative + recent sources. Use `WebSearch`. Aim for canonical references (official docs, primary announcements) plus one or two community framings.
2. **Check for predecessor content** — has the user written about this topic or a related one before? Look for series predecessors in the user's working folders (e.g. `From Sam/`, `From Liam/`, prior `AI Blog NNN - *.docx` files, project chapter files). If a series is in progress, find the most recent post and read it so the new piece can pick up the thread and inherit voice.
3. **Read referenced files** — if the user pointed at specific files, quotations, or paths in their message, read them in full and pull the relevant material.
4. **First-hand experience check** — if this conversation has already produced relevant first-hand work (e.g. we just packaged a plugin and we're now writing about packaging), list the concrete lessons from that experience as primary source material. First-hand beats secondary.
5. **Synthesise a research brief** the user can scan in under a minute:
   - 4–6 key facts / talking points (paraphrased, attributed)
   - Source URLs for paraphrased attribution
   - Notable framing from the field (one or two community angles)
   - Voice notes if a predecessor article exists (heading case, lede pattern, signature phrases, closer pattern — derive these by comparing the user's draft against the edited version if both are available)
   - A clear audience takeaway

6. **Present the research brief** to the user **before** asking the editorial questions. Decisions follow informed by what we found, not invented from the topic name alone.

## Editorial decisions (Mode A or B, after the topic + material are in hand)

Use `AskUserQuestion` to present each decision as a tickable list. **Each question should include — within the AskUserQuestion 4-option limit — at least one escape hatch on top of the substantive choices:**

- **"Find more relevant info"** — Mode A: call `wt-ai-search` with a refined query. Mode B: run another `WebSearch` pass. Re-ask once new findings come back.
- **"Show more options"** — propose additional choices and re-ask.
- **"Other"** is provided automatically by `AskUserQuestion`; the user can always type their own answer.

Process one decision at a time. Do not batch unrelated decisions into one question.

### Decisions to collect (in order)

1. **Topic** — Mode A: which of today's findings to cover. Mode B: confirm topic and theme fit.
2. **Theme fit** — confirm which of the five editorial themes the topic maps to: finance/audit sector news, AI coding/agent tools, beginner-worthy concepts, model releases, or beginner-friendly explainers.
3. **Angle** — what is the audience takeaway? Examples: "what this means for auditors", "what changes for modellers", "a beginner-friendly explainer of X", "implications for advisory firms", "Excel/Power BI relevance".
4. **Headline shape** — factual statement, named-release headline, contrast headline, question headline, "Why it matters" / lesson-led headline.
5. **Structure cut** — quick brief, conceptual explainer, news + analysis, comparative take, hands-on walkthrough, lessons-led retrospective.
6. **Image concept** — one-line description of the central visual metaphor for the Gemini `--concept` argument. Offer 3–4 candidates rooted in the topic.
7. **Flow-chart concept** — what process, decision flow, or relationship the Mermaid chart should illustrate. Offer 3–4 candidates.

Skip any decision the user has already settled at invocation.

## Built-in re-search loop

When the user ticks **"Find more relevant info"** on any decision:

- **Mode A**: call `wt-ai-search` with a query refined by that decision context.
- **Mode B**: run another `WebSearch` pass on the refined query.

Examples:

- On angle choice → "find more info on the auditor/compliance implications of [topic]".
- On image concept → "any commentary showing how [topic] is being visualised in the community?".

Re-present the question once the new findings come back. Loop until the user picks a concrete option.

## What this skill returns

An agreed brief, ready for `wt-ai-write`:

```
Topic:               <one-line topic>
Source notes:        <key paraphrased facts + attributions — from wt-ai-search (Mode A) OR from the Mode-B investigation>
Voice notes:         <if a predecessor article exists, distil its editorial moves: heading case, lede style, signature phrases, closer pattern, bracketed-numeral conventions>
Theme:               <one of the 5 editorial themes>
Angle:               <audience takeaway, one sentence>
Headline shape:      <factual | named-release | contrast | question | lesson-led | why-it-matters>
Structure cut:       <quick-brief | explainer | news+analysis | comparative | walkthrough | lessons-led>
Image concept:       <one-line visual metaphor for the Gemini --concept argument>
Flowchart concept:   <process / decision flow the Mermaid chart should illustrate>
```

## Structure report — present this to the user before handing off

The brief above is the dense handoff to `wt-ai-write`. The user also needs to **see the shape** of the article before drafting starts. Present a structure report using this exact template. **Never include word counts on any section. The topic decides length.**

```
### Working headline
> *<headline draft in the target voice>*

(Alternative shape, if useful: *<one alternative>*.)

### Lede
> *<a sketch of the opening — 2–3 sentences as they will roughly read; mark which voice moves are in use>*

### Section 1 — <Sentence-case heading>
<One line: the idea this section carries.>
[If a visual lands here: *Flow chart sits here — <what it shows>.* / *Image sits here — <what it shows>.*]

### Section 2 — <Sentence-case heading>
<One line.>

### Section 3 — <Sentence-case heading>
<One line.>
[If the section is a list (six lessons, four steps), name each item with its sharp framing line and a one-line gloss. No section word counts.]

### Section <N> — <Closing-section heading, e.g. "Word to the wise">
<One line: the takeaway / call-back.>

### Sign-off
> *<the closing line — series hook, forward look, etc.>*

---

**Where visuals land**

| Visual | Position | Function |
|---|---|---|
| Flow chart | <which section / between which sections> | <what it shows> |
| Image | <which section / between which sections> | <what it shows> |

**Voice cross-checks baked in**

- <Heading case rule>
- <Numbered-list convention>
- <Lede pattern>
- <Closer pattern>
- <Person, language, punctuation rules>
- <Any signature phrases the predecessor article uses>
```

After presenting this, ask the user one question: *"Does this shape hold up, or do you want any section reshaped before drafting?"*

## What this skill does NOT do

- Does **not** fetch from the curated builder digest directly — that is `wt-ai-search`. (Mode B uses general `WebSearch` instead.)
- Does **not** draft prose, generate the image, or render the flow chart. Those belong to `wt-ai-write`.
- Does **not** invent material. Every fact in the brief must trace to a source — a `wt-ai-search` finding, a web search result, a predecessor article, or first-hand experience documented in this conversation.
- Does **not** assign word counts to sections, ever. The topic decides length; high-level guidance lives in `wt-ai-write` (and is itself count-free).

## See also

- `wt-ai-search` — fetches raw findings (input to this skill in Mode A); also called for mid-flow re-searches in Mode A.
- `wt-ai-write` — turns the agreed brief into prose, image, and flow chart.
- `wt-writing-auditor` — voice and style authority for the blog (referenced from `wt-ai-write` once drafting begins, and used here in Mode B when distilling voice notes from a predecessor article).

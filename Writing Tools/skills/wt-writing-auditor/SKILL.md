---
name: wt-writing-auditor
description: "Audit and fix blog articles in Liam Bastick's style to match Liam Bastick's editorial standards. Use this skill whenever asked to review, audit, check, proofread, edit, or fix any Liam-style article — including DAX function articles, Excel A-to-Z articles, Final Friday Fix challenges, Monday Morning Mulling solutions, AI blog articles, Thought articles, newsletters, or any other Liam-style publication. Also trigger when the user mentions 'Liam style', 'Liam editorial style', 'writing audit', 'check this article', 'proofread for Liam', or references any blog content in Liam's style that needs quality review. Covers grammar, formatting, technical accuracy, tone, word choice, product name spacing, Power Pivot compatibility, and style compliance. Produces a markdown error report and a tracked-changes Word document."
---

# Writing Auditor — Liam Bastick Style

Audit any article against Liam Bastick's editorial standards. Liam is the final quality gate.

## Two-tier rule system

1. **TIER 1 — UK English** (foundation): standard British conventions — spelling, punctuation, grammar.
2. **TIER 2 — Liam's editorial rules** (top): Liam's house rules, sit ON TOP of Tier 1 and win on conflict.

Both tiers are spelled out in `references/liam-rules.md`, labelled and separated.

## Before auditing — load all three reference files

The rules, templates, and error patterns live in references — do not skip any.

1. **`references/liam-rules.md`** — Tier 1 (UK1–UK6) + Tier 2 (A1–A20 formatting, B1–B3 bullets, C1–C12 grammar/style, D1–D11 technical, E1–E3 images, F1–F2 terminology, G1–G5 MMM-specific, H1–H3 AI Blog-specific). Primary rule source.
2. **`references/style-guide.md`** — universal rules and series-specific templates (DAX, Excel, FFF, MMM, AI Blog).
3. **`references/error-checklist.md`** — real error patterns from 80+ analysed articles, calibrated by severity. Pass 0 of this file is the web-verification checklist for Step 1 below.

## Workflow

### Step 0 — Confirm with the user before running

This skill produces a substantive audit and a tracked-changes Word document. Both take time and modify the user's working files. When the skill is invoked, **the first action is to ask the user before doing anything else**:

> "I'm about to audit *<article name>* against Liam's editorial standards and apply tracked changes to the docx. The audit will take a few minutes and the docx will be modified in place. Shall I proceed?"

Wait for explicit confirmation. Do not load the reference files, run web verification, or open the article until the user has said yes. If the user wants a partial run (audit report only, no docx changes; or docx fixes only, no full audit), capture that scope before starting and skip the steps the user did not ask for.

### Step 1 — Identify article type and verify facts

Detect series from the title:

| Series | Signal |
|--------|--------|
| DAX | "Power Pivot Principles" / "A to Z of DAX Functions" |
| Excel | "A to Z of Excel Functions" |
| FFF | "Final Friday Fix" |
| MMM | "Monday Morning Mulling" |
| AI Blog | "AI blog" or discusses AI tools — apply H1–H3 |
| Other | Thoughts, newsletters — universal rules only |

Run **Pass 0 (Web Verification)** from `error-checklist.md`. Claude's training data is stale; product names, DAX syntax, and AI tools change. At minimum verify product/feature names, DAX function syntax (`site:learn.microsoft.com`, `site:dax.guide`), Power Pivot compatibility, and AI tool currency.

**Visual calculation functions** (*e.g.* **COLLAPSEALL**, **EXPANDALL**, **COLLAPSE**, **EXPAND**) are **Power BI-only** — flag immediately if the article claims Power Pivot support.

### Step 2 — Audit by priority

Apply ALL rules from `liam-rules.md`. Priority order on findings:

1. **Technical accuracy (Critical)** — D-series rules: function names, syntax, no angle brackets, product name spacing, Power Pivot vs Power BI, no rewriting complex explanations (D2).
2. **Liam Tier 2 (Critical)** — every A/B/C/D/E/F/G/H rule from `liam-rules.md`.
3. **UK Tier 1** — UK1–UK6.
4. **Grammar quality** — subject-verb agreement, missing articles/verbs/prepositions, "let's" + base form, homophones, parallel structure.
5. **Tone and structure** — series template compliance (`style-guide.md`), filler removal, FFF→MMM tense conversion, feature names in single quotes.

### Step 3 — Produce both outputs

**Output A — Error report (Markdown).** Start with a **Freshness Check** summarising Pass 0 web findings (✅ confirmed / ⚠️ potentially outdated / ❌ incorrect / 🔍 unverifiable, with source URLs). Then findings grouped by severity (Critical / Major / Minor / Suggestion). Each entry: location, problematic text, the fix, rule reference (*e.g.* "Liam A3" or "UK2").

**Output B — Tracked-changes Word document.** Detailed XML markup procedure in `references/docx-workflow.md`. Key rule: **edit the user's ORIGINAL .docx** — unpack the ZIP, modify `word/document.xml` with `<w:ins>`/`<w:del>`/`<w:comment>` markup, repack. Never create a new .docx from markdown — that destroys original formatting, images, and styles. Every change must have `w:author="Claude"`, `w:date`, and unique `w:id`. If no .docx was uploaded, produce a new .docx with corrections applied (no tracked changes possible) and tell the user tracked changes need an original.

## What NOT to flag

- Liam's intentional humour (puns, asides, self-deprecation).
- First-person voice in Excel series ("my example", "I") — Liam's style.
- Shared educational content repeated across related articles (*e.g.* probability intros in NORM* articles).
- "every business day" vs "every other business day" — both valid.
- Liam's irreverent sign-offs ("We'll feel free to ignore you").

## What NOT to rewrite

- Complex function explanations — flag for Liam with a note (Rule D2). Paraphrasing introduces factual errors.

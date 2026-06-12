---
name: wt-dax-blog-writer
description: "Write SumProduct DAX function blog articles in Liam Bastick's editorial style. Use this skill whenever asked to write, draft, create, or generate a DAX function article, DAX blog post, Power Pivot Principles article, or any 'A to Z of DAX Functions' content. Also trigger when the user mentions 'write DAX blog', 'DAX article for [function name]', 'Power Pivot Principles article', 'A to Z of DAX', or asks to write about any specific DAX function in Liam/SumProduct style. Produces publication-ready markdown articles that follow SumProduct's exact template and Liam Bastick's editorial voice."
---

# DAX Blog Writer — SumProduct Style

Generate publication-ready DAX function articles matching Liam Bastick's editorial standards for the SumProduct *Power Pivot Principles: The A to Z of DAX Functions* series.

## Before writing — load these references

The rules and template live in references, not here. Read in order:

1. The `wt-sumproduct-writing-auditor` skill's `references/liam-rules.md` — UK English (Tier 1) + Liam's SumProduct rules (Tier 2). Single source of truth.
2. The `wt-sumproduct-writing-auditor` skill's `references/style-guide.md` — Section 2 is the DAX series template.
3. The `wt-sumproduct-writing-auditor` skill's `references/error-checklist.md` — known error patterns. Section 7 is the pre-publication checklist.
4. This skill's `references/article-template.md` — exact DAX article structure, fixed wording, and image conventions derived from 20+ Liam-approved articles.

## Workflow

1. **Research.** Web-search Microsoft Learn (`DAX FUNCTIONNAME site:learn.microsoft.com`) and dax.guide. Confirm Power Pivot compatibility and DirectQuery support. Identify the function category and note any similar Excel function.
2. **Plan the example pattern** — see `references/article-template.md` Section 10:
   - Table constructor → scalar functions with multiple behaviours to show
   - DATATABLE + measure → filter context functions needing visuals
   - DAX query view → table-returning or complex setup
3. **Write to the template** exactly. Apply every rule from `liam-rules.md`. Sub-section walkthroughs use bold-italic (Liam A9).
4. **Self-audit** against `error-checklist.md` Section 7 before output.
5. **Output** as Markdown saved to `/mnt/user-data/outputs/` with `[IMAGE PLACEHOLDER: description]` markers. Filename: `DAX_NNN__The_FUNCTIONNAME_Function.md` — ask for the article number if unknown.

## Non-negotiables

- **Do NOT rewrite complex function explanations in your own words** (Liam D2). Flag for Liam's review instead.
- **Do NOT manufacture humour** — Liam's dry wit appears naturally; forced jokes break voice.
- **Technical accuracy is paramount** — verify against Microsoft documentation before writing.
- **The auditor's rules win** — if anything here conflicts with `liam-rules.md`, the auditor wins.

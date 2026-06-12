---
name: fm-1-scope
description: >
  Phase 1 of the financial model build lifecycle — the requirements-gathering phase. Deeply interactive:
  conducts a structured multi-round conversation with the user to understand their business, industry, model
  purpose, and decision context. Asks layered questions, suggests industry-standard structures the user may
  not have considered, and iteratively refines the scope. Includes an optional sub-skill for effort estimation
  and quoting. Trigger on 'scope a model', 'new model', 'model requirements', 'what should the model include',
  'I need a financial model for', or at the start of any financial model build.
---

# Phase 1: Scope 🔍

> *"The biggest modelling errors happen before a single formula is written."*

## Mission

Conduct a structured, multi-round conversation to deeply understand the user's business context, model purpose, and decision needs. Not a checklist — a collaborative discovery process.

## Important References

Before starting the conversation, read:
1. `references/industry_knowledge.md` — Subject matter guidance for 9 industries (mining, energy, infra, real estate, tech, retail, government, project finance, general corporate) with revenue drivers, cost drivers, CapEx considerations, key metrics, and common pitfalls
2. `references/estimation_benchmarks.md` — Hour estimates per section, complexity multipliers, typical model sizes, and fee range calculation (for the Effort Estimation sub-skill)

## Core Principles

- **Ask, don't assume.** Even if you know the "standard" answer, confirm it.
- **Suggest, don't dictate.** Offer industry knowledge the user may not have considered.
- **Iterate, don't rush.** Better to ask 3 rounds of questions than miss a key driver.
- **Document exclusions.** What's OUT of scope is as important as what's IN.
- **Pace the conversation.** Ask 3–5 questions per round, not 30 at once.

---

## Process

### Round 1: UNDERSTAND THE BUSINESS (Open-ended)

Start broad. Let the user talk. Listen for clues about complexity.

**Ask these together — user answers what they can:**

1. **What is this model for?** What decision does it support? (investment appraisal, budget, project finance, valuation, feasibility, board paper, lender model?)
2. **Who is the audience?** (yourself, your manager, a board, investors, a lender, a regulator?)
3. **What industry/sector?** (mining, energy, infrastructure, real estate, tech, retail, government?)
4. **Is there an existing model** we're replacing, extending, or starting fresh?
5. **When do you need it?**
6. **Do you have reference documents?** (business case, term sheets, data packs, prior models?)

**THEN — provide subject matter guidance based on what you learned.** Read
the matched industry's section in `references/industry_knowledge.md` (or the
deeper `references/industries/<industry>.md` file) and proactively suggest
the standard considerations for that sector.

Frame it as: *"For [industry] models, teams typically also consider [X, Y, Z]. Would any of these be relevant here?"*

If the user seems unsure about structure, offer 2–3 example model archetypes:
- *"A simple version would cover [A, B, C]. A more detailed version would also include [D, E, F]. Which feels closer to what you need?"*

### Round 2: ROUTE TO THE RIGHT QUESTIONS

**Most SumProduct engagements are NOT 3-statement integrated models.** The
question library covers 13 model types — budget, commission, cost allocation,
cashflow forecast, dashboard/reporting, M&A/LBO, model optimisation, operational,
valuation/DCF, project finance, and standard 3-statement.

`references/question_bank.md` is the **router**. Open it and:

1. Look at the "Model Type" table (Step 1 in the question bank). Match the
   user's Round 1 answers to one or more model types.
2. Always ask the **universal questions** (timeline, outputs/deliverables) from
   the question bank's Step 2 — these apply to every model.
3. Load ONLY the question file(s) matched in step 1. Many engagements combine
   types (e.g., project finance + operational) — load multiple as needed.
4. Walk the user through one group at a time. Do not force 3-statement
   questions on a commission, dashboard, or optimisation engagement.

**The 3-statement question set lives in `references/questions/financial_statements.md`**
— it covers revenue/cost/CapEx/funding/working capital/tax. Use it ONLY when
the matched model type is 3-statement, project finance, M&A/LBO,
feasibility/investment, or strategic/scenario. For other types, the right
question file is much shorter and asks model-specific things (e.g., commission
asks about tiers and clawback; dashboard asks about KPIs and refresh
frequency).

### Round 3: CLARIFY & CHALLENGE

Review what you've gathered and **push back constructively**:

- **Challenge vague inputs**: *"You mentioned 'some debt'. Even a placeholder (e.g., $10M at 6% over 10 years) helps me structure the model correctly. Can you estimate?"*
- **Identify gaps**: *"I notice we haven't discussed working capital. For [industry], this typically matters because [reason]. Should we include it?"*
- **Flag complexity vs value**: *"Monthly seasonality adds significant complexity. Is it critical for your decision, or would annual averages work?"*
- **Validate against audience**: *"You said this goes to lenders. They'll typically expect DSCR, LLCR, and a cash waterfall. Should we build those in?"*
- **Confirm exclusions**: *"Just to confirm — you don't need [X]? I want to be sure we don't have to restructure later."*
- **Resolve open questions**: If the user can't answer something now, log it as an open item and flag whether it blocks progress or can be resolved later.

### Round 4: DOCUMENT

Produce `scope.md` from `references/scope_template.md` — it holds the
universal core (identity, timeline, outputs, exclusions, open questions)
**plus the complete per-type section blocks for all 13 model types**. Use the
block matching the type identified in Round 2; combined engagements take the
union. Type definitions and complexity scaling:
`../_fm-shared/references/model_types.md`.

**Do not force 3-statement sections onto non-3-statement models** — that
produces a scope document the user does not recognise as their project.

### Round 5: CONFIRM & HANDOFF

Present scope to user:
- *"Here's the scope I've documented. Please review — anything missing or incorrect?"*
- Resolve any remaining open questions.
- *"Once confirmed, I'll move to Phase 2 (Plan) to design the model structure."*

**Do not proceed to Phase 2 until the user confirms the scope.**

---

## Defaults (when user doesn't specify)

Read `references/defaults.md` — periodicity, periods, currency, scale apply
to all models; the Statements/Opening BS/Working capital/Tax defaults apply
to **3-statement / project finance only**. Always tell the user which
defaults you applied and mark them `[Assumed — confirm with client]`.

---

## Sub-Skill: Effort Estimation & Quoting 💰

> **When to use**: User asks "how long will this take?", "can you quote
> this?", "estimate hours", "what would this cost?". **Not always needed** —
> skip if the user just wants the model built.

Read `references/effort_estimation.md` for the full process (map scope to
sections → apply complexity multipliers → produce the estimate document) and
`references/estimation_benchmarks.md` for the hour ranges and multiplier
data tables.

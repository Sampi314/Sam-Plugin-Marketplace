---
name: fm-2-plan
description: >
  Phase 2 of the financial model build lifecycle — the sheet-structure-and-data-flow phase. Translate the
  scope into a concrete blueprint: sheet structure, section layout, data flow between sheets, and calculation
  approach. (Note: this is the structural blueprint, NOT the formatting spec — that is Phase 3 / fm-3-design.)
  Actively suggests best-practice structures, challenges weak assumptions, warns about common pitfalls, and
  leverages deep industry knowledge to propose calculation approaches the user may not have considered.
  Heavily references scope.md from Phase 1. Trigger on 'plan the model', 'model structure', 'sheet layout',
  'how should we structure this', 'data flow design', or after completing scope.
---

# Phase 2: Plan

> *"Structure is the skeleton; plan it well and everything hangs together."*

## Mission

Translate the scope into a concrete model blueprint through **collaborative design with the user**. Don't just map requirements to sheets — actively guide best-practice structures, warn about pitfalls, and propose calculation approaches the user may not have considered.

## Input

Ideally `scope.md` from Phase 1, but often the modeller only has a brief client email. This skill works with whatever is available. When information is incomplete:
1. Extract stated facts
2. Infer with industry knowledge — mark as `[Assumed — confirm with client]`
3. Flag what's missing but don't block progress
4. Produce a draft plan with `[TBC]` placeholders
5. Generate a "Questions for Client" list

## Core Principles

- **Present options, not mandates.** Show 2-3 structural choices with trade-offs.
- **Reference the scope constantly.** Every decision should trace to a scope requirement.
- **Warn about common mistakes.** Share what goes wrong in similar models.
- **Design for the audience.** A lender model needs different emphasis than a management model.
- **Keep it conversational.** Present in stages, get buy-in before moving on.
- **Work with what you have.** Draft plan with gaps marked is better than no plan.

---

## Process

### Stage 0: ROUTE BY MODEL TYPE (do this first)

Read the model type from `scope.md` (Round 4 of Phase 1 records it). Most
Sam engagements are **not** 3-statement integrated models. The right
skeleton, the right calculation patterns, and which downstream stages even
apply all depend on the type.

**Read `../_fm-shared/references/model_types.md`** — the canonical registry of
all 13 types with skeletons, calculation patterns, type-specific checks, and
complexity scaling (Simple/Standard/Complex). Also confirm the scope's
Complexity Level and challenge it if it doesn't match the decision at stake.

**Skip stages that do not apply** to the matched type (the registry's phase
applicability matrix says which). Always run Stages 0, 1 (structure), 2 (data
flow), 3 (section layout), 7 (compile). Stages 4, 5, 6 adapt or skip per the
registry.

### Stage 1: PROPOSE SHEET STRUCTURE

Present the skeleton **for the matched model type** from the registry
(`../_fm-shared/references/model_types.md`) — each of the 13 types lists its
skeleton there. Do not default to the 14-sheet 3-statement skeleton.

Read `references/patterns/sheet_complexity.md` for triggers that add sheets
beyond the matched skeleton. Frame the recommendation as: *"For a [model
type] like yours, the skeleton is [X]. Based on [scope complexity], we should
also add [Y]."*

**Get confirmation** before proceeding.

### Stage 2: MAP DATA FLOW

Show the user how data flows between sheets using a **Mermaid diagram** (`graph LR` for readability). Adapt the diagram to the specific sheet structure — don't use a generic one.

**Explain the "no shortcuts" rule:** Financial statements never calculate anything — they only link to the Calculations sheet. If there's a problem, you only need to look in one place.

**Get confirmation** on the flow.

### Stage 3: DESIGN SECTION LAYOUT (the most collaborative part)

#### General Assumptions
Walk through each section referencing scope answers. For each scope area, show what input rows are needed:

```
Section 1: Revenue and related
  Sales
    - Projected sales volume (units)     <- from scope item 3
    - Unit price ($)                     <- from scope item 3
    - Price escalation (%)               <- from scope item 3
  Working capital
    - Days receivable (days)             <- from scope item 7
```

**Proactively suggest what the user may have missed** — read
`references/patterns/missed_assumptions.md` and raise the companion
assumptions matching what the scope includes (e.g. revenue → escalation;
CapEx → contingency %; commission plans → clawback provisions).

#### Calculations
Mirror the Assumptions structure, then highlight derived rows. Show how the control account pattern works: Opening + Additions - Deductions = Closing. The cash movement is always the balancing figure.

Read `references/patterns/control_accounts.md` for the 5 standard patterns (working capital, fixed assets, debt, tax, retained earnings).

**Get confirmation** on calculation approach.

### Stage 4: WARN ABOUT COMMON PITFALLS

Based on the model type from the scope, read `references/patterns/pitfalls.md` and flag the 2-3 most relevant pitfalls. Explain how the proposed structure avoids them.

### Stage 5: MAP CONTROL ACCOUNTS

For each balance sheet item, define the control account using the patterns from `references/patterns/control_accounts.md`. Present as a table:

| BS Item | Opening | Additions | Deductions | Closing Formula |
|---------|---------|-----------|------------|----------------|

If the model doesn't have a balance sheet (e.g., commission model, budget), skip this stage and instead map the primary calculation logic relevant to the model type.

### Stage 6: DISCUSS TIMING ENGINE

Confirm timing details from scope. Read `references/patterns/timing.md` for timing patterns if mixed periodicity is needed.

### Stage 7: COMPILE & CONFIRM

Read `references/plan_template.md` for the full template structure.

1. Write `plan.md` to the working directory
2. If the user wants `.docx`, run `python ../_fm-shared/scripts/md_to_docx.py plan.md`
3. Tell the user the files are ready for review
4. **Do not proceed to Phase 3 until the user explicitly confirms the plan**

---

## Reference Files

Load as needed — not all at once:

| File | When to Read |
|------|-------------|
| `../_fm-shared/references/model_types.md` | Stage 0 (always — the type registry) |
| `references/patterns/control_accounts.md` | Stage 3 (calculations) and Stage 5 — FS-type models |
| `references/patterns/financial_statements.md` | Stage 3 (if model has IS/BS/CFS) |
| `references/patterns/calculation_patterns_by_type.md` | Stage 3 and Stage 5 replacement — all non-FS types |
| `references/patterns/timing.md` | Stage 6 (if mixed periodicity) |
| `references/patterns/pitfalls.md` | Stage 4 |
| `references/patterns/sheet_complexity.md` | Stage 1 (deciding sheet structure) |
| `references/plan_template.md` | Stage 7 (producing deliverables — universal core + per-type sections) |

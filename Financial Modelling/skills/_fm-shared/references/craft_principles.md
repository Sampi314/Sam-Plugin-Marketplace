# CRaFT Principles Guide

> SumProduct's CRaFT methodology defines **four qualities** a good financial model should exhibit. These are guiding principles, not a rigid pass/fail checklist — not every model needs every technique, and pragmatic trade-offs are expected. Use CRaFT to guide decisions during Build and to frame findings during Test.

## What CRaFT Means

**C**onsistency · **R**obustness · **a** · **F**lexibility · **T**ransparency

The "a" is just the word "and" — the framework is really four pillars: Consistent, Robust, Flexible, Transparent.

---

## C — Consistency

> *"If it looks the same, it should work the same."*

### The Principle
A consistent model uses the same conventions everywhere. When a user sees a yellow cell, they know it's an input. When they see a dark blue heading, they know it's a new section. When they see a formula in one period, they can trust it works the same way in every other period.

### How It Manifests

- **Cell Styles** — the same Named Style is used for the same purpose throughout (Assumption = yellow everywhere, not yellow on one sheet and blue on another)
- **Sheet structure** — periodic sheets share the same header block (rows 1–9), the same column layout (A–I fixed, J onwards for periods)
- **Formula uniformity** — a formula row has the same R1C1 pattern across all period columns (the first column may differ for initialisation, but this should be the only exception)
- **Section numbering** — auto-incrementing, not manually typed
- **Labels** — Calculations mirrors Assumptions labels by linking, not retyping

### When to Relax
- One-off sheets (Cover, Navigator) don't need periodic structure
- Very small models (< 5 sheets) may not need formal section numbering
- If the model is for internal use only, style rigour can be lighter

### Typical Test Checks
- Are Cell Styles applied? (Stylist agent)
- Are R1C1 patterns uniform? (Logic agent — pattern break detection)
- Is the header block consistent? (Stylist + manual check)

---

## R — Robustness

> *"The model should be materially free from error, mathematically accurate, and readily auditable."*

### The Principle
A robust model produces correct results, handles edge cases gracefully, and tells you when something is wrong. It doesn't silently produce garbage when an input is unusual.

### How It Manifests

- **Error checks** — built-in checks that flag when the balance sheet doesn't balance, when the cash flow doesn't reconcile, when values are impossible
- **Data validation** — input cells have constraints preventing nonsensical entries (no negative volumes, no 200% tax rates)
- **No circular references** — unless intentional and documented (e.g., interest on average cash balance with iterative calculation enabled)
- **Control accounts** — Opening + Movements = Closing, enforced by formula structure
- **Rounding tolerance** — balance checks use `ROUND(..., Rounding_Accuracy)` not exact comparison (floating point maths means 0.0000000001 ≠ 0)
- **Named ranges resolve** — no dead names in the Name Manager

### When to Relax
- Very early-stage models (feasibility sketches) may skip data validation
- If the model is for a single known user, validation can be lighter
- Some checks (insolvency flag) may not be relevant for all model types
- Error check formatting (tick/cross with Wingdings) is nice-to-have, not essential

### Typical Test Checks
- Error checks all pass? (Sentry agent)
- Named ranges resolve? (Sentry agent)
- Circular references? (Sentry agent)
- Data validation present on inputs? (Sentry + Architect agents)
- Control accounts balance? (Logic agent)

---

## F — Flexibility

> *"The model should adapt to changing assumptions without formula rewrites."*

### The Principle
A flexible model lets users change key assumptions and see the impact immediately. Changing the start date, periodicity, or number of periods shouldn't require touching any formulas. Adding a new cost line shouldn't break the model.

### How It Manifests

- **Parameterised timing** — the Timing sheet drives all dates; changing periodicity or start date cascades automatically
- **No hardcoded values in Calculations** — every number in the calculation engine traces back to an input cell or named range
- **Relative references in time series** — formulas use `RC[-1]` (previous period) not `$J$17` (absolute column reference), so extending periods is just copying a column
- **Named ranges for constants** — `Days_in_Year` rather than the number 365 buried in a formula
- **Scalable structure** — adding a period column requires no formula changes

### When to Relax
- If the model will never change periodicity (e.g., always annual), parameterised timing is still good practice but not critical
- Static models (one-time analysis, no ongoing use) can be less flexible
- Some hardcoded values are acceptable structural constants (0, 1, -1, 12, 365)

### Typical Test Checks
- No hardcoded values in Calculations period columns? (Logic agent)
- Timing is parameterised? (Manual check of Timing sheet)
- Formulas use relative column references? (Logic agent — R1C1 analysis)
- Can a new period column be added without breaking? (Architect agent — scalability)

---

## T — Transparency

> *"Anyone picking up this model should understand it without needing the developer."*

### The Principle
A transparent model explains itself. Labels are clear, units are visible, cross-references are documented, and the calculation logic can be followed without clicking into every cell.

### How It Manifests

- **Units column** (column G) — every calculation row shows its unit, referencing named ranges (`=Currency`, `=Percentage`, `=Unit`)
- **Row references** (column H) — where a row references another row's output, show `"Row 47"` so the reader can trace the logic
- **Formula audit column** — FORMULATEXT in column P of the Calculations sheet shows every formula as text
- **Style Guide sheet** — documents all formatting conventions with visual examples
- **Navigator sheet** — hyperlinked table of contents to every sheet
- **Section structure** — clear heading hierarchy (H1 for major sections, H2 for sub-sections, H3 for groups)
- **Named ranges** — key parameters have meaningful names visible in formulas
- **Cover sheet** — identifies the model, developer, client, purpose

### When to Relax
- Formula audit column (FORMULATEXT) adds clutter on simple models — skip if < 50 calculation rows
- Row references are most valuable in complex models with 200+ calculation rows
- Internal quick models may skip the Style Guide sheet
- Named ranges for every single cell is overkill — use for parameters, timing, error checks, units

### Typical Test Checks
- Style Guide exists and is complete? (Stylist agent)
- Navigator links to every sheet? (Hyperlinks agent)
- Units column uses named ranges? (Logic agent)
- Formula audit column present? (Efficiency agent)

---

## Applying CRaFT Pragmatically

### Model Complexity → CRaFT Rigour

| Model Complexity | C | R | F | T |
|-----------------|---|---|---|---|
| Quick internal sketch (1-day build) | Basic styles | Error checks only | Parameterised timing | Clear labels |
| Standard budget/forecast (1-week build) | Full Cell Styles, uniform formulas | Full checks, validation on key inputs | Full timing + named ranges | Units column, Navigator |
| Client-facing model (2-4 week build) | Everything | Everything | Everything | Everything including audit column |
| Lender/regulatory model (4+ week build) | Everything + documented in Style Guide | Everything + custom checks | Everything + scenario engine | Everything + full documentation pack |

### During Build (Phase 4): Use CRaFT to Guide Decisions

When faced with a choice, ask:
- "Is this **consistent** with how I've done it elsewhere in the model?"
- "Is this **robust** — will it still work if the input changes?"
- "Is this **flexible** — will it break if someone extends the timeline?"
- "Is this **transparent** — will someone understand this without asking me?"

### During Test (Phase 5): Use CRaFT to Frame Findings

When raising a finding, note which CRaFT principle it violates. This helps the user understand *why* it matters, not just *what* is wrong.

Example:
> "⚠️ WARNING: Row 47 has a hardcoded value (1.05) in the Calculations sheet instead of referencing an assumption cell. This violates **Flexibility** (hardcoded values can't be changed by the user) and **Transparency** (the assumption is invisible)."

### What CRaFT Is NOT

- It is **not** a 300-page standards document with mandatory rules
- It is **not** a binary pass/fail — it's a quality spectrum
- It is **not** prescriptive about *how* to achieve each quality — only *what* quality to aim for
- A model can be CRaFT-compliant without implementing every single technique listed here
- The goal is a model that is **fit for purpose**, not a model that ticks every box

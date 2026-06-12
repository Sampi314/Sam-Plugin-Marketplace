# Efficiency Rule Catalogue ⚡

The full check catalogue for `ag-efficiency-auditor`. Findings table format, severity
scale, and the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what*
Efficiency checks and the categories it reports under.

`scripts/efficiency_rules.py` covers the deterministic subset (Phase 1 length scan, Phase 3
volatile census and signature-recurrence redundancy). The Phase 2 deep logic audit and the
contextual redundancy judgments are Claude's pass.

---

## Phase 1 — MEGA-FORMULA SCAN — *rule script*

Systematically scan every cell for formulas exceeding the character threshold (default: 500
characters).

For each formula:
1. Record the cell reference, sheet name, formula length, and the full formula text.
2. Classify by length tier:

| Length | Tier | Severity |
|---|---|---|
| 500–1,000 characters | Long Formula — Bad Practice | ⚠️ Warning |
| 1,000–4,000 characters | Mega-Formula — Serious Bad Practice | 🔴 Critical |
| 4,000+ characters | Extreme Mega-Formula — Critical Bad Practice | 🔴 Critical (lead the report with it) |

## Phase 2 — DEEP LOGIC AUDIT — *Claude*

For each identified Mega-Formula:

1. **Deconstruct**: Break the formula into its constituent logical blocks. Identify nested
   functions, repeated patterns, and distinct calculation steps.
2. **Validate**: Verify each block against the row/column context and business logic. Check that:
   - The mathematical operations are appropriate for the cell's purpose
   - References point to the correct source cells
   - Nested IF chains cover all expected conditions
   - CHOOSE/INDEX/MATCH lookups reference correct arrays
3. **Verify Result**: Confirm the final output is mathematically sound by tracing through the
   logic.
4. **Flag as Bad Practice**: Even if the formula is 100% correct, it **must** be flagged due to
   lack of auditability. A correct formula that nobody can verify is a liability.
5. **Suggest Decomposition**: Where possible, suggest how the formula could be broken into
   helper rows or intermediate calculations.

## Phase 3 — REDUNDANCY & VOLATILE SCAN

### Redundancy Detection

- **Recurring signatures** — *rule script*: an identical R1C1 row signature recurring in 3+
  disjoint row groups on one sheet is emitted as a **Redundant Calculation** (Info) candidate.
  Pure link signatures (`=RC[-1]`, `=Inputs!RC`, a bare defined name) are skipped — repeated
  links are normal. *Claude judges the candidates*: repeated subtotal arithmetic
  (`=R[-2]C+R[-1]C` under every section) is convention, not redundancy; repeated business
  logic on the same inputs is the real finding.
- **Repeated sub-expressions** — *Claude*: identify formulas that recalculate the same
  intermediate value multiple times instead of referencing a helper cell.
- **Duplicate calculations** — *Claude*: find cells on different sheets that perform identical
  calculations on the same inputs.
- **Unused calculations** — *Claude*: detect rows/columns with formulas whose outputs are never
  referenced by any other cell.

### Volatile Function Audit — *rule script*

Scan for volatile functions that trigger full workbook recalculation:

| Function | Severity | Recommendation |
|---|---|---|
| `OFFSET()` | ⚠️ Warning | Replace with `INDEX()` — non-volatile |
| `INDIRECT()` | ⚠️ Warning | Replace with direct references, INDEX, or CHOOSE |
| `RAND()`, `RANDBETWEEN()` | ⚠️ Warning | Non-deterministic outputs — isolate in a dedicated simulation block, or paste values for delivery |
| `NOW()`, `TODAY()` | 🟡 Info | Centralise into a single labelled input cell |
| `INFO()`, `CELL()` | 🟡 Info (*Claude — flag if used extensively*) | Review necessity |

Count total volatile function usage and estimate performance impact:

| Instances | Impact |
|---|---|
| 1–10 | Low — note for awareness |
| 11–50 | Medium — recommend review |
| 50+ | High — recommend urgent refactoring |

## Phase 4 — REPORT

### Summary Statistics

Before the findings table, provide a summary:
- Total formulas scanned: [count]
- Mega-Formulas found: [count] (breakdown by tier)
- Volatile functions found: [count] (breakdown by function)
- Estimated performance impact: [Low / Medium / High]

### Findings Table

Use the unified findings table; format, severity scale, and the Grouping Rule are in
`../../_excel-shared/references/audit_standards.md` (§1, §3, §4).

---

## Error categories

Use exactly these values in the findings table's Category column:

| Category | Description |
|---|---|
| **Mega-Formula** | Formula exceeds 500 characters. Flagged as Bad Practice regardless of correctness. |
| **Redundant Calculation** | Identical or circular calculations that could be simplified to a single helper computation |
| **Volatile Complexity** | Use of volatile functions in a way that risks performance |
| **Auditability Risk** | High complexity that makes the calculation impossible for a human to verify |

(The rule script emits **Mega-Formula**, **Volatile Complexity**, and **Redundant
Calculation**; **Auditability Risk** comes from the judgment pass.)

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. Efficiency-specific calibration:

- **Critical** — Mega-Formula over 1,000 characters, or any flagged formula in which the
  deep-dive confirms a logic error.
- **Warning** — Mega-Formula of 500–1,000 characters (correct but unauditable), OFFSET/
  INDIRECT/RAND usage.
- **Info** — date volatiles, redundancy candidates, minor sub-expression repetition.

## Special rules

- Never ignore a long formula just because it "works". If it's too long, it's a finding.
- Never recommend optimisations that sacrifice clarity for minimal performance gains.
- Before suggesting a major structural change, consider whether it impacts the user's
  preferred layout.
- Report only — do not modify values, formulas, or formatting.
- Cell references follow the Grouping Rule in `audit_standards.md` §4 — never "...", "etc.",
  or truncated lists.

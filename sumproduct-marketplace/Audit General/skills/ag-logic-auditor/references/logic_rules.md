# Logic Rule Catalogue 🧠

The full check catalogue for `ag-logic-auditor`. Findings table format, severity scale,
and the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what* Logic
checks and the categories it reports under.

`scripts/logic_rules.py` covers the deterministic subset (Phase 3c pattern breaks from
`r1c1_rows`, Phase 3d hard-coded literals). Everything else here is Claude's judgment pass.

---

## Phase 1 — MAP CONTEXT

Build a **Context Map** for each sheet before any logic checking begins.

1. **Identify Row Descriptors**: Scan the leftmost populated column(s) to capture the
   description/label for each row (e.g., "Revenue", "DSCR", "Tax Rate", "Opening Balance").
2. **Identify Column Headers**: Scan the topmost populated row(s) to capture header labels
   (e.g., "FY2024", "Assumption", "Unit", "Total", "Jan", "Feb").
3. **Identify Section Headers**: Detect merged cells, bold rows, or indentation patterns that
   define logical sections (e.g., "Operating Costs", "Debt Schedule").
4. **Store the Context Map** for use in all subsequent phases.

## Phase 2 — REASON

Understand the business logic defined in the project documentation.

1. Read `calculation_logic.md` and `model_design_spec.md` if available.
2. Identify key calculation drivers: Revenue, COGS, Depreciation, Tax, Debt Service, DSCR, etc.
3. Note any industry-specific rules (e.g., tax methods, infrastructure availability payment
   structures).
4. Build a mental map of expected formula relationships between sections and sheets.

## Phase 3 — AUDIT FORMULA SENSIBILITY

For each formula cell, use the Context Map to assess whether the formula is **contextually
reasonable**:

### 3a. Operator Check

Does the operation match what the row description and column header imply?

| Context (Row Description) | Sensible Operations | Suspicious Operations |
|---|---|---|
| "Total" / "Subtotal" | SUM, SUBTOTAL of items above | Single cell reference, multiplication |
| "Growth %" / "Escalation" | Division of two periods, percentage calc | SUM of values, absolute reference |
| "Opening Balance" | Prior period's Closing Balance reference | SUM, unrelated sheet link |
| "Closing Balance" | Opening + Additions − Deductions | Single cell reference, unrelated calc |
| "DSCR" / "LLCR" / "ICR" | CFADS / Debt Service (or similar ratio) | SUM, direct input |
| "Variance" / "Difference" | Actual − Budget or (A−B)/B | SUM, unrelated lookup |
| "Average" / "Mean" | AVERAGE function or manual equivalent | SUM without division |
| "Tax" / "Excise" / "Duty" | Rate × Base, with correct base identified | Flat amount, wrong base reference |
| "Depreciation" | Cost / Life, or declining balance calc | SUM of unrelated items |
| "Interest" | Balance × Rate × Time factor | SUM, wrong balance reference |

### 3b. Reference Direction Check

Does the formula reference cells that make contextual sense?

- A **"Total"** should reference cells **above** it (or within the same section).
- A **time-series formula** should typically reference the **previous column** (same row) or
  assumption rows.
- A **"link" cell** should reference a **different sheet**.
- An **"Opening Balance"** should reference the **prior period's Closing Balance** (previous
  column, lower in the section).
- A **"Closing Balance"** should reference the **same period's Opening Balance** (same column,
  higher in the section) plus movements.

### 3c. Consistency Check (Pattern Break Detection) — *rule script*

Within a row of repeating formulas (e.g., a time series across columns):

1. Convert each cell's formula to R1C1 notation (`extract.json` pre-computes this in
   `r1c1_rows` / `r1c1_cols`).
2. Identify the **dominant pattern** (the formula used by the majority of cells in the row).
3. Flag any cell whose R1C1 formula **differs from the dominant pattern**.
4. **Intentionality is Claude's call**: the **first column** in a time series may legitimately
   differ (initial period seeds from an opening value or base assumption), and **subtotal/total
   columns** legitimately switch to SUM. Flag a deviation as an error only if it appears
   inconsistent with the business logic; otherwise report it as a verified intentional variant
   or drop it.

`logic_rules.py` runs steps 1–3 over `r1c1_rows` (row patterns). Column patterns
(`r1c1_cols`) and the intentionality judgment in step 4 stay with Claude.

### 3d. Hard-Code in Formula Check — *rule script*

Detect literal numbers embedded in formulas that should be cell references:

- Any numeric literal other than `0`, `1`, `-1`, `100`, `12`, `365`, `52` (common structural
  constants) is suspicious. (The rule script's allow-list is `0`, `1`, `-1`, `12`, `100` —
  treat flagged `365`/`52` as time-basis constants and clear them in the judgment pass.)
- Example: `=RC[-1]*1.05` — the `1.05` likely represents a growth rate and should reference an
  input cell.
- Exception: Array constants, rounding precision arguments (e.g., `ROUND(..., 2)`), date
  components (`DATE(2024,1,1)`), and MATCH/INDEX position offsets are acceptable. The script
  auto-exempts literals inside ROUND*/DATE* functions; clear acceptable MATCH/INDEX offsets
  and array constants by eye.

## Phase 4 — VALIDATE

Compare model outputs against expected business logic and reasonableness:

1. **Sanity Checks**: Flag values that are impossible or highly improbable:
   - Negative tax expense (when profit is positive)
   - Margins > 100% or < −100%
   - DSCR values that are negative when cash flows are positive
   - Opening Balance ≠ Prior period Closing Balance
   - Balance sheet that doesn't balance
   - Percentages stored as whole numbers (e.g., 5 instead of 5% or 0.05)

2. **Business Rule Validation**: Compare formula logic against documented business rules:
   - Excise Duty: Is it applied on the correct volume/value base?
   - Tax: Is the rate applied to the correct taxable income line?
   - Depreciation: Does the method match the asset class requirements?
   - Debt: Are repayment schedules consistent with the facility terms?

3. **Cross-Sheet Consistency**: Verify that values flowing between sheets are correctly linked:
   - Revenue on the P&L matches Revenue on the calculation sheet.
   - Cash flow movements tie back to Balance Sheet changes.
   - Summary sheet totals match the detail sheets.

## Phase 5 — REPORT

Use the unified findings table; format, severity scale, and the Grouping Rule are in
`../../_excel-shared/references/audit_standards.md` (§1, §3, §4).

### R1C1 Notation Rule

When a finding references a formula pattern, **always express formulas in R1C1 notation**.
This makes repeating patterns self-evident and removes column-specific noise.

- **R1C1 is mandatory** for: Formula Pattern Break, Formula Context Error, Hard-Coded Value,
  Reference Direction Error, Logical Flaw.
- **R1C1 is optional** for: Sanity Check Failure, Assumption Mismatch.
- Use the standard's `Expected R1C1: ... Actual: ...` fields (and JSON keys `r1c1_expected` /
  `r1c1_actual`) — `audit_lib.a1_to_r1c1()` converts without Excel.

**R1C1 conversion rules:**

| A1 Style | R1C1 Equivalent | Meaning |
|---|---|---|
| Relative (e.g., `B5` from `C6`) | `R[-1]C[-1]` | Offset in brackets = relative |
| Absolute (e.g., `$B$5`) | `R5C2` | No brackets = absolute |
| Mixed row-abs (e.g., `$B5`) | `RC2` | Column absolute, row relative |
| Mixed col-abs (e.g., `B$5`) | `R5C[-1]` | Row absolute, column relative |
| Same row (e.g., `R[0]C[-1]`) | `RC[-1]` | `R[0]` simplifies to `R` |
| Cross-sheet (e.g., `Sheet1!$D$5`) | `Sheet1!R5C4` | Sheet prefix stays, reference converts normally |

---

## Error categories

Use exactly these values in the findings table's Category column:

| Category | Description |
|---|---|
| **Logical Flaw** | The formula logic is fundamentally incorrect for the business context |
| **Assumption Mismatch** | Formula does not align with the defined business assumptions or design spec |
| **Sanity Check Failure** | Output values are impossible or highly improbable |
| **Excise Error** | Incorrect application of tax, excise, or duty rules |
| **Formula Context Error** | Formula operation doesn't align with the cell's row/column meaning |
| **Formula Pattern Break** | Cell's formula differs from the repeating pattern in its row/column |
| **Hard-Coded Value** | Literal number in a formula instead of a cell reference |
| **Reference Direction Error** | Formula references cells in an unexpected direction or location |
| **Cross-Sheet Mismatch** | Values flowing between sheets are incorrectly linked or don't reconcile |
| **Mega-Formula** | Formula exceeds 4,000 characters, making it impossible to audit or maintain (the Efficiency auditor owns the systematic length scan; Logic flags extremes it trips over) |

(The rule script emits **Formula Pattern Break** and **Hard-Coded Value**; the remaining
categories come from the judgment pass.)

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. Logic-specific calibration:

- **Critical** — formula logic clearly wrong for context: a confirmed Logical Flaw, a failed
  sanity check with material output impact, a cross-sheet link to the wrong line.
- **Warning** — suspicious and unconfirmed: pattern breaks pending intentionality review,
  hard-coded literals, operator/label mismatches that may be deliberate.
- **Info** — minor inconsistency unlikely to affect outputs materially.

## Special rules

- **Numerical Sense Checking**: Always perform a contextual "sanity check" on numerical outputs.
- **Mega-Formula Detection**: Flag formulas exceeding 4,000 characters even if correct.
- Never assume the current logic is correct just because it "works".
- Never modify values or formatting — report only.
- Cell references follow the Grouping Rule in `audit_standards.md` §4 — never "...", "etc.",
  or truncated lists.

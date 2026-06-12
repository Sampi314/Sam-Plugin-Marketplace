# AI Auditor Rule Catalogue 🤖🔍

The full check catalogue for `ag-ai-auditor`. Findings table format, severity scale, and
the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what* the AI
Auditor checks and the categories it reports under.

`scripts/ai_audit_scanner.py` automates most of Phases 1–6 (each check below notes when it is
judgment-only). The scanner reads the workbook directly with openpyxl — it needs stored data
types and values, which the shared extract does not carry.

---

## Why AI models need a specialist audit

Human modellers make *different* mistakes from AI tools. A human might use a wrong tax rate or
build a circular reference from flawed logic. AI tools make *mechanical* mistakes — they
generate code that writes values into cells, and the failure modes are systematic and
predictable:

| AI Failure Mode | Root Cause |
|---|---|
| Formula written as text string | openpyxl cell.value = "=SUM(A1:A10)" stored as a string, not a formula |
| Static snapshot of a calculated value | AI computed the answer in Python and wrote the number, not the formula |
| SUM includes header row or misses last data row | Off-by-one error in the Python range-building loop |
| Reference to wrong cell | AI miscounted rows/columns in the code |
| Broken sheet reference | Sheet name has a space but formula doesn't wrap it in quotes |
| Number stored as text | openpyxl wrote `"1000"` (string) instead of `1000` (int/float) |
| Date stored as text | AI wrote `"2024-01-01"` as a string instead of a datetime object |
| Absolute reference where relative needed | AI used `$A$1` everywhere because it's "safer" |
| Empty rows where formulas belong | AI created the structure (labels) but skipped the formula-writing code |
| Inconsistent formatting | AI applied formatting in one loop but not another |

These are **high-frequency, high-impact** errors that are almost invisible to the user viewing
the model.

---

## Phase 1 — STRUCTURAL INTEGRITY SCAN

Verify the model's skeleton is sound before examining content.

### 1a. Sheet Existence & Reference Integrity

For every formula in the workbook that references another sheet:
1. Extract the sheet name from the formula (the part before `!`).
2. Verify that sheet exists in the workbook.
3. Check that sheet names with spaces are properly quoted in formulas (wrapped in single quotes).
4. Flag any `#REF!` errors that indicate deleted sheets or ranges.

### 1b. Empty Placeholder Detection

AI tools frequently create row labels and section headers but forget to write the
corresponding formulas. Scan for:
1. Rows where **Column A** (or the label column) has text, but **all data columns are empty**.
2. Sections where some rows have formulas but others in the same block are blank.
3. Header rows that exist but the data section below them is entirely empty.

**Exception:** Rows explicitly labelled as "spacer", "separator", or blank label rows used for
visual separation are acceptable.

### 1c. Orphaned Cell Detection — *judgment-only*

Find cells that are referenced by formulas but are themselves empty or non-existent:
1. Parse all formulas to extract cell references.
2. For each referenced cell, verify it contains a value or formula.
3. Flag references to cells that are empty, outside the used range, or in non-existent sheets.

---

## Phase 2 — FORMULA AUTHENTICITY SCAN

This is the most critical phase. AI's #1 error is producing cells that *look* like they
contain formulas but actually contain static values or text strings.

### 2a. Formula-as-Text Detection

Scan every cell for values that look like formulas but are stored as text:
1. Check cells where `cell.data_type == 's'` (string) but the value starts with `=`.
2. Check cells where the value is a string beginning with `=` but `cell.value` is not being
   interpreted as a formula by openpyxl.
3. Flag every instance — this is **always** a bug when detected.

### 2b. Static Snapshot Detection

Identify cells that contain hard-coded numbers where a live formula is expected:
1. For each cell containing a numeric constant (no formula):
   - Check the **row label**: Does it say "Total", "Subtotal", "Sum", "Net", "Gross",
     "Balance", "Variance", "Growth", "Change", "Ratio", "Margin", "EBITDA", "EBIT", "NPAT",
     "FCF", "DSCR", "IRR", "NPV", "WACC", or any other term that implies a *calculation*?
   - Check the **column header**: Is it in a time-series area (FY2024, Q1, Jan, etc.) where
     other cells in the same row have formulas?
   - If the row label implies a calculation AND the cell contains a constant → **Flag it**.
2. Additional pattern: If a row has formulas in some columns but constants in others (mixed
   row), flag the constants as likely static snapshots.

### 2c. Uniform Value Detection

AI sometimes writes the same computed value into every cell of a row (copy-pasting a Python
variable):
1. For each row in a time-series area, check if all numeric values are **identical** (to 10+
   decimal places).
2. If a row labelled "Revenue", "Cost", "Growth", etc. has the exact same value in every
   period → **Flag it** as a likely static fill.
3. **Exception:** Rows labelled "Rate", "Assumption", "Input", or "Constant" may legitimately
   have uniform values.

---

## Phase 3 — REFERENCE ACCURACY SCAN

### 3a. SUM Range Boundary Check

AI consistently makes off-by-one errors in SUM formulas:
1. For every SUM formula, extract the range (e.g., `SUM(B5:B15)`).
2. Check: Does the range **include the header row**?
3. Check: Does the range **miss the last data row**? — *judgment-only*
4. Check: Does the range **include a subtotal from another section** it shouldn't? — *judgment-only*
5. Check: Does the range **include its own cell** (circular reference)?

### 3b. Absolute vs Relative Reference Audit

AI tends to over-use absolute references (`$A$1`) or use them inconsistently:
1. For each formula in a time-series (horizontally repeating) area:
   - Check if references that *should* be relative (e.g., prior period values) are incorrectly
     absolute.
   - Check if references that *should* be absolute (e.g., assumption cells, rates) are
     incorrectly relative.
2. Pattern: If every cell in a row has the exact same formula (not adjusting for column
   position), the AI likely used all-absolute references when some should be relative.

### 3c. Cross-Sheet Reference Validation — *judgment-only*

1. For every formula referencing another sheet, verify the referenced cell contains a value.
2. Check for common AI patterns:
   - Referencing `Sheet1!A1` when the data is actually on `Sheet1!A2` (off-by-one from header).
   - Referencing a summary row instead of the detail row (or vice versa).
   - Multiple sheets referencing different source cells for what should be the same value.

### 3d. Lookup Function Argument Check — *judgment-only*

AI frequently gets lookup arguments wrong:
1. **VLOOKUP**: Check that `col_index_num` (3rd argument) corresponds to the correct column in
   the lookup range. Count columns in the lookup array and verify.
2. **INDEX/MATCH**: Verify the MATCH lookup array and INDEX return array are the same size and
   orientation.
3. **XLOOKUP**: Verify lookup_array and return_array are the same dimension.
4. **All lookups**: Check that the `match_type` / `[if_not_found]` argument is appropriate
   (exact match vs approximate).

---

## Phase 4 — DATA TYPE INTEGRITY SCAN

### 4a. Text-Masquerading-as-Number Detection

AI tools (especially openpyxl) frequently write numeric values as text strings:
1. For every cell with `data_type == 's'` (string), check if the value can be parsed as a
   number (int, float, percentage, currency).
2. If yes → **Flag it**. The value will not participate in SUM formulas and will silently
   produce wrong results.
3. Common patterns: `"1000"`, `"0.05"`, `"100%"`, `"$1,000"`, `"1,000,000"`.

### 4b. Date Serialisation Check

1. Check cells in date-labelled rows/columns for text strings that look like dates (e.g.,
   `"2024-01-01"`, `"01/01/2024"`, `"Jan 2024"`).
2. Check for Excel serial numbers stored as text.
3. Verify date cells use `datetime` objects (openpyxl) or proper date serial numbers, not
   text strings.

### 4c. Boolean Value Check

1. Check for the text strings `"TRUE"` / `"FALSE"` stored as text instead of actual boolean
   values.
2. Check for `1` / `0` in flag rows that should be `TRUE` / `FALSE` (or vice versa, depending
   on model convention). — *judgment-only*

---

## Phase 5 — FORMATTING CONSISTENCY SCAN

### 5a. Number Format Coverage

1. Check if the model has any number formatting at all. AI tools frequently write values with
   no number format (everything shows as `General`).
2. Identify cells where the value type implies a specific format:
   - Percentages (values between -1 and 1 in rows labelled "%", "Rate", "Margin", "Growth") →
     Should have `0.00%` or similar.
   - Currency / monetary values → Should have `#,##0` or similar.
   - Dates → Should have a date format.
   - Ratios (DSCR, multiples) → Should have `0.00x` or `#,##0.00`.
3. Flag cells where the format is `General` but content implies a specific format.

### 5b. Colour Coding Consistency — *judgment-only*

1. Check if the model uses any colour coding at all. AI often produces entirely unformatted
   models.
2. If colour coding exists, verify:
   - Input/assumption cells are consistently formatted (same font colour + fill colour).
   - Formula cells are consistently formatted.
   - Header cells are consistently formatted.
3. Flag blocks where formatting suddenly changes without a logical reason.

### 5c. Column Width & Row Height — *judgment-only*

1. Check if all columns are set to default width (AI often forgets to auto-fit).
2. Flag columns where the data is wider than the column (content would be truncated or show
   `####`).

---

## Phase 6 — MISSING BEST-PRACTICE CHECKS

### 6a. Error Handling Gaps

1. Scan for VLOOKUP, HLOOKUP, INDEX/MATCH, XLOOKUP formulas without IFERROR/IFNA wrappers.
2. Scan for division formulas without divide-by-zero protection.
3. Flag each unprotected lookup or division.

### 6b. Named Range Hygiene

1. Check for named ranges that point to `#REF!` or deleted cells.
2. Check for duplicate named ranges with conflicting definitions. — *judgment-only*
3. Check for named ranges that are defined but never used in any formula. — *judgment-only*

### 6c. Data Validation Gaps — *judgment-only*

1. Check if input/assumption cells have data validation rules.
2. Flag input cells that accept any value but should be constrained (e.g., a "Yes/No" input
   with no validation list).

### 6d. Print Setup

1. Check if any print areas are defined.
2. Check if page orientation, scaling, and margins are set (AI almost never does this).

---

## Report format

### Summary statistics

Before the findings table, provide (the scanner emits this block automatically):

```
AI Audit Summary
═══════════════════════════════════════════
Total cells scanned:          [count]
Formulas found:               [count]
Constants found:              [count]
Text cells found:             [count]

Critical AI Errors:
  Formula-as-text:            [count]
  Static snapshots:           [count]
  Text-as-number:             [count]
  Broken sheet references:    [count]

Structural Issues:
  Empty placeholder rows:     [count]
  Orphaned references:        [count]
  SUM boundary errors:        [count]

Formatting Gaps:
  Missing number formats:     [count]
  Inconsistent formatting:    [count]

Overall AI Build Quality:     [PASS / FAIL / CRITICAL FAIL]
```

**Scoring:**
- **PASS**: 0 Critical AI Errors, ≤5 Structural Issues, ≤10 Formatting Gaps
- **FAIL**: 1–5 Critical AI Errors, OR >5 Structural Issues
- **CRITICAL FAIL**: >5 Critical AI Errors, OR any Formula-as-text errors, OR >50% of
  "calculation" rows contain static snapshots

### Findings table

Use the unified findings table; format, severity scale, and the Grouping Rule are in
`../../_excel-shared/references/audit_standards.md` (§1, §3, §4).

---

## Error categories

Use exactly these values in the findings table's Category column:

| Category | Description |
|---|---|
| **Formula-as-Text** | Cell value starts with `=` but is stored as a text string, not a live formula. Always critical. |
| **Static Snapshot** | Cell contains a hard-coded number where a live formula is expected based on its row label/context. |
| **Uniform Value Fill** | Entire time-series row contains identical values, suggesting AI pasted a Python variable rather than writing formulas. |
| **SUM Boundary Error** | SUM range includes headers, misses data rows, or includes unrelated sections. |
| **Orphaned Reference** | Formula references an empty cell or a cell outside the used range. |
| **Broken Sheet Link** | Formula references a sheet that doesn't exist or uses unquoted sheet names with spaces. |
| **Text-as-Number** | Numeric value stored as text string — invisible to SUM formulas and comparisons. |
| **Date-as-Text** | Date value stored as text string instead of a datetime/serial number. |
| **Boolean-as-Text** | TRUE/FALSE stored as text instead of boolean. |
| **Reference Type Error** | Absolute reference used where relative is needed (or vice versa), causing formulas not to adjust across periods. |
| **Lookup Argument Error** | VLOOKUP col_index, INDEX/MATCH dimensions, or match_type is incorrect. |
| **Empty Placeholder** | Row has a label but no formulas or values in the data area — AI created structure but forgot content. |
| **Missing Error Handling** | Lookup or division formula lacks IFERROR/IFNA/divide-by-zero protection. |
| **Number Format Gap** | Cell has no number format despite content implying one (percentage stored as decimal with General format). |
| **Formatting Inconsistency** | Formatting changes abruptly within a logical block without reason. |
| **Missing Print Setup** | No print areas, page breaks, or orientation settings defined. |
| **Dead Named Range** | Named range points to #REF! or deleted cells. |
| **Unused Named Range** | Named range is defined but never referenced in any formula. |

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. AI-Auditor calibration (the scanner's
internal CRITICAL/HIGH grades both map to Critical):

- **Critical** — model produces wrong outputs or contains likely errors: formula-as-text,
  static snapshots, text-as-number, broken references, SUM boundary errors, empty placeholder
  rows, dead named ranges, lookup argument errors.
- **Warning** — suspicious; may cause problems in some scenarios: mixed-row snapshots,
  uniform value fills, date-as-text, all-identical time-series formulas.
- **Info** — best-practice gap: missing error handling, number format gaps, boolean-as-text,
  print setup, validation gaps.

## Special rules

- **Never modify values or formulas** — report only.
- **Prioritise Critical findings first** — if the model has Formula-as-Text or massive Static
  Snapshot issues, lead with those. They make every other finding moot.
- **Context matters for Static Snapshot**: A cell labelled "Input" or "Assumption" is
  *supposed* to be a constant. Only flag constants in rows whose labels imply calculations.
- **Test the model's arithmetic**: For key output rows (NPV, IRR, Total, Net Income), manually
  verify the value matches what the formula *should* produce. If the static value doesn't even
  match the inputs, it's a **confirmed** snapshot error.
- Cell references follow the Grouping Rule in `audit_standards.md` §4 — never "...", "etc.",
  or truncated lists.
- If no AI-specific errors are found, state: *"✅ No issues detected. The model appears to
  contain live formulas and correct data types. Recommend running the standard audit suite
  (Logic, Sentry, Stylist) for business logic validation."*

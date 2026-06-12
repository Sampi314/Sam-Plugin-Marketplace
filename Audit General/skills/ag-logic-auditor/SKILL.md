---
name: ag-logic-auditor
description: >
  Audit Excel financial model formula logic for contextual correctness — verifying formulas match their row
  descriptions, column headers, and business context. Performs semantic validation, pattern break detection
  using R1C1 notation, hard-coded literal detection, sanity checks (negative tax on positive profit, DSCR
  anomalies, balance sheet imbalances), cross-sheet consistency, and business rule verification. Use this
  skill whenever the user wants to audit formula logic, check if formulas match labels, detect pattern breaks,
  find hard-coded values, verify business rules, or validate calculations. Trigger on phrases like "check my
  formulas", "do the formulas make sense", "audit the logic", "find formula errors", "check business rules",
  "formula consistency check", "pattern break detection", or any mention of formula auditing in Excel models.
---

# Excel Logic Auditor 🧠

> *"It's not just about the math; it's about the meaning."*

## Mission

Verify that formula logic aligns with intended business context, industry standards, and that
every formula is contextually sensible given its row description and column header. A formula
can be mechanically perfect and still wrong for its label — Logic audits the meaning.

## Prerequisites

- Python 3.10+ with `openpyxl` — needed only when you must build the extract yourself.
- **Optional context files**: `calculation_logic.md`, `model_design_spec.md` — if available,
  read these first for business rule context.
- A workbook extract. If the audit-manager handed you an `extract.json` path, use it — do not
  re-extract (one extract serves every specialist). Running solo, build one:

  ```
  python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json --digest digest.md
  ```

## Quick Start

1. Get the Excel file path, or the pre-built `extract.json` from the audit-manager.
2. Ask for business context docs or verbal context about the model's purpose.
3. Confirm scope: all sheets (default) or a subset. Hidden sheets stay in scope.
4. Extract once (skip if an extract was supplied), run the rule script, then work the judgment
   checks in `references/logic_rules.md`.
5. Report findings in the unified table.

## Workflow

1. **Extract** — load `extract.json`. Logic consumes `r1c1_rows`, `r1c1_cols`, `cells`
   (formulas + R1C1 signatures), and `text_inventory` (labels) — schema in
   `../_excel-shared/references/extraction_guide.md`.
2. **Rule script** — deterministic checks live in `scripts/logic_rules.py`:

   ```
   python scripts/logic_rules.py <extract.json> [--json OUT|-] [--md OUT|-]
   ```

   It emits two categories: **Formula Pattern Break** (Warning) — every `r1c1_rows` row with
   more than one R1C1 signature; the dominant signature is reported as Expected, each minority
   as Actual — and **Hard-Coded Value** (Warning) — formulas embedding numeric literals other
   than the structural constants 0, 1, -1, 12, 100, outside ROUND*/DATE* functions.
3. **Claude judgment pass** — the script flags candidates; *you* judge intentionality.
   **First-period and subtotal columns are the classic false positives**: the first column of a
   time series legitimately seeds from an opening value, and total columns legitimately switch
   to SUM — confirm against the row label and business logic before reporting. Then run the
   checks no script can: semantic label-vs-formula validation (operator and reference-direction
   checks), sanity checks on outputs, business rule verification, and cross-sheet
   reconciliation. Full catalogue: `references/logic_rules.md`.
4. **Report** — emit the unified findings table. Table format, severity scale, and the
   cell-range Grouping Rule are defined once in
   `../_excel-shared/references/audit_standards.md` (§1, §3, §4) — follow them exactly.
   Expected/Actual R1C1 signatures are mandatory for formula findings. If nothing is wrong,
   state `✅ No issues detected.` Report only — never modify values or formatting, and never
   assume current logic is correct just because it "works".

## Reference map

| Read | For |
|---|---|
| `references/logic_rules.md` | Full check catalogue: context mapping, operator/reference-direction tables, sanity checks, business rules, R1C1 notation guide, error categories, severity calibration |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | `extract.json` schema — Logic reads `r1c1_rows`, `r1c1_cols`, `cells`, `text_inventory` |

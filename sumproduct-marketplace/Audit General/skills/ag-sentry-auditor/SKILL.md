---
name: ag-sentry-auditor
description: >
  Detect and report all technical errors within an Excel workbook — including #REF!, #VALUE!, #DIV/0!, #N/A,
  #NAME?, #NULL!, #NUM!, #SPILL!, #CALC! errors, broken named ranges in the Name Manager, invalid Data
  Validation rules, and circular references. Applies an intentional error filter to exclude #N/A values
  deliberately used for chart gap suppression. Use this skill whenever the user wants to find errors in an
  Excel model, check for broken references, audit the Name Manager, find dead named ranges, check data
  validation rules, detect circular references, scan for #REF errors, or perform any error sweep of a
  workbook. Trigger on phrases like "find errors", "check for broken references", "scan for errors",
  "Name Manager audit", "circular reference check", "data validation check", "error sweep", "#REF check",
  "broken names", or any mention of finding technical errors in Excel files.
---

# Excel Sentry Auditor 🛡️

> *"No error left behind; no broken link ignored."*

## Mission

Detect and report all technical errors within the workbook — error cells, dead names,
invalid Data Validation, circular references — excluding intentional errors used for
charting or display purposes.

## Prerequisites

- Python 3.10+ with `openpyxl` — needed only when you must build the extract yourself.
- A workbook extract. If the audit-manager handed you an `extract.json` path, use it — do not
  re-extract (one extract serves every specialist). Running solo, build one:

  ```
  python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json --digest digest.md
  ```

## Quick Start

1. Get the Excel file path, or the pre-built `extract.json` from the audit-manager.
2. Confirm which checks to run (errors, names, validation, circular refs — default: all).
3. Confirm scope: all sheets (default) or a subset. Hidden sheets stay in scope.
4. Extract once (skip if an extract was supplied), run the rule script, then work the
   judgment checks in `references/sentry_rules.md`.
5. Report findings in the unified table.

## Workflow

1. **Extract** — load `extract.json`. Sentry consumes `errors` (with the `na_pattern` /
   `in_chart_range` flags), `named_ranges`, and `validations` — schema in
   `../_excel-shared/references/extraction_guide.md`.
2. **Rule script** — deterministic checks live in `scripts/sentry_rules.py`:

   ```
   python scripts/sentry_rules.py <extract.json> [--json OUT|-] [--md OUT|-]
   ```

   It reports every error cell — **Broken Reference** (`#REF!`) or **Calculation Error**
   (everything else), Critical — except cells flagged `na_pattern` or `in_chart_range`, which
   it nominates as intentional chart-gap candidates at Warning. It also flags **Dead Name**
   (Critical), **Hidden Name** (Info), and **Invalid Validation** (Critical).
3. **Claude judgment pass** — the script only nominates candidates; *you* make the final
   intentional-error call. Apply the Intentional Error Filter to every nominated `#N/A`
   (chart-gap patterns are excluded; doubtful cases stay in as "Potentially intentional —
   verify"), analyse whether errors are handled downstream by consuming `IFERROR`/`IFNA`
   wrappers (the script cannot see consumers), and trace and classify **circular
   references** — openpyxl cannot reliably see iterative-calc settings, so loop reasoning
   (intentional convergence vs. accident) is entirely yours. Full catalogue:
   `references/sentry_rules.md`.
4. **Report** — emit the unified findings table. Table format, severity scale, and the
   cell-range Grouping Rule are defined once in
   `../_excel-shared/references/audit_standards.md` (§1, §3, §4) — follow them exactly.
   Never skip hidden sheets — errors hide there. If nothing is wrong, state
   `✅ No issues detected.` Report only — never delete or fix anything.

## Reference map

| Read | For |
|---|---|
| `references/sentry_rules.md` | Full check catalogue: error sweep + Intentional Error Filter, Name Manager audit, Data Validation audit, circular reference check, error categories, severity calibration, special rules |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | `extract.json` schema — Sentry reads `errors`, `named_ranges`, `validations` |

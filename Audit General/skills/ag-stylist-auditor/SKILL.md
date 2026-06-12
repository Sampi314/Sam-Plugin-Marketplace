---
name: ag-stylist-auditor
description: >
  Audit Excel financial model formatting and presentation for consistency — dynamically detecting the
  model's own style convention (via Style Guide sheets, named Cell Styles, or statistical inference)
  then enforcing it. Checks colour coding (input vs formula vs link vs header cells), number
  formats against row/column context (percentages left as General, dates as numbers), alignment,
  borders, and hard-coded values missing input formatting. Use whenever the user
  wants to check formatting consistency, audit cell colours, verify number formats, check style
  conventions, review presentation quality, or find formatting errors. Trigger on "check formatting",
  "audit colours", "check number formats", "formatting consistency", "style audit", "colour coding
  check", "presentation review", "are inputs formatted correctly", or any mention of formatting,
  styling, or visual consistency in Excel models.
---

# Excel Stylist Auditor 🎨

> *"Style is the signature of quality; structure is the foundation of trust."*

## Mission

Ensure the Excel model adheres to its **own** formatting standards — detected dynamically, never
assumed — and that every cell's number format is contextually appropriate given its row description
and column header. Detection always comes before enforcement: there is no fixed colour standard.

## Prerequisites

- Python 3.10+ with `openpyxl` — needed only when you must build the extract yourself.
- A workbook extract. If the audit-manager handed you an `extract.json` path, use it — do not
  re-extract (extraction is the expensive step; one extract serves every specialist). Running
  solo, build one:

  ```
  python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json --digest digest.md
  ```

## Quick Start

1. Get the Excel file path, or the pre-built `extract.json` from the audit-manager.
2. Confirm scope: all sheets (default) or a subset. Hidden sheets stay in scope.
3. Extract once (skip if an extract was supplied).
4. Run the rule script, then work the judgment checks in `references/stylist_rules.md`.
5. Report findings in the unified table, opening with the Style Convention Summary.

## Workflow

1. **Extract** — load `extract.json`. Stylist consumes `cells` (style/fmt/font/fill), `styles`,
   `text_inventory`, and `conditional_formatting` (schema in
   `../_excel-shared/references/extraction_guide.md`).
2. **Rule script** — deterministic checks live in `scripts/stylist_rules.py`:

   ```
   python scripts/stylist_rules.py <extract.json> [--json OUT|-] [--md OUT|-] [--convention OUT|-]
   ```

   It always runs convention detection (style-guide sheet lookup, named Cell Style census,
   statistical font/fill inference with confidence %) and emits deviation candidates: **Colour
   Coding** warnings (constants styled as formulas, formulas styled as inputs) and **Number
   Format** warnings (row context implies %, date, or currency but the format disagrees).
   `--convention` writes the Style Convention Summary block that opens every report. Detected
   style-guide sheets are skipped in the deviation scan — a legend deliberately shows every style.
3. **Claude judgment pass** — the script is deterministic only; you adjudicate. Read the
   style-guide legend itself when one is detected, settle below-threshold (<75% confidence)
   conventions cell by cell or with the user, apply heading exemptions (a heading containing a
   number is not a hard-coded input), and run the checks no script can: alignment consistency,
   border patterns, and number-format tolerance calls (`0.0%` vs `0.00%` is minor). Full
   catalogue: `references/stylist_rules.md`.
4. **Report** — Style Convention Summary first, then the unified findings table. Table format,
   severity scale, and the cell-range Grouping Rule are defined once in
   `../_excel-shared/references/audit_standards.md` (§1, §3, §4) — follow them exactly. If
   nothing is wrong, state `✅ No issues detected.` Report only — never modify the workbook;
   never assess formula logic (that is the Logic auditor's job).

## Reference map

| Read | For |
|---|---|
| `references/stylist_rules.md` | Detection cascade, scan phases, number-format context table, error categories, severity calibration |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | `extract.json` schema — Stylist reads `cells`, `styles`, `text_inventory`, `conditional_formatting` |

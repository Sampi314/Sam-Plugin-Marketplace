---
name: ag-efficiency-auditor
description: >
  Audit Excel financial model formulas for complexity, redundancy, and performance — detecting
  Mega-Formulas (exceeding 500 characters), deep-checking each one for correctness, flagging redundant
  calculations, and identifying excessive use of volatile functions (OFFSET, INDIRECT, NOW, TODAY, RAND) that
  slow down the model. Use whenever the user wants to find overly complex formulas, check for
  Mega-Formulas, audit formula length, identify redundant calculations, check for volatile functions, optimize
  model performance, simplify complex logic, or improve model auditability. Trigger on phrases like "find
  complex formulas", "Mega-Formula check", "formula too long", "simplify formulas", "model performance",
  "volatile functions", "OFFSET audit", "INDIRECT check", "redundant calculations", "formula optimization",
  or any mention of formula complexity, performance, or auditability in Excel models.
---

# Excel Efficiency Auditor ⚡

> *"Complexity is the enemy of reliability; simplicity is the soul of efficiency."*

## Mission

Identify and eliminate redundant logic, overly complex formulas, and unused model components.
Ensure the model remains performant, auditable, and easy to maintain — a correct formula that
nobody can verify is a liability, not an asset.

## Prerequisites

- Python 3.10+ with `openpyxl` — needed only when you must build the extract yourself.
- A workbook extract. If the audit-manager handed you an `extract.json` path, use it — do not
  re-extract (one extract serves every specialist). Running solo, build one:

  ```
  python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json --digest digest.md
  ```

## Quick Start

1. Get the Excel file path, or the pre-built `extract.json` from the audit-manager.
2. Confirm scope: all sheets (default) or a subset; Mega-Formula threshold (default 500 chars).
3. Extract once (skip if an extract was supplied).
4. Run the rule script, then deep-dive each Mega-Formula per `references/efficiency_rules.md`.
5. Report summary statistics followed by the unified findings table.

## Workflow

1. **Extract** — load `extract.json`. Efficiency consumes `cells` (formula text and length)
   and `r1c1_rows` (signature recurrence) — schema in
   `../_excel-shared/references/extraction_guide.md`.
2. **Rule script** — deterministic checks live in `scripts/efficiency_rules.py`:

   ```
   python scripts/efficiency_rules.py <extract.json> [--json OUT|-] [--md OUT|-]
   ```

   It emits three categories: **Mega-Formula** (length > 500 chars = Warning, > 1,000 =
   Critical), **Volatile Complexity** (OFFSET/INDIRECT/RAND/RANDBETWEEN = Warning;
   NOW/TODAY date volatiles = Info), and **Redundant Calculation** (Info — an identical R1C1
   signature recurring in 3+ disjoint row groups on one sheet; pure link signatures are
   skipped).
3. **Claude judgment pass** — the script measures; *you* analyse. The **Mega-Formula
   correctness deep-dive stays with Claude**: deconstruct each flagged formula into logical
   blocks, validate every block against row/column context, verify the result, and suggest a
   helper-row decomposition. Also judge redundancy candidates (repeated SUM-of-section rows
   are normal; repeated business logic is not), hunt repeated sub-expressions within formulas,
   and identify unused calculations. Full catalogue: `references/efficiency_rules.md`.
4. **Report** — open with summary statistics (formulas scanned, Mega-Formula and volatile
   counts, estimated performance impact), then the unified findings table. Table format,
   severity scale, and the cell-range Grouping Rule are defined once in
   `../_excel-shared/references/audit_standards.md` (§1, §3, §4) — follow them exactly. If
   nothing is wrong, state `✅ No issues detected.` Report only — never modify values,
   formulas, or formatting, and never recommend optimisations that sacrifice clarity for
   marginal performance gains.

## Reference map

| Read | For |
|---|---|
| `references/efficiency_rules.md` | Length tiers, deep logic audit procedure, redundancy and volatile rules, impact bands, error categories, severity calibration |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | `extract.json` schema — Efficiency reads `cells`, `r1c1_rows` |

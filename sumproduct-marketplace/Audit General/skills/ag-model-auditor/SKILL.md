---
name: ag-model-auditor
description: >
  Comprehensive Excel financial model auditor using pywin32 COM automation. Performs formula consistency checks,
  semantic logic validation (detecting mismatches between cell formulas and row/column labels), formatting audits,
  data validation reviews, hyperlink checks, Name Manager analysis, plus VBA, Power Query, and Power Pivot code
  review. Generates structured audit reports (Excel, Markdown, HTML). Use whenever the user wants to audit,
  review, check, or validate an Excel model or workbook — including "check my model", "audit this spreadsheet",
  "find formula errors", "review formatting consistency", "check for broken links", "validate my Excel file",
  "review VBA code", or any mention of model auditing, formula checking, spreadsheet review, or Excel quality
  assurance. Also trigger when users mention checking if formulas match their labels or finding inconsistencies
  in a financial model.
---

# Excel Model Auditor 🔍

> *"An unaudited model is just a rumour with formatting."*

## Mission

Deep single-script inspection of an Excel workbook via pywin32 COM: formula
consistency, semantic logic, formatting, data validation, hyperlinks, Name
Manager, VBA, Power Query, and Power Pivot — one run, one structured report.

**Role**: standalone single-pass auditor — for a coordinated multi-specialist
audit with consolidation use `ag-audit-manager`; this skill is the quick
one-shot alternative. For a client-ready walkthrough document built from
consolidated findings, see `ag-detailed-audit-report`.

## Prerequisites

- **Windows OS** with Excel installed (the script drives Excel through COM)
- **Python packages**: `pywin32`, `openpyxl` (report generation)
- Install if needed: `pip install pywin32 openpyxl --break-system-packages`

## Quick Start

1. Get the Excel file path from the user (the script attaches to an already-open
   workbook, or opens it read-only itself).
2. Confirm scope: which checks, which sheets, which output format — default is
   all checks, all sheets, `xlsx`.
3. Run the auditor:

   ```bash
   python scripts/excel_auditor.py <file.xlsx> [--sheets "A,B"] [--checks "formula,format,..."] \
       [--output-format xlsx|md|html] [--output-path DIR] [--severity all]
   ```

4. Do the AI judgment pass on `ambiguous_formulas_<workbook>.json` (see below).
5. Present the report and discuss findings.

## Workflow

1. **Deterministic pass — the script.** `scripts/excel_auditor.py` runs the
   full check catalogue (formula pattern breaks, hardcoded values, semantic
   rules R001–R012, formatting consistency, hyperlinks, names, validation,
   VBA/PQ/PP review). Read `references/model_auditor_rules.md` for the complete
   catalogue, category list, CLI options, and edge cases before running.
2. **Judgment pass — Claude.** The script handles only what regexes can decide;
   judgment calls stay with you: review `ambiguous_formulas_<workbook>.json`
   (formulas matching no rule but looking suspicious), apply semantic reasoning
   against `references/semantic_rules.md`, filter intentional exceptions, and
   add Warning findings where label and formula genuinely disagree.
3. **Report.** Findings use the unified specialist table — read
   `../_excel-shared/references/audit_standards.md` for the column format,
   severity scale (🔴 Critical / ⚠️ Warning / 🟡 Info), Grouping Rule, and the
   findings JSON schema. The script emits one row per affected cell; group
   same-issue cells into ranges per the standards when presenting or
   consolidating. If nothing is found, state `✅ No issues detected.`

## Outputs

| File | Purpose |
|------|---------|
| `Audit_Report_<workbook>_<stamp>.xlsx\|md\|html` | Human-readable report in the requested format |
| `audit_findings_<workbook>.json` | Interchange JSON (audit_standards.md §5, `agent: "model-auditor"`) |
| `ambiguous_formulas_<workbook>.json` | Queue for the AI judgment pass |

## Reference map

| Read | For |
|------|-----|
| `references/model_auditor_rules.md` | Full check catalogue, category table, CLI options, judgment-pass procedure, edge cases |
| `references/semantic_rules.md` | Label-vs-formula semantic rules R001–R012 + ambiguous-case taxonomy |
| `../_excel-shared/references/audit_standards.md` | Findings table format, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | extract.json sections — relevant when running inside an orchestrated `ag-audit-manager` audit that shares one extraction |

Auditors report only — never modify the model without explicit instruction.
Hidden sheets, rows, and columns are always in scope: errors hide there.

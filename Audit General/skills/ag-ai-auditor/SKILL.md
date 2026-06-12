---
name: ag-ai-auditor
description: >
  Audit Excel financial models built by AI tools (Claude, GPT, Copilot) for the specific errors LLMs
  commonly introduce via openpyxl/pywin32: formula-as-text (string formulas missing =), static snapshots
  where live formulas should exist, SUM boundary errors, orphaned references, broken cross-sheet links,
  text-masquerading-as-numbers, date serialisation errors, absolute/relative reference confusion, empty
  placeholder rows, lookup argument errors, missing error handling, and formatting inconsistencies. Use
  whenever checking an AI-built model, verifying AI-generated Excel output, or reviewing any workbook
  produced by an LLM. Trigger on "check AI model", "audit AI-built Excel", "verify openpyxl output",
  "AI model quality check", "validate AI Excel", "check Claude's model", "GPT built this", or any
  mention of reviewing an Excel file created by AI.
---

# Excel AI Auditor 🤖🔍

> *"Trust but verify — especially when the builder doesn't understand what it built."*

## Mission

Detect and report the specific class of errors that AI tools (LLMs using openpyxl, pywin32,
xlsxwriter, etc.) commonly introduce when building Excel financial models. These errors differ
from human errors — they arise from the fundamental disconnect between *generating code that
writes cells* and *understanding what the spreadsheet should do*. The workbook *looks* complete,
but formulas may be dead text, links broken, and numbers static snapshots.

## Prerequisites

- Python 3.10+ with `openpyxl` (`pip install openpyxl --break-system-packages` if missing).
- The workbook itself — unlike the other specialists, the AI Auditor's scanner reads the
  `.xlsx`/`.xlsm` directly with openpyxl; no `extract.json` required (it inspects data types
  and stored values that the shared extract does not carry).

## Quick Start

1. Get the Excel file path from the user (or the audit-manager).
2. Run the scanner: `python scripts/ai_audit_scanner.py <model.xlsx>`.
3. Review the raw findings and apply contextual judgment (see Workflow step 3).
4. Present the report: summary statistics block, then the unified findings table.

## Workflow

1. **Locate the workbook** — confirm the path with the user; `.xlsx`/`.xlsm` expected.
2. **Rule script** — the deterministic scan lives in `scripts/ai_audit_scanner.py`:

   ```
   python scripts/ai_audit_scanner.py <filepath> [--sheet SHEET_NAME ...] [--output OUTPUT_PATH]
   ```

   `--sheet` limits the scan to named sheet(s) (default: all); `--output` writes the markdown
   report to a file (default: stdout). The scanner runs the full check catalogue —
   formula-as-text, static snapshots, uniform value fills, text/date/boolean-as-text, empty
   placeholders, broken sheet references, SUM boundary errors, missing error handling, number
   format gaps, absolute/relative reference audit, print setup, dead named ranges — and emits
   the summary statistics block, the PASS/FAIL quality score, and the unified findings table.
   If the script is unavailable, perform the checks manually with openpyxl following
   `references/ai_rules.md`.
3. **Claude judgment pass** — the scanner is keyword-driven; *you* filter and confirm.
   Constants in rows labelled "Input"/"Assumption" are *supposed* to be constants — only
   uphold Static Snapshot findings where the label implies a calculation. For key output rows
   (NPV, IRR, Total, Net Income), manually verify the value matches what the formula *should*
   produce — a static value that doesn't even tie to the inputs is a **confirmed** snapshot.
   Run the judgment-only checks the scanner skips: orphaned cell references, lookup argument
   verification (VLOOKUP col_index, INDEX/MATCH dimensions), cross-sheet off-by-one targets,
   colour-coding consistency. Full catalogue: `references/ai_rules.md`.
4. **Report** — summary statistics first, then the unified findings table. Table format,
   severity scale, and the cell-range Grouping Rule are defined once in
   `../_excel-shared/references/audit_standards.md` (§1, §3, §4) — follow them exactly.
   Prioritise Critical findings: if the model has formula-as-text or mass static snapshots,
   lead with those — they make every other finding moot. If nothing is wrong, state
   `✅ No issues detected.` and recommend the standard audit suite (Logic, Sentry, Stylist)
   for business-logic validation. Report only — never modify values or formulas.

## Reference map

| Read | For |
|---|---|
| `references/ai_rules.md` | AI failure-mode table, all six detection phases, summary/scoring format, error categories, severity calibration |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | `extract.json` schema — context if running inside an orchestrated audit (the scanner itself reads the workbook directly) |

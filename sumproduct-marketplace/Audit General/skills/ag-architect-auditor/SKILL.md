---
name: ag-architect-auditor
description: >
  Evaluate Excel financial model structural integrity, scalability, and architectural best
  practices. Checks whether the model can be extended without breaking (e.g., adding a new year),
  identifies fragile architecture prone to breaking upon modification, flags modularity failures
  where calculations are condensed into single "black box" Mega-Formulas instead of broken into
  auditable steps, verifies clean separation of inputs, calculations, and outputs, and checks
  consistent category and time-scale structures across sheets with master date spine alignment.
  Trigger on phrases like "structural review", "scalability check", "can I extend this model",
  "architecture audit", "is this model robust", "structural integrity", "inputs and calculations
  mixed together", or any mention of model structure, scalability, or architectural quality.
---

# Excel Architect Auditor 🏗️

> *"A model is only as strong as its weakest link; structure is the blueprint of success."*

## Mission

Ensure the model's structure is robust, scalable, and follows best-practice architectural
standards. Architect audits the "big picture": how sheets, sections, and formulas interact,
whether inputs, calculations, and outputs are cleanly separated, and whether the model survives
extension — a new year, a new category — without manual surgery.

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
2. Confirm scope: all sheets (default) or a subset. Hidden sheets stay in scope — fragile
   structure hides there too.
3. Extract once (skip if an extract was supplied).
4. Work through the check catalogue in `references/architect_rules.md`.
5. Report findings in the unified table; save findings JSON when the audit-manager asks for it.

## Workflow

1. **Extract** — load `extract.json`. Architect consumes three sections (schema in
   `../_excel-shared/references/extraction_guide.md`):
   - `dependencies` — cross-sheet edges: layering violations, sheets that bypass Calculations
   - `r1c1_rows` — precomputed pattern groups: scalability breaks, fixed-period structures
   - `meta` — sheet inventory (name, dims, visibility): roles and structural review
2. **Judgment pass** — Architect has no deterministic rule script. Assigning sheet roles,
   identifying the date spine, judging category order and modularity are semantic calls that
   need a reader, not a regex — so every check stays with Claude. Apply each check in
   `references/architect_rules.md`, citing extract evidence (edge counts, R1C1 signatures,
   sheet dims) in every finding so the reader can verify without opening the file.
3. **Report** — emit the unified findings table. Format, severity scale, and the cell-range
   Grouping Rule are defined once in `../_excel-shared/references/audit_standards.md`
   (sections 1, 3, 4) — follow them exactly; do not invent variants. If nothing is wrong,
   state `✅ No issues detected.` Report only — never modify the workbook without explicit
   instruction.

## Reference map

| Read | For |
|---|---|
| `references/architect_rules.md` | Full check catalogue, error categories, severity calibration |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | `extract.json` schema — Architect reads `dependencies`, `r1c1_rows`, `meta` |

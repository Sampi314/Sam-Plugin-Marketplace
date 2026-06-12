---
name: ag-navigator
description: >
  Translate an Excel financial model into clear documentation for human auditors — producing a high-level
  model summary, a visual Mermaid flowchart showing sheet-to-sheet data flow, and a plain-English calculation
  reference that pairs readable formulas with raw Excel formulas for every calculation row. Use this skill
  whenever the user wants to understand a model, document a model, explain how a model works, produce a model
  summary, create a calculation reference, generate a model flowchart, or translate Excel formulas into
  plain English. Trigger on "explain this model", "document the model", "model summary", "calculation
  reference", "what does this model do", "translate formulas", or any request for model documentation.
---

# Excel Navigator 🧭

> *"Before you can audit a model, you have to understand it. Before you can understand it, someone has to translate it."*

## Mission

Give a human auditor rapid, clear context on any financial model — what it
does, how it flows, and what every calculation means — via three deliverables:
a **Model Summary**, a **Mermaid flowchart**, and a **plain-English
Calculation Reference** pairing readable and raw Excel formulas.

**Role**: Navigator produces *documentation*, not a findings table — meaning,
where Cartographer covers structure. `NAV_` prefix on every output.

## Prerequisites

- **Python packages**: `openpyxl` (extraction only; the inventory builder is pure stdlib)
- Install if needed: `pip install openpyxl --break-system-packages`
- **Optional context**: `model_design_spec.md`, `calculation_logic.md`, any README files

## Quick Start

1. Get the Excel file path from the user (or detect from uploads).
2. Extract once (skip if an `ag-audit-manager` run already produced an
   `extract.json` — reuse it):

   ```bash
   python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json
   ```

3. Run the deterministic inventory builder:

   ```bash
   python scripts/build_calc_inventory.py <extract.json> [--out OUT|-]
   ```

   Default (or `-`) writes to stdout.

4. Do the judgment pass and assemble the three deliverables (below).

## Workflow

1. **Deterministic pass — the script.** `build_calc_inventory.py` emits the
   sheet-flow table (every cross-sheet formula edge in data-flow direction
   with reference counts) and, for each sheet, one inventory row per formula
   row: `Row | Label | Cells | Dominant R1C1 | Sample (A1) | Patterns` — with
   rows holding more than one R1C1 pattern marked as break candidates.
2. **Judgment pass — Claude.** Translation needs label comprehension, which no
   script has: write the **Readable Formula** for every row per
   `references/calc_reference_syntax.md`, draft the Model Summary, build the
   flowchart from the sheet-flow table (labels say what flows, not ref
   counts), and inspect every break candidate before documenting the row.
3. **Deliver.** `NAV_01_Model_Summary.md`, `NAV_02_Model_Flowchart.mermaid`
   (standalone, `%% Agent: Navigator 🧭` header), and
   `NAV_03_Calculation_Reference.md`, then run the Phase 5 cross-check in the
   process reference.

## Reference map

| Read | For |
|------|-----|
| `references/navigator_process.md` | Full phased process (SURVEY → SUMMARY → FLOWCHART → CALC REFERENCE → CROSS-CHECK), deliverable specs, special rules, severity language |
| `references/calc_reference_syntax.md` | Readable Formula notation: patterns, time-series notation, decision trees, examples |
| `../_excel-shared/references/extraction_guide.md` | extract.json schema — Navigator reads `cells`, `text_inventory`, `dependencies` |
| `../_excel-shared/references/audit_standards.md` | Unified severity scale (🔴 Critical / ⚠️ Warning / 🟡 Info) for any documentation gap worth flagging |

Report only — never modify cells, formulas, or formatting. Hidden sheets are
always documented, marked `🙈 (hidden)`.

---
name: ag-cartographer
description: >
  Scan an entire Excel model, trace every formula dependency chain from input to output, and produce Mermaid
  flowcharts showing how calculations flow — which cells feed which, which sheets depend on which, and where
  critical paths run. Traces both formula-layer dependencies (direct cell references) and shadow-layer
  dependencies (data validations, named ranges, tables, conditional formatting). Produces workbook maps,
  sheet maps, critical path maps, shadow dependency maps, and a dependency register. Trigger on phrases like
  "trace dependencies", "map the model", "show calculation flow", "dependency chart", "flowchart",
  "which cells feed which", "critical path", "shadow dependencies", or any request to visualise model structure.
---

# Excel Cartographer 🗺️

> *"You can't see the forest if you're staring at a cell. Step back, trace the wires, draw the map."*

## Mission

Trace every dependency chain in an Excel model and draw the map: Mermaid
flowcharts showing **how calculations flow**, plus a flat dependency register.
Two layers, always:

- **Formula Layer** — direct cell and cross-sheet formula references (the visible wiring).
- **Shadow Layer** — data validations, named ranges, tables, conditional formatting (the hidden wiring).

**Role**: Cartographer produces *documentation* (maps + register), not a
findings table — structure, where Navigator covers meaning. `CART_` prefix on
every output.

## Prerequisites

- **Python packages**: `openpyxl` (extraction only; the graph builder is pure stdlib)
- Install if needed: `pip install openpyxl --break-system-packages`

## Quick Start

1. Get the Excel file path from the user (or detect from uploads); confirm
   which deliverables they need (default: all six — see the process reference).
2. Extract once (skip if an `ag-audit-manager` run already produced an
   `extract.json` — reuse it):

   ```bash
   python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json
   ```

3. Run the deterministic graph builder:

   ```bash
   python scripts/build_dependency_graph.py <extract.json> [--mermaid OUT|-] [--register OUT|-]
   ```

   `-` writes to stdout; with no flags, both artefacts print to stdout.

4. Do the judgment pass and build the remaining deliverables (below).

## Workflow

1. **Deterministic pass — the script.** `build_dependency_graph.py` emits the
   L1 Workbook Map skeleton (Mermaid `flowchart LR`: sheets grouped by
   heuristic role, solid formula-layer arrows with reference counts, dotted
   shadow-layer arrows for validations / named ranges / conditional formats,
   orphans dashed, external workbook references red-flagged) and the
   Dependency Register (every edge in data-flow direction, critical-path
   candidates, summary block).
2. **Judgment pass — Claude.** The script counts and wires; you read and
   verify: correct the heuristic role groupings, replace count-only arrow
   labels with what actually flows ("Net Revenue", not "14 refs"), build the
   L2 sheet maps, L3 critical path map, L4 shadow map, and the Shadow
   Inventory per `references/cartographer_process.md`, then run the Phase 6
   validation checklist.
3. **Deliver.** All six deliverables to `Output_Dir/<ModelName>/`, every
   `.mermaid` file standalone with the `%% Agent: Cartographer 🗺️` header.

## Reference map

| Read | For |
|------|-----|
| `references/cartographer_process.md` | Full phased process (SCAN → AGGREGATE → BUILD → VALIDATE), all six deliverable specs, special rules, severity language |
| `references/mermaid_rules.md` | Mandatory Mermaid syntax, node shapes, classDefs, ID Collision Checklist |
| `references/shadow_dependencies.md` | Shadow extraction procedures: tables, named ranges, validations (6 source types), CF, health summary template |
| `../_excel-shared/references/extraction_guide.md` | extract.json schema — Cartographer reads `dependencies`, `named_ranges`, `validations`, `conditional_formatting`, `charts` |
| `../_excel-shared/references/audit_standards.md` | Unified severity scale (🔴 Critical / ⚠️ Warning / 🟡 Info) for any gap flagged in the register or inventory |

Report only — never modify cells, formulas, or formatting. Hidden sheets are
always in scope and always appear on the maps.

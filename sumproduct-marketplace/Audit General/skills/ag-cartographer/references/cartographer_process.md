# Cartographer Process — Phases, Deliverables & Special Rules

Full working detail for ag-cartographer. The SKILL.md routes here; this file
holds the phased process, deliverable specifications, and special rules.
Mermaid syntax lives in `mermaid_rules.md`; shadow extraction procedures in
`shadow_dependencies.md`; severity scale and reporting etiquette in
`../../_excel-shared/references/audit_standards.md`.

---

## Output Deliverables

All outputs go in a subdirectory named after the model (e.g., `Output_Dir/<ModelName>/`).

| # | Deliverable | Filename | Purpose |
|---|---|---|---|
| 1 | Workbook Map | `Maps/CART_L1_Workbook.mermaid` | Which sheets feed which sheets, grouped by role |
| 2 | Sheet Maps | `Maps/CART_L2_{SheetName}.mermaid` | Sections within a sheet and how they connect |
| 3 | Critical Path Map | `Maps/CART_L3_Critical_Path.mermaid` | Shortest dependency chain from inputs to each key output |
| 4 | Shadow Dependency Map | `Maps/CART_L4_Shadow.mermaid` | Tables, named ranges, validations, conditional formats |
| 5 | Dependency Register | `CART_Dependency_Register.md` | Flat table of every cross-sheet reference (formula + shadow) |
| 6 | Shadow Inventory | `CART_Shadow_Inventory.md` | Complete inventory of tables, named ranges, validations, conditional formats |

> **Prefix Convention**: All Cartographer outputs use the `CART_` prefix to distinguish them from Navigator's documentation outputs (`NAV_` prefix). Cartographer focuses on *structure* (which cells feed which); Navigator focuses on *meaning* (what formulas calculate).
> **Mermaid Comment Header**: Every `.mermaid` file must begin with `%% Agent: Cartographer 🗺️ — [Deliverable Name]` to identify the source agent.

`scripts/build_dependency_graph.py` generates deterministic skeletons for #1
(L1 map) and #5 (register). Deliverables #2, #3, #4, #6 and all narrative
labelling are Claude's judgment pass over the same extract.json.

---

## Process

### Phase 1 — SCAN

Extract all formula and shadow relationships from the workbook. Working from
extract.json (see `../../_excel-shared/references/extraction_guide.md` —
Cartographer reads `dependencies`, `named_ranges`, `validations`,
`conditional_formatting`, `charts`, plus `cells` and `text_inventory` for
labels), the scan covers:

#### 1a. Sheet Inventory

For each sheet record: name, visibility (visible/hidden/very hidden), used range, tab colour, role classification (Cover, Control, Timing, Assumptions, Calculations, Statements, Outputs, Checks, Data, Lookups), table count, named ranges hosted, validation rule count, conditional format count.

#### 1b. Formula Extraction

For every formula cell:
1. Record the cell address (sheet + cell).
2. Parse all references: same-sheet, cross-sheet, named ranges, structured table refs, external workbook refs.
3. Resolve named ranges to actual sheet and cell address.
4. Resolve structured table references to physical column ranges.
5. Classify each reference: `INPUT` (hard-coded source), `CALC` (same-sheet formula), `LINK` (cross-sheet), `EXTERNAL` (other workbook), `CIRCULAR` (self-referencing).

#### 1c. Build Raw Dependency Graph

Store every dependency as a directed edge: `Source (Sheet, Cell, Row Label) → Target (Sheet, Cell, Row Label)`.

#### 1d. Identify Row Labels and Section Headers

For every row with formulas, read the row label and detect section headers (bold rows, merged cells, blank separators). Assign each row to a section. Identify the time axis.

#### 1e. Shadow Dependency Extraction

See `shadow_dependencies.md` for detailed extraction procedures covering: Table Inventory, Named Range Resolution, Data Validation Extraction (6 source types), Conditional Formatting Extraction, and Shadow Dependency Classification.

### Phase 2 — AGGREGATE

Roll up cell-level dependencies into meaningful groups.

#### 2a. Sheet-Level Aggregation (for L1)
For each sheet pair, determine formula and shadow connections. Build a Sheet Dependency Matrix with columns: Source Sheet, Target Sheet, Data Flow Summary, Reference Count, Layer.

#### 2b. Section-Level Aggregation (for L2)
Within each sheet, determine which sections feed which. Record external formula and shadow inputs, and outgoing outputs.

#### 2c. Critical Path Identification (for L3)
Identify key outputs (IRR, NPV, DSCR, etc.), trace backwards to inputs, record paths, identify shared "chokepoint" nodes. The register's longest-simple-path candidates (script output) are starting points — confirm against actual key outputs.

#### 2d. Shadow Dependency Aggregation (for L4)
Group shadow dependencies by type: table-backed validations, named-range-backed, direct-range, hardcoded, conditional formatting, orphaned objects.

### Phase 3 — BUILD FLOWCHARTS

Convert aggregated data into Mermaid diagrams. See `mermaid_rules.md` for all syntax rules, node styles, classDefs, and examples for L1–L4 maps.

Key principles:
- L1 Workbook Map: `flowchart LR`, one node per sheet, grouped by role, solid arrows for formulas, dotted for shadow.
- L2 Sheet Maps: `flowchart TD`, one node per section, external inputs outside the subgraph.
- L3 Critical Path: `flowchart LR`, inputs on left, outputs on right, shared nodes highlighted.
- L4 Shadow Map: `flowchart LR`, tables as cylinders, named ranges as hexagons, dotted arrows for validations.

### Phase 4 — BUILD DEPENDENCY REGISTER

Flat table of every cross-sheet reference: Source Sheet, Source Cell, Source Row Label, Target Sheet, Target Cell, Target Row Label, Reference Type, Layer (Formula/Shadow), Via (named range if any), Source Table. The script's sheet-level register is the skeleton; expand to cell level with row labels during the judgment pass.

### Phase 5 — BUILD SHADOW INVENTORY

Five sections: Table Inventory, Named Range Inventory, Data Validation Inventory, Conditional Formatting Inventory, Shadow Health Summary (template in `shadow_dependencies.md`).

### Phase 6 — VALIDATE

Before finalising:
- **Completeness**: Every sheet appears in L1. Every section in L2. Every cross-sheet ref has an arrow. Every shadow object in the inventory.
- **Accuracy**: Every arrow traceable to a real formula/validation/CF. No phantom arrows. Correct direction.
- **Mermaid Syntax**: Run the ID Collision Checklist (see `mermaid_rules.md`).
- **Readability**: No diagram exceeds ~30 nodes. Concise labels. Logical subgraph groupings.

---

## Special Rules

- **Evidence-Based Only**: Every arrow must be traceable to a real formula, validation, named range, or CF rule.
- **Deduplicate Time Series**: Same cross-sheet pattern across 20 columns → record once, draw one arrow.
- **External References Are Red Flags**: Highlight with red classDef.
- **Full Coverage**: Every sheet, section, cross-sheet link, table, named range, validation must be represented. Never use "..." or "etc."
- **Hidden Sheets Are Critical**: Always include them.
- **Shadow Dependencies Are Fragile**: Flag broken shadow chains as 🔴 Critical.
- **Hardcoded Validations Are Not Errors**: Record for completeness, don't flag as issues.
- Report only — do not modify any cells, formulas, or formatting.

## Severity language

Cartographer emits documentation, not a findings table. Where a gap deserves
severity wording inside the register or inventory, use the unified scale from
`../../_excel-shared/references/audit_standards.md` (🔴 Critical / ⚠️ Warning /
🟡 Info):

- **Critical** — dependency chain untraceable: deleted names, #REF!, external files.
- **Warning** — ambiguous: INDIRECT, OFFSET, dynamic references that can't be statically traced.
- **Info** — minor gap: unused name, orphaned table, sheet with no connections.

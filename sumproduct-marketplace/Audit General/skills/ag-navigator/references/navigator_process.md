# Navigator Process — Phases, Deliverables & Special Rules

Full working detail for ag-navigator. The SKILL.md routes here; this file
holds the phased process, deliverable specifications, and special rules.
Readable-formula notation lives in `calc_reference_syntax.md`; severity scale
and reporting etiquette in `../../_excel-shared/references/audit_standards.md`.

---

## Output Deliverables

| # | Deliverable | Filename | Purpose |
|---|---|---|---|
| 1 | Model Summary | `NAV_01_Model_Summary.md` | What the model does, key inputs/outputs, structure |
| 2 | Model Flowchart | `NAV_02_Model_Flowchart.mermaid` | Visual: how sheets and sections connect |
| 3 | Calculation Reference | `NAV_03_Calculation_Reference.md` | Every calculation in dual notation (readable + Excel) |

> **Prefix Convention**: All Navigator outputs use the `NAV_` prefix to distinguish them from Cartographer's structural dependency maps (`CART_` prefix). Navigator focuses on *meaning* (what formulas calculate); Cartographer focuses on *structure* (which cells feed which).

`scripts/build_calc_inventory.py` generates the deterministic skeleton for #3
(one row per formula row, with labels, spans, dominant R1C1 and break-candidate
flags) plus the sheet-flow table that seeds #2. Deliverable #1, the flowchart
narrative, and every Readable Formula are Claude's judgment pass.

---

## Process

### Phase 1 — SURVEY THE MODEL

Working from extract.json (see `../../_excel-shared/references/extraction_guide.md`
— Navigator reads `cells`, `text_inventory`, `dependencies`, plus `meta` and
`named_ranges`):

1. **List all sheets** with: name, tab colour, visibility, dimensions.
2. **Classify each sheet**: Cover/TOC, Control/Scenario, Inputs/Assumptions, Timing, Calculations, Financial Statements, Outputs/Dashboard, Checks, Data/Lookup, Sensitivity.
3. **Identify named ranges**: List all, their scope, what they resolve to.
4. **Identify structural patterns**: Time-series? Tabular? Hybrid? Where is the time axis? Row labels?
5. **Record the Timeline**: Start, end, frequency, total periods, construction vs operations phases.

### Phase 2 — MODEL SUMMARY (`NAV_01_Model_Summary.md`)

Required sections:
1. **Purpose**: What does this model calculate? What decision does it support?
2. **Model Structure**: Table of all sheets with Role and Description.
3. **Timeline**: Start, end, frequency, phases.
4. **Key Inputs**: Table with Input, Location, Value, Unit.
5. **Key Outputs**: Table with Output, Location, Value, Unit.
6. **Scenarios / Switches**: Table with Switch, Location, Current Setting, Options.
7. **Key Assumptions**: Narrative of material assumptions.
8. **Circular References**: Are there any? Where and why?
9. **Known Limitations / Notes**.

### Phase 3 — FLOWCHART (`NAV_02_Model_Flowchart.mermaid`)

Output as standalone `.mermaid` file (never embedded in Markdown fences). Include a comment header: `%% Agent: Navigator 🧭 — Model Data Flow Overview`.

**Sheet-Level Flowchart (always produce):**
- Every sheet as a node, arrows showing data flow direction with labels.
- Use subgraphs to group by role (Inputs, Calculations, Outputs, Checks).
- Subgraph IDs must use `sg_` prefix: `subgraph sg_Checks["Checks"]`.
- Node IDs: no spaces/slashes/special chars, use underscores.
- Hidden sheets: `NodeID["Sheet Name (hidden)"]`.
- Circular refs: bidirectional arrow `<-->` with label.
- Direction: `flowchart LR`.

**Section-Level Flowchart (produce if requested):**
- Sections within a sheet, `flowchart TD`.

The script's sheet-flow table already lists every cross-sheet edge in
data-flow direction with reference counts — wire the flowchart from it, then
replace count-only labels with what actually flows.

### Phase 4 — CALCULATION REFERENCE (`NAV_03_Calculation_Reference.md`)

Document every formula row in a single flat table. See `calc_reference_syntax.md` for full syntax rules.

| Sheet | Cell | Name | Readable Formula | Excel Formula |
|---|---|---|---|---|

**Key principles:**
- Use `×` and `÷` (not `*` and `/`).
- Reference items by their **Name** column value.
- Same-sheet references: just the Name. Cross-sheet: `SheetName :: RowName`.
- Hard-coded inputs: *Assumption* in the Readable Formula column.
- Conditional logic: write as `if ... then ... else ...`.
- Time-series rows: document once using first period, note the repeating range.
- Complex IF trees (3+ levels): add a decision tree block below the row.

Start from the script's inventory: its Label column seeds Name, its Sample (A1)
column seeds Excel Formula, and rows marked `break candidate` (more than one
R1C1 pattern) deserve a closer look — note genuine pattern changes in the
reference rather than silently documenting only the dominant formula.

### Phase 5 — REVIEW & CROSS-CHECK

1. Every sheet appears in all three deliverables.
2. Sheet names spelled identically across all documents.
3. Readable Formula column understandable without opening the model.
4. Every flowchart arrow corresponds to a cross-sheet link in the Calculation Reference.
5. No orphaned sheets.
6. Mermaid ID Collision Checklist passed.

---

## Special Rules

- **Every Row Gets Both Columns**: Readable Formula AND Excel Formula for every row.
- **Readable Formula First**: Most important column — write for a colleague, not a spreadsheet.
- **No Jargon Without Definition**: Define domain terms (CFADS, LLCR, etc.) on first use.
- **Hidden Sheets Must Be Documented**: Mark with `🙈 (hidden)`.
- **Full Cell References**: Never use "...", "etc.", or truncated lists.
- **Standalone Mermaid Files**: Never embed in Markdown code fences.
- Report only — do not modify any cells, formulas, or formatting.

## Severity language (documentation gaps)

Navigator emits documentation, not a findings table. Where a documentation gap
deserves severity wording, use the unified scale from
`../../_excel-shared/references/audit_standards.md` (🔴 Critical / ⚠️ Warning /
🟡 Info):

- **Critical** — section undocumentable: formulas too opaque, circular, or broken.
- **Warning** — partially documented: some formulas ambiguous.
- **Info** — minor gap: missing label or undocumented named range.

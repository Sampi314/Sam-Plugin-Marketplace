# Detailed Audit Report — Build Guide

How to populate each section of `report_template.md`. Inputs: the shared
`extract.json` (from `../../_excel-shared/scripts/extract_workbook.py`) and the
consolidated findings JSON (from
`../../ag-audit-manager/scripts/consolidate_findings.py`).

## Phase 1 — Data Collection

| Data Needed | Source | Used In |
|---|---|---|
| Model purpose, timeline, key I/O, scenarios | Navigator 🧭 output (or direct from extract.json `cells` + `text_inventory`) | Section 1 |
| Workbook-level flowchart | Navigator 🧭 / Cartographer `build_dependency_graph.py --mermaid` | Section 2a |
| Sheet-level flowcharts | Cartographer 🗺️ | Section 2b |
| Formula patterns (R1C1 + A1, grouped) | extract.json `r1c1_rows` / `r1c1_cols` | Section 3 |
| Cell formats, styles, number formats | extract.json `cells`, `styles` + Stylist convention block | Section 4 |
| Term frequency, tab names | Lingo `lingo_rules.py --terms` sidecar | Section 5 |
| Named range inventory | extract.json `named_ranges` | Section 6 |
| Structural assessment | Architect 🏗️ output | Section 7 |
| Hyperlink inventory | extract.json `hyperlinks` | Section 8 |
| VBA module inventory | VBA `vba_audit.py` (COM) | Section 9 |
| Power Query inventory | PQ `pq_audit.py` (COM) | Section 10 |
| All findings | consolidated findings JSON | Section 11 |

Run (or collect from) each source **before** assembling — the report is written
once, top to bottom.

## Phase 2 — Formula Inventory (Section 3, the signature section)

extract.json has already done the heavy lifting: `r1c1_rows[sheet]` lists, per
row, every R1C1 signature with the cells it covers (`n_patterns` > 1 = break).

1. For each sheet, for each row record: dominant pattern first (most cells),
   then minority patterns.
2. Display per pattern: R1C1 signature + A1 example (first cell of the group,
   from `cells`) + grouped cell range + count + status
   (✅ Consistent / ⚠️ Pattern Break).
3. Hard-coded constants in calculation areas: list separately at the top of
   each sheet's block as `(value)` patterns (from `cells` records with `v` but
   no `f`, filtered to calculation sheets).
4. Sort by row number; use `r1c1_cols` instead for tabular (non-time-series)
   sheets.
5. **Never truncate** — every unique pattern appears; no "..." or "and X more".

Worked example:

```
Sheet: Revenue, Row 17
  Dominant R1C1: =R[-3]C*R[-1]C      (22 cells: D17:Y17)   ✅ Consistent
  ⚠️ BREAK:     =R[-3]C*R[-1]C+100  (1 cell: Z17)          ← hardcoded +100
```

## Phase 3 — Style & Format Inventory (Section 4)

- 4a: workbook Cell Styles from extract.json `styles` (+ per-cell `style` usage
  counts from `cells`).
- 4b: colour convention from the Stylist script's `--convention` block
  (statistical inference with confidence %), or the model's Style Guide sheet.
- 4c: number-format frequency from `cells[].fmt`; flag context mismatches
  inline (e.g. "General on a percentage row") — these also appear as Stylist
  findings in 11c; the inventory shows the *convention*, the finding shows the
  *deviation*.

## Phase 4 — Assembly rules (per section)

- **S1** Keep to ~1 page. If Navigator hasn't run, derive from extract.json.
- **S2** Embed Mermaid inline (renders on GitHub/Obsidian/VS Code). Every
  flowchart keeps its `%% Agent:` comment header; subgraph IDs use the `sg_`
  prefix (Mermaid collision prevention).
- **S5** Mark the dominant term; only flag outliers with a clear majority
  (e.g. 12 vs 2 — close counts go to the user as a question, not a finding).
- **S6** Include the resolution chain; flag broken names 🔴, orphaned 🟡.
- **S7** Narrative + findings, not just a table.
- **S8** List ALL hyperlinks, working ones included — this is the inventory;
  broken ones additionally appear in 11g.
- **S9/S10** Inventory + purpose summary only — never paste full VBA/M code.
  If absent: "No VBA code present." / "No Power Queries present."
- **S11** Populate straight from the consolidated findings JSON: the IDs,
  agents, severities and grouped cell references are already assigned by
  `consolidate_findings.py` — do not renumber or regroup. Split rows into the
  11a–11i sub-sections by agent. Keep the summary count table at the top.
  Empty agent → "✅ No [category] detected." Not applicable → "ℹ️ No
  [component] present in this workbook."

## Special Rules

- **Never modify the workbook** — report only.
- **One report file**: everything in a single `AUDIT_REPORT_<ModelName>.md`.
- **Section numbering**: keep the 1–11 structure even when a section is empty.
- **Dedup across sections**: a cell may appear in Section 3 (inventory pattern
  break) AND Section 11b (finding) — keep both; inventory and findings serve
  different purposes.
- Grouping, severity and findings formats: defined once in
  `../../_excel-shared/references/audit_standards.md` — follow it, don't restate it.

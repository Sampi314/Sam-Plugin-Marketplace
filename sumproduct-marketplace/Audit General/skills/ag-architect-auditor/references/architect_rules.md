# Architect Rule Catalogue 🏗️

The full check catalogue for `ag-architect-auditor`. Findings table format, severity
scale, and the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what*
Architect checks and the categories it reports under.

All checks run against `extract.json` (sections `dependencies`, `r1c1_rows`, `meta` —
see `../../_excel-shared/references/extraction_guide.md`). Every check here is a judgment
call: cite extract evidence (edge counts, R1C1 signatures, sheet dims) in each finding.

---

## Phase 1 — Structural review

Analyse the workbook's layout and how sheets link together.

1. **Sheet inventory & role separation** — from `meta.sheets`, list every sheet with its
   role (Inputs, Calculations, Outputs, Checks, Navigation/Presentation), dimensions, and
   visibility. Assign roles from tab names, labels in `text_inventory` if loaded, and the
   direction of dependency edges (pure sources are usually inputs; pure sinks are outputs).
   Flag sheets that mix roles — hard-coded assumptions buried inside a calculation block,
   or output summaries computing fresh logic — because mixed roles defeat the
   inputs → calculations → outputs flow that makes a model checkable.
2. **Cross-sheet dependency map** — from `dependencies.sheet_edges`, map which sheets
   reference which. Flag backward edges (Calculations pulling from Outputs), circular
   sheet-level loops, and `[external]`-prefixed edges to other workbooks.
3. **Section identification** — within each sheet, identify logical sections (Revenue,
   OpEx, Debt, …) by scanning headers, merged cells, and bold rows. This anchors the
   "Description of Location" column in findings.
4. **Time axis consistency** — verify all time-series sheets share the same horizon,
   period frequency, and column alignment (e.g., FY1 always in column D). Misaligned
   columns make cross-sheet formulas silently reference the wrong period.
5. **Master date spine** — check that every time-series sheet references a central timing
   source (a Timing/Timeline sheet) rather than computing its own dates. Evidence: a
   `dependencies` edge from each calculation sheet to the timing sheet. A sheet with
   independent date arithmetic drifts the moment the model start date changes.

## Phase 2 — Scale & integrity checks

Identify areas where the model's architecture is compromised.

1. **Scalability assessment** — can a new year/period be added by extending columns, or
   does it require manual formula rewrites?
   - Flag formulas whose aggregation ranges are hard-coded to the current period count
     (e.g., `SUM(D5:Z5)` where Z is the final period and nothing marks the boundary).
   - Flag IF/CHOOSE structures with a fixed number of cases equal to the period count —
     adding a period means rewriting the formula, not filling right.
   - Check whether named ranges are dynamic or pinned to static extents.
   - `r1c1_rows` helps: a row that is one uniform R1C1 signature across all periods
     extends cleanly; a row with several signatures (`n_patterns > 1`) likely breaks.
2. **One-line modelling detection** — identify rows where an entire multi-step
   calculation is condensed into a single Mega-Formula instead of intermediate steps.
   A single formula performing lookup + conditional + arithmetic + aggregation is a
   modularity failure: it cannot be audited step by step. Cross-reference Efficiency
   agent findings if available — Efficiency flags length; Architect flags the missing
   intermediate rows.
3. **Structural fragility**:
   - Formulas referencing bare row/column numbers where a named range or structured
     reference would survive an insert.
   - Hard-coded sheet names inside formula strings (e.g., built with `INDIRECT`) that
     break silently if a sheet is renamed.
   - Cross-sheet references that skip intermediate calculation layers — e.g., a Summary
     sheet reaching directly into Assumptions instead of going through Calculations.
     Evidence: a `dependencies` edge that bypasses the layer the dependency map says
     should sit between them.
4. **Category consistency** — verify categories (cost items, revenue streams, asset
   classes) appear in the same order on every sheet that lists them. Re-ordered
   categories invite row-offset reference errors and make side-by-side review impossible.

---

## Error categories

Use exactly these values in the findings table's Category column:

| Category | Description |
|---|---|
| **Structural Weakness** | Fragile architecture that is prone to breaking upon modification |
| **Scalability Issue** | Logic that requires manual updates to extend time periods or categories |
| **Modularity Failure** | Calculations that should be broken into steps but are condensed into a single "black box" |
| **Date Spine Misalignment** | Sheet uses independent timing instead of referencing the master date spine |
| **Category Inconsistency** | Items listed in different order across sheets that reference them |
| **Fragile Reference** | Formula uses hard-coded row/column numbers or sheet names instead of structured references |

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. Architect-specific calibration:

- **Critical** — a structural flaw that will produce wrong numbers if the model is
  extended (hard-coded aggregation boundary, date spine misalignment already causing
  period drift).
- **Warning** — an architectural weakness that makes maintenance risky (Mega-Formula
  black boxes, layer-skipping references, fragile sheet-name strings).
- **Info** — a minor structural inconsistency (category order differences with no
  formula consequence yet, cosmetic section misalignment).

## Reporting

- Emit the unified findings table (`audit_standards.md` §1); group cell references per
  the Grouping Rule (§4) — never "…" or truncated lists.
- For formula-related findings, include `Expected R1C1:` / `Actual:` signatures — they
  are mandatory for formula findings per the standard.
- Report only — do not modify values, formulas, or formatting.

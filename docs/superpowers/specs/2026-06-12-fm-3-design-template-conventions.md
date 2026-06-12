# Design Spec — fm-3-design Template Conventions (vSN extract)

- **Date:** 2026-06-12
- **Phase touched:** fm-3-design (Phase 3 of the financial-modelling lifecycle)
- **Source of truth:** `SP Template Model vSN.xlsm`
- **Approach:** C — minimal churn (extend existing references; add `scripts/` folder)

## Background

The user reviewed `fm-3-design/SKILL.md` and identified eight conventions that the current references either omit, mis-state, or only partially cover. The `SP Template Model vSN.xlsm` was inspected with openpyxl to derive concrete rules from the live template; this spec captures the findings, the proposed encoding into fm-3-design, and the new extract/create scripts that will keep the references in sync with future template revisions.

## Goals

1. Make the references match the live template exactly (no drift).
2. Encode every convention as a **mechanical rule** rather than a per-sheet listing — so fm-4-build can apply rules generically rather than reading a sheet-by-sheet config.
3. Add `scripts/` to fm-3-design so the template stays the canonical source: `extract_from_template.py` regenerates the references, and `create_styles_and_guide.py` builds the 41 styles + Style Guide sheet in any target workbook.

## Non-goals

- Refactoring file structure (Approach C — stays as 5 references + new `scripts/`).
- Migrating the design phase to a different output format.
- Building the periodic-sheet content beyond column widths + freeze pane.

---

## Changes by reference file

### 1. `references/sumproduct_styles.md` — expand 30 → 41 styles with full property matrix

**Current:** Register of 30 styles with colour values and minimal properties.

**New:** Register of all 41 styles in the vSN template. Each row carries:

| Column | Detail |
|---|---|
| Style Name | As named in workbook (e.g. `Heading 1 Text`, `Assumption`) |
| Font | Family · size · bold/italic/underline · colour (RGB + theme index) |
| Fill | Pattern type + foreground colour (RGB + theme index) |
| Border | Per side (top/bottom/left/right): style + colour |
| Alignment | Horizontal · vertical · wrap · indent |
| Protection | Locked · hidden |
| Number Format | Format code (or `General` if none) |
| **Tick state** | Six checkboxes: applyFont / applyFill / applyBorder / applyAlignment / applyProtection / applyNumberFormat. Each TRUE if the named style's xf has a non-zero index for that property family (i.e. differs from Normal). |

**New styles to add** (in vSN, missing from the 30-style register): `Heading 4`, `Empty`, `Internal Ref`, `Hyperlink Text`, `Range Name Description`, `Right Currency`, `Right Number`, `WIP`, plus Excel built-ins `Normal`, `Comma`, `Comma [0]`, `Currency`, `Currency [0]`, `Per cent` (decide whether to canonise built-ins or list them as inherited).

**Decision needed during implementation:** include or exclude Excel built-ins in the canonical register (`Normal`, `Comma`, `Currency`, `Per cent`). Recommendation: **include**, because they appear on the Style Guide sheet's "Numerical Styles" section — the workbook treats them as part of the catalogue.

### 2. `references/style_creation_code.md` — switch from inline code to script reference + **add the two-pass application pattern**

**Current:** Inline pywin32 `create_all_styles(wb)` function for 30 styles. Mentions the `IncludeNumber=False` trap on `Assumption` but doesn't explain WHY.

**New:** Short narrative covering:
- When to call `create_all_styles(wb)` — before any sheet content.
- The IncludeNumber trap on `Assumption` (and now also on `Parameter`, `Constraint`, `WIP`, `Empty`, `Notes`).
- **The two-pass style application pattern** (new — this is how cells receive styles in practice).
- Pointer to `scripts/create_styles_and_guide.py` for the executable creation code. The script is the canonical implementation; the markdown describes the *contract*.

#### 2a. Two-pass style application (NEW — critical rule)

A cell that needs both a number format AND a coloured fill receives **two styles in sequence**, not one combined style. Each style ticks a different property group:

**Pass 1 — Format style** (sets the number format, leaves fill default):
- `applyNumberFormat = TRUE`
- `applyFill = FALSE` (no fill, inherits "none")
- Examples: `Comma`, `Comma [0]`, `Currency`, `Currency [0]`, `Per cent`, `Numbers 0`, `Date`, `Date Heading`, `Internal Ref`, `Line Calc`, `Row Ref`, `Right Currency`, `Right Number`, `Row_Summary`

**Pass 2 — Visual style** (adds fill / colour / border on top, preserves format from Pass 1):
- `applyNumberFormat = FALSE` (so the format from Pass 1 survives)
- `applyFill = TRUE` (the colour goes here)
- Examples: `Assumption`, `Parameter`, `Constraint`, `WIP`, `Empty`, `Notes`, `Range Name Description`, `Accounts Ref`, `Table_Heading`

```python
cell.style = "Currency"      # Pass 1 — sets _-"$"* #,##0.00 etc.
cell.style = "Assumption"    # Pass 2 — adds yellow fill, format survives because applyNumberFormat=False
```

**Combined styles** apply in one pass — they tick BOTH `applyNumberFormat` and `applyFill`. Use sparingly because they cannot be layered:
- `Heading 1 Number` (auto-numbering format + dark fill + border)
- `Heading 1 Text` (no format, dark fill, border) — visual only, can be applied alone
- `Error_Checks` (tick/cross format + green/red fill)

#### 2b. Style classification table

Add a classification table to `style_creation_code.md` (or `sumproduct_styles.md`) marking each of the 41 styles as `Format` / `Visual` / `Combined` / `Heading` / `Hyperlink`. This drives the two-pass application logic in `create_styles_and_guide.py` and in fm-4-build's cell-writing routines.

### 3. `references/validation_and_formats.md` — unchanged

Data validation rules and standalone number-format codes stay. The style register now also carries number formats (per-style), but standalone format codes are still needed for ad-hoc cell formatting that doesn't fit any style.

### 3.5 NEW: `references/style_application_matrix.md` — which style on which cell

A new lightweight reference that maps **cell purpose** to the styles applied (Pass 1 + Pass 2 from §2a). Drives both the design phase (so the spec includes the right styles per cell type) and fm-4-build (so the build phase applies them in the right order).

| Cell purpose | Pass 1 (format) | Pass 2 (visual) | Column | Example sheet/cell |
|---|---|---|---|---|
| Section number (Heading 1) | — | `Heading 1 Number` (combined) | B | Model Parameters B6 |
| Heading 1 text band | — | `Heading 1 Text` | C → last col | Model Parameters C6:R6 |
| Heading 2 text | — | `Heading 2 Text` | C → … | Model Parameters C8 |
| Heading 3 text | — | `Heading 3 Text` | D or E → … | Model Parameters E10 |
| Sheet title (top of each sheet) | — | `Sheet Title` | A1 | every sheet |
| Model name (below sheet title) | — | `Model Name` | A2 | every sheet |
| Back-link to Navigator | — | `Hyperlink` | A3:E3 merged | every sheet except Cover/Navigator |
| Date heading (period column header) | — | `Date Heading` (combined) | J+ row 5 | Timing J5 |
| Row label | — | `Line Calc` | E | periodic sheets |
| Units column | — | `Units` | G | periodic sheets |
| Row reference | — | `Row Ref` (combined: `"Row "###0` format) | H | periodic sheets |
| Currency input | `Currency` or `Currency [0]` | `Assumption` | I+ | Model Parameters G19 |
| Percentage input | `Per cent` | `Assumption` | I+ | growth rates etc. |
| Date input | `Date` | `Assumption` | I+ | Timing H15 |
| Number-of-periods input (no format style) | `Numbers 0` | `Assumption` | I+ | Model Parameters G20-24 |
| Currency parameter (operational, not assumption) | `Currency` or `Comma` | `Parameter` | I+ | Model Parameters G31 |
| Hard-coded number constant | — | `Constraint` | inline | one-off cells |
| Work-in-progress (review marker) | — | `WIP` | any | dev only — Phase 5 flags |
| Notes / commentary | — | `Notes` | any | inline annotations |
| Calculation result (number) | `Comma` or `Currency` | `Line Calc` | I+ | calculation sheets |
| Total row (single underline) | `Comma` or `Currency` | `Line Total` (combined: top thin border) | I+ | subtotal rows |
| Grand total (double underline) | `Comma` or `Currency` | `Total` (combined: top thin + bottom double border) | I+ | end-of-section totals |
| Error check (tick / cross) | — | `Error_Checks` (combined) | F or I | Error Checks F4, I12, I17 |
| Empty (placeholder cell — grey background) | — | `Empty` (combined: gray125 fill, blank) | any | blank cells in working sheets |
| Internal reference (cross-sheet) | `Internal Ref` (combined) | — | any | reference rows |
| Row summary column (Opening BS / period total) | `Row_Summary` (combined: number format + light fill) | — | I | balance sheet |
| Named range descriptor | — | `Range Name Description` | — | Style Guide doc |
| Accounts reference | `Accounts Ref` (combined) | — | — | optional |
| Right-aligned currency (compact) | `Right Currency` (combined) | — | — | dashboards |
| Right-aligned number (compact) | `Right Number` (combined) | — | — | dashboards |
| Table column header | — | `Table_Heading` | row header | tabular sections |

The matrix is **not exhaustive** — it captures the canonical pairings. New combinations may be added per client style request (the workflow the user described: "we need another style as client request"). When that happens:
1. Add the new style to the 41-style register in `sumproduct_styles.md` (regenerate via `extract_from_template.py` or hand-edit).
2. Add the new row to this matrix specifying its purpose and which pass it belongs to.
3. Re-run `create_styles_and_guide.py` to populate the Style Guide sheet in every new workbook.

### 4. `references/cf_and_column_layout.md` — major expansion

Add four new sections, plus correct the existing column-layout table.

#### 4a. **Column widths by sheet class** (replaces the current "uniform A-J grid" table)

Five sheet classes, each with its own widths:

| Sheet class | A | B-E | F | G | H | I | J+ | K+ |
|---|---|---|---|---|---|---|---|---|
| Cover | default | default | default | default | default | default | default | default (only C=3.7 set, see special block below) |
| Navigator | 3.7 | default | 17.7 | default | default | default | default | default |
| Static working (Model Parameters, Error Checks, Change Log, logs) | 3.7 | default | 9.1–27.0 (varies by content) | varies | varies | varies | varies | varies |
| Periodic working (Timing, Timing Template, No Timing Template) | 3.7 | default | default | 22.1 | 10.7 | default | 10.7 (period cols) | 10.7 each |
| Style Guide | 3.7 | default | 9.1 | default | 1.7 (spacer) | 17.3 (display) | 1.7 (spacer) | 23.4 (style name) |

Column A = 3.7 is **universal** across every sheet (sheet-margin convention). Columns B-E are intentionally left at Excel default (~8.43) — the staircase indents come from style differences, not width differences.

#### 4b. **Freeze pane rule (mechanical)** — NEW

**Rule:** The freeze pane is set to **one row below the Heading 1 row** and (for periodic sheets) **one column right of the last frozen column**.

| Sheet class | Heading 1 row | Last frozen col | Freeze pane address |
|---|---|---|---|
| Cover | n/a | n/a | None (static page) |
| Static working | 6 | A (no col freeze) | `A6` |
| Periodic working | 11 | I (cols A-I frozen) | `J11` |

`A6` means: rows 1-5 frozen, no column freeze. `J11` means: rows 1-10 frozen, columns A-I frozen. Build phase derives the freeze address from `(heading_row, last_frozen_col + 1)` — no per-sheet config needed.

#### 4c. **Heading staircase pattern** — NEW

```
Row N       B = Heading 1 Number  (formula =MAX($B$prev_range:$B[N-1])+1)
            C..L = Heading 1 Text  (8+ cells across data span)

Row N+2     C = Heading 2 Text    (indented one column right)
            extends across data span as needed

Row N+4     D or E = Heading 3 Text  (indented one more column)
```

- Heading 1 row = first scrollable row after freeze pane (row 6 static, row 11 periodic).
- Heading 2 row = Heading 1 row + 2 (one blank spacer row between levels).
- Heading 3 row = Heading 2 row + 2.
- The staircase is **column-indented** (B → C → D → E) and **row-spaced** (with one blank row between levels).
- The `Heading N Number` style only appears on Heading 1 — it auto-numbers section numbers via the `=MAX` formula.

#### 4d. **Heading 1 cover area rule (band length)** — NEW

The Heading 1 cover area is the band of cells styled `Heading 1 Text` that runs across the heading row.

**Rule:** `Heading 1 Text` style is applied from **column B to (sheet's last-used column + 1)**.

Verified examples from vSN:

| Sheet | Sheet last col | H1 band end col |
|---|---|---|
| Model Parameters | R | R |
| Timing | O | O |
| Error Checks | K | K |
| No Timing Template | O | O |
| Timing Template | O | O |

The band extends one cell past the rightmost data column to give the band a visual buffer at the right edge. Build phase computes this from `worksheet.dimensions` after data is populated.

#### 4e. **Named range naming convention** — NEW

Two prefixes, mandatory:

| Prefix | Purpose | Format | Example |
|---|---|---|---|
| `HL_NNN` | Sheet hyperlink target (one per sheet, anchored at `$A$3`) | 3-digit zero-padded number | `HL_001 → Cover!$A$3` |
| `HL_<name>` | Special navigation targets | PascalCase name | `HL_Navigator → Navigator!$A$1` |
| `N_<PascalCase>` | Named constants and key cells | PascalCase, underscores between words | `N_Days_in_Year`, `N_Overall_Error_Check`, `N_Model_Start_Date` |
| `_xleta.*` | Excel-internal (LET-equivalent), **do not user-define** | n/a | `_xleta.IF` |

Current SKILL.md lists ranges without the `N_` prefix (`Days_in_Year`) and without 3-digit `HL_` (`HL_BS_Errors`). The template uses **`N_Days_in_Year`** and **`HL_001`** style — update the SKILL.md naming examples and the design_template.md Named Range register table to use the prefix.

#### 4f. **Conditional formatting** — minor doc correction

CF rules are applied **cell-by-cell, not as a single range**. The Error Checks sheet has 4 CF rules applied to individual cells F4, I12 (twice — duplicate rule, possibly a bug), I17. Add to the doc: "Apply one CF rule per error cell, not a sheet-wide range — gives independent formatting metadata per check."

### 5. `references/design_template.md` — minor updates

- Section 2 (Named Range register) header table: change examples to use `N_` / `HL_NNN` prefix.
- Section 6 (Column layout per sheet class): split into five sheet-class tables matching the vSN reality (Cover / Navigator / Static / Periodic / Style Guide).
- Section 7 (Navigation): add the per-sheet A3 hyperlink convention — `location='HL_Navigator'`, merged `A3:E3`, styled `Hyperlink`.
- Section 8 (Build notes): note the freeze-pane derivation rule and the H1 band rule so Build doesn't have to look them up.

### 6. SKILL.md updates

- Section 2 (DEFINE NAMED RANGES): update example names to use `N_` / `HL_NNN` prefix.
- Section 5 (DEFINE CONDITIONAL FORMATTING): no change.
- Section 6 (DEFINE COLUMN LAYOUT): point to new sheet-class breakdown.
- Section 6.5 (NEW) **DEFINE HEADING STAIRCASE & FREEZE PANE** — point to `cf_and_column_layout.md` 4b–4d.
- Process step list: add "use `scripts/create_styles_and_guide.py` to build the 41 styles + Style Guide sheet in the workbook" as the Build hand-off note.

---

## New scripts

### `scripts/extract_from_template.py`

**Purpose:** Read any `.xlsm` template and regenerate the reference markdowns so the docs stay in sync.

**Inputs:** `--template path/to/template.xlsm`, `--output references/`.

**Outputs:**
1. Rewritten `sumproduct_styles.md` — 41-style register table with full property matrix and tick states.
2. Updated tables in `cf_and_column_layout.md`:
   - Column widths by sheet class (auto-discover classes from sheet name patterns).
   - Freeze pane rule (verify all sheets follow `A6` / `J11` / None pattern; flag exceptions).
   - Named range convention examples (extract `HL_*` and `N_*` from `wb.defined_names`).

**Implementation notes:**
- Parse `xl/styles.xml` directly (via zipfile + ElementTree) — openpyxl's NamedStyle doesn't surface apply* flags. Use `cellStyleXfs[xfId]` and check `fontId != 0`, `fillId != 0`, etc. to derive the tick state.
- Resolve theme colour indices to RGB via `xl/theme/theme1.xml`. Fall back to `th{n}` label if resolution fails.
- Emit Markdown tables, sorted by style name alphabetically.

### `scripts/create_styles_and_guide.py`

**Purpose:** Apply the 41-style register to a target workbook AND build the `Style Guide` sheet.

**Inputs:** `--workbook path/to/target.xlsm` (or open `wb` object from caller).

**Process:**
1. Parse `sumproduct_styles.md` — extract the 41-style register table into a Python list of style specs.
2. For each spec, create an `openpyxl.styles.NamedStyle` with Font / Fill / Border / Alignment / Protection / NumberFormat set per the spec's tick state. Add to workbook (`wb.add_named_style(ns)`).
3. Create a `Style Guide` sheet if it doesn't exist (or update if it does).
4. Build the Style Guide sheet in three sections:
   - **Formatting of Headers / Dividers** — rows 6 H1, 8 table header, 10–20 style rows (Sheet Title, Model Name, Header 1-4, Notes, Table Heading)
   - **Individual Cell Styles** — H1 row 23, table header row 25, data rows 27+ (Assumption, Constraint, Empty, Error Check, Hyperlink, Internal Ref, Line Calc, Line Total, Parameter, Range Name Description, Row Ref, Row Summary, Units, WIP)
   - **Numerical Styles** — H1 row, table header, data rows (Comma, Comma [0], Currency, Currency [0], Date, Date Heading, Numbers 0, Per cent)
5. Each style row: C column = Description (Normal style), I column = live example (the named style itself, so it displays), K column = Style Name (Normal style).
6. Apply the H1 cover area rule: `Heading 1 Text` from B to last-used column + 1.
7. Apply column widths: A=3.7, F=9.1, H=1.7, I=17.3, J=1.7, K=23.4, N=1.7.
8. Set freeze pane = `A6`.

**Implementation notes:**
- Must call `create_styles` **before** any data is populated (IncludeNumber trap — styles with applyNumberFormat=TRUE overwrite cell formats set earlier).
- The `Assumption` style has applyNumberFormat=FALSE in the vSN template — so applying it doesn't change the cell's number format. This matches the existing `style_creation_code.md` documentation.
- Use `wb.add_named_style(...)` per style. Catch the duplicate-name exception if the style already exists (idempotent runs).

---

## Bugs found in vSN template (for fix in create script)

These are deviations or anomalies that the create script should **not** reproduce; document them so future templates avoid them.

1. **Cover sheet's A3 not merged** — Every other sheet has `A3:E3` merged with the `Navigator` back-link. Cover does not. Either Cover should also have it (for consistency), or the convention should explicitly exclude Cover.
2. **Navigator's A3 self-links** — `location='HL_Navigator'` resolves to `Navigator!$A$1`, which is the same sheet. Clicking it from Navigator does nothing useful. Recommendation: omit A3 hyperlink on Navigator, or link to Cover.
3. **Hyperlink mechanism inconsistent** — Cover, Style Guide, Model Parameters, Timing, Error Checks, Change Log, Sam Notes, Timing Template, No Timing Template all use **relationship-based** hyperlinks (`id='rId1'` or `id='rId3'`). Navigator alone uses **location-based** (`location='HL_Navigator'`). Recommendation: standardise on location-based — it survives sheet reorders and copies, where relationship-based can break.
4. **Error Checks: duplicate CF rule on I12** — two identical `cellIs notEqual 0` rules on the same cell. Likely paste artefact. The create script should write only one.

---

## Out of scope

- Implementation of the periodic-sheet content (rows below Heading 1) — that belongs to fm-4-build.
- Migration of existing models built from vSN.xlsm — that's a one-off Phase 6 task per model.
- A user-facing diff between the new register and the old register (Liam's review tool) — could be added later as a third script if needed.

---

## Success criteria

1. `extract_from_template.py path/to/SP Template Model vSN.xlsm` regenerates `sumproduct_styles.md` containing 41 styles with property matrix + tick states.
2. `create_styles_and_guide.py path/to/new_model.xlsx` produces a workbook with 41 named styles added AND a `Style Guide` sheet that renders correctly (no `#REF!`, no missing cell styles).
3. The Style Guide sheet visually matches the vSN template's Style Guide sheet section by section.
4. The updated `cf_and_column_layout.md` answers all of: "what's the freeze pane on a periodic sheet?", "where does the Heading 1 band end?", "what's the naming convention for an error check cell?".
5. The fm-3-design SKILL.md still fits within the thin-SKILL.md pattern (under ~120 lines).

## Implementation order

1. Build `extract_from_template.py` and run it against vSN. Diff the output against current `sumproduct_styles.md`.
2. Hand-edit any extraction artefacts (theme colour resolution failures, edge cases). Commit `sumproduct_styles.md` overwrite.
3. Expand `cf_and_column_layout.md` with the four new sections (4b–4e) + corrected column widths (4a).
4. Update `design_template.md` with sheet-class column tables + A3 hyperlink convention + freeze pane derivation rule in Section 8.
5. Update `SKILL.md` Section 2 (named-range prefix) + Section 6 (point to new column widths).
6. Build `create_styles_and_guide.py`. Test against a clean .xlsx; verify Style Guide sheet renders.
7. Document the bug list (above) in `cf_and_column_layout.md` as a "Bugs in the vSN template" appendix — so Phase 6 audit checks can flag them.

Estimated effort: 1–2 sessions for the references + scripts, with the extractor doing most of the markdown generation.

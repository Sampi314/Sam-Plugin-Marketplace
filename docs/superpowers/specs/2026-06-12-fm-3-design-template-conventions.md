# Design Spec — fm-3-design Template Conventions (vSN extract)

- **Date:** 2026-06-12
- **Phase touched:** fm-3-design (Phase 3 of the financial-modelling lifecycle)
- **Source of truth:** `SP Template Model vSN.xlsm`
- **Approach:** C — minimal churn (extend existing references; add `scripts/` folder)

## Background

The user reviewed `fm-3-design/SKILL.md` and identified eight conventions that the current references either omit, mis-state, or only partially cover. The `SP Template Model vSN.xlsm` was inspected with openpyxl to derive concrete rules from the live template.

**Strategic frame:** fm-3-design has **two equal first-class deliverables** that stay in sync — the reference markdowns AND the scripts. Neither subordinates the other.

| Deliverable | Who reads it | Role |
|---|---|---|
| **Reference markdowns** (`sumproduct_styles.md`, `cf_and_column_layout.md`, `style_application_matrix.md`, `validation_and_formats.md`, `design_template.md`, `style_creation_code.md`) | **Claude** — at design-phase conversation time. **Humans** — when editing conventions. | The canonical *spec*. What every workbook should look like, by rule. |
| **`build_template_workbook.py`** | **The user / fm-4-build** — invoked to produce a clean starter workbook on demand. | The canonical *implementation*. Every workbook the script produces obeys the spec. |
| **`extract_from_template.py`** | **Sam** — when the template evolves (new client style, revised column width). | The synchronisation tool. Run against any new template, diff against the references, update references. |

Why both first-class:
- **References without script** would force fm-4-build to re-implement style creation, freeze pane logic, and column widths every time — drift inevitable.
- **Script without references** would mean Claude has no spec to read during design conversations and would have to read Python to answer "what's the freeze pane on a periodic sheet?".
- **Both together** means Claude answers from markdown, the user builds from script, and the extract tool keeps them in sync against the real template.

fm-4-build consumes the script's output (a clean starter workbook) and adds model-specific content. It does not re-derive column widths, freeze panes, or styles — those are baked in.

## Goals

1. Make the script and references match the live template exactly (no drift).
2. Encode every convention as a **mechanical rule in the script** — so every workbook the script produces looks the same.
3. Make the script idempotent and parameterisable: callable to produce a clean starter workbook on demand, with optional sheet inclusions per project.

## Non-goals

- Refactoring file structure (Approach C — stays as 5 references + new `scripts/`).
- Migrating the design phase to a different output format.
- Building the periodic-sheet **content** below Heading 1 (assumption rows, calculation rows etc.) — that belongs to fm-4-build.
- Backwards-compatibility with existing vSN-built models — the script produces new clean workbooks; existing models keep working as-is.
- A bug-report or migration tool for existing models (vSN deviations are not in scope; the script just does it right).

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

#### 4c.1 **Inter-section spacing rule** — NEW

Between the end of one Heading 1 section and the start of the next, leave **two blank rows**. So if Section 1 ends at row N (its last data row), Section 2's Heading 1 row is at row N+3.

```
Row M        Section 1 last content row
Row M+1      blank
Row M+2      blank
Row M+3      Section 2 Heading 1   (B = next section number, C..end = Heading 1 Text band)
```

This rule applies across the whole working sheet — the build script computes Heading 1 positions by accumulating section heights plus the 2-row spacer between each.

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

### `scripts/build_template_workbook.py` — PRIMARY DELIVERABLE

**Purpose:** Produce a clean starter workbook containing every fm-3-design convention applied correctly. fm-4-build takes this workbook and adds model-specific content; it does not re-derive conventions.

**Inputs:**
- `--output path/to/new_model.xlsx` (required)
- `--sheets <list>` (optional — which standard sheets to include; default = all)
- `--register references/sumproduct_styles.md` (optional — alternative style register)

**Process (executed in this order — order matters because of IncludeNumber and the H1-band-after-data rule):**

#### Phase A — Style creation (must come first)

1. Parse `sumproduct_styles.md` — extract the 41-style register into Python `StyleSpec` dataclass instances (font, fill, border, alignment, protection, number_format, tick state per group).
2. For each spec, create `openpyxl.styles.NamedStyle` with only the property groups whose tick state is TRUE. Add via `wb.add_named_style(ns)`.
3. Catch `KeyError` on duplicate names — idempotent.

#### Phase B — Skeleton sheets

For each standard sheet (default list: Cover, Navigator, Style Guide, Model Parameters, Timing, Error Checks, Change Log, Timing Template, No Timing Template):

1. Create sheet if it doesn't exist.
2. **A1**: `Sheet Title` style + formula `=IF(ISERROR(RIGHT(CELL("filename",A2),LEN(CELL("filename",A2))-FIND("]",CELL("filename",A2)))),"",RIGHT(CELL("filename",A2),LEN(CELL("filename",A2))-FIND("]",CELL("filename",A2))))` (extracts sheet name from file path).
3. **A2**: `Model Name` style + value `=N_Model_Name`.
4. **A3**: `Hyperlink` style + value `"Navigator"` + `location='HL_Navigator'`. Merge `A3:E3`. Skip on Navigator itself (no self-link).
5. **Column widths** per sheet class (Cover / Navigator / Static / Periodic / Style Guide — see §4a).
6. **Freeze pane** per mechanical rule (§4b): `A6` for static, `J11` for periodic, none for Cover.

#### Phase C — Named ranges

1. Register `HL_Navigator` → `Navigator!$A$1`.
2. For each sheet in tab order, register `HL_NNN` (NNN = 3-digit zero-padded index) → `<SheetName>!$A$3`.
3. Register the `N_*` constants on Model Parameters and Timing per the standard list (Model_Name, Client_Name, Days_in_Year, Months_in_Month/Qtr/Half_Yr/Year, Quarters_in_Year, Periodicity, Reporting_Month_Factor, Model_Start_Date, Example_Reporting_Month, Rounding_Accuracy, Very_Large_Number, Very_Small_Number, Thousand, Overall_Error_Check).
4. The cells those names point at receive their values per the standard (most as `Assumption` style with appropriate `Numbers 0` / `Currency` / `Date` format style applied first per the two-pass pattern).

#### Phase D — Heading staircase + Style Guide sheet content

**For each working sheet** (Model Parameters, Timing, Error Checks, Timing Template, No Timing Template):

1. Apply Heading 1 row (row 6 static, row 11 periodic):
   - B column: `Heading 1 Number` + formula `=MAX($B$prev:$B[N-1])+1`.
   - C through (last-used-col + 1): `Heading 1 Text` style across the band.
2. Where the design has sub-sections, apply Heading 2 / Heading 3 at the staircase positions (row +2 indent +1, row +4 indent +1) — but for the bare skeleton, only Heading 1 is required.
3. Between sections: leave 2 blank rows before the next Heading 1.

**For Style Guide sheet specifically:** populate the three documentation sections (Formatting / Individual / Numerical) per the vSN layout — rows 6/8/10-20, 23/25/27-53, 56/58/60-74 with three columns per row (C = description, I = live example styled with the style, K = style name).

#### Phase E — Verification

1. Open the produced .xlsx with openpyxl, read back, assert:
   - 41 styles present.
   - All sheets exist with correct freeze panes.
   - A3 hyperlinks resolve to `HL_Navigator`.
   - Style Guide sheet's live-example cells render with the expected styles.
2. Print a one-line success summary.

**Implementation notes:**
- Phase A must come before any cell value is written (IncludeNumber trap — styles with applyNumberFormat=TRUE that are added later won't retroactively reformat cells, but a style applied to a cell that already has a number format may overwrite it depending on tick state).
- Phase D's "last-used-col + 1" computation needs the sheet's data extent **after** Phase B/C wrote values — so Heading 1 band styling runs after data writes. This is the inversion of the usual "styles first" rule.
- Use `wb.add_named_style(...)` per style. Catch `ValueError` on duplicate names so re-runs are idempotent.
- The script must NOT require Excel to be installed (openpyxl-only). Distinct from `fm-4-build/references/style_creation_code.md` which uses pywin32 / COM for cells that need active Excel features.

---

## Success criteria

1. `extract_from_template.py path/to/SP Template Model vSN.xlsm` regenerates `sumproduct_styles.md` containing 41 styles with property matrix + tick states.
2. `build_template_workbook.py --output new_model.xlsx` produces a clean starter workbook with:
   - All 41 named styles registered, visible in Home → Cell Styles → Custom.
   - Standard skeleton sheets present: Cover, Navigator, Style Guide, Model Parameters, Timing, Error Checks, Change Log, Timing Template, No Timing Template.
   - Every sheet has Sheet Title in A1, Model Name in A2, Navigator back-link in A3:E3 (merged, `Hyperlink` style, location-based hyperlink to `HL_Navigator`).
   - Working sheets have Heading 1 row at the correct row (6 static, 11 periodic) with B = Heading 1 Number (auto-numbering formula), C → last-used-col + 1 = Heading 1 Text band.
   - Freeze panes set per the mechanical rule (`A6` / `J11` / None).
   - Column widths set per sheet class (Cover / Navigator / Static / Periodic / Style Guide).
   - All named ranges (`HL_NNN`, `HL_Navigator`, `N_*` constants) registered.
   - Style Guide sheet built with three sections (Headers / Individual / Numerical), populated with every style's name, description, and live example.
3. The output workbook opens cleanly in Excel and matches the vSN template's structure section-by-section (allowing for fixed inconsistencies — A3 merged on Cover, Navigator without self-link).
4. The updated `cf_and_column_layout.md` answers all of: "what's the freeze pane on a periodic sheet?", "where does the Heading 1 band end?", "what's the naming convention for an error check cell?", "how many blank rows go between sections?".
5. The fm-3-design SKILL.md still fits within the thin-SKILL.md pattern (under ~120 lines).
6. The script is **idempotent**: re-running it does not duplicate styles or sheets — it skips items that already exist.

## Implementation order

1. **Build `extract_from_template.py`** and run it against vSN. Diff the output against current `sumproduct_styles.md`.
2. **Hand-edit any extraction artefacts** (theme colour resolution failures, edge cases). Commit `sumproduct_styles.md` overwrite.
3. **Expand `cf_and_column_layout.md`** with the new sections (4a corrected column widths, 4b freeze pane rule, 4c heading staircase, 4c.1 two-row inter-section spacing, 4d H1 band rule, 4e named-range convention, 4f CF correction).
4. **Add `style_application_matrix.md`** (NEW reference) with the cell-purpose → (Pass 1 + Pass 2) mapping table.
5. **Update `design_template.md`** with sheet-class column tables + A3 hyperlink convention + freeze pane derivation rule in Section 8.
6. **Update `SKILL.md`** Section 2 (named-range prefix) + Section 6 (point to new column widths) + Section 6.5 (NEW: heading staircase and freeze pane). Position the script as the primary deliverable.
7. **Build `build_template_workbook.py`** in three phases:
   a. Style creation (41 styles + Style Guide sheet) — verify against vSN.
   b. Skeleton sheet creation (Cover, Navigator, Model Parameters, Timing, etc.) with A1/A2/A3 conventions, freeze panes, column widths.
   c. Heading 1 staircase application + named ranges + the two-blank-row inter-section spacing.
8. **Idempotency test** — re-run twice, confirm no duplicates.

Estimated effort: 1 session for the references + the extract script + the markdown updates. 1 additional session for the full `build_template_workbook.py` (the workbook skeleton is the bulk of the work).

# Stylist Rule Catalogue 🎨

The full check catalogue for `ag-stylist-auditor`. Findings table format, severity scale,
and the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what* Stylist
checks and the categories it reports under.

`scripts/stylist_rules.py` covers the deterministic subset of Phases 0, 2, and 3 (convention
detection, named-style/statistical colour-coding deviations, keyword-driven number-format
mismatches). Everything else here is Claude's judgment pass.

---

## Phase 0 — DETECT STYLE CONVENTION

Before any audit begins, determine **what formatting rules this model uses**. Follow this
priority cascade — stop as soon as a reliable convention is found:

### Step 1: Look for a Style Guide Sheet

Search for any sheet whose name contains keywords like: `Style Guide`, `Formatting`, `Legend`,
`Key`, `Standards`, `Convention`, `How to Use`, `Instructions`, `Cover`, `README`, or is named
exactly `L`. (The rule script's sheet-name lookup uses style/legend/key/guide; widen by eye.)

**If no sheet name matches:**
- Scan the first 50 rows of every sheet for a high density of style-related keywords:
  `Table Heading`, `Standard Assumption`, `Offsheet Reference`, `Formatting of Headers`,
  `Style Legend`.
- A sheet containing 3 or more of these keywords is your **Style Guide Sheet**, regardless of
  its name.

Once found, extract and map:

| Element | What to Capture |
|---|---|
| Input / Assumption cells | Font colour, fill colour, font style |
| Formula / Calculation cells | Font colour, fill colour |
| Link cells (cross-sheet) | Font colour, fill colour |
| Table / Section Headings | Font colour, fill colour, bold status, custom number format |
| Hard-coded / Override cells | Font colour, fill colour, any special marker |
| Check / Validation cells | Font colour, fill colour |
| Timing / Date rows | Font colour, fill colour |
| Output / Result cells | Font colour, fill colour |

Store this as the **Detected Style Map**. Skip the style-guide sheet itself in the deviation
scan — a legend deliberately shows every style on demo cells, so flagging it is pure noise.

### Step 2: Inspect Excel Named Cell Styles

Inspect the workbook's **Cell Styles** (named styles). Look for:
- **Input/Assumption:** `Input`, `Assumption`, `Technical_Input`, `Assumption_Flex`
- **Formula/Calculation:** `Calculation`, `Line_Total`, `Line_Operation`, `Line_Summary`, `Line_Subtotal`
- **Link/External:** `Link`, `OffSheet`, `Linked Cell`
- **Header/Heading:** `Table_Heading`, `Header1`, `Header2`, `Header3`, `Sheet_Header`
- **Integrity:** `Check`, `Check Cell`, `WIP`

For each named style found, extract its font colour, fill colour, border, and number format.
Store as the **Detected Style Map**. The rule script adopts named styles as the convention when
≥50% of formula/constant cells carry a custom style.

### Step 3: Statistical Inference from Workbook Analysis

Perform a statistical check across the workbook:

1. **Sample cells across all sheets** (up to 500–1,000 cells, spread proportionally; the rule
   script tallies every populated cell in the extract).
2. **Classify each sampled cell** by type:
   - **Input**: Contains a constant (no formula), not in a header row/column.
   - **Formula**: Contains a formula referencing only the same sheet.
   - **Link**: Contains a formula referencing a different sheet or workbook.
   - **Header / Heading**: In the first row(s)/column(s), bold/merged, OR matching the
     "Table Heading" style.
3. **For each cell type, tally the formatting attributes** (font colour, fill colour, font
   style, border style).
4. **Identify the dominant style per cell type** using majority vote.
5. **Confidence thresholds**:
   - **≥ 75%** → Adopt automatically.
   - **50–74%** → Adopt but flag as "inferred with moderate confidence".
   - **< 50%** → No clear convention; ask the user before proceeding (report under
     **Style Convention Unclear**).

### Output of Phase 0

Produce a **Style Convention Summary** at the top of every audit report (the rule script's
`--convention` flag emits this block):

> *Detection method: [Style Guide Sheet / Named Styles / Statistical Inference]*
> *Confidence: [High / Moderate / Low]*

| Cell Type | Font Colour | Fill Colour | Font Style | Source | Confidence |
|---|---|---|---|---|---|
| Input | Blue (#0000FF) | Light Yellow (#FFFFCC) | Normal | Style Guide | ✅ Definitive |
| Formula | Black (#000000) | No Fill | Normal | Inferred (92%) | ✅ High |
| Link | Green (#008000) | No Fill | Normal | Inferred (78%) | ✅ High |
| Header | White (#FFFFFF) | Dark Blue (#003366) | Bold | Inferred (95%) | ✅ High |

---

## Phase 1 — MAP CONTEXT

Build a **Context Map** for each sheet.

1. **Identify Row Descriptors**: Scan the leftmost populated column(s) for labels (e.g.,
   "Revenue", "DSCR", "Tax Rate").
2. **Identify Column Headers**: Scan the topmost populated row(s) for headers (e.g., "FY2024",
   "Assumption", "Unit").
3. **Identify Section Headers**: Detect merged cells, bold rows, or indentation that define
   logical sections.
4. **Store the Context Map** for use in all subsequent phases.

## Phase 2 — SCAN FORMATTING

Using the **Detected Style Map** from Phase 0:

1. For each populated cell, determine its type (Input / Formula / Link / Header / Heading).
   - **Precedence 1:** If the cell has a **Named Style**, classify it based on that name.
   - **Precedence 2:** If the cell matches the formatting of a **Style Guide Legend** entry,
     classify it as such.
   - **Precedence 3:** Statistical inference based on content (formula vs. constant) and location.
   - **Crucial:** If a cell is classified as a **Heading** (via named style or style guide
     match), do not flag it as a "Hard-coded Input" even if it contains a number.
2. Compare its actual formatting against the expected formatting for that type.
3. Flag deviations. The rule script emits the named-style and ≥75%-confidence statistical
   deviations; below-threshold adjudication, heading exemptions, alignment, and borders are
   Claude's calls.

## Phase 3 — CHECK NUMBER FORMAT

Cross-reference the **number format** against what the row/column context suggests:

| Context Clue (Row Description contains) | Expected Number Format(s) |
|---|---|
| "Rate", "Margin", "%", "Percentage", "Growth" | Percentage (`0.00%`) |
| "Date", "Start", "End", "Maturity" | Date format (`dd/mm/yyyy` or similar) |
| "$", "Revenue", "Cost", "Price", "Balance", "Cash" | Currency / Accounting (`#,##0` or `$#,##0`) |
| "Ratio", "Multiple", "x", "DSCR", "LLCR" | Number with decimals (`0.00x` or `#,##0.00`) |
| "Count", "Units", "Number of", "Qty" | Integer (`#,##0`) |
| "Flag", "Switch", "Yes/No", "Boolean" | General or custom (`0` / `1`) |
| "Name", "Description", "Label", "Status" | Text / General |

**Rules:**
- Allow reasonable tolerances (e.g., `0.0%` vs `0.00%` is minor).
- If a column header suggests a unit (e.g., "Unit" column says "$m"), validate that the row's
  number format is consistent.

## Phase 4 — REPORT

Section A is the Style Convention Summary (Phase 0 output); Section B is the unified findings
table. Table columns, the severity scale, and the Grouping Rule are defined in
`../../_excel-shared/references/audit_standards.md` (§1, §3, §4).

---

## Error categories

Use exactly these values in the findings table's Category column:

| Category | Description |
|---|---|
| **Colour Coding** | Cell formatting doesn't match the Detected Style Map for its type |
| **Alignment Mismatch** | Inconsistent text or number alignment within a block |
| **Border Inconsistency** | Missing or inconsistent border styles |
| **Non-Standard Input** | Hard-coded values without the model's defined Input formatting |
| **Number Format** | Number format doesn't match what row/column context implies |
| **Style Convention Unclear** | No clear convention detected — requires user confirmation |

(The rule script emits **Colour Coding** and **Number Format**; the remaining categories come
from the judgment pass.)

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. Stylist-specific calibration:

- **Critical** — format clearly wrong for context and materially misleading (a percentage
  displayed as a raw decimal in a delivered output; an input masquerading as a formula in a
  convention the model definitively declares).
- **Warning** — suspicious deviation that may be intentional but warrants review (the rule
  script's Colour Coding and Number Format candidates land here by default).
- **Info** — cosmetic consistency issue (alignment drift, border irregularity, minor format
  tolerance differences).

## Special rules

- Never modify values or logic — report only.
- Never assume a fixed colour standard — **always detect first**.
- Do not assess whether formula logic is correct — that is the Logic auditor's responsibility.
- Cell references follow the Grouping Rule in `audit_standards.md` §4 — never "...", "etc.",
  or truncated lists.

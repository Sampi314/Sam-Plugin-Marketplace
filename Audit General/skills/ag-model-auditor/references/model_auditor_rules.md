# Excel Model Auditor — Check Catalogue

Full catalogue of checks performed by `scripts/excel_auditor.py`, the categories
it emits, the CLI surface, the AI judgment pass, and edge-case handling.
Findings format, severity scale, and the cell-range Grouping Rule are defined
once in `../../_excel-shared/references/audit_standards.md` — not here.

## CLI

```bash
python scripts/excel_auditor.py <file_path> [options]
```

| Flag | Description | Default |
|------|-------------|---------|
| `--sheets "Sheet1,Sheet2"` | Target specific sheets (comma-separated) | All sheets |
| `--checks "formula,format,validation,hyperlinks,names,vba,pq,pp"` | Which checks to run | All checks |
| `--output-format xlsx\|md\|html` | Report output format | `xlsx` |
| `--output-path <path>` | Directory for the report and JSON files | Same directory as input file |
| `--severity critical\|warning\|info\|all` | Minimum severity to include | `all` |

The script auto-detects a running Excel instance and attaches to an already-open
workbook; otherwise it starts Excel hidden, opens the file read-only, and closes
everything it opened when done.

## Categories

Every finding carries one of these skill-specific categories (the Category
column in the unified findings table):

| Category | Detects | Typical severity |
|----------|---------|------------------|
| Formula Consistency | Row/column pattern breaks; hardcoded values inside formula ranges | 🔴 Critical / ⚠️ Warning |
| Semantic Logic | Formula operation contradicts its row label / column header (rules R001–R012) | 🔴 Critical / ⚠️ Warning |
| Formatting | Inconsistent number formats, mixed fonts, inconsistent decimal places | ⚠️ Warning / 🟡 Info |
| Hyperlinks | Broken internal targets, missing external files | ⚠️ Warning / 🟡 Info |
| Name Manager | Named ranges containing `#REF!`, uninspectable names | 🔴 Critical / 🟡 Info |
| Data Validation | Validation rules referencing broken ranges | ⚠️ Warning |
| VBA Code | Missing `Option Explicit`, `.Select`/`.Activate`, Shell calls, hardcoded paths, locked projects | ⚠️ Warning / 🟡 Info |
| Power Query | Hardcoded file paths, missing `try...otherwise` error handling | ⚠️ Warning / 🟡 Info |
| Power Pivot | `CALCULATE` without explicit filter context | 🟡 Info |

## Check catalogue (priority order)

### 1. Formula Consistency & Semantic Logic — priority Critical

**Consistency checks (deterministic):**

- Formulas that break row/column patterns (e.g. a column of `=B2*C2`, `=B3*C3`,
  `=B4*D4` — flags row 4). A pattern is "dominant" when ≥70% of the formulas in
  the row/column share one normalised signature; outliers are flagged Critical.
- Hardcoded values inside ranges that otherwise contain formulas (≥60% formulas
  in a run of ≥3 cells) — flagged Warning, because a typed-over constant
  silently freezes the calculation.
- Formula references that skip expected cells.
- Circular references.

**Semantic logic checks (two-pass):**

- **Pass 1 — rule-based (deterministic, in the script).** The label-pattern
  rules live in `references/semantic_rules.md` (R001–R012). They catch common
  mismatches such as:
  - Label says "Total" but the formula doesn't use SUM/SUBTOTAL or addition
  - Label says "per unit" / "average" but the formula multiplies without dividing
  - Label says "%" / "percentage" but the result isn't a ratio
  - Label says "Variance" / "Difference" but the formula doesn't subtract
  - Label says "Growth" but the formula isn't period-over-period
- **Pass 2 — AI judgment (Claude, after the script).** Formulas that match no
  rule but look suspicious (multiple operator types, INDIRECT/OFFSET, vague
  labels) are written to `ambiguous_formulas_<workbook>.json` for review — see
  *AI judgment pass* below.

### 2. Formatting & Style Consistency — priority Warning

- Inconsistent number formats within logical ranges (column-dominant format
  vs. minority outliers)
- Mixed font styles/sizes within sections (sheet flagged when >3 font/size
  combinations appear)
- Inconsistent decimal places in financial figures
- Missing or inconsistent cell borders in tables
- Unlocked cells in protected sheets (or vice versa)
- Inconsistent column widths for similar data
- Colour-coding inconsistencies (e.g. input cells not highlighted)

### 3. Hyperlinks, Name Manager & Data Validation — priority Warning

**Hyperlinks:**

- Tests every hyperlink target: internal sheet references, external file links, URLs
- Flags links pointing to deleted sheets or invalid ranges; external file links
  whose target no longer exists

**Name Manager:**

- Lists all named ranges and checks for:
  - Names referencing `#REF!` errors (Critical — the name is dead)
  - Unused named ranges
  - Workbook vs. sheet scope conflicts
  - Names pointing to deleted sheets

**Data Validation:**

- Documents all data validation rules
- Inconsistent validation within logical ranges
- Validation rules referencing broken (`#REF!`) ranges
- Cells whose current value conflicts with their own validation rule

### 4. VBA / Power Query / Power Pivot Code Review — priority Info

**VBA:**

- Extracts all modules, classes, and userforms (requires "Trust access to the
  VBA project object model"; a locked project is reported, not skipped silently)
- Flags: `.Select`/`.Activate` usage, missing `Option Explicit`, unqualified
  `Range` references, error-handling gaps, hardcoded paths
- Potentially dangerous code: Shell commands, file-system access

**Power Query:**

- Extracts all M code from workbook connections
- Hardcoded file paths, missing `try...otherwise` error handling, inefficient
  step ordering
- Validates that source references are accessible

**Power Pivot:**

- Extracts DAX measures (best-effort via the COM Model object)
- Common issues: missing `ALL()` in ratio measures, `CALCULATE` without
  filters, inefficient iterator usage
- Validates measure references against existing tables/columns

## AI judgment pass

The script performs deterministic checks only. Judgment calls — intentional-error
filtering, semantic label matching beyond the R-rules, spelling, business
rules — stay with Claude. After the script completes, it writes
`ambiguous_formulas_<workbook>.json`: formulas that matched no rule but have
characteristics worth reviewing. For each entry:

1. Read the formula, its resolved references, and the surrounding labels
   (row label, column header, cell value — all included in the JSON).
2. Decide whether the formula's operation matches the label's semantic meaning.
3. Mismatch → add a finding (severity ⚠️ Warning) with a clear explanation in
   the Description of Issue, including `— Recommend:` guidance.
4. Formula appears correct → skip it; do not pad the report.

The ambiguous-case taxonomy (multiple operations, nested functions, vague
labels, cross-sheet references, named ranges, INDIRECT/OFFSET, UDF/LAMBDA
calls) is defined at the end of `references/semantic_rules.md`.

**Worked example:**

- Cell `E10` has formula `=C10*D10` (Price × Quantity)
- Row label: "Price per Item"; column header: "Calculation"
- **Finding** (⚠️ Warning, Semantic Logic): the formula calculates Total Price
  (Price × Quantity), but the label suggests a unit price — Recommend: divide
  by quantity or reference the unit price directly if "per item" is intended.

## Report outputs

All formats use the unified specialist findings table defined in
`../../_excel-shared/references/audit_standards.md` §1 (Sheet | Cell Reference |
Description of Location | Severity | Category | Description of Issue). The
script emits one row per affected cell; apply the Grouping Rule
(audit_standards.md §4) when summarising or consolidating, so identical issues
collapse into range references.

| File | Content |
|------|---------|
| `Audit_Report_<workbook>_<stamp>.xlsx` | Summary sheet (counts by category × severity) + All Findings sheet |
| `Audit_Report_<workbook>_<stamp>.md` | Severity summary + unified findings table |
| `Audit_Report_<workbook>_<stamp>.html` | Styled standalone page, severity colour-coded |
| `audit_findings_<workbook>.json` | Findings in the audit_standards.md §5 interchange schema, `agent: "model-auditor"` |
| `ambiguous_formulas_<workbook>.json` | Queue for the AI judgment pass |

## Edge cases

- **Merged cells** — flag but don't crash; note merged ranges in findings.
- **Array formulas / SPILL ranges** — handle CSE `{=...}` and dynamic arrays.
- **External links** — flag `[Book.xlsx]` references as potential issues.
- **Very large workbooks** — process sheet-by-sheet (`--sheets`) to manage
  memory; per-cell COM reads are the bottleneck.
- **Protected workbooks** — report when the VBA project is password-protected
  (code cannot be extracted) rather than silently skipping.

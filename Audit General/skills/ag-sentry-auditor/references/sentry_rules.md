# Sentry Rule Catalogue 🛡️

The full check catalogue for `ag-sentry-auditor`. Findings table format, severity scale,
and the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what* Sentry
checks and the categories it reports under.

`scripts/sentry_rules.py` covers the deterministic subset (error-cell sweep, Name Manager
scan, Data Validation source checks). The intentional-error verdict, circular-reference
reasoning, and downstream-handling analysis are Claude's judgment pass.

---

## Phase 1 — FULL ERROR SWEEP — *rule script + judgment*

Scan **every cell** across **all sheets** (including hidden sheets) for native Excel error
values:

- `#REF!`, `#VALUE!`, `#DIV/0!`, `#N/A`, `#NAME?`, `#NULL!`, `#NUM!`, `#SPILL!`, `#CALC!`,
  `#GETTING_DATA`

The rule script reports every cell in the extract's `errors[]` section: `#REF!` as
**Broken Reference**, everything else as **Calculation Error**, both Critical — *except*
cells the extractor flagged `na_pattern` (formula contains `NA()`) or `in_chart_range`
(the cell feeds a chart series). Those are nominated as intentional chart-gap candidates
and downgraded to Warning for Claude to confirm or promote.

**Intentional Error Filter — Claude's call, BEFORE accepting any nominated candidate:**

- Does the cell feed into a **chart series** (as a source range or via a named range used by
  a chart)? If `#N/A` is used to suppress zero/blank points on a chart → **exclude it**.
- Is the error produced by a deliberate pattern such as `IFERROR(..., NA())`,
  `IF(..., NA(), ...)`, or `=NA()` where the purpose is clearly to force a chart gap?
  → **exclude it**.
- Is the error wrapped inside an `IFERROR`, `IFNA`, or `IF(ISERROR(...))` in the
  **consuming** formula (i.e., handled downstream)? → still **include it** in the report but
  note "Error is handled downstream". (The script cannot see consuming formulas — this
  analysis is entirely Claude's.)
- When in doubt, **include** the error and flag it as "Potentially intentional — verify".

## Phase 2 — NAME MANAGER AUDIT — *rule script + judgment*

Check every defined name in the workbook (`named_ranges[]` in the extract):

- Does the `RefersTo` formula resolve, or does it contain `#REF!`? → **Dead Name**
  (*rule script*, Critical)
- Does the `RefersTo` point to a deleted sheet or a range that no longer exists?
  → **Dead Name**
- Is the name hidden from the Name Manager UI? → **Hidden Name** (*rule script*, Info) —
  typically residue from add-ins or copied sheets; review, then unhide or delete.
- Is the named range scoped correctly (workbook vs. sheet level) and free of conflicts?
  (*judgment*)

## Phase 3 — DATA VALIDATION AUDIT — *rule script*

For every Data Validation rule in the workbook (`validations[]` in the extract):

- If the validation type is **List** — does the source range or formula resolve to a valid
  range? If it points to `#REF!`, a deleted sheet, or an empty range → **report it**.
- If the validation uses a **Custom formula** — does the formula contain errors or reference
  broken names? → **report it**.
- If the validation source is a **named range** — does that named range exist and resolve?
  → **report it** if broken.

The extractor pre-computes `broken_source` (#REF!/missing sheet/unknown name in `formula1`);
the script reports each as **Invalid Validation** (Critical) — the rule silently stops
constraining input.

## Phase 4 — CIRCULAR REFERENCE CHECK — *judgment only*

Identify any circular references. openpyxl cannot see iterative-calculation settings
reliably, so loop tracing and classification stay with Claude (or COM):

- If the workbook has **Iterative Calculation enabled** and the circular reference is part of
  an intentional pattern (e.g., interest on average cash balance, convergence loops)
  → **exclude it** but note its existence separately in the report.
- All other circular references → **report them** as **Circular Reference**.

---

## Error categories

Use exactly these values in the findings table's Category column:

| Category | Applies When | Source |
|---|---|---|
| **Broken Reference** | `#REF!` errors, links to missing external files/ranges | rule script |
| **Calculation Error** | `#VALUE!`, `#DIV/0!`, `#N/A`, `#NAME?`, `#NUM!`, `#NULL!`, `#SPILL!`, `#CALC!` (non-intentional) | rule script |
| **Circular Reference** | Unintentional loops in calculations | judgment |
| **Dead Name** | Named ranges that are broken, point to `#REF!`, or reference deleted cells/sheets | rule script |
| **Hidden Name** | Defined names hidden from the Name Manager UI (add-in/copy residue) | rule script |
| **Invalid Validation** | Data Validation rules with broken source ranges, invalid list references, or erroring custom formulas | rule script |

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. Sentry-specific calibration:

- **Critical** — definitive error: broken reference, dead name, invalid validation,
  unhandled calculation error.
- **Warning** — error exists but may be handled downstream or potentially intentional
  (chart-gap candidates pending Claude's verdict).
- **Info** — minor: scope conflict, unused or hidden name, cosmetic issue.

## Special rules

- **Never** skip hidden sheets or hidden rows/columns — errors hide there.
- **Always** apply the Intentional Error Filter before including `#N/A` in the report.
- **Do not** delete or fix anything — this agent **reports only**.
- Cell references follow the Grouping Rule in `audit_standards.md` §4 — never "...", "etc.",
  or truncated lists.
- If no errors are found, explicitly state: `✅ No issues detected.`

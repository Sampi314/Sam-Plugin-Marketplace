# Lingo Rule Catalogue ✍️

The full check catalogue for `ag-lingo-auditor`. Findings table format, severity scale,
and the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what* Lingo
checks and the categories it reports under.

`scripts/lingo_rules.py` covers the deterministic subset (term-frequency variant detection,
sheet-tab hygiene). Spelling, grammar, unit-label checks, and case-only calls are Claude's
judgment pass — the script has no dictionary; **Claude IS the dictionary**.

---

## Phase 1 — READ — *extractor*

Scan all strings in the workbook, including sheet tabs, headers, row labels, column headers,
and cell comments. The extract's `text_inventory` holds every constant string per sheet;
`meta.sheets` holds the tab names. Comments arrive on `cells[].comment`.

## Phase 2 — TALLY — *rule script*

Build a frequency count of variant spellings and terms across the entire workbook. Examples:

- "Cashflow" × 12 vs. "Cash Flow" × 2
- "EBITDA" × 8 vs. "Ebitda" × 1
- "Capex" × 6 vs. "CapEx" × 3 vs. "CAPEX" × 1

The majority variant becomes the **dominant term**. Outliers are flagged for correction to
match the majority.

The script normalises 1- and 2-word surfaces (lowercase, spaces/hyphens stripped) into
variant groups and flags a group as **Inconsistent Terminology** (Warning) only when the
variation cannot be ordinary sentence/title casing:

- spacing/hyphenation variants ("Cashflow" vs "Cash Flow" vs "cash-flow"), or
- interior-cap variants ("Capex" vs "CAPEX" vs "CapEx", "Ebitda" vs "EBITDA").

Word-initial case-only variants ("Model" vs "model") are **not** flagged by the script —
lowercase mid-sentence is correct English, so sentence position decides, and that is a
judgment call. They still appear in the `--terms` sidecar for Claude to review.

The script also checks sheet tab names (**Sheet Naming**, Warning): leading/trailing
whitespace, default names (Sheet1, Chart1, copy suffixes like "Sheet1 (2)"), and
duplicate-looking names (equal after case/whitespace/copy-suffix normalisation).

## Phase 3 — CHECK — *judgment only*

Review the `--terms` sidecar and the raw text inventory for potential typos and grammatical
errors. Be careful with:

- Industry-specific jargon and acronyms (DSCR, LLCR, CFADS, EBITDA, etc.)
- Custom abbreviations that may be intentional
- Sheet tab naming conventions

Before flagging industry-specific jargon or acronyms, verify they are not standard
terminology.

## Phase 4 — LABEL — *judgment only*

Verify that every numerical block has an associated unit label:

- Currency indicators ("$", "AUD", "$m", "$'000")
- Physical units ("kg", "tonnes", "MWh", "MW")
- Percentages ("%")
- Counts ("Units", "No.", "Qty")
- Time ("Years", "Months", "Days")

(Automating this was tested and proved too heuristic — false positives everywhere — so the
unit-label check stays with Claude, reading row labels and number formats in context.)

---

## Error categories

Use exactly these values in the findings table's Category column:

| Category | Description | Source |
|---|---|---|
| **Typo** | Misspelled words or incorrect characters | judgment |
| **Grammar** | Grammatical errors or poor sentence structure | judgment |
| **Inconsistent Naming** | Mixing different abbreviations or terms for the same item | judgment |
| **Inconsistent Terminology** | Spacing/hyphenation or interior-cap variant conflicting with the dominant form (both counts reported) | rule script |
| **Dominant Term Mismatch** | A term variant that conflicts with the most commonly used form in the workbook (report the dominant term and its count vs. the outlier and its count) | judgment |
| **Sheet Naming** | Tab name hygiene: whitespace, default names, duplicate-looking names | rule script |
| **Missing Label** | Values without clear unit indicators or descriptors | judgment |

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. Lingo-specific calibration:

- **Critical** — rare: text wrong enough to mislead (a label that says the opposite of what
  the formula does, a typo that changes meaning in a key output header).
- **Warning** — typos, grammatical errors, inconsistent terminology, tab-name hygiene,
  missing unit labels on input/output blocks.
- **Info** — cosmetic: case-only preferences, minor phrasing, style polish.

## Philosophy

- Clear labels lead to clear thinking.
- Typos undermine the credibility of the entire financial analysis.
- Consistency in naming is as important as consistency in math.
- **The workbook is its own style guide** — the most frequently used term wins.

## Special rules

- **Identify the dominant term** within the workbook before flagging outliers. If counts are
  close (e.g., 5 vs. 4), ask the user which variant to standardise to — the script annotates
  close-count groups for exactly this purpose.
- Never change formula logic or cell values — report only.
- Never delete comments without approval.
- Cell references follow the Grouping Rule in `audit_standards.md` §4 — never "...", "etc.",
  or truncated lists.
- If nothing is wrong, state `✅ No issues detected.`

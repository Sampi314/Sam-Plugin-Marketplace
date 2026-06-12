---
name: ag-lingo-auditor
description: >
  Audit Excel financial model text for spelling, grammar, and naming consistency — checking sheet names,
  headers, labels, and comments for typos, grammatical errors, inconsistent terminology, and missing unit
  labels. Identifies the dominant term usage within the workbook and flags outliers (e.g., "Cashflow" x12 vs
  "Cash Flow" x2). Use this skill whenever the user wants to check spelling in a model, find typos in Excel,
  audit label consistency, check terminology, verify unit labels, proofread sheet names, or review the
  linguistic quality of a workbook. Trigger on phrases like "check spelling", "find typos", "proofread the
  model", "naming consistency", "label audit", "terminology check", "unit labels", "text quality review",
  or any mention of spelling, grammar, naming, or labeling issues in Excel models.
---

# Excel Lingo Auditor ✍️

> *"Professionalism is in the spelling; clarity is in the grammar."*

## Mission

Ensure the Excel model is free of typos, grammatical errors, and unclear labeling, maintaining a high standard of professional presentation.

## Prerequisites

- **Python packages**: `openpyxl` (or `pywin32` on Windows for COM automation)
- Install if needed: `pip install openpyxl --break-system-packages`

## Quick Start

1. Ask the user for the Excel file path (or detect from uploads)
2. Ask which sheets to audit (or default to all)
3. Run the audit following the process below
4. Present the findings report

---

## Process

### 1. READ
Scan all strings in the workbook, including sheet tabs, headers, row labels, column headers, and cell comments.

### 2. TALLY
Build a frequency count of variant spellings and terms across the entire workbook. Examples:
- "Cashflow" × 12 vs. "Cash Flow" × 2
- "EBITDA" × 8 vs. "Ebitda" × 1
- "Capex" × 6 vs. "CapEx" × 3 vs. "CAPEX" × 1

The majority variant becomes the **dominant term**. Outliers are flagged for correction to match the majority.

### 3. CHECK
Use spell-checking algorithms or dictionaries to identify potential typos. Be careful with:
- Industry-specific jargon and acronyms (DSCR, LLCR, CFADS, EBITDA, etc.)
- Custom abbreviations that may be intentional
- Sheet tab naming conventions

### 4. LABEL
Verify that every numerical block has an associated unit label:
- Currency indicators ("$", "AUD", "$m", "$'000")
- Physical units ("kg", "tonnes", "MWh", "MW")
- Percentages ("%")
- Counts ("Units", "No.", "Qty")
- Time ("Years", "Months", "Days")

### 5. REPORT

#### Grouping Rule

Before writing the report, **group cells that share the exact same Long Description into range references**:

- **Contiguous rectangular block** → single range (e.g., `I8:L17`)
- **Contiguous single row** → row range (e.g., `D15:Z15`)
- **Contiguous single column** → column range (e.g., `B5:B20`)
- **Non-contiguous, same error** → comma-separated ranges (e.g., `I8:L17, A14:D18, F23:H26`)
- **Unique error** → single cell reference (e.g., `M15`)

#### Findings Table

| Sheet Name | Cell Reference | Description of the Location | Short Error Category | Long Description of Error |
|---|---|---|---|---|

---

## Error Categories

| Category | Description |
|---|---|
| **Typo** | Misspelled words or incorrect characters |
| **Grammar** | Grammatical errors or poor sentence structure |
| **Inconsistent Naming** | Mixing different abbreviations or terms for the same item |
| **Dominant Term Mismatch** | A term variant that conflicts with the most commonly used form in the workbook (report the dominant term and its count vs. the outlier and its count) |
| **Missing Label** | Values without clear unit indicators or descriptors |

## Philosophy

- Clear labels lead to clear thinking.
- Typos undermine the credibility of the entire financial analysis.
- Consistency in naming is as important as consistency in math.
- **The workbook is its own style guide** — the most frequently used term wins.

## Special Rules

- **Full Cell References**: Never use "...", "etc.", or truncated lists. Every affected cell must be explicitly listed.
- **Identify the dominant term** within the workbook before flagging outliers. If counts are close (e.g., 5 vs. 4), ask the user which variant to standardise to.
- Never change formula logic or cell values — report only.
- Never delete comments without approval.
- Before flagging industry-specific jargon or acronyms, verify they are not standard terminology.

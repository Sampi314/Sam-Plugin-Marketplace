---
name: fm-3-design
description: >
  Phase 3 of the financial model build lifecycle — the formatting-specification
  phase. Define the model's Cell Styles, Named Ranges, Number Formats, Data
  Validation rules, Conditional Formatting rules, and Column Layout conventions
  so Phase 4 (Build) can execute mechanically. Use this skill when defining
  model formatting standards, designing Cell Styles, planning Named Ranges,
  specifying Data Validation, or creating formatting conventions. Trigger on
  'design the styles', 'define formatting', 'Cell Style spec', 'named range
  plan', 'data validation design', or after completing the Plan phase.
---

# Phase 3: Design 🎨

> *"A well-designed model speaks before you read a single formula."*

## Mission

Define every visual and structural specification the model needs — Cell Styles, Named Ranges, Number Formats, Data Validation, Conditional Formatting, Navigation, and Column Layout. The output is `design.md` — a complete spec that Phase 4 (Build) executes mechanically.

## Input

`scope.md` from Phase 1 and `plan.md` from Phase 2.

## Important Reference

Before designing, read:
1. `references/sumproduct_styles.md` — Complete specification of all 30 Cell Styles extracted from production SumProduct models, with RGB and BGR colour values, pywin32 code, and IncludeNumber flags
2. `references/validation_and_formats.md` — Complete catalogue of Data Validation rules by input type and Number Format strings with usage guide (COM constants live in `../fm-4-build/references/com_reference.md`)
3. `references/design_template.md` — the exact structure `design.md` must follow; this is the Phase 4 input contract

## Process

### 1. DEFINE CELL STYLES

SumProduct models use **Excel Cell Styles** (not direct formatting). Every cell gets a Named Style applied via the Cell Styles gallery (Home → Cell Styles → Custom section).

The 30-style register and the pywin32 `create_all_styles(wb)` function live in:

- `references/sumproduct_styles.md` — the human-readable style register (colours, fonts, purpose).
- `references/style_creation_code.md` — the pywin32 code that creates them, the style application rules table, and the Assumption-style trap example.

**Key rules:**

1. Styles are created once at the workbook level, then applied to cells. Never format cells directly.
2. Call `create_all_styles(wb)` **before** any sheet content is built — otherwise styles with `IncludeNumber=True` will overwrite number formats you've already set.
3. `Assumption` style has `IncludeNumber=False`. Apply the style first, then set the number format separately. See the trap example in `references/style_creation_code.md`.

### 2. DEFINE NAMED RANGES

Produce the complete Named Range register from the plan. See Phase 4 references for the full list. Minimum required ranges:

**Technical Constants** (Model Parameters sheet): Days_in_Year, Months_in_Month, Months_in_Qtr, Months_in_Half_Yr, Months_in_Year, Quarters_in_Year, Rounding_Accuracy, Very_Large_Number, Very_Small_Number, Thousand.

**Unit Labels** (Model Parameters sheet): Unit, Currency, Dollars, Boolean, Percentage, No_of_Days, Year, No_of_Years, Multiplier, plus any project-specific units.

**Timing** (Timing sheet): Model_Start_Date, Periodicity, Number_of_Periods, Example_Reporting_Month, Reporting_Month_Factor.

**Navigation** (per sheet): HL_Navigator, HL_1 through HL_n, Overall_Error_Check.

**Error Checks** (BS/CFS sheets): HL_BS_Errors, HL_BS_Balance, HL_BS_Insolvency, HL_Op_BS_Errors, etc.

### 3. DEFINE NUMBER FORMATS

Use the complete format catalogue in `references/validation_and_formats.md`
(standard/summary numbers, percentages, dates, error-check tick/cross,
section numbers, row refs, hidden, decimals, scientific — with a
segment-by-segment explanation and a "choosing the right format" guide).

### 4. DEFINE DATA VALIDATION

Use the validation rule catalogue in `references/validation_and_formats.md`
(rules per input type for Timing and General Assumptions inputs; the pywin32
constants needed at Build time are in `../fm-4-build/references/com_reference.md`).

### 5. DEFINE CONDITIONAL FORMATTING

Use the standard CF rules in `references/cf_and_column_layout.md` (error-check
green/red, inactive-period greying, per-period BS/CFS checks).

### 6. DEFINE COLUMN LAYOUT

Use the standard column layout in `references/cf_and_column_layout.md`
(columns A–J+ widths, purposes, typical styles). Non-periodic sheets deviate
freely; the layout governs periodic working sheets.

### 7. CONFIRM WITH USER

Present a design summary — style deltas from the standard register, named-range
count, validation and CF rule counts, any column-layout deviations — and get
explicit user confirmation before handing `design.md` to Phase 4. Every other
phase ends with this checkpoint; keeping the lifecycle consistent means the
user signs off each artefact before the next phase consumes it. Do not proceed
to Build until confirmed.

## Output

Produce `design.md` structured exactly per `references/design_template.md`:
0 Header · 1 Cell Styles (with deltas) · 2 Named Range register · 3 Number
Format registry · 4 Data Validation spec · 5 Conditional Formatting rules ·
6 Column layout · 7 Navigation spec · 8 Build notes & exceptions. Phase 4
consumes it section by section — keep the numbering intact.

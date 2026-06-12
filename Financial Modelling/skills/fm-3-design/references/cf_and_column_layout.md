# Conditional Formatting Rules & Column Layout

Companion to `validation_and_formats.md` (validation rules + number formats)
and `style_creation_code.md` (Cell Styles). Together these three files hold
the complete Design-phase specification detail.

## Standard Conditional Formatting Rules

| Range | Rule | Format |
|-------|------|--------|
| Error check cells | =0 | Green fill (0xCEEFC6), dark green font (0x006100) |
| Error check cells | <>0 | Red fill (0xCEC7FF), dark red font (0x06009C) |
| Period data columns | Counter > Number_of_Periods | Grey fill, grey font (inactive) |
| BS check cells per period | =0 / <>0 | Same green/red as error checks |
| CFS check cells per period | =0 / <>0 | Same green/red as error checks |

Colours are BGR (COM convention) — see `fm-4-build/references/com_reference.md`.

## Standard Column Layout

| Column | Width | Purpose | Typical Style |
|--------|-------|---------|--------------|
| A | 2 | Sheet name overflow | Sheet Title / Model Name |
| B | 5 | Section numbers | Heading 1 Number |
| C | 3 | Section headings | Heading 1/2/3 Text |
| D | 3 | Sub-headings | Heading 2/3 Text |
| E | 30 | Row labels | Line Calc / Assumption |
| F | 2 | Spacer | Empty |
| G | 10 | Units | Units |
| H | 10 | Row references | Row Ref |
| I | 12 | Summary / Opening BS | Row_Summary / Assumption |
| J+ | 12 each | Period columns | Line Calc / Assumption |

Non-periodic sheets (Cover, Navigator, dashboards) deviate freely — this
layout governs the periodic working sheets (Assumptions, Calculations,
statements, schedules).

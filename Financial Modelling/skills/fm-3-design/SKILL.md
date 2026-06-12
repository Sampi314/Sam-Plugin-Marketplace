---
name: fm-3-design
description: >
  Phase 3 of the SumProduct financial model build lifecycle — the
  formatting-specification phase. Defines Cell Styles, Named Ranges, Number
  Formats, Data Validation, Conditional Formatting, Column Layout, Heading
  Staircase, Freeze Pane, and Heading 1 band rules so Phase 4 (Build) can
  execute mechanically. Use when defining model formatting standards,
  designing Cell Styles, planning Named Ranges, specifying Data Validation,
  or creating formatting conventions. Trigger on 'design the styles',
  'define formatting', 'Cell Style spec', 'named range plan', 'data
  validation design', 'create template workbook', or after completing the
  Plan phase.
---

# Phase 3: Design 🎨

> *"A well-designed model speaks before you read a single formula."*

## Mission

Define every visual and structural specification the model needs and hand Phase 4 (Build) a starter workbook that already obeys every convention. The output of this phase is twofold:

1. `design.md` — the per-model spec Phase 4 consumes (see `references/design_template.md`).
2. A clean starter `.xlsx` produced by `scripts/build_template_workbook.py` — already carries the 41 styles, Style Guide sheet, skeleton sheets, named ranges, freeze panes, column widths, and Heading 1 bands.

## Inputs

`scope.md` (Phase 1) and `plan.md` (Phase 2).

## How to use this skill

Read **only the reference(s) relevant to the decision you're making**. The references are intentionally narrow — single-topic — so you don't pay token cost for the rest.

| When you need to decide / answer | Read |
|---|---|
| Which Cell Styles exist; their fonts, fills, borders, number formats, and tick states | `references/sumproduct_styles.md` |
| Which style goes on which cell (input vs calc vs total vs heading vs error check) | `references/style_application_matrix.md` |
| How to apply styles (two-pass pattern, IncludeNumber trap, when to call create) | `references/style_creation_code.md` |
| What column widths to set on each sheet class | `references/column_widths.md` |
| Where to put the freeze pane | `references/freeze_pane_rule.md` |
| How to lay out Heading 1 / 2 / 3 within a sheet | `references/heading_staircase.md` |
| How wide the Heading 1 band runs across the heading row | `references/heading_1_band.md` |
| How to name a Named Range (`N_*` constant, `HL_NNN` nav target) | `references/named_range_convention.md` |
| What CF rules go on error checks and inactive period columns | `references/conditional_formatting.md` |
| What Data Validation rule goes on each input type | `references/data_validation.md` |
| Which Number Format string to apply for an ad-hoc cell that no style covers | `references/number_formats.md` |
| Structure of `design.md` — the artefact handed to Phase 4 | `references/design_template.md` |

## How to use the scripts

| Goal | Run |
|---|---|
| Produce a clean starter workbook for a new model | `python scripts/build_template_workbook.py --output new_model.xlsx` |
| Refresh the reference markdowns from an updated template | `python scripts/extract_from_template.py --template path/to/template.xlsm --output references/` |

The build script is **idempotent** — re-running it on the same workbook will not duplicate styles or sheets.

## Process

1. **Read `scope.md` and `plan.md`** to understand the model's named-range needs, periodicity, and sheet list.
2. **Decide deltas from the standard register** — most models adopt the 41-style register and standard widths/freeze panes verbatim. Per-model deviations (a new client-specific colour, an extra period column on Cover) belong in `design.md` Section 1a (style deltas) or Section 8 (build notes).
3. **Run `scripts/build_template_workbook.py`** to produce the starter workbook. Verify it opens and the Style Guide sheet renders.
4. **Write `design.md`** per `references/design_template.md`. For sections where the standard applies unchanged, say "Standard — no deltas" rather than omitting.
5. **Confirm with the user** before handing to Phase 4. Present: style deltas, named-range count, validation/CF rule counts, any column-layout or freeze-pane deviations. Do not proceed to Build until confirmed.

## Output

- `design.md` — structured per `references/design_template.md` (0 Header · 1 Cell Styles + deltas · 2 Named Range register · 3 Number Format registry · 4 Data Validation spec · 5 Conditional Formatting rules · 6 Column layout · 7 Navigation · 8 Build notes & exceptions).
- A clean starter workbook from `scripts/build_template_workbook.py`.

Phase 4 consumes `design.md` section by section against the starter workbook — keep the numbering intact.

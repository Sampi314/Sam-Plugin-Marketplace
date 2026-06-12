# Cell Style Creation — Contract and Application Pattern

The canonical *implementation* of style creation lives in `scripts/build_template_workbook.py` (`phase_a_create_styles`). This file describes the *contract* — what callers and downstream phases must respect.

## When to call

Call the style-creation phase **before any cell value is written** to any worksheet. Styles registered later cannot retroactively reformat cells that already have direct number formatting applied.

```
1. wb = Workbook()
2. build_template_workbook.phase_a_create_styles(wb)   # styles first
3. (write data / values to cells)
4. (apply styles to cells)
```

## The two-pass application pattern

A cell that needs both a number format AND a coloured fill receives **two styles in sequence**, not one combined style. Each style "ticks" a different property group.

### Pass 1 — Format style (sets the number format, no fill)

- `applyNumberFormat = TRUE`
- `applyFill = FALSE` (fill is "none", so the cell inherits its prior background)

Format-style examples: `Comma`, `Comma [0]`, `Currency`, `Currency [0]`, `Per cent`, `Numbers 0`, `Date`, `Date Heading`, `Internal Ref`, `Line Calc`, `Row Ref`, `Right Currency`, `Right Number`, `Row_Summary`.

### Pass 2 — Visual style (adds fill/border, preserves format)

- `applyNumberFormat = FALSE` — so Pass 1's format survives
- `applyFill = TRUE` — the colour goes here

Visual-style examples: `Assumption`, `Parameter`, `Constraint`, `WIP`, `Empty`, `Notes`, `Range Name Description`, `Accounts Ref`, `Table_Heading`.

### Worked example — currency input cell

```python
cell.style = "Currency"      # Pass 1: number format = _-"$"* #,##0.00 etc.
cell.style = "Assumption"    # Pass 2: yellow fill, format survives because applyNumberFormat=False
```

### Combined styles — single pass

Some styles tick both `applyNumberFormat` and `applyFill` and must be applied alone (cannot be layered): `Heading 1 Number`, `Heading 1 Text`, `Error_Checks`, `Empty`, `Row_Summary`, `Internal Ref`, `Line Calc`, `Line Total`, `Row Ref`, `Date Heading`, `Table_Heading`.

## The IncludeNumber trap

`Assumption` and other Visual-style entries have `applyNumberFormat = FALSE` deliberately. If a Visual style applied number format, every currency-vs-percentage input would need its own coloured Visual style — multiplying the style count. The "False" lets one yellow `Assumption` overlay any of the format styles.

If a future style is added with both fill AND number format set, the build script must either:
1. Mark it Combined and apply it alone (preferred for fixed positions like Heading bands), or
2. Set `applyNumberFormat = FALSE` to keep it Visual and layerable.

## Required reading order

For each design decision, read the matching focused reference:

- Which style on which cell? → `style_application_matrix.md`
- What's in the style register? → `sumproduct_styles.md`
- How is `Style Guide` sheet built? → see `scripts/build_template_workbook.py` `phase_d_style_guide_sheet`
- What number formats exist outside the style register? → `validation_and_formats.md`

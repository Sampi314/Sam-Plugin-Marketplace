# Conditional Formatting Rules

## Standard rules

| Range | Rule | Format |
|---|---|---|
| Error check cells | `cellIs equal 0` | Green fill `#CEEFC6`, dark green font `#006100` |
| Error check cells | `cellIs notEqual 0` | Red fill `#CEC7FF`, dark red font `#06009C` |
| Period data columns | `formula: Counter > N_Number_of_Periods` | Grey fill, grey font (inactive periods) |
| BS check cells per period | =0 / <>0 | Same green/red as error checks |
| CFS check cells per period | =0 / <>0 | Same green/red as error checks |

Colours are CSS hex (RGB). The `style_creation_code.md` BGR/COM equivalents are: green `0xC6EFCE` (fg) / `0x006100` (font); red `0xFFC7CE` (fg) / `0x9C0006` (font).

## Application — cell-by-cell, not range-wide

Apply one CF rule per error cell, not a sheet-wide range that covers all of them. Cell-by-cell rules:

- Give each error its own independent formatting metadata.
- Survive cell moves and inserts.
- Are easier to audit in Phase 5 — each rule maps to one error check.

The vSN template's Error Checks sheet has CF rules on F4, I12, I17 individually (not on a single F4:I17 range).

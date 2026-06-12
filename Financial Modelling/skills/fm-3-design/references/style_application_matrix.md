# Style Application Matrix

Which style goes on which cell purpose. Cells that need both a number format AND a coloured fill receive **two styles in sequence** — see `style_creation_code.md` §2a for the two-pass pattern.

| Cell purpose | Pass 1 (format style) | Pass 2 (visual style) | Column | Example |
|---|---|---|---|---|
| Section number (Heading 1) | — | `Heading 1 Number` (combined) | B | Model Parameters B6 |
| Heading 1 text band | — | `Heading 1 Text` | C → last col | Model Parameters C6:R6 |
| Heading 2 text | — | `Heading 2 Text` | C → … | Model Parameters C8 |
| Heading 3 text | — | `Heading 3 Text` | D or E → … | Model Parameters E10 |
| Sheet title | — | `Sheet Title` | A1 | every sheet |
| Model name | — | `Model Name` | A2 | every sheet |
| Back-link to Navigator | — | `Hyperlink` | A3:E3 merged | every sheet except Navigator |
| Date heading (period col) | — | `Date Heading` (combined) | row 5 across J+ | Timing J5 |
| Row label | — | `Line Calc` | E | periodic sheets |
| Units column | — | `Units` | G | periodic sheets |
| Row reference | — | `Row Ref` (combined) | H | periodic sheets |
| Currency input | `Currency` or `Currency [0]` | `Assumption` | I+ | Model Parameters G19 |
| Percentage input | `Per cent` | `Assumption` | I+ | growth rates |
| Date input | `Date` | `Assumption` | I+ | Timing H15 |
| Plain-number input | `Numbers 0` | `Assumption` | I+ | Model Parameters G20 |
| Currency parameter | `Currency` or `Comma` | `Parameter` | I+ | Model Parameters G31 |
| Hard-coded constant | — | `Constraint` | inline | one-off cells |
| Work-in-progress marker | — | `WIP` | any | dev-only |
| Notes / commentary | — | `Notes` | any | inline annotations |
| Calculation result | `Comma` or `Currency` | `Line Calc` | I+ | calc sheets |
| Subtotal row | `Comma` or `Currency` | `Line Total` (combined, top thin border) | I+ | subtotals |
| Grand total | `Comma` or `Currency` | `Total` (combined, top thin + bottom double border) | I+ | end-of-section |
| Error check (tick / cross) | — | `Error_Checks` (combined) | F or I | Error Checks F4, I12, I17 |
| Empty placeholder (grey) | — | `Empty` (combined, gray125 fill) | any | blank cells |
| Internal reference | `Internal Ref` (combined) | — | any | reference rows |
| Row summary column | `Row_Summary` (combined) | — | I | balance sheet |

When a client requests a new style:

1. Add it to the `sumproduct_styles.md` register (or re-extract from an updated template).
2. Add a row to this matrix specifying its Pass 1 / Pass 2 role and cell purpose.
3. Re-run `scripts/build_template_workbook.py` — every new workbook gets the new style baked in.

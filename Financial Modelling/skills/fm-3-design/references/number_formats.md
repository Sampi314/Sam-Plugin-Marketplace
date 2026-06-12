# Number Format Catalogue

For format codes embedded in named styles, see the **NumberFormat** column of `sumproduct_styles.md`. The catalogue below is for **standalone formatting** — when no style provides the format you need.

## Standard model formats

| Purpose | Format String | Display Example | When to Use |
|---|---|---|---|
| Standard numbers | `_(#,##0_);[Red]\(#,##0\);_("—"_);` | 1,234 / (1,234) / — | Most calculated values |
| Summary numbers | `_-* #,##0_-;[Red]* \(#,##0\);_-* "-"_-;_-@_-` | 1,234 / (1,234) / "-" | Summary/total columns (I) |
| Two decimal places | `_(#,##0.00_);[Red]\(#,##0.00\);_("—"_.00);` | 1,234.56 / (1,234.56) | Ratios, rates, per-unit values |
| Percentages (whole) | `0%` | 5% / 50% / 100% | Growth rates, margins, tax rates |
| Percentages (1dp) | `0.0%` | 5.5% / 12.3% | Interest rates, precise rates |
| Percentages (2dp) | `0.00%` | 5.50% | Very precise rates |
| Full date | `[$-C09]d mmm yy;@` | 1 Jul 24 | Date values in data rows |
| Heading date | `mmm yy` | Jun 25 | Period header labels (row 5) |
| Section number | `#,##0"."` | 1. / 2. / 3. | Section numbering (col B) — built into `Heading 1 Number` style |
| Row reference | `"Row "###0` | Row 47 | Cross-reference indicators (col H) — built into `Row Ref` style |
| Error check | `"ý";"ý";"þ"` | ✓ or ✗ | Wingdings tick/cross — built into `Error_Checks` style |
| Hidden | `;;;` | (nothing) | Suppressed cells — built into `Empty` style |
| Scientific | `0.E+00` | 1.E+99 | Very large/small numbers (Model Parameters) |
| Integer | `#,##0` | 1,234 | Counts, units, headcount |
| Multiplier | `0.0"x"` | 1.5x | DSCR, multiples, ratios |
| Currency (symbol, 0dp) | `"$"* _(#,##0_);"$"* \(#,##0\);"$"* _("—"_)` | $ 1,234 | Currency with symbol — rare in models |
| Currency (symbol, 2dp) | `"$"* _(#,##0.00_);"$"* \(#,##0.00\);"$"* _("—"_.00)` | $ 1,234.56 | Currency with 2dp |

## Format segments explained

Excel custom formats have up to 4 segments separated by semicolons:

```
positive ; negative ; zero ; text
```

- `_(` — adds space equal to width of `(` — aligns positives with negative brackets.
- `[Red]` — colour the negative values red.
- `\(` and `\)` — literal brackets around negatives.
- `"—"` — display an em-dash for zero values.
- `_-` — adds space equal to width of `-`.
- `#,##0` — number with thousands separator, no decimals.
- `0%` — multiply by 100 and show `%` symbol.
- `[$-C09]` — locale (English Australia); affects month/day name spelling.

## Choosing the right format

| Row label contains | Apply format |
|---|---|
| Revenue, Cost, Price, Balance, Cash, Debt, Asset, Liability, Equity | Standard numbers or 2dp |
| Rate, Margin, Growth, Inflation, Yield, Percentage, % | Percentage (0% or 0.0%) |
| Date, Start, End, Maturity, Settlement | Date format |
| Count, Units, Volume, Quantity, Headcount, Number of | Integer (`#,##0`) |
| Days, Day count | Integer (`#,##0`) |
| Ratio, Multiple, DSCR, LLCR, x | Multiplier (`0.0"x"`) or 2dp |
| Flag, Switch, Boolean, Yes/No | General or hidden |
| Year, Period, Counter | Integer or General |

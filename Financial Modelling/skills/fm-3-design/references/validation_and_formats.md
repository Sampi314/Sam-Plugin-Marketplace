# Validation & Number Format Catalogue

> Complete catalogue of Data Validation rules and Number Format strings used in SumProduct models.

## Data Validation Rules

### Timing Sheet

| Cell | Input | Validation Type | Formula1 | Input Title | Input Message |
|------|-------|----------------|----------|-------------|---------------|
| Number of Periods | Integer | List | `"5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20"` | Number of Periods | Select the total number of forecast periods (5–20) |
| Periodicity | Integer | List | `"1,2,3,4,6,12"` | Periodicity | Months per period: 1=Monthly, 3=Quarterly, 6=Half-yearly, 12=Annual |
| Reporting Month | Integer | List | `"1,2,3,4,5,6,7,8,9,10,11,12"` | Reporting Month | Financial year end month: 1=January ... 12=December |
| Model Start Date | Date | Date ≥ | `"01/01/2000"` | Start Date | Enter the first day of the first period |

### General Assumptions — by Input Type

| Input Type | Validation Type | Operator | Formula1 | Formula2 | Input Message | Error Message |
|-----------|----------------|----------|----------|----------|---------------|---------------|
| Percentage (0–100%) | Decimal | Between | `0` | `1` | Enter as decimal: 0.05 = 5% | Value must be between 0 and 1 |
| Percentage (can exceed 100%) | Decimal | GreaterEqual | `0` | — | Enter as decimal: 1.5 = 150% | Value must be ≥ 0 |
| Positive integer | Whole Number | GreaterEqual | `0` | — | Enter a whole number ≥ 0 | Must be a non-negative integer |
| Positive number (with decimals) | Decimal | GreaterEqual | `0` | — | Enter a number ≥ 0 | Must be non-negative |
| Day count (0–365) | Whole Number | Between | `0` | `365` | Enter days (0–365) | Days must be between 0 and 365 |
| Day count (0–90) | Whole Number | Between | `0` | `90` | Enter days (0–90) | Days must be between 0 and 90 |
| Year count | Whole Number | Between | `1` | `50` | Enter useful life in years | Must be 1–50 years |
| Boolean switch | List | — | `"0,1"` | — | 0 = Off, 1 = On | Select 0 or 1 |
| Currency amount (any sign) | Decimal | — | — | — | Enter amount | — |
| Scenario selector | List | — | Named range or comma list | — | Select scenario | Must select from list |
| Date | Date | GreaterEqual | `=Model_Start_Date` | — | Enter a date on or after model start | Date must be ≥ start date |

### pywin32 Validation Constants

The COM constants behind these rules (validation types, operators, alert
styles) live in `../../fm-4-build/references/com_reference.md` — the single
source of truth for COM constants. Look values up there at Build time rather
than copying them here.

---

## Number Format Catalogue

### Standard Model Formats

| Purpose | Format String | Display Example | When to Use |
|---------|--------------|----------------|-------------|
| Standard numbers | `_(#,##0_);[Red]\(#,##0\);_("—"_);` | 1,234 / (1,234) / — | Most calculated values |
| Summary numbers | `_-* #,##0_-;[Red]* \(#,##0\);_-* "-"_-;_-@_-` | 1,234 / (1,234) / "-" | Summary/total columns (I) |
| Two decimal places | `_(#,##0.00_);[Red]\(#,##0.00\);_("—"_.00);` | 1,234.56 / (1,234.56) | Ratios, rates, per-unit values |
| Percentages (whole) | `0%` | 5% / 50% / 100% | Growth rates, margins, tax rates |
| Percentages (1dp) | `0.0%` | 5.5% / 12.3% | Interest rates, precise rates |
| Percentages (2dp) | `0.00%` | 5.50% | Very precise rates |
| Full date | `[$-C09]d mmm yy;@` | 1 Jul 24 | Date values in data rows |
| Heading date | `mmm yy` | Jun 25 | Period header labels (row 5) |
| Section number | `#,##0"."` | 1. / 2. / 3. | Section numbering (col B) |
| Row reference | `"Row "###0` | Row 47 | Cross-reference indicators (col H) |
| Error check | `"ý";"ý";"þ"` | ✓ or ✗ | Error check cells (with Wingdings font via CF) |
| Hidden | `;;;` | (nothing) | Suppressed cells |
| Scientific | `0.E+00` | 1.E+99 | Very large/small numbers (Model Parameters) |
| Integer | `#,##0` | 1,234 | Counts, units, headcount |
| Multiplier | `0.0"x"` | 1.5x | DSCR, multiples, ratios |
| Currency (symbol) | `"$"* _(#,##0_);"$"* \(#,##0\);"$"* _("—"_)` | $ 1,234 | Currency with symbol (rare in models) |
| Currency (2dp) | `"$"* _(#,##0.00_);"$"* \(#,##0.00\);"$"* _("—"_.00)` | $ 1,234.56 | Currency with 2dp |

### Format Segments Explained

Excel custom formats have up to 4 segments separated by semicolons:
```
positive ; negative ; zero ; text
```

- `_(` — adds space equal to width of "(" — aligns positive with negative brackets
- `[Red]` — colour the negative values red
- `\(` and `\)` — literal brackets around negative values
- `"—"` — display an em-dash for zero values
- `_-` — adds space equal to width of "-"
- `#,##0` — number with thousands separator, no decimals
- `0%` — multiply by 100 and show % symbol

### Choosing the Right Format

| Row Description Contains | Apply Format |
|-------------------------|-------------|
| Revenue, Cost, Price, Balance, Cash, Debt, Asset, Liability, Equity | Standard numbers or 2dp |
| Rate, Margin, Growth, Inflation, Yield, Percentage, % | Percentage (0% or 0.0%) |
| Date, Start, End, Maturity, Settlement | Date format |
| Count, Units, Volume, Quantity, Headcount, Number of | Integer (#,##0) |
| Days, Day count | Integer (#,##0) |
| Ratio, Multiple, DSCR, LLCR, x | Multiplier (0.0"x") or 2dp |
| Flag, Switch, Boolean, Yes/No | General or hidden |
| Year, Period, Counter | Integer or General |

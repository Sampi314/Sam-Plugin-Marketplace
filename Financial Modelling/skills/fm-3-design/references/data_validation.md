# Data Validation Rules

## Timing sheet

| Cell | Input | Validation Type | Formula1 | Input Title | Input Message |
|------|-------|----------------|----------|-------------|---------------|
| Number of Periods | Integer | List | `"5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20"` | Number of Periods | Select the total number of forecast periods (5–20) |
| Periodicity | Integer | List | `"1,2,3,4,6,12"` | Periodicity | Months per period: 1=Monthly, 3=Quarterly, 6=Half-yearly, 12=Annual |
| Reporting Month | Integer | List | `"1,2,3,4,5,6,7,8,9,10,11,12"` | Reporting Month | Financial year end month: 1=January ... 12=December |
| Model Start Date | Date | Date ≥ | `"01/01/2000"` | Start Date | Enter the first day of the first period |

## General assumptions — by input type

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
| Date | Date | GreaterEqual | `=N_Model_Start_Date` | — | Enter a date on or after model start | Date must be ≥ start date |

## pywin32 validation constants

The COM constants behind these rules (validation types, operators, alert styles) live in `../../fm-4-build/references/com_reference.md`. Look up values there at Build time rather than copying them here.

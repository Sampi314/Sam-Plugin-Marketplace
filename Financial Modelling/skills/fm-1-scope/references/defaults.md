# Scoping Defaults (when the user doesn't specify)

These defaults apply to **3-statement / project finance** models. For other
model types (budget, commission, dashboard, optimisation, etc.), the
"Statements/Opening BS/Depreciation/Working capital" defaults do NOT apply —
match the conventions in the matching `questions/<type>.md` file instead.

| Parameter | Default | When this default applies |
|-----------|---------|---------------------------|
| Periodicity | Annual (12 months) | All models. Suggest monthly for cashflow forecasts and commission models; quarterly for project finance |
| Forecast periods | 10 | All models |
| FY end month | June (month 6) | All models — ask, varies by jurisdiction |
| Currency | AUD | All models — Sam base |
| Scale | Thousands ('000) | All financial models. Use whole numbers for headcount, units, or per-unit metrics |
| Statements | IS + BS + CFS | **3-statement / project finance only** — skip entirely for budget, commission, dashboard, valuation-only, cost allocation, optimisation |
| Opening BS | Yes | **3-statement only** |
| Depreciation | Straight-line | **Models that include CapEx and a Balance Sheet** |
| Tax rate | 30% | **Models that include tax** (Australian corporate rate) |
| Working capital | Include | **3-statement / project finance only** |

Always tell the user which defaults you applied, and mark them
`[Assumed — confirm with client]` in scope.md.

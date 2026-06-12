# extract.json — Schema & Per-Auditor Consumption Map

Produced by `../scripts/extract_workbook.py`. One extraction serves every
auditor: **extract once, audit many times.** The audit-manager extracts at the
start of an orchestrated run and passes the path to each specialist; a
specialist running solo extracts for itself.

```
python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json --digest digest.md
```

## openpyxl vs COM split

`extract_workbook.py` is pure openpyxl: works with Excel closed, parallel-safe,
cross-platform. Two things live outside the file format's readable parts and
need the COM bridge (`../scripts/excel_automation.py`, Windows + Excel only):
**Power Query M code** (ag-pq-auditor) and **VBA source** (ag-vba-auditor).

## Top-level keys

| Key | Shape | Notes |
|---|---|---|
| `meta` | `{file, sheet_count, sheets: [{name, dims, max_row, max_col, state, tab_color}], truncated_sheets?}` | `state`: visible / hidden / veryHidden |
| `cells` | `{sheet: [{addr, r, c, v?, f?, r1c1?, fmt?, style?, font?, fill?, align?, borders?, merged?, comment?}]}` | Only populated cells; only non-default keys present. `fmt` = number format (absent if General), `style` = named Cell Style (absent if Normal), `fill` = solid fill ARGB, `borders` = subset of "TBLR" |
| `r1c1_rows` | `{sheet: [{row, n_patterns, patterns: {r1c1_sig: [addrs]}}]}` | Pattern-break pre-compute: `n_patterns > 1` = break candidate |
| `r1c1_cols` | same, per column | |
| `errors` | `[{sheet, addr, error, formula, na_pattern, in_chart_range}]` | `na_pattern` = formula contains `NA()`; `in_chart_range` = cell feeds a chart series (intentional-#N/A candidates) |
| `named_ranges` | `[{name, refers_to, scope, broken, hidden}]` | `broken` = contains #REF! |
| `validations` | `[{sheet, sqref, type, operator, formula1, formula2, broken_source}]` | `broken_source` = #REF!/missing sheet/unknown name in formula1 |
| `conditional_formatting` | `[{sheet, range, type, operator, formulas, priority}]` | |
| `hyperlinks` | `[{sheet, addr, target, display, internal, source, broken}]` | `source`: "ui" or "formula" (parsed `HYPERLINK()`); `broken` checked for internal targets |
| `text_inventory` | `{sheet: [{addr, text}]}` | Every constant string: labels, headers, narrative |
| `dependencies` | `{sheet_edges: [{from, to, count}]}` | Cross-sheet formula reference counts; `[external]` prefix = external workbook |
| `styles` | `[{name, custom}]` | Workbook Cell Styles registry |
| `charts` | `[{sheet, title, series_ranges}]` | Best-effort via openpyxl |

## Who reads what

| Auditor | Primary sections |
|---|---|
| Sentry 🛡️ | `errors` (+ `na_pattern`/`in_chart_range` for the intentional filter), `named_ranges`, `validations` |
| Logic 🧠 | `r1c1_rows`, `r1c1_cols`, `cells` (formulas + labels via `text_inventory`) |
| Stylist 🎨 | `cells` (style/fmt/font/fill), `styles`, `conditional_formatting` |
| Efficiency ⚡ | `cells` (formula length), `r1c1_rows` (redundancy) |
| Lingo ✍️ | `text_inventory`, `meta.sheets` (tab names) |
| Architect 🏗️ | `dependencies`, `r1c1_rows`, `meta` |
| Hyperlinks 🔗 | `hyperlinks`, `meta.sheets` (orphan detection) |
| Cartographer 🗺️ | `dependencies`, `named_ranges`, `validations`, `conditional_formatting` (shadow layer), `charts` |
| Navigator 🧭 | `cells`, `text_inventory`, `dependencies` |
| AI Auditor 🤖 | `cells` (has its own scanner too) |
| PQ ⚡ / VBA 📦 | not in extract.json — use `excel_automation.py` |

## Size control

`--max-cells` (default 200,000) caps per-cell records; pattern groups, errors,
and inventories always cover the whole workbook regardless. Truncation is
recorded in `meta.truncated_sheets`. For huge models, run per-sheet with
`--sheets` rather than raising the cap blindly.

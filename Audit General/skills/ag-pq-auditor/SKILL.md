---
name: ag-pq-auditor
description: >
  Audit Power Query M code in Excel workbooks for performance issues, data quality risks, security concerns,
  coding standards violations, and architecture problems. Extracts M code using pywin32 COM automation, then
  runs rule-based checks covering: query folding breaks, duplicate data sources, missing type enforcement,
  hardcoded file paths, embedded credentials, missing error handling, auto-generated step names, long queries,
  and circular dependencies. Use this skill whenever the user wants to review Power Query code, audit M code,
  check PQ performance, find security issues in queries, or review data pipeline quality. Trigger on "review
  Power Query", "audit PQ", "check M code", "query performance", or any mention of Power Query auditing.
---

# Excel PQ Auditor ⚡

> *"Data in, garbage out — unless you audit the pipeline."*

## Mission

Audit Power Query M code for performance, data quality, security, standards, and architecture
problems. The split is strict: deterministic pattern checks run in `scripts/pq_audit.py`; judgment
calls (is that `Table.Buffer` a justified folding sacrifice? is that flagged "token" really a
credential?) stay with Claude.

## Prerequisites

- **Workbook extraction**: Windows + Excel + `pywin32` (`pip install pywin32`). Power Query
  definitions are invisible to openpyxl and absent from `extract.json`, so extraction goes through
  the **shared COM bridge** `../_excel-shared/scripts/excel_automation.py` — only the rule engine
  `scripts/pq_audit.py` lives in this skill. The bridge starts its own hidden Excel instance,
  opens the workbook read-only, and always quits on exit.
- **No Excel needed** for `--m-dir` (loose `.m` files) or `--demo` — those paths are pure Python.

## Quick Start

```
python scripts/pq_audit.py <workbook.xlsx> [--json OUT|-] [--md OUT|-]   # COM extract + rules
python scripts/pq_audit.py --m-dir <folder> [--json OUT|-] [--md OUT|-]  # loose .m files, no Excel
python scripts/pq_audit.py --demo                                        # self-test on embedded bad queries
```

`-` writes to stdout; with neither flag the markdown findings table prints to stdout. A workbook
with no queries prints `No Power Query queries found` and exits 0.

## Workflow

1. **Extract** — `pq_audit.py <workbook>` extracts internally. To pull the M code yourself (e.g.
   to save it for line-by-line review), use the shared bridge from a script in this skill's
   `scripts/` folder:

   ```python
   import sys
   from pathlib import Path
   sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

   from excel_automation import excel_app, open_workbook, PowerQueryManager

   with excel_app() as xl:
       with open_workbook(xl, r"C:\path\model.xlsx") as wb:
           queries = {q["name"]: q["formula"] for q in PowerQueryManager.list_queries(wb)}
   ```

2. **Rule script** — deterministic checks only: `audit_pq_query(name, m_code)` per query (folding
   breaks, late column/row reduction, redundant or missing type enforcement, expand-all-columns,
   missing `try ... otherwise`, hardcoded paths, credentials, `Expression.Evaluate`, non-HTTPS
   `Web.Contents`, auto-generated step names, long queries, dead steps, uncommented queries) and
   `audit_pq_architecture(queries)` across queries (circular references, duplicate data sources,
   shared hardcoded paths needing a parameter query).

3. **Claude judgment pass** — work through the Claude-side checks in `references/pq_rules.md`:
   query inventory and load destinations, join null-handling, date culture/locale, unencrypted
   database connections, transformation logic duplicated across queries — and vet every script
   finding (the credential regex is deliberately greedy; a late filter may be deliberate).

4. **Report** — emit the unified findings table. Format, severity scale, the cell-range Grouping
   Rule, and the findings JSON schema are defined once in
   `../_excel-shared/references/audit_standards.md` (§1, §3–5) — follow them exactly. PQ findings
   use sheet `(Power Query)`, cells = query name(s), location `Query: <name>`. Report only —
   never modify M code. If nothing is wrong: `✅ No issues detected.`

## Reference map

| Read | For |
|---|---|
| `references/pq_rules.md` | Full rule catalogue (script/Claude split), error categories, judgment guidance |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | extract.json schema — PQ is *not* in it; this skill uses the COM bridge instead |
| `../_excel-shared/scripts/excel_automation.py` | Shared COM bridge: `excel_app`, `open_workbook`, `PowerQueryManager` |

# Power Query Audit Rules — ag-pq-auditor

The complete check catalogue for the PQ Auditor. Findings format, the severity
scale, the cell-range Grouping Rule, and the findings JSON schema are defined
once in `../../_excel-shared/references/audit_standards.md` — they are not
repeated here.

**Detected by** says who runs the check: **Script** = deterministic rule in
`../scripts/pq_audit.py` (`audit_pq_query` per query, `audit_pq_architecture`
across queries); **Claude** = judgment call no regex can make. Every Script
finding still gets a Claude sanity pass — the script nominates, Claude vets.

---

## Phase 1 — INVENTORY (Claude)

List all queries: name, type (table / connection-only / function / parameter),
load destination (worksheet, Data Model, connection only). Map dependencies
between queries. Identify data sources. Note query groups. This inventory is
context for every later phase — e.g. a "Dead Step" in a connection-only
staging query may be deliberate scaffolding.

## Phase 2 — PERFORMANCE

| Check | Severity | Category | Detected by |
|---|---|---|---|
| Query folding break: `Table.Buffer` mid-query (any step before the last) | 🔴 Critical | Query Folding Break | Script |
| Query folding break: `Table.Sort` before a later `Table.SelectRows` | 🔴 Critical | Query Folding Break | Script |
| Column reduction (`Table.SelectColumns`/`RemoveColumns`/`RemoveOtherColumns`) first applied after the midpoint of the step chain | ⚠️ Warning | Loading Excess Columns | Script |
| No column filtering at all on a wide source | ⚠️ Warning | Loading Excess Columns | Claude (needs source width) |
| Row filtering (`Table.SelectRows`) first applied after the midpoint | ⚠️ Warning | Late Row Filter | Script |
| No row filtering applied early when the logic allows it | ⚠️ Warning | Late Row Filter | Claude |
| Redundant repeated `Table.TransformColumnTypes` steps | 🟡 Info | Redundant Type Conversion | Script |
| Multiple queries hitting the same source independently | 🔴 Critical | Duplicate Data Source | Script (architecture) |
| `Table.ExpandTableColumn` with a `null` column list (expand all) | ⚠️ Warning | Expand All Columns | Script |

Judgment overlay: `Table.Buffer` is sometimes a *justified* folding sacrifice
(e.g. stabilising a sort before a merge, or forcing a single read of a slow
source). The script flags it; Claude decides whether to keep, downgrade, or
annotate the finding.

## Phase 3 — DATA QUALITY

| Check | Severity | Category | Detected by |
|---|---|---|---|
| Fallible source call (`File.Contents`, `Web.Contents`, `Excel.Workbook`, `Csv.Document`, `Json.Document`, `Xml.Tables`, `OData.Feed`, `Sql.Database`) with no `try ... otherwise` | 🔴 Critical | No Error Handling | Script |
| Type-conversion steps unguarded by `try`/error-tolerant conversion (no fallible source present) | 🟡 Info | No Error Handling | Script |
| No `Table.TransformColumnTypes` anywhere (output columns left as `any`) | 🔴 Critical | Missing Type Enforcement | Script |
| Types applied earlier but the final step is not type-enforced | ⚠️ Warning | Missing Type Enforcement | Script |
| Joins (`Table.NestedJoin`/`Table.Join`) without null/missing-value handling | ⚠️ Warning | No Error Handling | Claude |
| Date/number parsing without explicit culture/locale | ⚠️ Warning | Missing Type Enforcement | Claude |

## Phase 4 — SECURITY

| Check | Severity | Category | Detected by |
|---|---|---|---|
| Hardcoded drive or UNC paths (`"C:\..."`, `"\\server\..."`) | 🔴 Critical | Hardcoded File Path | Script |
| Embedded credentials (`password=`, `pwd=`, `apikey`, `api_key`, `token`, `secret`, ...) | 🔴 Critical | Embedded Credentials | Script |
| `Expression.Evaluate` (dynamic code execution) | 🔴 Critical | Dynamic Code Execution | Script |
| `Web.Contents` over plain `http://` | ⚠️ Warning | External URL | Script |
| External HTTPS URLs — endpoint legitimacy and approval | ⚠️ Warning | External URL | Claude |
| Unencrypted database connections | ⚠️ Warning | Embedded Credentials | Claude (connection metadata) |

Judgment overlay: the credential regex is deliberately greedy — a column named
`Token` or a step renaming `Secret Santa` will trip it. Claude confirms a real
secret before reporting (and recommends rotation if one has been exposed).

## Phase 5 — STANDARDS

| Check | Severity | Category | Detected by |
|---|---|---|---|
| Auto-generated step names (`#"Changed Type1"`, `#"Removed Columns"`, ...) | ⚠️ Warning | Auto-generated Step Names | Script |
| Query exceeds 20 transformation steps | ⚠️ Warning | Long Query | Script |
| Long query (>15 lines) without a single comment | 🟡 Info | Uncommented Query | Script |
| Dead steps — `let` bindings never referenced by a later step or the output | ⚠️ Warning | Dead Step | Script |
| Same transformation logic duplicated across queries (should be a function) | ⚠️ Warning | Duplicate Data Source | Claude |

## Phase 6 — ARCHITECTURE (cross-query)

| Check | Severity | Category | Detected by |
|---|---|---|---|
| Circular dependencies between queries | 🔴 Critical | Circular Dependency | Script |
| Duplicate data source connections (same source call in 2+ queries) | 🔴 Critical | Duplicate Data Source | Script |
| Same hardcoded path shared by 2+ queries (needs a parameter query) | ⚠️ Warning | Missing Parameterisation | Script |
| Hardcoded dates, server names, or environment values that should be parameters | ⚠️ Warning | Missing Parameterisation | Claude |

The script's reference graph is heuristic (query names matched as `#"Name"`
literals or bare identifiers) — a step that shadows another query's name can
produce a false edge. Claude verifies any reported cycle before it reaches the
report.

---

## Error categories

| Category | Description |
|---|---|
| **Query Folding Break** | A step order that stops the source doing the work (buffer mid-query, sort before filter) |
| **Duplicate Data Source** | Multiple queries hitting the same source independently, or duplicated transformation logic |
| **Loading Excess Columns** | Not filtering columns early enough |
| **Late Row Filter** | Not filtering rows early enough |
| **Redundant Type Conversion** | Multiple type-conversion steps |
| **Expand All Columns** | `Table.ExpandTableColumn` with a `null` column list |
| **No Error Handling** | Missing `try ... otherwise` on fallible operations |
| **Missing Type Enforcement** | Output columns not explicitly (or finally) typed |
| **Hardcoded File Path** | Local/UNC paths embedded in M code |
| **Embedded Credentials** | Passwords or API keys in plain text |
| **External URL** | Web data source needing verification (non-HTTPS is auto-flagged) |
| **Dynamic Code Execution** | `Expression.Evaluate`, especially with user-supplied input |
| **Auto-generated Step Names** | Default names from the PQ editor |
| **Long Query** | Query exceeds 20 transformation steps |
| **Uncommented Query** | Long query with no comments |
| **Dead Step** | `let` binding defined but never referenced |
| **Circular Dependency** | Queries referencing each other |
| **Missing Parameterisation** | Shared hardcoded paths/values that should live in a parameter query |

## Finding fields (PQ-specific)

PQ findings have no cell addresses: `sheet` is always `(Power Query)`, `cells`
holds the query name(s) involved, and `location` is `Query: <name>` (or
`Query dependency graph` / `Data sources` for architecture findings).
`r1c1_expected`/`r1c1_actual` stay null. Everything else follows
`audit_standards.md`.

## Script CLI (scripts/pq_audit.py)

```
python pq_audit.py <workbook.xlsx> [--json OUT|-] [--md OUT|-]   # COM extraction
python pq_audit.py --m-dir FOLDER  [--json OUT|-] [--md OUT|-]   # loose .m files
python pq_audit.py --demo                                        # embedded bad-query self-test
```

Workbook mode needs Windows + Excel + pywin32 (shared bridge
`../../_excel-shared/scripts/excel_automation.py`); it prints
`No Power Query queries found` and exits 0 when the workbook has none.
`--m-dir` and `--demo` are pure Python. The demo exits 1 if its deliberately
bad queries yield fewer than 6 findings.

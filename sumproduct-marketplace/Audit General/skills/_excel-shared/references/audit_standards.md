# Audit Standards — Single Source of Truth

Canonical definitions for the entire `excel-*` audit family. Every auditor
emits findings in these formats; the audit-manager consolidates on the
assumption that they do. **Change formats here, never in individual skills.**

---

## 1. Findings table — specialist auditors

Every specialist (Sentry, Logic, Stylist, Lingo, Efficiency, Architect,
Hyperlinks, VBA, PQ, AI, Model) reports findings in exactly this table:

```markdown
| Sheet | Cell Reference | Description of Location | Severity | Category | Description of Issue |
|---|---|---|---|---|---|
| Calculations | J47:AC47 | Revenue calculation row | 🔴 Critical | Formula Pattern Break | Breaks dominant row pattern. Expected R1C1: `=R[-2]C*R[-1]C`. Actual: `=R[-2]C*R[-1]C+100` — Recommend: restore the uniform formula or document the exception |
```

Column rules:

- **Sheet** — exact tab name.
- **Cell Reference** — grouped ranges per the Grouping Rule (§4). Never "..."
  or truncated lists.
- **Description of Location** — what the row/section is (its label), so the
  reader can find it without opening the file.
- **Severity** — exactly one of the three §3 values, emoji included.
- **Category** — from the skill's own category list (categories stay
  skill-specific; they are defined in each skill's `references/<skill>_rules.md`).
- **Description of Issue** — plain statement of the problem. For formula
  findings, the expected and actual R1C1 signatures are **mandatory**
  (`Expected R1C1: ... Actual: ...`). Append a recommendation after
  `— Recommend:` where useful.

If a specialist finds nothing, it states: `✅ No issues detected.`

## 2. Consolidated table — audit-manager / detailed-audit-report

The consolidated report uses the same columns plus two prefixes:

```markdown
| ID | Agent | Sheet | Cell Reference | Description of Location | Severity | Category | Description of Issue |
```

- **ID** — `F001`-style sequence, assigned at consolidation time (specialists
  never assign IDs).
- **Agent** — specialist name + emoji, e.g. `Sentry 🛡️`, `Logic 🧠`.

## 3. Severity scale

| Severity | Meaning | Delivery impact |
|---|---|---|
| 🔴 **Critical** | Definitive error — wrong output, broken reference, integrity compromised | Must fix; blocks delivery |
| ⚠️ **Warning** | Suspicious or bad practice — may be intentional, warrants review | Fix, or user explicitly accepts |
| 🟡 **Info** | Cosmetic / consistency / awareness item | Nice to fix; not blocking |

JSON values: `"critical"` / `"warning"` / `"info"`.

**Legacy mapping** (for older skill text and historic reports):
`🔴 HIGH:` → Critical · `⚠️ MEDIUM:` → Warning · `🟡 LOW:` → Info ·
model-auditor's Critical/Warning/Info → identity. Severity used to be a prefix
inside the Long Description; it is now a **dedicated column** — prefix parsing
was the fragile step in consolidation.

## 4. Grouping Rule (canonical text — stated here only)

Before reporting, group cells that share the same Severity, Category, and
Description of Issue into range references:

- Contiguous rectangular block → `I8:L17`
- Contiguous single row → `D15:Z15`
- Contiguous single column → `B5:B20`
- Non-contiguous, same issue → comma-separated ranges `I8:L17, F23:H26`
- Unique issue → single cell `M15`

Never use "...", "etc.", or truncated lists — every affected cell must be
explicitly covered by a listed range. *Why: ungrouped findings bury one real
issue under 40 identical rows; truncated lists make the report unactionable.*

`audit_lib.cells_to_ranges()` implements this rule — rule scripts get it for free.

## 5. Findings JSON interchange schema

Rule scripts and specialists exchange findings as JSON so the audit-manager
can consolidate mechanically:

```json
{
  "findings": [
    {
      "agent": "sentry",
      "sheet": "Calculations",
      "cells": ["J47:AC47"],
      "location": "Revenue calculation row",
      "severity": "critical",
      "category": "Formula Pattern Break",
      "description": "Breaks dominant row pattern — Recommend: restore uniform formula",
      "r1c1_expected": "=R[-2]C*R[-1]C",
      "r1c1_actual": "=R[-2]C*R[-1]C+100"
    }
  ]
}
```

`r1c1_expected` / `r1c1_actual` are null for non-formula findings.
`audit_lib.emit_json()` / `load_findings()` read and write this shape.

## 6. Consolidation rules (audit-manager)

- **Dedup key**: `(sheet, overlapping cell ranges, category)`. Same key from
  two agents → keep the more detailed finding, append
  `(also flagged by <agent>)`. Different categories on the same cell → keep
  both; they are different concerns.
- **Severity on merge** = max (Critical > Warning > Info).
- **Sort order**: Severity desc → Sheet (workbook tab order) → first cell
  (row, then column).
- **ID assignment**: `F001…` after sorting.
- Implemented by `ag-audit-manager/scripts/consolidate_findings.py`.

## 7. Shared reporting etiquette

- Auditors **report only** — never modify the model without explicit instruction.
- Hidden sheets/rows/columns are always in scope (errors hide there).
- If a check cannot run (e.g. VBA on a non-Windows host), say so in the report
  rather than silently skipping.

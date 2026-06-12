---
name: ag-vba-auditor
description: >
  Audit VBA code in Excel workbooks for security risks, performance issues, error handling gaps, coding
  standards violations, and maintainability concerns. Extracts VBA using pywin32 COM automation, then runs
  rule-based checks covering: Shell/SendKeys/registry security risks, Select/Activate performance issues,
  cell-by-cell loops, missing error handlers, bare Resume Next, missing Option Explicit, hardcoded sheet
  names, long procedures, and GoTo misuse. Use this skill whenever the user wants to review VBA code, audit
  macros, check for security risks in VBA, find performance issues in VBA, or review Excel macro code.
  Trigger on "review VBA", "audit macros", "check VBA code", "VBA security", "macro review", or any mention
  of VBA auditing.
---

# Excel VBA Auditor 📦

> *"Just because it runs doesn't mean it's right."*

## Mission

Audit VBA code for security risks, performance issues, error handling gaps, standards violations,
and maintainability concerns. The split is strict: deterministic pattern checks run in
`scripts/vba_audit.py`; judgment calls (is that `Workbook_Open` body harmless? does that `FileCopy`
validate its paths?) stay with Claude.

## Prerequisites

- **Workbook extraction**: Windows + Excel + `pywin32` (`pip install pywin32`), plus the Trust
  Center setting File → Options → Trust Center → Macro Settings → ✅ *Trust access to the VBA
  project object model*. VBA source is invisible to openpyxl and absent from `extract.json`, so
  extraction goes through the **shared COM bridge** `../_excel-shared/scripts/excel_automation.py`
  — only the rule engine `scripts/vba_audit.py` lives in this skill. The bridge opens the workbook
  read-only in its own hidden Excel instance and always quits; the script additionally
  force-disables macros (`AutomationSecurity`) so nothing auto-runs during the audit.
- **No Excel needed** for `--bas-dir` (exported `.bas`/`.cls`/`.frm` files) or `--demo`.

## Quick Start

```
python scripts/vba_audit.py <workbook.xlsm> [--json OUT|-] [--md OUT|-]   # COM extract + rules
python scripts/vba_audit.py --bas-dir <folder> [--json OUT|-] [--md OUT|-] # exported modules, no Excel
python scripts/vba_audit.py --demo                                         # self-test on embedded bad modules
```

`-` writes to stdout; with neither flag the markdown findings table prints to stdout. Exit codes:
a `.xlsx` target prints `No VBA project found` **without starting Excel** (the format cannot store
VBA) and exits 0; a macro workbook with no module code prints `No VBA code found` (exit 0); a
Trust-Center refusal prints the settings fix and exits 2.

## Workflow

1. **Extract** — `vba_audit.py <workbook>` extracts internally. To pull module source yourself,
   use the shared bridge from a script in this skill's `scripts/` folder:

   ```python
   import sys
   from pathlib import Path
   sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

   from excel_automation import excel_app, open_workbook, VBAManager

   with excel_app() as xl:
       with open_workbook(xl, r"C:\path\model.xlsm") as wb:
           modules = {m["name"]: VBAManager.get_module_code(wb, m["name"])
                      for m in VBAManager.list_macros(wb) if m["line_count"]}
   ```

2. **Rule script** — deterministic checks only: `audit_vba_module(name, code)` splits each module
   into procedures and covers security (Shell/WScript, SendKeys, registry, Kill, network objects,
   auto-execution, xlVeryHidden), performance (Select/Activate, missing ScreenUpdating/Calculation
   guards around cell-writing loops, cell-by-cell loops, Copy/Paste, implicit ActiveSheet), error
   handling (public procedures without handlers, bare Resume Next, handlers not restoring
   Application state), and standards (Option Explicit, magic numbers, commented-out code, GoTo
   flow control, procedures over 50 lines, hardcoded sheet names).

3. **Claude judgment pass** — work through the Claude-side checks in `references/vba_rules.md`:
   component inventory and entry points, FileCopy/Open-For-Output path validation, whether
   auto-run bodies are harmless, handlers that silently swallow errors, magic strings — and vet
   every script finding (the magic-number rule nominates; Claude trims the trivia).

4. **Report** — emit the unified findings table. Format, severity scale, the cell-range Grouping
   Rule, and the findings JSON schema are defined once in
   `../_excel-shared/references/audit_standards.md` (§1, §3–5) — follow them exactly. VBA findings
   use sheet `(VBA)`, cells = module name, location `Module: <m> / Proc: <p>`. Report only —
   never modify VBA code. If nothing is wrong: `✅ No issues detected.`

## Reference map

| Read | For |
|---|---|
| `references/vba_rules.md` | Full rule catalogue (script/Claude split), error categories, judgment guidance |
| `../_excel-shared/references/audit_standards.md` | Findings table, severity scale, Grouping Rule, findings JSON schema |
| `../_excel-shared/references/extraction_guide.md` | extract.json schema — VBA is *not* in it; this skill uses the COM bridge instead |
| `../_excel-shared/scripts/excel_automation.py` | Shared COM bridge: `excel_app`, `open_workbook`, `VBAManager`, Trust-Center hint |

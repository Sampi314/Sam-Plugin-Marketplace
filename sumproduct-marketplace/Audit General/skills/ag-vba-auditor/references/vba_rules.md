# VBA Audit Rules — ag-vba-auditor

The complete check catalogue for the VBA Auditor. Findings format, the
severity scale, the cell-range Grouping Rule, and the findings JSON schema are
defined once in `../../_excel-shared/references/audit_standards.md` — they are
not repeated here.

**Detected by** says who runs the check: **Script** = deterministic rule in
`../scripts/vba_audit.py` (`audit_vba_module(name, code)`, which splits
modules into procedures on the Sub/Function/Property boundaries); **Claude** =
judgment call no regex can make. Every Script finding still gets a Claude
sanity pass — the script nominates, Claude vets.

---

## Phase 1 — INVENTORY (Claude)

Catalogue all VBA components: Standard Modules, Class Modules, UserForms,
Document Modules (ThisWorkbook / Sheet modules). Count procedures
(Sub/Function/Property, Public vs Private). Identify entry points (`Auto_Open`,
`Workbook_Open`, button-assigned macros). Map inter-module dependencies. This
context shapes severity: `Shell` in a documented admin tool is a different
conversation from `Shell` in `Workbook_Open`.

## Phase 2 — SECURITY

| Check | Severity | Category | Detected by |
|---|---|---|---|
| `Shell`, `WScript.Shell`, `CreateObject("WScript.Shell")` | 🔴 Critical | Security Risk | Script |
| `SendKeys` | 🔴 Critical | Security Risk | Script |
| `SaveSetting`, `GetSetting`, `DeleteSetting` (registry) | 🔴 Critical | Security Risk | Script |
| `Kill` (file deletion) | ⚠️ Warning | Security Risk | Script |
| `FileCopy`, `Open ... For Output` without path validation | ⚠️ Warning | Security Risk | Claude (validation is contextual) |
| `XMLHTTP`, `WinHttp`, `ADODB.Connection` to external endpoints | ⚠️ Warning | Security Risk | Script (presence) + Claude (endpoint review) |
| `Auto_Open` / `Workbook_Open` present | ⚠️ Warning | Auto-execution Risk | Script (presence) + Claude (is the body harmless?) |
| `xlVeryHidden` set/unset programmatically | 🟡 Info | Security Risk | Script |

## Phase 3 — PERFORMANCE

| Check | Severity | Category | Detected by |
|---|---|---|---|
| `.Select`, `.Activate`, `Selection.`, `ActiveCell.` | ⚠️ Warning | Select/Activate | Script |
| Missing `ScreenUpdating = False` around cell-writing loops | ⚠️ Warning | Missing Application Guards | Script |
| Missing `Calculation = xlCalculationManual` around cell-writing loops | ⚠️ Warning | Missing Application Guards | Script |
| Reading/writing cells one at a time inside loops | 🔴 Critical | Cell-by-Cell Loop | Script |
| `.Copy` + `.Paste`/`.PasteSpecial` instead of direct value assignment | ⚠️ Warning | Copy/Paste | Script |
| Unqualified `Range(`/`Cells(` (implicit ActiveSheet) | ⚠️ Warning | Implicit ActiveSheet | Script |

## Phase 4 — ERROR HANDLING

| Check | Severity | Category | Detected by |
|---|---|---|---|
| Public Sub/Function with no `On Error` handling at all | 🔴 Critical | Missing Error Handler | Script |
| `On Error Resume Next` with no later `Err.Number` check | 🔴 Critical | Bare Resume Next | Script |
| Error handler not restoring Application state (`ScreenUpdating`, `Calculation`) it changed | ⚠️ Warning | Missing Cleanup | Script |
| Error handler silently exits without user feedback | 🟡 Info | Missing Cleanup | Claude (what counts as feedback is contextual) |

## Phase 5 — STANDARDS

| Check | Severity | Category | Detected by |
|---|---|---|---|
| Missing `Option Explicit` in the module declarations | 🔴 Critical | Missing Option Explicit | Script |
| Hardcoded magic numbers (literals other than 0/1 outside `Const`/`Dim`) | ⚠️ Warning | Magic Number | Script (nominates) + Claude (filters trivia) |
| Hardcoded magic strings | ⚠️ Warning | Magic Number | Claude |
| Dead/commented-out code (3+ consecutive comment lines that look like code) | 🟡 Info | Dead Code | Script |
| `GoTo` for flow control (excluding `On Error GoTo` / `GoTo 0`) | ⚠️ Warning | GoTo Misuse | Script |
| Procedure exceeding 50 executable lines | ⚠️ Warning | Long Procedure | Script |
| `Sheets("Sheet1")` / `Worksheets("...")` string literals instead of CodeName or constant | ⚠️ Warning | Hardcoded Sheet Name | Script |

Judgment overlay: the magic-number rule lists every non-0/1 literal it sees —
a `2` used as a column offset rarely deserves a report row, an undocumented
`1.175` tax multiplier always does. Claude trims the list before reporting.

---

## Error categories

| Category | Description |
|---|---|
| **Security Risk** | Code that could harm the system or expose data (Shell, SendKeys, registry, Kill, network, xlVeryHidden) |
| **Auto-execution Risk** | Code runs automatically on workbook events |
| **Missing Error Handler** | No error handling in a public procedure |
| **Bare Resume Next** | `On Error Resume Next` without error checking |
| **Missing Cleanup** | Error handler doesn't restore Application settings / give feedback |
| **Select/Activate** | Unnecessary use of `.Select`, `.Activate`, `Selection`, `ActiveCell` |
| **Cell-by-Cell Loop** | Reading/writing cells individually inside a loop |
| **Missing Application Guards** | Cell-writing loop without ScreenUpdating/Calculation guards |
| **Copy/Paste** | Clipboard round-trip instead of direct value assignment |
| **Implicit ActiveSheet** | Range/Cells reference without a sheet qualifier |
| **Missing Option Explicit** | Module lacks `Option Explicit` |
| **Magic Number** | Hardcoded numeric/string literal that should be a named constant |
| **Dead Code** | Commented-out code blocks left in the module |
| **GoTo Misuse** | `GoTo` for flow control instead of structured logic |
| **Long Procedure** | Procedure exceeds 50 executable lines |
| **Hardcoded Sheet Name** | Sheet referenced by tab-name string instead of CodeName |

## Finding fields (VBA-specific)

VBA findings have no cell addresses: `sheet` is always `(VBA)`, `cells` holds
the module name, and `location` is `Module: <module> / Proc: <procedure>`
(module-level findings use `Module: <module> (declarations)` or
`Module: <module> (line N)`). `r1c1_expected`/`r1c1_actual` stay null.
Everything else follows `audit_standards.md`.

## Script CLI (scripts/vba_audit.py)

```
python vba_audit.py <workbook.xlsm> [--json OUT|-] [--md OUT|-]   # COM extraction
python vba_audit.py --bas-dir FOLDER [--json OUT|-] [--md OUT|-]  # exported .bas/.cls/.frm
python vba_audit.py --demo                                        # embedded bad-module self-test
```

Workbook mode needs Windows + Excel + pywin32 + the Trust Center setting
"Trust access to the VBA project object model" (shared bridge
`../../_excel-shared/scripts/excel_automation.py`; macros are force-disabled
via `AutomationSecurity` while the file is open). Exit codes: a `.xlsx` is
dismissed without starting Excel ("No VBA project found", exit 0); a workbook
with no module code prints "No VBA code found" (exit 0); a Trust-Center
refusal prints the fix and exits 2. `--bas-dir` and `--demo` are pure Python;
the demo exits 1 if its deliberately bad modules yield fewer than 6 findings.

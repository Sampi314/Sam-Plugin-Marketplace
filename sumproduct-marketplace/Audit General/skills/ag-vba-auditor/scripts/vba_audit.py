"""vba_audit.py — deterministic VBA checks for excel-vba-auditor.

Usage:
    python vba_audit.py <workbook.xlsm> [--json OUT|-] [--md OUT|-]
    python vba_audit.py --bas-dir FOLDER [--json OUT|-] [--md OUT|-]
    python vba_audit.py --demo

Extraction:
  * <workbook>  -> COM via the shared bridge (excel_automation.py in
                   ../../_excel-shared/scripts/): Windows + Excel + pywin32 +
                   Trust Center "Trust access to the VBA project object model".
                   A .xlsx is dismissed politely WITHOUT starting Excel — the
                   format cannot store VBA (exit 0). Macros are force-disabled
                   (AutomationSecurity) while the workbook is open. A
                   Trust-Center refusal prints the fix and exits 2.
  * --bas-dir   -> loose exported modules (*.bas, *.cls, *.frm) — no Excel.
  * --demo      -> embedded deliberately-bad module set; fails (exit 1) if it
                   produces fewer than 6 findings.

Deterministic checks only — full catalogue and the script/Claude split live in
../references/vba_rules.md:
  audit_vba_module(name, code) -> list[Finding]

What stays with Claude (judgment, not regex): whether an Auto_Open body is
harmless, whether a FileCopy/Open-For-Output validates its paths, whether a
handler "silently exits", and which flagged magic numbers actually matter.

Output follows ../../_excel-shared/references/audit_standards.md.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output

AGENT = "vba"
SHEET = "(VBA)"

_PROC_START_RE = re.compile(
    r"^\s*(?:(Public|Private|Friend)\s+)?(?:Static\s+)?"
    r"(Sub|Function|Property\s+(?:Get|Let|Set))\s+([A-Za-z_]\w*)", re.I)
_PROC_END_RE = re.compile(r"^\s*End\s+(Sub|Function|Property)\b", re.I)
_STR_RE = re.compile(r'"[^"]*"')
_AUTOEXEC_RE = re.compile(r"(?i)^(Auto_Open|Auto_Close|Workbook_Open|Workbook_BeforeClose)$")
_CODEISH_RE = re.compile(
    r"(?i)(=|^\s*(Set|Dim|If|For|Do|While|Call|With|End|Next|Sub|Function)\b|\.\w+)")


# ---------------------------------------------------------------------------
# Line / procedure helpers
# ---------------------------------------------------------------------------

def _split_comment(line: str) -> tuple[str, str]:
    """(code, comment) — split on the first ' outside a string, or Rem."""
    if re.match(r"\s*Rem(\s|$)", line, re.I):
        return "", line.strip()
    in_str = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_str = not in_str
        elif ch == "'" and not in_str:
            return line[:i], line[i + 1:].strip()
    return line, ""


def _blank_strings(code: str) -> str:
    return _STR_RE.sub('""', code)


def split_procedures(code: str) -> tuple[list[str], list[dict]]:
    """(declaration lines, procs). Each proc: {name, kind, visibility, lines}."""
    decls: list[str] = []
    procs: list[dict] = []
    current: dict | None = None
    for raw in code.splitlines():
        code_part, _ = _split_comment(raw)
        if current is None:
            m = _PROC_START_RE.match(code_part)
            if m:
                current = {"visibility": (m.group(1) or "Public").capitalize(),
                           "kind": m.group(2).split()[0].capitalize(),
                           "name": m.group(3), "lines": [raw]}
            else:
                decls.append(raw)
        else:
            current["lines"].append(raw)
            if _PROC_END_RE.match(code_part):
                procs.append(current)
                current = None
    if current:
        procs.append(current)
    return decls, procs


# ---------------------------------------------------------------------------
# Module-level rules
# ---------------------------------------------------------------------------

def audit_vba_module(name: str, code: str) -> list[Finding]:
    findings: list[Finding] = []
    if not code.strip():
        return findings
    decls, procs = split_procedures(code)
    decl_code = "\n".join(_split_comment(l)[0] for l in decls)
    if not re.search(r"(?im)^\s*Option\s+Explicit\b", decl_code):
        findings.append(Finding(agent=AGENT, sheet=SHEET, cells=[name],
            location=f"Module: {name} (declarations)", severity="critical",
            category="Missing Option Explicit",
            description="Module does not declare `Option Explicit` — a typo in a variable name "
                        "becomes a silent new Variant instead of a compile error — Recommend: "
                        "add `Option Explicit` and declare every variable"))
    findings.extend(_check_dead_code(name, code))
    for proc in procs:
        findings.extend(_analyse_proc(name, proc))
    return findings


def _check_dead_code(module: str, code: str) -> list[Finding]:
    """>=3 consecutive comment-only lines that look like code -> Dead Code."""
    findings, run, start_line = [], 0, 0
    lines = code.splitlines()
    for idx, raw in enumerate(lines + [""], 1):  # sentinel flushes the last run
        code_part, comment = _split_comment(raw)
        if not code_part.strip() and comment and _CODEISH_RE.search(comment):
            if run == 0:
                start_line = idx
            run += 1
        else:
            if run >= 3:
                findings.append(Finding(agent=AGENT, sheet=SHEET, cells=[module],
                    location=f"Module: {module} (line {start_line})", severity="info",
                    category="Dead Code",
                    description=f"{run} consecutive commented-out code lines starting at line "
                                f"{start_line} — stale logic misleads the next maintainer — "
                                f"Recommend: delete it (version control remembers)"))
            run = 0
    return findings


# ---------------------------------------------------------------------------
# Procedure-level rules
# ---------------------------------------------------------------------------

def _analyse_proc(module: str, proc: dict) -> list[Finding]:
    findings: list[Finding] = []
    name = proc["name"]
    loc = f"Module: {module} / Proc: {name}"
    rows = []
    for raw in proc["lines"]:
        code_part, comment = _split_comment(raw)
        rows.append((code_part, _blank_strings(code_part)))
    raw_code = "\n".join(r[0] for r in rows)   # comments gone, strings intact
    code = "\n".join(r[1] for r in rows)       # strings blanked too

    def add(severity, category, description):
        findings.append(Finding(agent=AGENT, sheet=SHEET, cells=[module], location=loc,
                                severity=severity, category=category, description=description))

    # --- security ---
    if re.search(r"(?<![.\w])Shell\b", code) or "WScript.Shell" in raw_code:
        add("critical", "Security Risk",
            "Launches external processes via `Shell`/`WScript.Shell` — arbitrary command "
            "execution from a workbook — Recommend: remove it, or isolate and document the "
            "exact command")
    if re.search(r"\bSendKeys\b", code):
        add("critical", "Security Risk",
            "`SendKeys` injects keystrokes into whatever window has focus — fragile and a "
            "security hazard — Recommend: drive the object model directly")
    if re.search(r"\b(SaveSetting|GetSetting|DeleteSetting)\b", code):
        add("critical", "Security Risk",
            "Reads/writes the Windows registry (`SaveSetting`/`GetSetting`/`DeleteSetting`) — "
            "state outlives the workbook on the user's machine — Recommend: store state in the "
            "workbook or a config file")
    if re.search(r"(?<![.\w])Kill\b", code):
        add("warning", "Security Risk",
            "`Kill` deletes files with no recycle-bin recovery — Recommend: validate the path "
            "and confirm with the user before deleting")
    if re.search(r"\b(XMLHTTP|WinHttp|MSXML2|ADODB\.Connection|InternetExplorer\.Application)\b",
                 raw_code, re.I):
        add("warning", "Security Risk",
            "Makes external network/database connections (`XMLHTTP`/`WinHttp`/`ADODB`) — "
            "Recommend: verify the endpoints, credential handling, and necessity")
    if re.search(r"\bxlVeryHidden\b", code, re.I):
        add("info", "Security Risk",
            "Sets sheets to `xlVeryHidden` programmatically — content becomes invisible to the "
            "Excel UI — Recommend: document why, or use ordinary hidden")
    if _AUTOEXEC_RE.match(name):
        add("warning", "Auto-execution Risk",
            f"`{name}` runs automatically on workbook open/close — users execute it without "
            f"asking to — Recommend: keep auto-run minimal, visible, and documented")

    # --- performance ---
    sel_hits = re.findall(r"\.Select\b|\.Activate\b|\bSelection\s*\.|\bActiveCell\b", code)
    if sel_hits:
        add("warning", "Select/Activate",
            f"{len(sel_hits)} use(s) of `.Select`/`.Activate`/`Selection`/`ActiveCell` — slow, "
            f"and dependent on whatever the user last clicked — Recommend: act on range objects "
            f"directly")
    loop_depth, cell_lines, writes_in_loop = 0, 0, False
    for _, bl in rows:
        s = bl.strip()
        if re.match(r"(?i)(For\b|Do\b|While\b)", s):
            loop_depth += 1
        if loop_depth > 0 and re.search(r"\b(Cells|Range)\s*\(", bl):
            cell_lines += 1
            if "=" in bl:
                writes_in_loop = True
        if re.match(r"(?i)(Next\b|Loop\b|Wend\b)", s):
            loop_depth = max(0, loop_depth - 1)
    if cell_lines:
        add("critical", "Cell-by-Cell Loop",
            f"Reads/writes individual cells inside a loop ({cell_lines} line(s)) — every touch "
            f"is a COM round-trip — Recommend: read the range into a Variant array, work in "
            f"memory, write back once")
    if writes_in_loop:
        missing = []
        if not re.search(r"(?i)ScreenUpdating\s*=\s*False", code):
            missing.append("`Application.ScreenUpdating = False`")
        if not re.search(r"(?i)Calculation\s*=\s*xl(Calculation)?Manual", code):
            missing.append("`Application.Calculation = xlCalculationManual`")
        if missing:
            add("warning", "Missing Application Guards",
                f"Writes to cells in a loop without {' or '.join(missing)} — every write "
                f"repaints and recalculates — Recommend: set guards on entry and restore them "
                f"on every exit path")
    if re.search(r"\.Copy\b", code) and re.search(r"\.Paste(Special)?\b", code):
        add("warning", "Copy/Paste",
            "Uses clipboard `.Copy`/`.Paste` where a direct value assignment would do — slower "
            "and clobbers the user's clipboard — Recommend: `Destination.Value = Source.Value`")
    impl = re.findall(r"(?<![\w.])(?:Range|Cells)\s*\(", code)
    if impl:
        add("warning", "Implicit ActiveSheet",
            f"{len(impl)} unqualified `Range(`/`Cells(` call(s) operate on whatever sheet "
            f"happens to be active — Recommend: qualify with a worksheet object")

    # --- error handling ---
    has_handler = re.search(r"(?i)On\s+Error\s+GoTo\s+(?!0\b)(\w+)", code)
    has_resume_next = re.search(r"(?i)On\s+Error\s+Resume\s+Next", code)
    if (proc["visibility"] == "Public" and proc["kind"] in ("Sub", "Function")
            and not has_handler and not has_resume_next):
        add("critical", "Missing Error Handler",
            "Public procedure has no `On Error` handling — a runtime error dumps the user into "
            "the VBA debugger — Recommend: add `On Error GoTo` with a handler that reports and "
            "restores state")
    if has_resume_next and not re.search(
            r"(?i)\bErr\b\s*\.\s*(Number|Description)|\bErr\b\s*<>|\bErr\b\s*=", code):
        add("critical", "Bare Resume Next",
            "`On Error Resume Next` with no later `Err.Number` check — every error is silently "
            "swallowed — Recommend: check `Err.Number` after each guarded call, then restore "
            "`On Error GoTo 0`")
    if has_handler:
        label = has_handler.group(1)
        mlab = re.search(rf"(?im)^\s*{re.escape(label)}\s*:", code)
        if mlab:
            tail = code[mlab.end():]
            needs = []
            if re.search(r"(?i)ScreenUpdating\s*=\s*False", code) and \
                    not re.search(r"(?i)ScreenUpdating\s*=\s*True", tail):
                needs.append("`ScreenUpdating = True`")
            if re.search(r"(?i)Calculation\s*=\s*xl(Calculation)?Manual", code) and \
                    not re.search(r"(?i)Calculation\s*=\s*xl(Calculation)?Automatic", tail):
                needs.append("`Calculation = xlCalculationAutomatic`")
            if needs:
                add("warning", "Missing Cleanup",
                    f"Error handler `{label}:` exits without restoring {' or '.join(needs)} — "
                    f"an error leaves Excel frozen for the user — Recommend: restore "
                    f"Application state inside the handler")

    # --- standards ---
    nums: set[str] = set()
    for _, bl in rows:
        s = bl.strip()
        if re.match(r"(?i)((Public\s+|Private\s+)?Const\b|Declare\b|Dim\b)", s):
            continue
        for n in re.findall(r"(?<![\w.])\d+(?:\.\d+)?(?![\w.])", bl):
            if n not in ("0", "1"):
                nums.add(n)
    if nums:
        uniq = sorted(nums, key=lambda x: (len(x), x))
        shown = ", ".join(f"`{u}`" for u in uniq[:8])
        more = f" and {len(uniq) - 8} more" if len(uniq) > 8 else ""
        add("warning", "Magic Number",
            f"Unexplained numeric literal(s) {shown}{more} in executable code — Recommend: "
            f"promote to a named `Const` with a comment")
    flow = re.sub(r"(?i)On\s+Error\s+GoTo\s+\w+", "", code)
    gotos = sorted({g for g in re.findall(r"(?i)\bGoTo\s+(\w+)", flow) if g != "0"})
    if gotos:
        shown = ", ".join(f"`{g}`" for g in gotos[:5])
        add("warning", "GoTo Misuse",
            f"`GoTo` used for flow control (label(s) {shown}) — spaghetti logic — Recommend: "
            f"restructure with If/Select Case/loops; reserve GoTo for error handlers")
    n_exec = len([bl for _, bl in rows if bl.strip()]) - 2  # minus Sub/End Sub lines
    if n_exec > 50:
        add("warning", "Long Procedure",
            f"{n_exec} executable lines (threshold 50) — too much to hold in one head — "
            f"Recommend: split into smaller single-purpose procedures")
    sheet_lits = sorted(set(re.findall(r'(?i)\b(?:Sheets|Worksheets)\s*\(\s*"([^"]+)"', raw_code)))
    if sheet_lits:
        shown = ", ".join(f'`"{s}"`' for s in sheet_lits[:5])
        more = f" and {len(sheet_lits) - 5} more" if len(sheet_lits) > 5 else ""
        add("warning", "Hardcoded Sheet Name",
            f"Sheet(s) referenced by tab-name string ({shown}{more}) — breaks the moment a user "
            f"renames the tab — Recommend: use the sheet CodeName or a named constant")
    return findings


# ---------------------------------------------------------------------------
# Extraction front-ends + demo
# ---------------------------------------------------------------------------

def extract_modules(path: str) -> dict:
    """Pull {module_name: code} via the shared COM bridge (macros disabled)."""
    from excel_automation import excel_app, open_workbook, VBAManager
    with excel_app() as xl:
        try:
            xl.AutomationSecurity = 3  # msoAutomationSecurityForceDisable: never run macros
        except Exception:
            pass
        with open_workbook(xl, path) as wb:
            out = {}
            for m in VBAManager.list_macros(wb):
                if m["line_count"] > 0:
                    out[m["name"]] = VBAManager.get_module_code(wb, m["name"])
            return out


def load_bas_dir(folder: str) -> dict:
    root = Path(folder)
    if not root.is_dir():
        sys.exit(f"--bas-dir: not a directory: {folder}")
    modules = {}
    for p in sorted(list(root.glob("*.bas")) + list(root.glob("*.cls")) + list(root.glob("*.frm"))):
        text = p.read_text(encoding="utf-8-sig", errors="replace")
        m = re.search(r'Attribute\s+VB_Name\s*=\s*"([^"]+)"', text)
        body = "\n".join(l for l in text.splitlines()
                         if not re.match(r"\s*(Attribute\s|VERSION\s)", l))
        modules[m.group(1) if m else p.stem] = body
    return modules


DEMO_MODULES = {
    "Module1": '''Sub UpdateReport()
    Dim i As Long
    Sheets("Data").Select
    For i = 1 To 5000
        ActiveSheet.Cells(i, 2).Value = Cells(i, 1).Value * 1.175
    Next i
    Range("A1").Copy
    Range("B5").PasteSpecial Paste:=xlPasteValues
    If i > 42 Then GoTo SkipIt
    Shell "cmd.exe /c dir", vbHide
SkipIt:
    SendKeys "{ENTER}"
End Sub

Private Function GetRate() As Double
    On Error Resume Next
    GetRate = Worksheets("Assumptions").Range("B2").Value
    ' rate = 0.08
    ' If rate = 0 Then rate = 0.05
    ' GetRate = rate
End Function
''',
    "ThisWorkbook": '''Option Explicit

Private Sub Workbook_Open()
    Application.ScreenUpdating = False
    On Error GoTo Handler
    SaveSetting "MyApp", "Startup", "LastRun", "today"
    Sheets("Audit").Visible = xlVeryHidden
    Exit Sub
Handler:
    MsgBox "Failed"
End Sub
''',
}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("workbook", nargs="?", help="Macro workbook to audit (COM extraction)")
    ap.add_argument("--bas-dir", dest="bas_dir",
                    help="Folder of exported .bas/.cls/.frm modules (no Excel needed)")
    ap.add_argument("--demo", action="store_true",
                    help="Run the rules on an embedded deliberately-bad module set")
    ap.add_argument("--json", dest="json_out", help="Findings JSON path ('-' = stdout)")
    ap.add_argument("--md", dest="md_out", help="Findings markdown path ('-' = stdout)")
    args = ap.parse_args(argv)

    if args.demo:
        modules = dict(DEMO_MODULES)
    elif args.bas_dir:
        modules = load_bas_dir(args.bas_dir)
    elif args.workbook:
        path = Path(args.workbook).resolve()
        if not path.exists():
            sys.exit(f"Workbook not found: {path}")
        if path.suffix.lower() == ".xlsx":
            print(f"No VBA project found — {path.name} is a .xlsx, a format that cannot store "
                  f"VBA (macro workbooks are .xlsm/.xlsb). Nothing to audit.")
            return 0
        try:
            modules = extract_modules(str(path))
        except RuntimeError as exc:   # Trust Center access refused
            print(str(exc))
            return 2
    else:
        ap.error("give a workbook, --bas-dir, or --demo")

    modules = {n: c for n, c in modules.items() if c.strip()}
    if not modules:
        print("No VBA code found — nothing to audit.")
        return 0

    findings: list[Finding] = []
    for nm, mcode in modules.items():
        findings.extend(audit_vba_module(nm, mcode))
    findings = group_findings(findings)

    if args.demo:
        if len(findings) < 6:
            print(f"DEMO FAILED: expected >= 6 findings, got {len(findings)}")
            return 1
        print(f"Demo OK: {len(findings)} findings from {len(modules)} deliberately-bad modules.")

    write_output(findings, args.json_out, args.md_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

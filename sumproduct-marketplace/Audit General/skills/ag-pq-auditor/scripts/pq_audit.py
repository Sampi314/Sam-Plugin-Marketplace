"""pq_audit.py — deterministic Power Query M-code checks for excel-pq-auditor.

Usage:
    python pq_audit.py <workbook.xlsx> [--json OUT|-] [--md OUT|-]
    python pq_audit.py --m-dir FOLDER  [--json OUT|-] [--md OUT|-]
    python pq_audit.py --demo

Extraction:
  * <workbook>  -> COM via the shared bridge (excel_automation.py in
                   ../../_excel-shared/scripts/): Windows + Excel + pywin32.
                   Prints "No Power Query queries found" and exits 0 when the
                   workbook has none. The bridge opens read-only in its own
                   hidden Excel instance and always quits on exit.
  * --m-dir     -> loose .m files (one query per file, name = file stem).
                   Pure Python — no Excel needed.
  * --demo      -> embedded deliberately-bad query set; fails (exit 1) if it
                   produces fewer than 6 findings.

Deterministic checks only — full catalogue and the script/Claude split live in
../references/pq_rules.md:
  audit_pq_query(name, m_code)   per-query rules
  audit_pq_architecture(queries) cross-query rules

What stays with Claude (judgment, not regex): whether a Table.Buffer is a
justified folding sacrifice, whether a flagged "token" is really a credential,
join null-handling, date culture, and the business sense of the architecture.

Output follows ../../_excel-shared/references/audit_standards.md.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output

AGENT = "pq"
SHEET = "(Power Query)"

_WORD_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_.]*")
_PATH_RE = re.compile(r'"((?:[A-Za-z]:\\|\\\\)[^"]*)"')
_CRED_RE = re.compile(
    r"(?i)\b(password|pwd|passwd|apikey|api[_-]?key|access[_-]?token|"
    r"auth[_-]?token|token|secret|client[_-]?secret)\b\s*[=:]")
_FALLIBLE_RE = re.compile(
    r"\b(File\.Contents|Web\.Contents|Excel\.Workbook|Csv\.Document|"
    r"Json\.Document|Xml\.Tables|OData\.Feed|Sql\.Database)\b")
_SOURCE_RE = re.compile(
    r'\b(File\.Contents|Web\.Contents|Sql\.Database|OData\.Feed|'
    r'SharePoint\.Files|SharePoint\.Tables|Access\.Database)\s*\(\s*("(?:""|[^"])*")')
_AUTO_STEP_PREFIXES = (
    "Changed Type", "Removed Columns", "Removed Other Columns", "Renamed Columns",
    "Added Custom", "Added Conditional Column", "Added Index", "Filtered Rows",
    "Sorted Rows", "Grouped Rows", "Merged Queries", "Appended Query",
    "Expanded", "Promoted Headers", "Replaced Value", "Removed Duplicates",
    "Removed Errors", "Removed Blank Rows", "Removed Top Rows", "Removed Bottom Rows",
    "Split Column", "Pivoted Column", "Unpivoted", "Duplicated Column",
    "Reordered Columns", "Kept", "Transposed Table", "Extracted", "Inserted",
    "Calculated", "Trimmed Text", "Cleaned Text", "Uppercased Text",
    "Lowercased Text", "Capitalized Each Word", "Merged Columns", "Custom",
)
_AUTO_STEP_RE = re.compile(
    r"^(?:" + "|".join(re.escape(p) for p in _AUTO_STEP_PREFIXES) + r")(?: [\w%./-]+)*\d*$")


def _finding(name: str, severity: str, category: str, description: str) -> Finding:
    return Finding(agent=AGENT, sheet=SHEET, cells=[name], location=f"Query: {name}",
                   severity=severity, category=category, description=description)


# ---------------------------------------------------------------------------
# M-code parsing helpers (string-aware, heuristic, tolerant)
# ---------------------------------------------------------------------------

def strip_comments(code: str) -> str:
    """Remove // and /* */ comments without touching string literals."""
    out, i, n, in_str = [], 0, len(code), False
    while i < n:
        ch = code[i]
        if in_str:
            out.append(ch)
            if ch == '"':
                if i + 1 < n and code[i + 1] == '"':
                    out.append('"'); i += 2; continue
                in_str = False
            i += 1; continue
        if ch == '"':
            in_str = True; out.append(ch); i += 1; continue
        if ch == "/" and i + 1 < n and code[i + 1] == "/":
            while i < n and code[i] != "\n":
                i += 1
            continue
        if ch == "/" and i + 1 < n and code[i + 1] == "*":
            j = code.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        out.append(ch); i += 1
    return "".join(out)


def parse_let_steps(code: str) -> tuple[list[tuple[str, str]], str]:
    """(steps as [(name, expression)], final expression) of the top-level let.
    Tracks strings, bracket depth, and nested let/in. No let -> ([], code)."""
    n, i, depth, let_depth, in_str = len(code), 0, 0, 0, False
    let_pos = in_pos = None
    while i < n:
        ch = code[i]
        if in_str:
            if ch == '"':
                if i + 1 < n and code[i + 1] == '"':
                    i += 2; continue
                in_str = False
            i += 1; continue
        if ch == '"':
            in_str = True; i += 1; continue
        if ch in "([{":
            depth += 1; i += 1; continue
        if ch in ")]}":
            depth = max(0, depth - 1); i += 1; continue
        if ch.isalpha() or ch == "_":
            m = _WORD_RE.match(code, i)
            if depth == 0:
                if m.group(0) == "let":
                    let_depth += 1
                    if let_depth == 1 and let_pos is None:
                        let_pos = m.end()
                elif m.group(0) == "in" and let_depth:
                    let_depth -= 1
                    if let_depth == 0 and let_pos is not None and in_pos is None:
                        in_pos = i
            i = m.end(); continue
        i += 1
    if let_pos is None:
        return [], code.strip()
    body = code[let_pos:in_pos] if in_pos is not None else code[let_pos:]
    final = code[in_pos + 2:].strip() if in_pos is not None else ""
    steps = []
    for part in _split_bindings(body):
        name, expr = _split_binding(part)
        if name:
            steps.append((name, expr))
    return steps, final


def _split_bindings(body: str) -> list[str]:
    """Split a let body on commas at bracket depth 0 outside nested let/in."""
    parts, start = [], 0
    n, i, depth, let_depth, in_str = len(body), 0, 0, 0, False
    while i < n:
        ch = body[i]
        if in_str:
            if ch == '"':
                if i + 1 < n and body[i + 1] == '"':
                    i += 2; continue
                in_str = False
            i += 1; continue
        if ch == '"':
            in_str = True; i += 1; continue
        if ch in "([{":
            depth += 1; i += 1; continue
        if ch in ")]}":
            depth = max(0, depth - 1); i += 1; continue
        if ch == "," and depth == 0 and let_depth == 0:
            parts.append(body[start:i]); start = i + 1; i += 1; continue
        if ch.isalpha() or ch == "_":
            prev = body[i - 1] if i else ""
            m = _WORD_RE.match(body, i)
            if depth == 0 and prev not in '#"' and not (prev.isalnum() or prev in "._"):
                if m.group(0) == "let":
                    let_depth += 1
                elif m.group(0) == "in":
                    let_depth = max(0, let_depth - 1)
            i = m.end(); continue
        i += 1
    parts.append(body[start:])
    return [p for p in (s.strip() for s in parts) if p]


def _split_binding(binding: str) -> tuple[str | None, str]:
    """'name = expr' -> (name, expr); first '=' at depth 0 (ignores =>, <=, >=)."""
    n, i, depth, in_str = len(binding), 0, 0, False
    while i < n:
        ch = binding[i]
        if in_str:
            if ch == '"':
                if i + 1 < n and binding[i + 1] == '"':
                    i += 2; continue
                in_str = False
            i += 1; continue
        if ch == '"':
            in_str = True
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth = max(0, depth - 1)
        elif ch == "=" and depth == 0:
            nxt = binding[i + 1] if i + 1 < n else ""
            prv = binding[i - 1] if i else ""
            if nxt != ">" and prv not in "<>=":
                return binding[:i].strip(), binding[i + 1:].strip()
        i += 1
    return None, binding.strip()


def step_plain(name: str) -> str:
    """'#"Changed Type1"' -> 'Changed Type1'; bare identifiers pass through."""
    name = name.strip()
    if name.startswith('#"') and name.endswith('"'):
        return name[2:-1].replace('""', '"')
    return name


# ---------------------------------------------------------------------------
# Per-query rules
# ---------------------------------------------------------------------------

def audit_pq_query(name: str, m_code: str) -> list[Finding]:
    findings: list[Finding] = []
    code = strip_comments(m_code)
    steps, final = parse_let_steps(code)
    step_names = [step_plain(s) for s, _ in steps]
    nsteps = len(steps)
    tct_idx = [i for i, (_, e) in enumerate(steps) if "Table.TransformColumnTypes" in e]
    filt_idx = [i for i, (_, e) in enumerate(steps) if "Table.SelectRows" in e]

    # --- performance ---
    early_buf = [i for i, (_, e) in enumerate(steps)
                 if "Table.Buffer" in e and i < nsteps - 1]
    if early_buf:
        offenders = ", ".join(f"`{step_names[i]}`" for i in early_buf)
        findings.append(_finding(name, "critical", "Query Folding Break",
            f"`Table.Buffer` is applied mid-query (step(s) {offenders}) — every later step runs "
            f"in the mashup engine instead of folding back to the source — Recommend: buffer only "
            f"when required, and as late as possible"))
    sort_idx = [i for i, (_, e) in enumerate(steps) if "Table.Sort" in e]
    bad_order = [(s, f) for s in sort_idx for f in filt_idx if s < f]
    if bad_order:
        s, f = bad_order[0]
        findings.append(_finding(name, "critical", "Query Folding Break",
            f"`Table.Sort` (step `{step_names[s]}`) runs before `Table.SelectRows` "
            f"(step `{step_names[f]}`) — sorting the unfiltered set breaks folding and wastes "
            f"work — Recommend: filter first, sort last"))
    col_idx = [i for i, (_, e) in enumerate(steps)
               if re.search(r"Table\.(SelectColumns|RemoveColumns|RemoveOtherColumns)", e)]
    if col_idx and nsteps >= 4 and min(col_idx) > nsteps // 2:
        findings.append(_finding(name, "warning", "Loading Excess Columns",
            f"Column reduction first happens at step {min(col_idx) + 1} of {nsteps} "
            f"(`{step_names[min(col_idx)]}`) — all columns are dragged through the earlier steps "
            f"— Recommend: select/remove columns immediately after the source step"))
    if filt_idx and nsteps >= 4 and min(filt_idx) > nsteps // 2:
        findings.append(_finding(name, "warning", "Late Row Filter",
            f"Row filtering first happens at step {min(filt_idx) + 1} of {nsteps} "
            f"(`{step_names[min(filt_idx)]}`) — unwanted rows are transformed before being thrown "
            f"away — Recommend: filter rows as early as the logic allows"))
    if len(tct_idx) > 1:
        named = ", ".join(f"`{step_names[i]}`" for i in tct_idx)
        findings.append(_finding(name, "info", "Redundant Type Conversion",
            f"{len(tct_idx)} separate `Table.TransformColumnTypes` steps ({named}) — each pass "
            f"re-touches the whole table — Recommend: consolidate into a single typing step"))
    if re.search(r"Table\.ExpandTableColumn\s*\([^()]*?,\s*[^()]*?,\s*null", code):
        findings.append(_finding(name, "warning", "Expand All Columns",
            "`Table.ExpandTableColumn` with a `null` column list expands every column — new "
            "source columns silently appear in the output — Recommend: list the wanted columns "
            "explicitly"))

    # --- data quality ---
    fallible = sorted(set(_FALLIBLE_RE.findall(code)))
    has_try = bool(re.search(r"(?<![\w.])try(?![\w])", code))
    if fallible and not has_try:
        funcs = ", ".join(f"`{f}`" for f in fallible)
        findings.append(_finding(name, "critical", "No Error Handling",
            f"Fallible source call(s) {funcs} with no `try ... otherwise` anywhere in the query "
            f"— a missing file or offline endpoint fails the whole refresh — Recommend: wrap "
            f"source acquisition in `try ... otherwise`"))
    elif tct_idx and not has_try:
        findings.append(_finding(name, "info", "No Error Handling",
            "Type-conversion steps are unguarded by `try ... otherwise` — locale-sensitive "
            "parsing can throw on a single bad value — Recommend: consider error-tolerant "
            "conversion for externally-sourced text columns"))
    uses_tables = "Table." in code or "#table" in code
    if steps and uses_tables and not tct_idx:
        findings.append(_finding(name, "critical", "Missing Type Enforcement",
            "No `Table.TransformColumnTypes` anywhere in the query — output columns load as "
            "`any` and downstream formulas inherit text-as-number bugs — Recommend: type every "
            "output column explicitly"))
    elif steps and tct_idx:
        final_plain = step_plain(final)
        final_expr = next((e for s, e in steps if step_plain(s) == final_plain), None)
        if final_expr is not None and "Table.TransformColumnTypes" not in final_expr:
            findings.append(_finding(name, "warning", "Missing Type Enforcement",
                f"Final step `{final_plain}` is not the type-enforcement step — transformations "
                f"after `Table.TransformColumnTypes` can silently change column types — "
                f"Recommend: re-apply (or move) type enforcement as the last step"))

    # --- security ---
    paths = sorted(set(_PATH_RE.findall(code)))
    if paths:
        shown = ", ".join(f"`{p}`" for p in paths[:3])
        more = f" and {len(paths) - 3} more" if len(paths) > 3 else ""
        findings.append(_finding(name, "critical", "Hardcoded File Path",
            f"Hardcoded local/UNC path(s): {shown}{more} — the query breaks on any other "
            f"machine or folder move — Recommend: hold the path in a parameter query"))
    creds = sorted({c.lower() for c in _CRED_RE.findall(code)})
    if creds:
        shown = ", ".join(f"`{c}=`" for c in creds)
        findings.append(_finding(name, "critical", "Embedded Credentials",
            f"Credential-shaped pattern(s) in the M code: {shown} — secrets in query text are "
            f"visible to every workbook user and to version control — Recommend: use the Excel "
            f"credential store / parameters, and rotate any exposed secret"))
    if "Expression.Evaluate" in code:
        findings.append(_finding(name, "critical", "Dynamic Code Execution",
            "`Expression.Evaluate` executes dynamically-built M — with user-supplied input this "
            "is code injection — Recommend: replace with static expressions"))
    if re.search(r'Web\.Contents\s*\(\s*"http://', code):
        findings.append(_finding(name, "warning", "External URL",
            "`Web.Contents` over plain `http://` — data and any query-string secrets travel "
            "unencrypted — Recommend: use HTTPS (and verify the endpoint is approved)"))

    # --- standards ---
    auto = [s for s in step_names if _AUTO_STEP_RE.match(s)]
    if auto:
        shown = ", ".join(f'`#"{s}"`' for s in auto[:6])
        more = f" and {len(auto) - 6} more" if len(auto) > 6 else ""
        findings.append(_finding(name, "warning", "Auto-generated Step Names",
            f"{len(auto)} of {nsteps} steps keep editor default names ({shown}{more}) — the "
            f"applied-steps pane reads as noise — Recommend: rename steps to describe intent"))
    if nsteps > 20:
        findings.append(_finding(name, "warning", "Long Query",
            f"{nsteps} transformation steps (threshold 20) — hard to follow and to debug — "
            f"Recommend: split into staging + transformation queries"))
    for i, (s, _) in enumerate(steps):
        plain = step_plain(s)
        tail = " , ".join(e for _, e in steps[i + 1:]) + " " + final
        if f'#"{plain}"' in tail:
            continue
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", plain) and \
                re.search(rf'(?<![\w."]){re.escape(plain)}(?![\w"])', tail):
            continue
        findings.append(_finding(name, "warning", "Dead Step",
            f"Step `{plain}` is never referenced by a later step or the query output — "
            f"Recommend: delete it or re-wire the step chain"))
    nonblank = [l for l in m_code.splitlines() if l.strip()]
    if len(nonblank) > 15 and strip_comments(m_code) == m_code:
        findings.append(_finding(name, "info", "Uncommented Query",
            f"{len(nonblank)} lines of M with no comments — intent is undocumented — "
            f"Recommend: add `//` comments at each non-obvious step"))
    return findings


# ---------------------------------------------------------------------------
# Cross-query (architecture) rules
# ---------------------------------------------------------------------------

def _references(code: str, other: str) -> bool:
    if f'#"{other}"' in code:
        return True
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", other):
        return bool(re.search(rf'(?<![\w."#]){re.escape(other)}(?![\w"])', code))
    return False


def audit_pq_architecture(queries: dict) -> list[Finding]:
    findings: list[Finding] = []
    codes = {n: strip_comments(c) for n, c in queries.items()}
    names = list(codes)

    refs = {n: {o for o in names if o != n and _references(codes[n], o)} for n in names}
    cycles: set[frozenset] = set()
    for start in names:
        stack = [(start, [start])]
        while stack:
            node, path = stack.pop()
            for nxt in refs[node]:
                if nxt == start:
                    cycles.add(frozenset(path))
                elif nxt not in path:
                    stack.append((nxt, path + [nxt]))
    for cyc in sorted(cycles, key=lambda c: sorted(c)):
        members = sorted(cyc)
        listed = ", ".join(f"`{m}`" for m in members)
        findings.append(Finding(agent=AGENT, sheet=SHEET, cells=members,
            location="Query dependency graph", severity="critical",
            category="Circular Dependency",
            description=f"Queries {listed} reference each other in a loop — refresh order is "
                        f"undefined and evaluation may fail — Recommend: break the cycle with a "
                        f"staging query"))

    by_source: dict[str, set] = {}
    for n, code in codes.items():
        for func, lit in _SOURCE_RE.findall(code):
            by_source.setdefault(f"{func}({lit})", set()).add(n)
    for sig, qs in sorted(by_source.items()):
        if len(qs) > 1:
            members = sorted(qs)
            listed = ", ".join(f"`{m}`" for m in members)
            findings.append(Finding(agent=AGENT, sheet=SHEET, cells=members,
                location="Data sources", severity="critical",
                category="Duplicate Data Source",
                description=f"Queries {listed} each call `{sig}` independently — the source is "
                            f"hit once per query per refresh — Recommend: load it once in a "
                            f"staging query and reference that"))

    by_path: dict[str, set] = {}
    for n, code in codes.items():
        for p in set(_PATH_RE.findall(code)):
            by_path.setdefault(p, set()).add(n)
    for p, qs in sorted(by_path.items()):
        if len(qs) > 1:
            members = sorted(qs)
            listed = ", ".join(f"`{m}`" for m in members)
            findings.append(Finding(agent=AGENT, sheet=SHEET, cells=members,
                location="Data sources", severity="warning",
                category="Missing Parameterisation",
                description=f"Path `{p}` is hardcoded in {len(qs)} queries ({listed}) — every "
                            f"machine or folder change means editing each query — Recommend: "
                            f"hold the path in a single parameter query"))
    return findings


# ---------------------------------------------------------------------------
# Extraction front-ends + demo
# ---------------------------------------------------------------------------

def extract_queries(workbook: str) -> dict:
    """Pull {name: m_code} from a workbook via the shared COM bridge."""
    from excel_automation import excel_app, open_workbook, PowerQueryManager
    path = Path(workbook).resolve()
    if not path.exists():
        sys.exit(f"Workbook not found: {path}")
    with excel_app() as xl:
        with open_workbook(xl, str(path)) as wb:
            return {q["name"]: q["formula"] for q in PowerQueryManager.list_queries(wb)}


def load_m_dir(folder: str) -> dict:
    root = Path(folder)
    if not root.is_dir():
        sys.exit(f"--m-dir: not a directory: {folder}")
    return {p.stem: p.read_text(encoding="utf-8-sig", errors="replace")
            for p in sorted(root.glob("*.m"))}


DEMO_QUERIES = {
    "Sales": r'''let
    Source = Csv.Document(File.Contents("C:\Data\sales.csv"), [Delimiter=","]),
    #"Promoted Headers" = Table.PromoteHeaders(Source),
    Buffered = Table.Buffer(#"Promoted Headers"),
    #"Sorted Rows" = Table.Sort(Buffered, {{"Date", Order.Ascending}}),
    #"Filtered Rows" = Table.SelectRows(#"Sorted Rows", each [Amount] > 0),
    #"Changed Type" = Table.TransformColumnTypes(#"Filtered Rows", {{"Amount", type number}}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Changed Type", {{"Date", type date}}),
    Unused = Table.Distinct(#"Changed Type1"),
    Final = Table.AddColumn(#"Changed Type1", "Flag", each 1)
in
    Final''',
    "Customers": r'''let
    Source = Excel.Workbook(File.Contents("C:\Data\crm.xlsx"), null, true),
    Picked = Source{[Item="Customers",Kind="Table"]}[Data],
    WithOrders = Table.NestedJoin(Picked, {"ID"}, Orders, {"CustID"}, "OrderRows", JoinKind.LeftOuter),
    Expanded = Table.ExpandTableColumn(WithOrders, "OrderRows", null)
in
    Expanded''',
    "Orders": r'''let
    Source = Web.Contents("http://api.example.com/orders?apikey=SECRET123"),
    Parsed = Json.Document(Source),
    AsTable = Table.FromRecords(Parsed),
    Tagged = Table.NestedJoin(AsTable, {"CustID"}, Customers, {"ID"}, "Cust", JoinKind.LeftOuter)
in
    Tagged''',
    "Targets": r'''let
    Source = Excel.Workbook(File.Contents("C:\Data\crm.xlsx"), null, true),
    Picked = Source{[Item="Targets",Kind="Table"]}[Data],
    Eval = Expression.Evaluate("Table.RowCount(Picked)", #shared)
in
    Picked''',
}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("workbook", nargs="?", help="Workbook to audit (COM extraction)")
    ap.add_argument("--m-dir", dest="m_dir", help="Folder of loose .m files (no Excel needed)")
    ap.add_argument("--demo", action="store_true",
                    help="Run the rules on an embedded deliberately-bad query set")
    ap.add_argument("--json", dest="json_out", help="Findings JSON path ('-' = stdout)")
    ap.add_argument("--md", dest="md_out", help="Findings markdown path ('-' = stdout)")
    args = ap.parse_args(argv)

    if args.demo:
        queries = dict(DEMO_QUERIES)
    elif args.m_dir:
        queries = load_m_dir(args.m_dir)
    elif args.workbook:
        queries = extract_queries(args.workbook)
    else:
        ap.error("give a workbook, --m-dir, or --demo")

    if not queries:
        print("No Power Query queries found — nothing to audit.")
        return 0

    findings: list[Finding] = []
    for name, m_code in queries.items():
        findings.extend(audit_pq_query(name, m_code))
    findings.extend(audit_pq_architecture(queries))
    findings = group_findings(findings)

    if args.demo:
        if len(findings) < 6:
            print(f"DEMO FAILED: expected >= 6 findings, got {len(findings)}")
            return 1
        print(f"Demo OK: {len(findings)} findings from {len(queries)} deliberately-bad queries.")

    write_output(findings, args.json_out, args.md_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

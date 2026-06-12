"""Build sheet-level dependency artefacts for excel-cartographer.

Reads an extract.json (schema: ../_excel-shared/references/extraction_guide.md)
and emits two deterministic artefacts:

1. --mermaid : L1 Workbook Map skeleton (`flowchart LR`).
   - One node per sheet, grouped into subgraphs by heuristic role:
       input       = no inbound formula edges AND mostly constants
       output      = no outbound formula edges
       calculation = everything else
   - Solid arrows  = formula layer; label = cross-sheet reference count.
   - Dotted arrows = shadow layer: validations (sqref sheet fed by the sheet
     formula1 points at), conditional formatting (formatted range fed by the
     sheets its rule formulas reference), and named ranges (defining sheet fed
     to every sheet whose formulas or chart series use the name).
   - Sheets with no edge in either layer are styled `:::orphan`.
2. --register : Dependency Register markdown — every formula-layer and
   shadow-layer edge with counts, critical-path candidates (longest simple
   paths through the formula-layer sheet graph), and a summary block.

Edges are emitted in DATA-FLOW direction (source sheet --> consuming sheet).
Note extract.json's sheet_edges record the reverse (referencing -> referenced),
so this script inverts them.

Deterministic only. Claude's judgment pass afterwards: correct heuristic
roles, replace count-only arrow labels with what actually flows, build the
L2-L4 maps and shadow inventory (see references/mermaid_rules.md and
references/shadow_dependencies.md).

Usage:
    python build_dependency_graph.py <extract.json> [--mermaid OUT|-] [--register OUT|-]

With no output flags, both artefacts print to stdout. Exit code 0 on success.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))
from audit_lib import load_extract  # noqa: E402  (import also makes stdout UTF-8 safe)

MERMAID_RESERVED = {
    "end", "graph", "subgraph", "direction", "click", "style",
    "classdef", "class", "linkstyle", "flowchart", "default",
}

_SHEET_REF = re.compile(r"(?:'([^']+)'|([A-Za-z_][A-Za-z0-9_.]*))!")
_STRING = re.compile(r'"[^"]*"')

ROLE_GROUPS = (
    ("input", "sg_Inputs", "Inputs"),
    ("calculation", "sg_Calculations", "Calculations"),
    ("output", "sg_Outputs", "Outputs"),
)


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def sheet_refs(formula: str) -> list[str]:
    """Sheet names referenced in a formula / refers_to string (strings shielded)."""
    if not formula:
        return []
    found: list[str] = []
    for m in _SHEET_REF.finditer(_STRING.sub('""', formula)):
        name = m.group(1) or m.group(2)
        if name not in found:
            found.append(name)
    return found


def make_node_ids(sheet_names: list[str]) -> dict[str, str]:
    """Mermaid-safe, collision-free node IDs (no spaces, no reserved words)."""
    ids: dict[str, str] = {}
    taken: set[str] = set()
    for name in sheet_names:
        base = re.sub(r"\W+", "_", name).strip("_") or "Sheet"
        if base[0].isdigit():
            base = "S_" + base
        if base.lower() in MERMAID_RESERVED:
            base += "_"
        cand, n = base, 2
        while cand in taken:
            cand, n = f"{base}_{n}", n + 1
        ids[name] = cand
        taken.add(cand)
    return ids


def _esc(text: str) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ")


# ---------------------------------------------------------------------------
# Edge builders
# ---------------------------------------------------------------------------

def formula_edges(extract: dict):
    """Return (internal, external) edge lists as (src, dst, count) in data-flow
    direction. External-workbook references are reported separately because
    they are red flags, not normal wiring."""
    internal, external = [], []
    for e in extract.get("dependencies", {}).get("sheet_edges", []):
        src, dst, count = e["to"], e["from"], e.get("count", 1)
        if str(src).startswith("[external]") or str(dst).startswith("[external]"):
            external.append((src, dst, count))
        else:
            internal.append((src, dst, count))
    return internal, external


def name_usage(extract: dict, names: set[str]) -> dict[tuple[str, str], int]:
    """{(using_sheet, name): count} of formula cells / chart series that use a
    defined name. String literals are shielded so a label containing 'WACC'
    never counts as a reference."""
    pats = {
        nm: re.compile(r"(?<![A-Za-z0-9_.'])" + re.escape(nm) + r"(?![A-Za-z0-9_(])")
        for nm in names
    }
    use: dict[tuple[str, str], int] = {}
    for sheet, recs in extract.get("cells", {}).items():
        for rec in recs:
            f = rec.get("f")
            if not f:
                continue
            shielded = _STRING.sub('""', f)
            for nm, rx in pats.items():
                if rx.search(shielded):
                    use[(sheet, nm)] = use.get((sheet, nm), 0) + 1
    for chart in extract.get("charts", []) or []:
        for series in chart.get("series_ranges", []) or []:
            for nm, rx in pats.items():
                if rx.search(str(series)):
                    key = (chart.get("sheet") or "(chart)", nm)
                    use[key] = use.get(key, 0) + 1
    return use


def shadow_edge_list(extract: dict) -> list[dict]:
    """Shadow-layer edges: each is {src, dst, mechanism, via, detail, cross}."""
    edges: list[dict] = []
    names = {n["name"]: n for n in extract.get("named_ranges", [])}
    name_sheet = {
        nm: (sheet_refs(n.get("refers_to") or "") or [None])[0]
        for nm, n in names.items()
    }

    # 1. Named ranges: defining sheet feeds every sheet using the name.
    for (sheet, nm), count in sorted(name_usage(extract, set(names)).items()):
        src = name_sheet.get(nm)
        if not src:
            continue
        edges.append({
            "src": src, "dst": sheet, "mechanism": "named range", "via": nm,
            "detail": f"used by {count} cell(s)/series", "cross": src != sheet,
        })

    # 2. Validations: formula1's source sheet feeds the validated cells' sheet.
    for v in extract.get("validations", []):
        f1 = v.get("formula1") or ""
        srcs = sheet_refs(f1)
        bare = f1.lstrip("=").strip()
        if bare in name_sheet and name_sheet[bare] and name_sheet[bare] not in srcs:
            srcs.append(name_sheet[bare])  # list validation defined via a name
        for src in srcs:
            edges.append({
                "src": src, "dst": v["sheet"], "mechanism": "validation",
                "via": f1, "detail": f"sqref {v.get('sqref')}",
                "cross": src != v["sheet"],
            })

    # 3. Conditional formatting: rule-formula source sheets feed the formatted range.
    for cf in extract.get("conditional_formatting", []):
        srcs: list[str] = []
        for f in cf.get("formulas", []) or []:
            for s in sheet_refs(f or ""):
                if s not in srcs:
                    srcs.append(s)
            bare = (f or "").lstrip("=").strip()
            if bare in name_sheet and name_sheet[bare] and name_sheet[bare] not in srcs:
                srcs.append(name_sheet[bare])
        for src in srcs:
            edges.append({
                "src": src, "dst": cf["sheet"], "mechanism": "conditional format",
                "via": "; ".join(cf.get("formulas") or []),
                "detail": f"range {cf.get('range')}", "cross": src != cf["sheet"],
            })
    return edges


# ---------------------------------------------------------------------------
# Roles + critical path
# ---------------------------------------------------------------------------

def classify_roles(extract: dict, f_edges) -> dict[str, str]:
    sheets = [s["name"] for s in extract["meta"]["sheets"]]
    inbound = Counter()
    outbound = Counter()
    for src, dst, _ in f_edges:
        outbound[src] += 1
        inbound[dst] += 1
    roles: dict[str, str] = {}
    for s in sheets:
        recs = extract.get("cells", {}).get(s, [])
        n_formula = sum(1 for r in recs if "f" in r)
        n_pop = sum(1 for r in recs if "f" in r or "v" in r)
        mostly_constants = (n_formula < 0.5 * n_pop) if n_pop else True
        if inbound[s] == 0 and mostly_constants:
            roles[s] = "input"
        elif outbound[s] == 0:
            roles[s] = "output"
        else:
            roles[s] = "calculation"
    return roles


def longest_paths(f_edges, cap: int = 5) -> list[list[str]]:
    """All longest simple paths through the formula-layer sheet graph (data-flow
    direction). DFS with a visited set, so cycles cannot loop it."""
    adj: dict[str, set[str]] = {}
    for src, dst, _ in f_edges:
        adj.setdefault(src, set()).add(dst)
    best_len, best = 0, []

    def dfs(node: str, path: list[str], seen: set[str]) -> None:
        nonlocal best_len, best
        nxt = [n for n in sorted(adj.get(node, ())) if n not in seen]
        if not nxt:
            if len(path) > best_len:
                best_len, best = len(path), [list(path)]
            elif len(path) == best_len and len(best) < cap:
                best.append(list(path))
            return
        for n in nxt:
            path.append(n)
            seen.add(n)
            dfs(n, path, seen)
            path.pop()
            seen.discard(n)

    for start in sorted(adj):
        dfs(start, [start], {start})
    return best


# ---------------------------------------------------------------------------
# Emitters
# ---------------------------------------------------------------------------

def connected_sheets(f_edges, ext_edges, s_edges) -> set[str]:
    conn: set[str] = set()
    for src, dst, _ in f_edges:
        conn |= {src, dst}
    for src, dst, _ in ext_edges:
        conn |= {src, dst}
    for e in s_edges:
        if e["cross"]:
            conn |= {e["src"], e["dst"]}
    return conn


def build_mermaid(extract, f_edges, ext_edges, s_edges, roles) -> str:
    sheets = [s["name"] for s in extract["meta"]["sheets"]]
    hidden = {s["name"] for s in extract["meta"]["sheets"]
              if s.get("state", "visible") != "visible"}
    ext_names = sorted({src for src, _, _ in ext_edges} | {dst for _, dst, _ in ext_edges}
                       - set(sheets))
    ids = make_node_ids(sheets + ext_names)
    conn = connected_sheets(f_edges, ext_edges, s_edges)

    lines = [
        "%% Agent: Cartographer 🗺️ — Workbook Map",
        "%% Skeleton generated by build_dependency_graph.py. Judgment pass pending:",
        "%% verify roles, replace ref-count labels with what actually flows.",
        "flowchart LR",
    ]
    for role, sg_id, label in ROLE_GROUPS:
        members = [s for s in sheets if roles.get(s) == role]
        if not members:
            continue
        lines.append(f'    subgraph {sg_id}["{label}"]')
        for s in members:
            disp = s + (" (hidden)" if s in hidden else "")
            suffix = "" if s in conn else ":::orphan"
            lines.append(f'        {ids[s]}["{disp}"]{suffix}')
        lines.append("    end")

    if f_edges:
        lines.append("    %% Formula layer (solid; data flows source --> consumer)")
        for src, dst, count in f_edges:
            lines.append(f'    {ids[src]} -- "{count} refs" --> {ids[dst]}')
    if ext_edges:
        lines.append("    %% External workbook references (red flags)")
        for src, dst, count in ext_edges:
            lines.append(f'    {ids[src]}:::external -- "{count} refs" --> {ids[dst]}')
    cross_shadow: dict[tuple[str, str], list[dict]] = {}
    for e in s_edges:
        if e["cross"]:
            cross_shadow.setdefault((e["src"], e["dst"]), []).append(e)
    if cross_shadow:
        lines.append("    %% Shadow layer (dotted; validations / named ranges / CF)")
        for (src, dst), group in sorted(cross_shadow.items()):
            vias: list[str] = []
            for e in group:
                tag = e["via"] if e["mechanism"] == "named range" else e["mechanism"]
                if tag not in vias:
                    vias.append(tag)
            label = ", ".join(vias[:3]) + (f" +{len(vias) - 3} more" if len(vias) > 3 else "")
            lines.append(f'    {ids[src]} -. "{label}" .-> {ids[dst]}')
    lines.append("    classDef orphan stroke-dasharray: 5 5")
    lines.append("    classDef external fill:#FFCDD2,stroke:#C62828")
    return "\n".join(lines) + "\n"


def build_register(extract, f_edges, ext_edges, s_edges, roles, paths) -> str:
    lines = ["# Dependency Register — formula + shadow layers",
             "",
             "Generated by `build_dependency_graph.py`. Direction is data flow:",
             "*source sheet feeds consumer sheet*.",
             ""]

    lines += ["## Formula layer (cross-sheet references)", ""]
    if f_edges or ext_edges:
        lines += ["| Source sheet | Feeds | Refs |", "|---|---|---|"]
        for src, dst, count in f_edges:
            lines.append(f"| {_esc(src)} | {_esc(dst)} | {count} |")
        for src, dst, count in ext_edges:
            lines.append(f"| {_esc(src)} | {_esc(dst)} | {count} (external workbook — review) |")
    else:
        lines.append("No cross-sheet formula references found.")

    lines += ["", "## Shadow layer", ""]
    if s_edges:
        lines += ["| Source sheet | Feeds | Mechanism | Via | Detail |",
                  "|---|---|---|---|---|"]
        for e in s_edges:
            dst = e["dst"] + ("" if e["cross"] else " (same sheet)")
            lines.append(f"| {_esc(e['src'])} | {_esc(dst)} | {e['mechanism']} "
                         f"| `{_esc(e['via'])}` | {_esc(e['detail'])} |")
    else:
        lines.append("No shadow-layer edges resolved (hardcoded validations carry no edge).")

    lines += ["", "## Critical-path candidates (longest simple paths, formula layer)", ""]
    if paths:
        for i, p in enumerate(paths, 1):
            lines.append(f"{i}. {' → '.join(p)} ({len(p)} sheets)")
    else:
        lines.append("No cross-sheet formula paths found.")

    # Summary block
    names = extract.get("named_ranges", [])
    used_names = {e["via"] for e in s_edges if e["mechanism"] == "named range"}
    unused = sorted(n["name"] for n in names if n["name"] not in used_names)
    role_counts = Counter(roles.values())
    conn = connected_sheets(f_edges, ext_edges, s_edges)
    orphans = sorted(s for s in roles if s not in conn)
    lines += ["", "## Summary", "",
              f"- Sheets: {len(roles)} "
              f"(input {role_counts['input']}, calculation {role_counts['calculation']}, "
              f"output {role_counts['output']}) — heuristic roles, verify before delivery",
              f"- Formula-layer edges: {len(f_edges)}"
              + (f" (+{len(ext_edges)} external)" if ext_edges else ""),
              f"- Shadow-layer edges: {len(s_edges)} "
              f"({sum(1 for e in s_edges if e['cross'])} cross-sheet)",
              f"- Named ranges: {len(names)} defined, "
              f"{len(unused)} unreferenced" + (f" ({', '.join(unused)})" if unused else ""),
              f"- Unconnected sheets (no edges either layer): "
              + (", ".join(orphans) if orphans else "none")]
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def _write(text: str, dest: str, label: str) -> None:
    if dest == "-":
        print(text)
    else:
        path = Path(dest)
        if path.parent != Path("."):
            path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        print(f"Wrote {label} -> {dest}")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("extract", help="Path to extract.json")
    ap.add_argument("--mermaid", help="Workbook map output ('-' = stdout)")
    ap.add_argument("--register", help="Dependency register output ('-' = stdout)")
    args = ap.parse_args(argv)

    extract = load_extract(args.extract)
    f_edges, ext_edges = formula_edges(extract)
    s_edges = shadow_edge_list(extract)
    roles = classify_roles(extract, f_edges)
    paths = longest_paths(f_edges)

    mermaid = build_mermaid(extract, f_edges, ext_edges, s_edges, roles)
    register = build_register(extract, f_edges, ext_edges, s_edges, roles, paths)

    if not args.mermaid and not args.register:
        print(mermaid)
        print("---")
        print(register)
        return 0
    if args.mermaid:
        _write(mermaid, args.mermaid, "workbook map")
    if args.register:
        _write(register, args.register, "dependency register")
    return 0


if __name__ == "__main__":
    sys.exit(main())

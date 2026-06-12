"""consolidate_findings.py — merge specialist findings into one consolidated set.

Implements the consolidation rules in
../../_excel-shared/references/audit_standards.md section 6:

  * Dedup key      : (sheet, overlapping cell ranges, category). Two agents that
                     flag overlapping cells on the same sheet under the same
                     category are reporting one underlying issue.
  * On merge       : keep the more detailed (longer) description, append
                     "(also flagged by <agent>)", take the max severity
                     (Critical > Warning > Info), union the cell coverage and
                     re-group it per the Grouping Rule (section 4).
  * Sort order     : severity desc -> sheet (workbook tab order when an
                     extract.json is supplied, otherwise input order) ->
                     first cell (row, then column).
  * ID assignment  : F001-style sequence, assigned AFTER sorting — specialists
                     never assign IDs.

Usage:
    python consolidate_findings.py <findings1.json> <findings2.json> ...
        [--extract extract.json] [--out consolidated.json] [--md report.md]

Each input file uses the findings JSON interchange schema (audit_standards.md
section 5), normally one file per specialist agent, e.g. Workings/sentry-findings.json.
With neither --out nor --md, the consolidated markdown table prints to stdout.
A summary (per-agent counts, per-severity counts, dedup merges) always prints.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import (  # noqa: E402  (path bootstrap must run first)
    Finding,
    group_findings,
    write_output,
    load_extract,
    load_findings,
    expand_range,
    parse_a1,
    cells_to_ranges,
    SEVERITIES,
    SEVERITY_DISPLAY,
)

# Rank by index in SEVERITIES = ("critical", "warning", "info"): lower = more severe.
SEV_RANK = {sev: i for i, sev in enumerate(SEVERITIES)}

_UNPLACED = (10 ** 9, 10 ** 9)  # sort key for findings with no parseable A1 cell


# ---------------------------------------------------------------------------
# Cell coverage helpers
# ---------------------------------------------------------------------------

def split_cells(finding: Finding) -> tuple[set[tuple[int, int]], list[str]]:
    """Return (A1 coordinate set, non-A1 literal refs) for a finding.

    Literal refs (VBA module names, query names) cannot be expanded to
    coordinates; they participate in overlap tests by exact string match.
    """
    coords: set[tuple[int, int]] = set()
    literals: list[str] = []
    for ref in finding.cells:
        try:
            coords |= expand_range(ref)
        except ValueError:
            if ref not in literals:
                literals.append(ref)
    return coords, literals


def first_cell(finding: Finding) -> tuple[int, int]:
    """(row, col) of the first cell of the first parseable range, for sorting."""
    for ref in finding.cells:
        head = ref.split(":", 1)[0].strip()
        try:
            return parse_a1(head)
        except ValueError:
            continue
    return _UNPLACED


def rebuild_cells(coords: set[tuple[int, int]], literals: list[str]) -> list[str]:
    """Grouped range strings (Grouping Rule) followed by any literal refs."""
    cells: list[str] = []
    if coords:
        cells.extend(cells_to_ranges(coords).split(", "))
    cells.extend(literals)
    return cells


# ---------------------------------------------------------------------------
# Deduplication (audit_standards.md section 6)
# ---------------------------------------------------------------------------

def merge_pair(base: Finding, other: Finding,
               coords: set[tuple[int, int]], literals: list[str]) -> Finding:
    """Combine two findings that share the dedup key into one record."""
    # "More detailed" = longer description wins; its agent owns the finding.
    if len(other.description) > len(base.description):
        base, other = other, base
    severity = min((base.severity, other.severity), key=SEV_RANK.__getitem__)
    description = base.description
    if other.agent != base.agent:
        note = f"(also flagged by {other.agent})"
        if note not in description:
            description = f"{description} {note}"
    return Finding(
        agent=base.agent,
        sheet=base.sheet,
        cells=rebuild_cells(coords, literals),
        location=base.location or other.location,
        severity=severity,
        category=base.category,
        description=description,
        r1c1_expected=base.r1c1_expected or other.r1c1_expected,
        r1c1_actual=base.r1c1_actual or other.r1c1_actual,
    )


def consolidate(findings: list[Finding]) -> tuple[list[Finding], int]:
    """Dedup overlapping findings. Returns (consolidated list, merge count)."""
    accepted: list[dict] = []   # each: {"finding", "coords", "literals"}
    merges = 0
    for f in findings:
        f_coords, f_literals = split_cells(f)
        target = None
        for rec in accepted:
            g = rec["finding"]
            if g.sheet != f.sheet or g.category != f.category:
                continue
            if (f_coords & rec["coords"]) or (set(f_literals) & set(rec["literals"])):
                target = rec
                break
        if target is None:
            accepted.append({"finding": f, "coords": f_coords, "literals": f_literals})
            continue
        merges += 1
        union_coords = target["coords"] | f_coords
        union_literals = target["literals"] + [l for l in f_literals
                                               if l not in target["literals"]]
        target["finding"] = merge_pair(target["finding"], f, union_coords, union_literals)
        target["coords"] = union_coords
        target["literals"] = union_literals
    return [rec["finding"] for rec in accepted], merges


# ---------------------------------------------------------------------------
# Sorting and ID assignment
# ---------------------------------------------------------------------------

def sheet_order_map(findings: list[Finding], extract_path: str | None) -> dict[str, int]:
    """Sheet name -> sort rank. Workbook tab order when an extract is given;
    otherwise first-seen order across the input findings. Sheets the extract
    does not know about (e.g. '(workbook)' pseudo-sheets) sort after known ones."""
    order: dict[str, int] = {}
    if extract_path:
        meta = load_extract(extract_path).get("meta", {})
        for i, sheet in enumerate(meta.get("sheets", [])):
            order[sheet["name"]] = i
    for f in findings:
        if f.sheet not in order:
            order[f.sheet] = len(order)
    return order


def sort_and_number(findings: list[Finding], extract_path: str | None) -> list[Finding]:
    order = sheet_order_map(findings, extract_path)
    findings.sort(key=lambda f: (SEV_RANK[f.severity], order[f.sheet], *first_cell(f)))
    width = max(3, len(str(len(findings))))
    for i, f in enumerate(findings, start=1):
        f.id = f"F{i:0{width}d}"
    return findings


# ---------------------------------------------------------------------------
# Summary statistics
# ---------------------------------------------------------------------------

def print_summary(per_file: list[tuple[str, int]], total_in: int,
                  merges: int, findings: list[Finding]) -> None:
    print("\n=== Consolidation summary ===")
    print(f"Input files            : {len(per_file)}")
    for name, count in per_file:
        print(f"  {name}: {count} findings")
    print(f"Total input findings   : {total_in}")
    print(f"Dedup merges performed : {merges}")
    print(f"Consolidated findings  : {len(findings)}")

    by_agent: dict[str, int] = {}
    by_sev: dict[str, int] = {sev: 0 for sev in SEVERITIES}
    for f in findings:
        by_agent[f.agent] = by_agent.get(f.agent, 0) + 1
        by_sev[f.severity] += 1
    print("Per agent              :")
    for agent in sorted(by_agent):
        print(f"  {agent}: {by_agent[agent]}")
    print("Per severity           :")
    for sev in SEVERITIES:
        print(f"  {SEVERITY_DISPLAY[sev]}: {by_sev[sev]}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description="Consolidate specialist findings JSON files per audit_standards.md §6.")
    ap.add_argument("inputs", nargs="+", metavar="findings.json",
                    help="Specialist findings files (audit_standards.md §5 schema)")
    ap.add_argument("--extract", metavar="extract.json", default=None,
                    help="Workbook extract — supplies sheet tab order for sorting")
    ap.add_argument("--out", metavar="consolidated.json", default=None,
                    help="Write consolidated findings JSON (with id + agent) here, '-' = stdout")
    ap.add_argument("--md", metavar="report.md", default=None,
                    help="Write consolidated markdown table here, '-' = stdout")
    args = ap.parse_args(argv)

    all_findings: list[Finding] = []
    per_file: list[tuple[str, int]] = []
    for path in args.inputs:
        try:
            loaded = load_findings(path)
        except (OSError, ValueError, KeyError, TypeError) as exc:
            print(f"ERROR: cannot load {path}: {exc}", file=sys.stderr)
            return 1
        per_file.append((path, len(loaded)))
        all_findings.extend(loaded)

    total_in = len(all_findings)

    # Normalise first: merge same-agent duplicates and re-apply the Grouping
    # Rule, so cross-agent dedup compares clean, canonical records.
    all_findings = group_findings(all_findings)
    consolidated, merges = consolidate(all_findings)
    consolidated = sort_and_number(consolidated, args.extract)

    write_output(consolidated, args.out, args.md, consolidated=True)
    print_summary(per_file, total_in, merges, consolidated)
    return 0


if __name__ == "__main__":
    sys.exit(main())

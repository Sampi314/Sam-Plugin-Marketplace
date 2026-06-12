#!/usr/bin/env python3
"""efficiency_rules.py — deterministic complexity and performance checks for
excel-efficiency-auditor.

Consumes extract.json (sections: cells, r1c1_rows, text_inventory — see
../_excel-shared/references/extraction_guide.md) and performs:

1. Mega-Formula — formula length > 500 characters is a Warning; > 1,000
   characters is Critical. Length alone is the finding (an unauditable formula
   is bad practice even when correct); the deep correctness dive on each
   Mega-Formula stays with Claude.

2. Volatile Complexity — census of volatile functions, grouped per
   sheet/row/function:
   - OFFSET / INDIRECT             -> Warning (replace with INDEX / direct refs)
   - RAND / RANDBETWEEN            -> Warning (non-deterministic outputs)
   - NOW / TODAY (date volatiles)  -> Info    (centralise into one input cell)

3. Redundant Calculation (Info) — an identical R1C1 row signature recurring in
   3+ disjoint row groups on one sheet (from `r1c1_rows`): the same calculation
   may be computed repeatedly where one helper row could serve. Bare
   single-reference signatures (pure links like `=RC[-1]` or `=Inputs!RC`) are
   skipped — repeated links are normal, repeated logic is not.

Repeated sub-expression analysis, unused-calculation detection, and
decomposition design are judgment calls and stay with Claude — see
references/efficiency_rules.md.

Usage:
    python efficiency_rules.py <extract.json> [--json OUT|-] [--md OUT|-]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output, load_extract

AGENT = "efficiency"

MEGA_WARNING_LEN = 500
MEGA_CRITICAL_LEN = 1000

VOLATILE_FUNCS: dict[str, tuple[str, str]] = {
    # function: (severity, recommendation)
    "OFFSET": ("warning", "replace with INDEX, which is non-volatile"),
    "INDIRECT": ("warning", "replace with direct references, INDEX, or CHOOSE"),
    "RAND": ("warning", "isolate random draws in a dedicated simulation block, "
                        "or paste values for delivery"),
    "RANDBETWEEN": ("warning", "isolate random draws in a dedicated simulation "
                               "block, or paste values for delivery"),
    "NOW": ("info", "centralise the run date/time into a single labelled input cell"),
    "TODAY": ("info", "centralise the run date into a single labelled input cell"),
}

# A signature that is just "=" + one optional-sheet-qualified reference or one
# defined name is a pure link, not a calculation — exempt from the redundancy check.
_BARE_REF_RE = re.compile(
    r"^=(?:'[^']*'!|[A-Za-z_][A-Za-z0-9_.]*!)?"
    r"(?:R(?:\[-?\d+\]|\d+)?C(?:\[-?\d+\]|\d+)?|[A-Za-z_][A-Za-z0-9_.]*)$"
)


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

def row_labels(extract: dict, sheet: str) -> dict[int, str]:
    """Row number -> leftmost text label on that row (from text_inventory)."""
    labels: dict[int, tuple[int, str]] = {}
    for rec in extract.get("text_inventory", {}).get(sheet, []):
        m = re.match(r"^([A-Za-z]{1,3})(\d+)$", rec["addr"])
        if not m:
            continue
        col = 0
        for ch in m.group(1).upper():
            col = col * 26 + ord(ch) - 64
        row = int(m.group(2))
        if row not in labels or col < labels[row][0]:
            labels[row] = (col, rec["text"])
    return {row: text for row, (col, text) in labels.items()}


def location_for(labels: dict[int, str], row: int) -> str:
    label = labels.get(row, "").strip()
    return f"Row {row} — '{label}'" if label else f"Row {row}"


# ---------------------------------------------------------------------------
# Check 1 — Mega-Formula (length tiers)
# ---------------------------------------------------------------------------

def mega_formula_findings(extract: dict) -> list[Finding]:
    findings: list[Finding] = []
    for sheet, cells in extract.get("cells", {}).items():
        labels = row_labels(extract, sheet)
        for cell in cells:
            formula = cell.get("f")
            if not formula or len(formula) <= MEGA_WARNING_LEN:
                continue
            length = len(formula)
            severity = "critical" if length > MEGA_CRITICAL_LEN else "warning"
            findings.append(Finding(
                agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                location=location_for(labels, cell["r"]),
                severity=severity, category="Mega-Formula",
                description=(
                    f"Formula is {length:,} characters long (threshold "
                    f"{MEGA_WARNING_LEN}; >{MEGA_CRITICAL_LEN:,} is critical). "
                    f"Even if correct, it cannot be audited step by step. "
                    f"— Recommend: decompose into helper rows of named "
                    f"intermediate steps"),
            ))
    return findings


# ---------------------------------------------------------------------------
# Check 2 — Volatile Complexity
# ---------------------------------------------------------------------------

def volatile_findings(extract: dict) -> list[Finding]:
    findings: list[Finding] = []
    patterns = {fn: re.compile(r"\b" + fn + r"\s*\(", re.IGNORECASE)
                for fn in VOLATILE_FUNCS}
    for sheet, cells in extract.get("cells", {}).items():
        labels = row_labels(extract, sheet)
        for cell in cells:
            formula = cell.get("f")
            if not formula:
                continue
            for fn, (severity, recommend) in VOLATILE_FUNCS.items():
                if not patterns[fn].search(formula):
                    continue
                findings.append(Finding(
                    agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                    location=location_for(labels, cell["r"]),
                    severity=severity, category="Volatile Complexity",
                    description=(
                        f"Volatile function {fn}() forces recalculation of "
                        f"its dependents on every workbook change. "
                        f"— Recommend: {recommend}"),
                ))
    return findings


# ---------------------------------------------------------------------------
# Check 3 — Redundant Calculation (recurring R1C1 signature, 3+ disjoint groups)
# ---------------------------------------------------------------------------

def _disjoint_groups(rows: list[int]) -> list[list[int]]:
    groups: list[list[int]] = []
    for row in sorted(rows):
        if groups and row == groups[-1][-1] + 1:
            groups[-1].append(row)
        else:
            groups.append([row])
    return groups


def redundancy_findings(extract: dict) -> list[Finding]:
    findings: list[Finding] = []
    for sheet, rows in extract.get("r1c1_rows", {}).items():
        sig_rows: dict[str, dict[int, list[str]]] = {}
        for rec in rows:
            for sig, addrs in rec.get("patterns", {}).items():
                sig_rows.setdefault(sig, {})[rec["row"]] = list(addrs)
        for sig, by_row in sig_rows.items():
            if _BARE_REF_RE.match(sig.strip()):
                continue
            groups = _disjoint_groups(list(by_row))
            if len(groups) < 3:
                continue
            row_list = ", ".join(
                (str(g[0]) if len(g) == 1 else f"{g[0]}–{g[-1]}") for g in groups)
            cells = [addr for addrs in by_row.values() for addr in addrs]
            findings.append(Finding(
                agent=AGENT, sheet=sheet, cells=cells,
                location=f"Rows {row_list}",
                severity="info", category="Redundant Calculation",
                description=(
                    f"Identical R1C1 signature recurs in {len(groups)} disjoint "
                    f"row blocks on this sheet — the same calculation may be "
                    f"performed repeatedly where one helper row could serve. "
                    f"— Recommend: verify whether these blocks duplicate logic; "
                    f"calculate once and link if so"),
                r1c1_actual=sig,
            ))
    return findings


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("extract", help="Path to extract.json")
    ap.add_argument("--json", dest="json_out", metavar="OUT",
                    help="Findings JSON output path ('-' = stdout)")
    ap.add_argument("--md", dest="md_out", metavar="OUT",
                    help="Findings markdown table output path ('-' = stdout)")
    args = ap.parse_args(argv)

    extract = load_extract(args.extract)
    findings = (mega_formula_findings(extract)
                + volatile_findings(extract)
                + redundancy_findings(extract))
    findings = group_findings(findings)
    write_output(findings, args.json_out, args.md_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

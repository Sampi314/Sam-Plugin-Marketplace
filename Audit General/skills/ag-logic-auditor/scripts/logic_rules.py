#!/usr/bin/env python3
"""logic_rules.py — deterministic formula-logic checks for excel-logic-auditor.

Consumes extract.json (sections: r1c1_rows, cells, text_inventory — see
../_excel-shared/references/extraction_guide.md) and performs:

1. Formula Pattern Break (Warning) — every row in `r1c1_rows` with
   n_patterns > 1 is a break candidate. The dominant signature (the one used
   by the most cells in the row) is reported as Expected R1C1; each minority
   signature becomes one grouped finding whose cells are the deviating cells
   and whose Actual R1C1 is the minority signature. The script does NOT judge
   intentionality — first-period columns and subtotal columns legitimately
   differ; that adjudication stays with Claude.

2. Hard-Coded Value (Warning) — formula cells whose R1C1 form embeds numeric
   literals other than the structural constants 0, 1, -1, 12, 100, where the
   literal is not an argument inside a ROUND*/DATE* function call (names
   containing ROUND or DATE are exempt: ROUND, ROUNDUP, MROUND, DATE, EDATE,
   DATEDIF, …). String literals, sheet-name prefixes, and R1C1 reference
   numbers (R[2]C[-1], R5C3) are stripped before matching.

Semantic label-vs-formula validation, reference-direction checks, business
rules, sanity checks, and cross-sheet reconciliation are judgment calls and
stay with Claude — see references/logic_rules.md.

Usage:
    python logic_rules.py <extract.json> [--json OUT|-] [--md OUT|-]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output, load_extract, a1_to_r1c1

AGENT = "logic"

# Structural constants that are acceptable inside formulas.
ALLOWED_POSITIVE = {0.0, 1.0, 12.0, 100.0}
ALLOWED_NEGATIVE = {1.0}          # i.e. -1

_STRING_RE = re.compile(r'"[^"]*"')
_QUOTED_SHEET_RE = re.compile(r"'[^']*'!")
_BARE_SHEET_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_.]*!")
_R1C1_REF_RE = re.compile(r"\bR(?:\[-?\d+\]|\d+)?C(?:\[-?\d+\]|\d+)?(?![A-Za-z0-9_(\[])")
_NUM_RE = re.compile(r"(?<![A-Za-z0-9_.])(\d+(?:\.\d+)?)(?![A-Za-z0-9_.])")
_SIGN_CONTEXT = set("=(,+-*/^<>&{;")


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
# Check 1 — Formula Pattern Break (from r1c1_rows)
# ---------------------------------------------------------------------------

def pattern_break_findings(extract: dict) -> list[Finding]:
    findings: list[Finding] = []
    for sheet, rows in extract.get("r1c1_rows", {}).items():
        labels = row_labels(extract, sheet)
        for rec in rows:
            if rec.get("n_patterns", 1) <= 1:
                continue
            patterns: dict[str, list[str]] = rec["patterns"]
            total = sum(len(addrs) for addrs in patterns.values())
            dominant_sig, dominant_addrs = None, []
            for sig, addrs in patterns.items():     # insertion order breaks ties
                if len(addrs) > len(dominant_addrs):
                    dominant_sig, dominant_addrs = sig, addrs
            for sig, addrs in patterns.items():
                if sig == dominant_sig:
                    continue
                findings.append(Finding(
                    agent=AGENT, sheet=sheet, cells=list(addrs),
                    location=location_for(labels, rec["row"]),
                    severity="warning", category="Formula Pattern Break",
                    description=(
                        f"Breaks the dominant pattern of this row — "
                        f"{len(addrs)} of {total} formula cell(s) deviate. "
                        f"First-period and subtotal columns are common "
                        f"intentional variants; verify intent. "
                        f"— Recommend: restore the uniform formula or "
                        f"document the exception"),
                    r1c1_expected=dominant_sig, r1c1_actual=sig,
                ))
    return findings


# ---------------------------------------------------------------------------
# Check 2 — Hard-Coded Value (numeric literals embedded in formulas)
# ---------------------------------------------------------------------------

def _strip_for_literals(r1c1: str) -> str:
    """Remove everything that legitimately contains digits but is not a literal."""
    s = _STRING_RE.sub('""', r1c1)
    s = _QUOTED_SHEET_RE.sub("", s)
    s = _BARE_SHEET_RE.sub("", s)
    s = _R1C1_REF_RE.sub("", s)
    return s


def _enclosing_funcs(s: str) -> list[tuple[str, ...]]:
    """For each character position, the stack of open function names (upper)."""
    ctx: list[tuple[str, ...]] = [()] * len(s)
    stack: list[str] = []
    for i, ch in enumerate(s):
        if ch == "(":
            j = i - 1
            while j >= 0 and (s[j].isalnum() or s[j] in "_."):
                j -= 1
            stack.append(s[j + 1:i].upper())
        elif ch == ")" and stack:
            stack.pop()
        ctx[i] = tuple(stack)
    return ctx


def _is_exempt(funcs: tuple[str, ...]) -> bool:
    return any(("ROUND" in f or "DATE" in f) for f in funcs)


def _is_negative(s: str, pos: int) -> bool:
    j = pos - 1
    while j >= 0 and s[j] == " ":
        j -= 1
    if j < 0 or s[j] != "-":
        return False
    j -= 1
    while j >= 0 and s[j] == " ":
        j -= 1
    return j < 0 or s[j] in _SIGN_CONTEXT


def disallowed_literals(r1c1: str) -> list[str]:
    """Distinct disallowed numeric literals in an R1C1 formula, signs included."""
    stripped = _strip_for_literals(r1c1)
    ctx = _enclosing_funcs(stripped)
    out: list[str] = []
    for m in _NUM_RE.finditer(stripped):
        if _is_exempt(ctx[m.start()]):
            continue
        value = float(m.group(1))
        negative = _is_negative(stripped, m.start())
        if negative and value in ALLOWED_NEGATIVE:
            continue
        if not negative and value in ALLOWED_POSITIVE:
            continue
        token = ("-" if negative else "") + m.group(1)
        if token not in out:
            out.append(token)
    return out


def hardcode_findings(extract: dict) -> list[Finding]:
    findings: list[Finding] = []
    for sheet, cells in extract.get("cells", {}).items():
        labels = row_labels(extract, sheet)
        for cell in cells:
            formula = cell.get("f")
            if not formula:
                continue
            r1c1 = cell.get("r1c1") or a1_to_r1c1(formula, cell["r"], cell["c"])
            literals = disallowed_literals(r1c1)
            if not literals:
                continue
            plural = "s" if len(literals) > 1 else ""
            listed = ", ".join(f"`{t}`" for t in literals)
            findings.append(Finding(
                agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                location=location_for(labels, cell["r"]),
                severity="warning", category="Hard-Coded Value",
                description=(
                    f"Formula embeds hard-coded numeric literal{plural} "
                    f"{listed} — values that look like rates or drivers "
                    f"belong in referenced input cells, not inside formulas. "
                    f"— Recommend: move the literal{plural} to an input cell "
                    f"and reference it"),
                r1c1_actual=r1c1,
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
    findings = pattern_break_findings(extract) + hardcode_findings(extract)
    findings = group_findings(findings)
    write_output(findings, args.json_out, args.md_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

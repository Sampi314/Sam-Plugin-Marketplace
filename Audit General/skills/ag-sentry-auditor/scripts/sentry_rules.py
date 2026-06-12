"""sentry_rules.py — deterministic Sentry checks over an extract.json.

Usage:
    python sentry_rules.py <extract.json> [--json OUT|-] [--md OUT|-]

Checks (all mechanical — no judgment calls):
  * errors[]        -> every error cell is a finding. #REF! = "Broken Reference",
                       everything else = "Calculation Error". Severity critical,
                       EXCEPT cells flagged na_pattern or in_chart_range: those are
                       candidates for the intentional chart-gap filter and are
                       downgraded to warning for Claude to confirm or promote.
  * named_ranges[]  -> broken (contains #REF!) = "Dead Name" critical;
                       hidden = "Hidden Name" info.
  * validations[]   -> broken_source = "Invalid Validation" critical.

What this script deliberately does NOT do (Claude-side judgment):
  * the final intentional-#N/A verdict — the script only nominates candidates;
  * circular-reference detection/reasoning — openpyxl cannot see iterative-calc
    settings reliably, so loops need Claude (or COM) to trace and classify;
  * "error handled downstream" analysis of consuming formulas.

Output follows ../_excel-shared/references/audit_standards.md (unified findings
table / findings JSON).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output, load_extract, parse_a1

AGENT = "sentry"


def row_label(extract: dict, sheet: str, addr: str) -> str:
    """Nearest text label to the left in the same row — locates the finding
    for the reader without opening the file."""
    try:
        row, col = parse_a1(addr)
    except ValueError:
        return ""
    best_col, best_text = -1, ""
    for rec in extract.get("text_inventory", {}).get(sheet, []):
        try:
            r, c = parse_a1(rec["addr"])
        except ValueError:
            continue
        if r == row and c < col and c > best_col:
            best_col, best_text = c, rec.get("text", "")
    return best_text


def check_errors(extract: dict) -> list[Finding]:
    findings = []
    for rec in extract.get("errors", []):
        err = rec.get("error", "") or "(unknown error)"
        category = "Broken Reference" if err == "#REF!" else "Calculation Error"
        formula = rec.get("formula")
        formula_note = f" Formula: `{formula}`." if formula else ""

        flags = [name for name, key in (("NA() pattern", "na_pattern"),
                                        ("feeds a chart series", "in_chart_range"))
                 if rec.get(key)]
        if flags:
            severity = "warning"
            desc = (f"Cell evaluates to {err} — candidate intentional chart-gap #N/A "
                    f"({', '.join(flags)}) — verify before accepting.{formula_note}")
        else:
            severity = "critical"
            fix = ("trace and repair the failing reference"
                   if category == "Broken Reference" else "correct the failing formula")
            desc = f"Cell evaluates to {err}.{formula_note} — Recommend: {fix}"

        findings.append(Finding(
            agent=AGENT, sheet=rec.get("sheet", ""), cells=[rec.get("addr", "")],
            location=row_label(extract, rec.get("sheet", ""), rec.get("addr", "")) or "Error cell",
            severity=severity, category=category, description=desc,
        ))
    return findings


def check_named_ranges(extract: dict) -> list[Finding]:
    findings = []
    for nr in extract.get("named_ranges", []):
        name = nr.get("name", "")
        refers = nr.get("refers_to", "")
        scope = nr.get("scope", "workbook")
        if nr.get("broken"):
            findings.append(Finding(
                agent=AGENT, sheet="(Name Manager)", cells=[name],
                location=f"Defined name (scope: {scope})",
                severity="critical", category="Dead Name",
                description=(f"Named range refers to `{refers}` which contains #REF! "
                             f"— Recommend: repoint the name or delete it"),
            ))
        if nr.get("hidden"):
            findings.append(Finding(
                agent=AGENT, sheet="(Name Manager)", cells=[name],
                location=f"Defined name (scope: {scope})",
                severity="info", category="Hidden Name",
                description=(f"Defined name is hidden from the Name Manager UI "
                             f"(refers to `{refers}`) — typically residue from add-ins "
                             f"or copied sheets — Recommend: review, then unhide or delete"),
            ))
    return findings


def check_validations(extract: dict) -> list[Finding]:
    findings = []
    for dv in extract.get("validations", []):
        if not dv.get("broken_source"):
            continue
        cells = (dv.get("sqref") or "").split() or ["(unknown)"]
        vtype = dv.get("type") or "custom"
        findings.append(Finding(
            agent=AGENT, sheet=dv.get("sheet", ""), cells=cells,
            location=f"Data Validation rule ({vtype})",
            severity="critical", category="Invalid Validation",
            description=(f"Validation source `{dv.get('formula1')}` does not resolve "
                         f"(#REF!, missing sheet, or unknown name) — the rule silently "
                         f"stops constraining input — Recommend: repoint the source range"),
        ))
    return findings


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("extract", help="Path to extract.json from extract_workbook.py")
    ap.add_argument("--json", dest="json_out", help="Findings JSON path ('-' = stdout)")
    ap.add_argument("--md", dest="md_out", help="Findings markdown path ('-' = stdout)")
    args = ap.parse_args(argv)

    extract = load_extract(args.extract)
    findings = (check_errors(extract)
                + check_named_ranges(extract)
                + check_validations(extract))
    findings = group_findings(findings)
    write_output(findings, args.json_out, args.md_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

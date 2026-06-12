#!/usr/bin/env python3
"""stylist_rules.py — deterministic formatting checks for excel-stylist-auditor.

Consumes extract.json (sections: meta, cells, styles, text_inventory — see
../_excel-shared/references/extraction_guide.md) and performs:

Phase 0 — convention detection (always runs, emitted via --convention):
  (a) style-guide sheet lookup: sheet names containing style/legend/key/guide
  (b) named Cell Style census: cells[].style frequency vs the styles[] registry
  (c) statistical inference: dominant font colour / fill among formula cells
      vs constant numeric cells, each with a confidence %

Deviation candidates (deterministic only — judgment stays with Claude):
  - "Colour Coding" warnings: constant numeric cells styled like formulas and
    formula cells styled like inputs. Uses named-style classification when the
    registry is in real use, otherwise statistical convention at >=75%
    confidence. Below-threshold adjudication and heading exemptions are
    Claude's job, not this script's.
  - "Number Format" warnings: the nearest row label/unit text to the left
    implies %, date/period, or currency, but the cell's number format
    disagrees (lacks % / is General).

Detected style-guide sheets are skipped in the deviation scan: a legend sheet
deliberately shows every style on demo cells, so flagging it is pure noise.

Usage:
    python stylist_rules.py <extract.json> [--json OUT|-] [--md OUT|-] [--convention OUT|-]
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output, load_extract

AGENT = "stylist"

STYLE_GUIDE_KEYWORDS = ("style", "legend", "key", "guide")

# Named-style classification by name keyword. Neutral wins first: heading,
# units, check and navigation styles are legitimately applied to constants
# and formulas alike, so they carry no input/formula signal.
NEUTRAL_STYLE_KEYWORDS = (
    "head", "title", "units", "unit", "check", "cover", "nav",
    "section", "sub", "wip", "date", "flag", "normal",
)
INPUT_STYLE_KEYWORDS = ("assumption", "input", "hardcode", "entry")
FORMULA_STYLE_KEYWORDS = (
    "calc", "total", "ref", "link", "formula", "operation", "summary",
    "subtotal",
)

PCT_KEYWORDS = ("%", "percent", "margin")
DATE_KEYWORDS = ("date", "period")
CURRENCY_KEYWORDS = ("$", "currency")

CONFIDENCE_THRESHOLD = 0.75   # statistical convention adopted at >= 75 %
STYLE_COVERAGE_THRESHOLD = 0.5  # named styles "in use" when >= 50 % of
                                # calculation-layer cells carry a custom style


def classify_style(name: str | None) -> str | None:
    """Map a Cell Style name to 'input' / 'formula' / None (neutral/unknown)."""
    if not name:
        return None
    low = name.lower()
    if any(k in low for k in NEUTRAL_STYLE_KEYWORDS):
        return None
    if any(k in low for k in INPUT_STYLE_KEYWORDS):
        return "input"
    if any(k in low for k in FORMULA_STYLE_KEYWORDS):
        return "formula"
    return None


def is_constant_numeric(cell: dict) -> bool:
    v = cell.get("v")
    return "f" not in cell and isinstance(v, (int, float)) and not isinstance(v, bool)


def dominant(counter: Counter) -> tuple[object, float, int]:
    """Return (value, confidence, n). Confidence 0.0 when nothing counted."""
    total = sum(counter.values())
    if not total:
        return None, 0.0, 0
    value, count = counter.most_common(1)[0]
    return value, count / total, total


# ---------------------------------------------------------------------------
# Phase 0 — convention detection
# ---------------------------------------------------------------------------

def detect_convention(extract: dict) -> dict:
    sheets = [s["name"] for s in extract.get("meta", {}).get("sheets", [])]
    guide_sheets = [s for s in sheets
                    if any(k in s.lower() for k in STYLE_GUIDE_KEYWORDS)]

    registry = extract.get("styles", []) or []
    custom_styles = [s["name"] for s in registry if s.get("custom")]

    style_use: Counter = Counter()
    font_by_class = {"input": Counter(), "formula": Counter()}
    fill_by_class = {"input": Counter(), "formula": Counter()}
    n_class = {"input": 0, "formula": 0}
    n_styled = 0

    for sheet, cells in extract.get("cells", {}).items():
        for cell in cells:
            style = cell.get("style")
            if style:
                style_use[style] += 1
            if "f" in cell:
                cls = "formula"
            elif is_constant_numeric(cell):
                cls = "input"
            else:
                continue
            n_class[cls] += 1
            if style:
                n_styled += 1
            font_by_class[cls][(cell.get("font") or {}).get("color")] += 1
            fill_by_class[cls][cell.get("fill")] += 1

    n_calc_layer = n_class["input"] + n_class["formula"]
    coverage = n_styled / n_calc_layer if n_calc_layer else 0.0

    stats = {}
    for cls in ("input", "formula"):
        font, font_conf, _ = dominant(font_by_class[cls])
        fill, fill_conf, _ = dominant(fill_by_class[cls])
        stats[cls] = {"n": n_class[cls],
                      "font": font, "font_conf": font_conf,
                      "fill": fill, "fill_conf": fill_conf}

    method = "named_styles" if (custom_styles and coverage >= STYLE_COVERAGE_THRESHOLD) \
        else "statistical"
    return {
        "guide_sheets": guide_sheets,
        "custom_styles": custom_styles,
        "style_use": style_use,
        "coverage": coverage,
        "stats": stats,
        "method": method,
    }


def convention_markdown(conv: dict) -> str:
    def colour(v):
        return f"`{v}`" if v else "(none)"

    lines = ["## Style Convention Summary", ""]
    method_label = ("Named Cell Styles" if conv["method"] == "named_styles"
                    else "Statistical inference (font/fill tallies)")
    lines.append(f"- **Detection method:** {method_label} — "
                 f"{conv['coverage']:.0%} of formula/constant cells carry a custom style")
    if conv["guide_sheets"]:
        lines.append(f"- **Style guide sheet(s):** {', '.join(conv['guide_sheets'])} — "
                     "read the legend itself; this script only detects its presence "
                     "(and skips it in the deviation scan)")
    else:
        lines.append("- **Style guide sheet:** none detected by sheet name")
    lines.append(f"- **Custom Cell Styles registered:** {len(conv['custom_styles'])}")
    lines.append("")
    if conv["custom_styles"]:
        lines.append("| Cell Style | Class (by name) | Cells using it |")
        lines.append("|---|---|---|")
        for name in conv["custom_styles"]:
            cls = classify_style(name) or "neutral / unknown"
            lines.append(f"| {name} | {cls} | {conv['style_use'].get(name, 0)} |")
        lines.append("")
    lines.append("### Statistical tallies (classic convention hint: inputs blue "
                 "font or yellow fill; formulas black font, no fill)")
    lines.append("")
    lines.append("| Cell class | Cells | Dominant font colour | Confidence | Dominant fill | Confidence |")
    lines.append("|---|---|---|---|---|---|")
    for cls, label in (("input", "Constant (input candidate)"),
                       ("formula", "Formula")):
        s = conv["stats"][cls]
        lines.append(f"| {label} | {s['n']} | {colour(s['font'])} | {s['font_conf']:.0%} "
                     f"| {colour(s['fill'])} | {s['fill_conf']:.0%} |")
    lines.append("")
    lines.append("Conventions below 75% confidence are **not** enforced by this script — "
                 "adjudicate those cell-by-cell (or ask the user).")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Deviation candidates — Colour Coding
# ---------------------------------------------------------------------------

def row_label(texts_by_row: dict, row: int, col: int) -> str:
    """Nearest text in the same row to the LEFT of (row, col); '' if none."""
    candidates = [(c, t) for c, t in texts_by_row.get(row, []) if c < col]
    if not candidates:
        return ""
    return max(candidates)[1]


def colour_coding_findings(extract: dict, conv: dict) -> list[Finding]:
    findings: list[Finding] = []
    skip_sheets = set(conv["guide_sheets"])

    if conv["method"] == "named_styles":
        for sheet, cells in extract.get("cells", {}).items():
            if sheet in skip_sheets:
                continue
            for cell in cells:
                cls = classify_style(cell.get("style"))
                if cls is None:
                    continue
                if is_constant_numeric(cell) and cls == "formula":
                    findings.append(Finding(
                        agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                        location=f"Cell Style '{cell['style']}'",
                        severity="warning", category="Colour Coding",
                        description=(f"Constant value carries calculation-class "
                                     f"Cell Style '{cell['style']}' — a hard-coded "
                                     f"number is masquerading as a formula. "
                                     f"— Recommend: restyle as an input or replace "
                                     f"with the intended formula"),
                    ))
                elif "f" in cell and cls == "input":
                    findings.append(Finding(
                        agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                        location=f"Cell Style '{cell['style']}'",
                        severity="warning", category="Colour Coding",
                        description=(f"Formula carries input-class Cell Style "
                                     f"'{cell['style']}' — a calculation is "
                                     f"masquerading as a hard-coded input. "
                                     f"— Recommend: restyle as a calculation or "
                                     f"confirm the cell should be an input"),
                    ))
        return findings

    # Statistical mode: enforce only attributes where BOTH classes have a
    # >=75 %-confident dominant value and the two values differ.
    stats = conv["stats"]
    for attr, getter in (("font", lambda c: (c.get("font") or {}).get("color")),
                         ("fill", lambda c: c.get("fill"))):
        si, sf = stats["input"], stats["formula"]
        if (si[f"{attr}_conf"] < CONFIDENCE_THRESHOLD
                or sf[f"{attr}_conf"] < CONFIDENCE_THRESHOLD
                or si[attr] == sf[attr]):
            continue
        for sheet, cells in extract.get("cells", {}).items():
            if sheet in skip_sheets:
                continue
            for cell in cells:
                value = getter(cell)
                if is_constant_numeric(cell) and value == sf[attr]:
                    findings.append(Finding(
                        agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                        location="Statistically inferred convention",
                        severity="warning", category="Colour Coding",
                        description=(f"Constant value formatted like a formula "
                                     f"({attr} `{value}` matches the dominant "
                                     f"formula convention, not the input "
                                     f"convention `{si[attr]}`). "
                                     f"— Recommend: apply input formatting or "
                                     f"replace with the intended formula"),
                    ))
                elif "f" in cell and value == si[attr]:
                    findings.append(Finding(
                        agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                        location="Statistically inferred convention",
                        severity="warning", category="Colour Coding",
                        description=(f"Formula formatted like an input "
                                     f"({attr} `{value}` matches the dominant "
                                     f"input convention, not the formula "
                                     f"convention `{sf[attr]}`). "
                                     f"— Recommend: apply calculation formatting"),
                    ))
    return findings


# ---------------------------------------------------------------------------
# Deviation candidates — Number Format vs row context
# ---------------------------------------------------------------------------

def number_format_findings(extract: dict, conv: dict) -> list[Finding]:
    findings: list[Finding] = []
    skip_sheets = set(conv["guide_sheets"])
    addr_col = re.compile(r"^([A-Za-z]{1,3})\d+$")

    def col_num(addr: str) -> int:
        m = addr_col.match(addr)
        n = 0
        for ch in m.group(1).upper():
            n = n * 26 + ord(ch) - 64
        return n

    for sheet, cells in extract.get("cells", {}).items():
        if sheet in skip_sheets:
            continue
        texts_by_row: dict[int, list[tuple[int, str]]] = defaultdict(list)
        for t in extract.get("text_inventory", {}).get(sheet, []):
            texts_by_row[int(re.sub(r"[A-Za-z$]", "", t["addr"]))].append(
                (col_num(t["addr"]), t["text"]))

        for cell in cells:
            if "f" not in cell and not is_constant_numeric(cell):
                continue
            fmt = cell.get("fmt")  # absent => General
            # Scan left-side texts nearest-first; the first keyword hit decides
            # the expected format class (unit columns sit closest to the data).
            lefts = sorted(((c, t) for c, t in texts_by_row.get(cell["r"], [])
                            if c < cell["c"]), reverse=True)
            for _, text in lefts:
                low = text.lower()
                if any(k in low for k in PCT_KEYWORDS):
                    if not fmt or "%" not in fmt:
                        findings.append(Finding(
                            agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                            location=f"Row context '{text}'",
                            severity="warning", category="Number Format",
                            description=(f"Row context '{text}' implies a percentage "
                                         f"but the number format is "
                                         f"`{fmt or 'General'}` (no % token). "
                                         f"— Recommend: apply a percentage format"),
                        ))
                    break
                if any(k in low for k in DATE_KEYWORDS):
                    if not fmt:
                        findings.append(Finding(
                            agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                            location=f"Row context '{text}'",
                            severity="warning", category="Number Format",
                            description=(f"Row context '{text}' implies a date/period "
                                         f"value but the number format is General. "
                                         f"— Recommend: apply a date or period format"),
                        ))
                    break
                if any(k in low for k in CURRENCY_KEYWORDS):
                    if not fmt:
                        findings.append(Finding(
                            agent=AGENT, sheet=sheet, cells=[cell["addr"]],
                            location=f"Row context '{text}'",
                            severity="warning", category="Number Format",
                            description=(f"Row context '{text}' implies a currency "
                                         f"value but the number format is General. "
                                         f"— Recommend: apply a currency/accounting "
                                         f"format"),
                        ))
                    break
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
    ap.add_argument("--convention", dest="conv_out", metavar="OUT",
                    help="Style Convention Summary markdown ('-' = stdout)")
    args = ap.parse_args(argv)

    extract = load_extract(args.extract)
    conv = detect_convention(extract)

    if args.conv_out:
        block = convention_markdown(conv)
        if args.conv_out == "-":
            print(block)
        else:
            Path(args.conv_out).write_text(block + "\n", encoding="utf-8")
            print(f"Wrote convention block -> {args.conv_out}")

    findings = colour_coding_findings(extract, conv)
    findings += number_format_findings(extract, conv)
    findings = group_findings(findings)
    write_output(findings, args.json_out, args.md_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

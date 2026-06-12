"""lingo_rules.py — deterministic Lingo checks over an extract.json.

Usage:
    python lingo_rules.py <extract.json> [--json OUT|-] [--md OUT|-] [--terms OUT|-]

Checks (all mechanical — no judgment calls):
  * Term-frequency tally across text_inventory + sheet tab names: 1- and 2-word
    surfaces are normalised (lowercase, spaces/hyphens stripped) into variant
    groups. A group is flagged as "Inconsistent Terminology" (warning) when the
    variation cannot be ordinary sentence/title casing:
      - spacing/hyphenation variants ("Cashflow" vs "Cash Flow" vs "cash-flow"), or
      - interior-cap variants ("Capex" vs "CAPEX" vs "CapEx", "Ebitda" vs "EBITDA").
    The dominant (most frequent) form wins; outliers are reported with both counts.
    Word-initial case-only variants ("Model" vs "model") are NOT flagged here —
    lowercase mid-sentence is correct English, so sentence position decides, and
    that is a judgment call. They still appear in the --terms sidecar for Claude.
  * Sheet tab names -> "Sheet Naming" warning for: leading/trailing whitespace,
    default names (Sheet1, Sheet2, Chart1, copy suffixes like "Sheet1 (2)"),
    and duplicate-looking names (equal after case/whitespace/copy-suffix
    normalisation).

--terms writes the full term-frequency table (all variant groups + unigram
counts) as markdown. Claude reviews it for spelling, grammar, jargon, and the
case-only calls — the script has no dictionary; Claude IS the dictionary.

What this script deliberately does NOT do (Claude-side judgment):
  * spelling and grammar review;
  * missing-unit-label detection on numeric rows (tested, too heuristic to
    automate without false positives — Claude checks unit hints in context);
  * deciding close-count ties (5 vs 4) — the script annotates them for the user.

Output follows ../_excel-shared/references/audit_standards.md.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output, load_extract

AGENT = "lingo"

_WORD_RE = re.compile(r"[A-Za-z](?:[A-Za-z'-]*[A-Za-z])?")
_DEFAULT_TAB = re.compile(r"^(Sheet|Chart)\d+(?: \(\d+\))?$")
_COPY_SUFFIX = re.compile(r"\s*\(\d+\)$")


def _norm(surface: str) -> str:
    return re.sub(r"[^a-z0-9]", "", surface.lower())


def _interior_caps(surface: str) -> bool:
    """True for CapEx / EBITDA style forms — sentence position never produces
    uppercase beyond a word's first letter, so these variants are real."""
    return any(ch.isupper() for word in surface.split() for ch in word[1:])


def build_tally(extract: dict):
    """key -> {surface -> [(sheet, addr), ...]} over 1- and 2-word surfaces."""
    occ: dict[str, dict[str, list]] = defaultdict(lambda: defaultdict(list))

    def add(text: str, sheet: str, addr: str):
        words = _WORD_RE.findall(text or "")
        for n in (1, 2):
            for i in range(len(words) - n + 1):
                surface = " ".join(words[i:i + n])
                key = _norm(surface)
                if len(key) >= 3:
                    occ[key][surface].append((sheet, addr))

    for sheet, recs in extract.get("text_inventory", {}).items():
        for rec in recs:
            add(rec.get("text", ""), sheet, rec.get("addr", ""))
    for s in extract.get("meta", {}).get("sheets", []):
        add(s.get("name", ""), s.get("name", ""), "(sheet tab)")
    return occ


def check_terminology(occ) -> list[Finding]:
    findings = []
    for key in sorted(occ):
        forms = occ[key]
        if len(forms) < 2:
            continue
        spacing_variant = len({f.casefold() for f in forms}) > 1
        cap_variant = any(_interior_caps(f) for f in forms)
        if not (spacing_variant or cap_variant):
            continue  # word-initial case only -> sidecar, Claude decides

        ranked = sorted(forms.items(), key=lambda kv: (-len(kv[1]), kv[0]))
        dominant, dom_locs = ranked[0]
        for outlier, locs in ranked[1:]:
            close = " (counts are close — confirm the standard with the user)" \
                if len(dom_locs) - len(locs) <= 1 else ""
            by_sheet: dict[str, list[str]] = defaultdict(list)
            for sheet, addr in locs:
                by_sheet[sheet].append(addr)
            for sheet, addrs in by_sheet.items():
                findings.append(Finding(
                    agent=AGENT, sheet=sheet, cells=addrs,
                    location=f'Label text containing "{outlier}"',
                    severity="warning", category="Inconsistent Terminology",
                    description=(f'"{outlier}" (×{len(locs)}) conflicts with the '
                                 f'dominant form "{dominant}" (×{len(dom_locs)})'
                                 f'{close} — Recommend: standardise to the dominant form'),
                ))
    return findings


def check_tab_names(extract: dict) -> list[Finding]:
    findings = []
    sheets = [s.get("name", "") for s in extract.get("meta", {}).get("sheets", [])]

    lookalikes: dict[str, list[str]] = defaultdict(list)
    for name in sheets:
        base = dict(agent=AGENT, sheet=name, cells=["(sheet tab)"],
                    location="Sheet tab name", severity="warning",
                    category="Sheet Naming")
        if name != name.strip():
            findings.append(Finding(**base, description=(
                f"Tab name {name!r} has leading/trailing whitespace — invisible in "
                f"the tab strip but breaks formula references typed by hand "
                f"— Recommend: trim it")))
        if _DEFAULT_TAB.match(name.strip()):
            findings.append(Finding(**base, description=(
                f"Default tab name {name!r} says nothing about the sheet's content "
                f"— Recommend: rename to describe its purpose")))
        lookalikes[_COPY_SUFFIX.sub("", re.sub(r"\s+", " ", name.strip().casefold()))].append(name)

    for group in lookalikes.values():
        if len(group) > 1:
            others = ", ".join(repr(n) for n in group)
            for name in group:
                findings.append(Finding(
                    agent=AGENT, sheet=name, cells=["(sheet tab)"],
                    location="Sheet tab name", severity="warning",
                    category="Sheet Naming",
                    description=(f"Tab name {name!r} looks like a duplicate of "
                                 f"({others}) — differs only by case, spacing, or a "
                                 f"copy suffix — Recommend: rename or remove the spare"),
                ))
    return findings


def terms_markdown(occ, source: str) -> str:
    lines = [f"# Term-frequency inventory — {source}", "",
             "## Variant groups (same letters, different case/spacing/hyphenation)", ""]
    groups = [(k, v) for k, v in sorted(occ.items()) if len(v) > 1]
    if groups:
        lines += ["| Normalised key | Surface forms (count) | Script-flagged |",
                  "|---|---|---|"]
        for key, forms in groups:
            flagged = "yes" if (len({f.casefold() for f in forms}) > 1
                                or any(_interior_caps(f) for f in forms)) else "no — review"
            cell = ", ".join(f"`{f}` ×{len(locs)}"
                             for f, locs in sorted(forms.items(), key=lambda kv: -len(kv[1])))
            lines.append(f"| {key} | {cell} | {flagged} |")
    else:
        lines.append("No variant groups found.")

    lines += ["", "## Unigram frequency", "", "| Term | Count | Example location |", "|---|---|---|"]
    unigrams = []
    for key, forms in occ.items():
        for surface, locs in forms.items():
            if " " not in surface:
                unigrams.append((surface, locs))
    for surface, locs in sorted(unigrams, key=lambda kv: (-len(kv[1]), kv[0].casefold())):
        sheet, addr = locs[0]
        lines.append(f"| {surface} | {len(locs)} | {sheet}!{addr} |")
    return "\n".join(lines) + "\n"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("extract", help="Path to extract.json from extract_workbook.py")
    ap.add_argument("--json", dest="json_out", help="Findings JSON path ('-' = stdout)")
    ap.add_argument("--md", dest="md_out", help="Findings markdown path ('-' = stdout)")
    ap.add_argument("--terms", dest="terms_out",
                    help="Term-frequency sidecar markdown path ('-' = stdout)")
    args = ap.parse_args(argv)

    extract = load_extract(args.extract)
    occ = build_tally(extract)
    findings = group_findings(check_terminology(occ) + check_tab_names(extract))
    write_output(findings, args.json_out, args.md_out)

    if args.terms_out:
        text = terms_markdown(occ, extract.get("meta", {}).get("file", args.extract))
        if args.terms_out == "-":
            print(text)
        else:
            with open(args.terms_out, "w", encoding="utf-8") as fh:
                fh.write(text)
            print(f"Wrote term-frequency table -> {args.terms_out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

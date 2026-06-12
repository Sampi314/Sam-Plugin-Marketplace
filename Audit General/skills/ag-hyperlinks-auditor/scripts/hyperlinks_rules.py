"""hyperlinks_rules.py — deterministic Hyperlinks checks over an extract.json.

Usage:
    python hyperlinks_rules.py <extract.json> [--json OUT|-] [--md OUT|-]

Checks (all mechanical — no judgment calls):
  * hyperlinks[] with broken=true            -> "Broken Link" critical
    (internal target sheet/name no longer resolves).
  * placeholder / suspicious external targets -> warning:
      - localhost URLs, example.com, targets containing TODO -> "Placeholder URL"
      - mailto: with no @                                    -> "Malformed URL"
      - file:// with a drive letter, raw C:\\ / UNC paths     -> "Non-Portable Path"
  * orphaned sheets -> "Orphaned Sheet" info: a visible sheet that is the target
    of zero internal links AND contains zero links out, when the workbook has
    3+ sheets and at least one internal link exists. (If the workbook has no
    internal links at all, navigation simply isn't link-based — flagging every
    sheet would be noise, so the check stands down.)

A workbook with zero hyperlinks is a clean pass: the script prints the standard
"No issues detected" output.

What this script deliberately does NOT do (Claude-side judgment):
  * display-text-vs-target review (misleading links, stale TOC wording);
  * navigation-intent checks (missing return links, TOC completeness,
    circular navigation) — these need an understanding of the model's
    intended navigation pattern;
  * liveness checks on external URLs (no network access assumed).

Output follows ../_excel-shared/references/audit_standards.md.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

from audit_lib import Finding, group_findings, write_output, load_extract

AGENT = "hyperlinks"

_DRIVE_FILE_URL = re.compile(r"^file:/{0,3}[A-Za-z]:", re.IGNORECASE)
_DRIVE_PATH = re.compile(r"^[A-Za-z]:[\\/]")


def _sheet_of_target(target: str, named_ranges: list[dict]) -> str | None:
    """Resolve an internal hyperlink target to its sheet name.
    Handles 'Sheet'!A1 / Sheet!A1 / #Sheet!A1 and defined-name targets
    (resolved through named_ranges[].refers_to)."""
    t = (target or "").lstrip("#").strip()
    if "!" in t:
        return t.split("!", 1)[0].strip("'")
    for nr in named_ranges:
        if nr.get("name") == t:
            refers = nr.get("refers_to") or ""
            if "!" in refers:
                return refers.split("!", 1)[0].strip("'").lstrip("=")
    return None


def _location(link: dict) -> str:
    display = link.get("display")
    via = "HYPERLINK() formula" if link.get("source") == "formula" else "cell hyperlink"
    if display:
        return f'{via}, display text "{display}"'
    return via


def check_links(extract: dict) -> list[Finding]:
    findings = []
    for link in extract.get("hyperlinks", []):
        sheet, addr = link.get("sheet", ""), link.get("addr", "")
        target = link.get("target") or ""
        low = target.lower()
        base = dict(agent=AGENT, sheet=sheet, cells=[addr], location=_location(link))

        if link.get("internal") and link.get("broken"):
            findings.append(Finding(
                **base, severity="critical", category="Broken Link",
                description=(f"Internal link target `{target}` does not resolve "
                             f"(missing sheet, deleted name, or out-of-bounds cell) "
                             f"— Recommend: repoint or remove the link"),
            ))
            continue
        if link.get("internal"):
            continue

        # External-target hygiene (deterministic string checks only).
        if "//localhost" in low or low.startswith("localhost"):
            findings.append(Finding(
                **base, severity="warning", category="Placeholder URL",
                description=(f"Link targets localhost (`{target}`) — a development "
                             f"placeholder that will not resolve for other users "
                             f"— Recommend: replace with the real destination"),
            ))
        elif "example.com" in low or "todo" in low:
            findings.append(Finding(
                **base, severity="warning", category="Placeholder URL",
                description=(f"Link target `{target}` looks like a placeholder "
                             f"(example.com / TODO) — Recommend: replace with the "
                             f"real destination or remove"),
            ))
        elif low.startswith("mailto:") and "@" not in target:
            findings.append(Finding(
                **base, severity="warning", category="Malformed URL",
                description=(f"mailto link `{target}` has no @ — it cannot address "
                             f"anyone — Recommend: complete or remove the address"),
            ))
        elif _DRIVE_FILE_URL.match(target) or _DRIVE_PATH.match(target) or target.startswith("\\\\"):
            findings.append(Finding(
                **base, severity="warning", category="Non-Portable Path",
                description=(f"Link target `{target}` is an absolute local/UNC path "
                             f"— it breaks the moment the file is shared or moved "
                             f"— Recommend: use a relative path or a shared location"),
            ))
    return findings


def check_orphans(extract: dict) -> list[Finding]:
    links = extract.get("hyperlinks", [])
    named_ranges = extract.get("named_ranges", [])
    sheets = extract.get("meta", {}).get("sheets", [])
    visible = [s["name"] for s in sheets if s.get("state", "visible") == "visible"]
    internal = [l for l in links if l.get("internal")]
    if len(visible) < 3 or not internal:
        return []  # not a link-navigated workbook — orphan check stands down

    targeted = {_sheet_of_target(l.get("target", ""), named_ranges) for l in internal}
    has_links_out = {l.get("sheet") for l in links}

    findings = []
    for name in visible:
        if name not in targeted and name not in has_links_out:
            findings.append(Finding(
                agent=AGENT, sheet=name, cells=["(whole sheet)"],
                location="Sheet tab", severity="info", category="Orphaned Sheet",
                description=("Visible sheet is neither the target of any internal "
                             "link nor contains links out — unreachable via the "
                             "model's navigation layer — Recommend: add a TOC entry "
                             "or confirm the sheet is meant to stand alone"),
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
    findings = group_findings(check_links(extract) + check_orphans(extract))
    write_output(findings, args.json_out, args.md_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())

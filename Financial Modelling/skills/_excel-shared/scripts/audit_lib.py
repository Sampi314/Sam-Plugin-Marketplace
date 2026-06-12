"""Shared audit toolkit for the excel-* skill family.

Implements the formats defined in ../references/audit_standards.md:
the Finding record, the Grouping Rule engine, A1->R1C1 conversion, and
markdown/JSON emitters. Rule scripts in each skill's scripts/ folder
import this via a 3-line bootstrap:

    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "_excel-shared" / "scripts"))

    from audit_lib import Finding, group_findings, emit_markdown, emit_json, load_extract

Pure stdlib — no third-party imports, so it works wherever Python does.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field, asdict

# Windows consoles default to cp1252, which cannot print the severity emoji.
# Reconfigure stdout/stderr to UTF-8 once here so every rule script inherits it.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

SEVERITIES = ("critical", "warning", "info")

SEVERITY_DISPLAY = {
    "critical": "\U0001F534 Critical",   # red circle
    "warning": "⚠️ Warning",   # warning sign
    "info": "\U0001F7E1 Info",           # yellow circle
}

# Older skill text used HIGH/MEDIUM/LOW prefixes; map them onto the canonical scale.
LEGACY_SEVERITY_MAP = {
    "high": "critical", "critical": "critical",
    "medium": "warning", "warning": "warning",
    "low": "info", "info": "info",
}

SPECIALIST_COLUMNS = (
    "Sheet", "Cell Reference", "Description of Location",
    "Severity", "Category", "Description of Issue",
)
CONSOLIDATED_COLUMNS = ("ID", "Agent") + SPECIALIST_COLUMNS


@dataclass
class Finding:
    agent: str
    sheet: str
    cells: list            # list[str]: "A1", "A1:B3", may hold several ranges
    location: str
    severity: str           # "critical" | "warning" | "info"
    category: str
    description: str
    r1c1_expected: str | None = None
    r1c1_actual: str | None = None
    id: str | None = None   # assigned at consolidation only

    def __post_init__(self):
        self.severity = normalise_severity(self.severity)

    def cell_ref(self) -> str:
        return ", ".join(self.cells)


def normalise_severity(value: str) -> str:
    v = (value or "").strip().lower().strip(":").replace("\U0001F534", "").replace(
        "⚠️", "").replace("\U0001F7E1", "").strip()
    if v in LEGACY_SEVERITY_MAP:
        return LEGACY_SEVERITY_MAP[v]
    raise ValueError(f"Unknown severity {value!r}; expected one of {SEVERITIES} or legacy HIGH/MEDIUM/LOW")


# ---------------------------------------------------------------------------
# A1 helpers
# ---------------------------------------------------------------------------

def col_letter(n: int) -> str:
    s = ""
    while n:
        n, rem = divmod(n - 1, 26)
        s = chr(65 + rem) + s
    return s


def col_number(letters: str) -> int:
    n = 0
    for ch in letters.upper():
        n = n * 26 + (ord(ch) - 64)
    return n


_A1_RE = re.compile(r"^\$?([A-Za-z]{1,3})\$?(\d+)$")


def parse_a1(ref: str) -> tuple[int, int]:
    """'B7' -> (row=7, col=2). Raises ValueError on non-cell refs."""
    m = _A1_RE.match(ref.strip())
    if not m:
        raise ValueError(f"Not an A1 cell reference: {ref!r}")
    return int(m.group(2)), col_number(m.group(1))


def expand_range(ref: str) -> set[tuple[int, int]]:
    """'A1:B2' or 'A1' (or 'A1:B2, D4') -> set of (row, col) coords."""
    coords: set[tuple[int, int]] = set()
    for part in ref.split(","):
        part = part.strip()
        if not part:
            continue
        if ":" in part:
            a, b = part.split(":", 1)
            r1, c1 = parse_a1(a)
            r2, c2 = parse_a1(b)
            for r in range(min(r1, r2), max(r1, r2) + 1):
                for c in range(min(c1, c2), max(c1, c2) + 1):
                    coords.add((r, c))
        else:
            coords.add(parse_a1(part))
    return coords


# ---------------------------------------------------------------------------
# Grouping Rule engine (audit_standards.md §4)
# ---------------------------------------------------------------------------

def cells_to_ranges(coords) -> str:
    """Collapse a set of (row, col) coords into the canonical grouped string.

    Greedy maximal-rectangle extraction: repeatedly take the top-left-most
    remaining cell, grow the widest run rightwards, then extend that run
    downwards while every column is still present. Produces ranges like
    'I8:L17, D15:Z15, M15'.
    """
    remaining = set(coords)
    parts: list[str] = []
    while remaining:
        r0, c0 = min(remaining)                      # top-most, then left-most
        width = 1
        while (r0, c0 + width) in remaining:
            width += 1
        height = 1
        while all((r0 + height, c) in remaining for c in range(c0, c0 + width)):
            height += 1
        for r in range(r0, r0 + height):
            for c in range(c0, c0 + width):
                remaining.discard((r, c))
        first = f"{col_letter(c0)}{r0}"
        if width == 1 and height == 1:
            parts.append(first)
        else:
            parts.append(f"{first}:{col_letter(c0 + width - 1)}{r0 + height - 1}")
    return ", ".join(parts)


def group_findings(findings: list[Finding]) -> list[Finding]:
    """Merge findings that share (agent, sheet, severity, category, description,
    r1c1 pair) into one finding whose cells are re-grouped per the Grouping Rule.
    Cells that don't parse as A1 (e.g. VBA module names) are kept verbatim."""
    buckets: dict[tuple, list[Finding]] = {}
    order: list[tuple] = []
    for f in findings:
        key = (f.agent, f.sheet, f.severity, f.category, f.description,
               f.r1c1_expected, f.r1c1_actual, f.location)
        if key not in buckets:
            buckets[key] = []
            order.append(key)
        buckets[key].append(f)

    merged: list[Finding] = []
    for key in order:
        group = buckets[key]
        coords: set[tuple[int, int]] = set()
        literal: list[str] = []
        for f in group:
            for ref in f.cells:
                try:
                    coords |= expand_range(ref)
                except ValueError:
                    if ref not in literal:
                        literal.append(ref)
        cells: list[str] = []
        if coords:
            cells.extend(cells_to_ranges(coords).split(", "))
        cells.extend(literal)
        proto = group[0]
        merged.append(Finding(
            agent=proto.agent, sheet=proto.sheet, cells=cells,
            location=proto.location, severity=proto.severity,
            category=proto.category, description=proto.description,
            r1c1_expected=proto.r1c1_expected, r1c1_actual=proto.r1c1_actual,
        ))
    return merged


# ---------------------------------------------------------------------------
# A1 -> R1C1 conversion (pure Python, no Excel needed)
# ---------------------------------------------------------------------------

# Cell refs inside formulas, with optional $ anchors. Negative look-around stops
# matches inside function names (LOG10) and defined names (Rate1).
_REF_RE = re.compile(r"(?<![A-Za-z0-9_.$])(\$?)([A-Za-z]{1,3})(\$?)(\d+)(?![A-Za-z0-9_(])")
_STRING_RE = re.compile(r'"[^"]*"')


def a1_to_r1c1(formula: str, row: int, col: int) -> str:
    """Convert an A1-style formula to its R1C1 signature relative to (row, col).

    Quoted string literals are protected from conversion. Sheet-qualified refs
    ('Sheet'!A1) keep their prefix; only the cell part converts. Ranges convert
    endpoint by endpoint. Used to compute pattern signatures: cells whose
    formulas share one R1C1 signature are CRaFT-consistent.
    """
    if not formula or not formula.startswith("="):
        return formula

    # Shield string literals so "A1" inside text never converts.
    shields: list[str] = []

    def _shield(m):
        shields.append(m.group(0))
        return f"\x00{len(shields) - 1}\x00"

    work = _STRING_RE.sub(_shield, formula)

    def _convert(m):
        col_abs, letters, row_abs, digits = m.groups()
        ref_col, ref_row = col_number(letters), int(digits)
        # Excel ignores case but a ref like 'xfd1048577' is out of range -> leave alone
        if ref_col > 16384 or ref_row > 1048576:
            return m.group(0)
        r = f"R{ref_row}" if row_abs else ("R" if ref_row == row else f"R[{ref_row - row}]")
        c = f"C{ref_col}" if col_abs else ("C" if ref_col == col else f"C[{ref_col - col}]")
        return r + c

    work = _REF_RE.sub(_convert, work)
    for i, s in enumerate(shields):
        work = work.replace(f"\x00{i}\x00", s)
    return work


# ---------------------------------------------------------------------------
# Emitters / loaders (audit_standards.md §1, §2, §5)
# ---------------------------------------------------------------------------

def _md_escape(text: str) -> str:
    return str(text).replace("|", "\\|").replace("\n", " ").strip()


def emit_markdown(findings: list[Finding], consolidated: bool = False) -> str:
    if not findings:
        return "✅ No issues detected."
    cols = CONSOLIDATED_COLUMNS if consolidated else SPECIALIST_COLUMNS
    lines = ["| " + " | ".join(cols) + " |",
             "|" + "---|" * len(cols)]
    for f in findings:
        desc = f.description
        if f.r1c1_expected or f.r1c1_actual:
            desc = (f"{desc} Expected R1C1: `{f.r1c1_expected or '(n/a)'}`. "
                    f"Actual: `{f.r1c1_actual or '(n/a)'}`")
        row = [f.sheet, f.cell_ref(), f.location,
               SEVERITY_DISPLAY[f.severity], f.category, desc]
        if consolidated:
            row = [f.id or "", f.agent] + row
        lines.append("| " + " | ".join(_md_escape(v) for v in row) + " |")
    return "\n".join(lines)


def emit_json(findings: list[Finding], path: str | None = None) -> str:
    payload = {"findings": [
        {k: v for k, v in asdict(f).items() if not (k == "id" and v is None)}
        for f in findings
    ]}
    text = json.dumps(payload, indent=2, ensure_ascii=False)
    if path:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)
    return text


def load_findings(path: str) -> list[Finding]:
    with open(path, encoding="utf-8") as fh:
        payload = json.load(fh)
    out = []
    for rec in payload.get("findings", []):
        rec = dict(rec)
        rec.pop("id", None)
        out.append(Finding(**rec))
    return out


def load_extract(path: str) -> dict:
    """Load an extract.json produced by extract_workbook.py."""
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def write_output(findings: list[Finding], json_path: str | None,
                 md_path: str | None, consolidated: bool = False) -> None:
    """Standard CLI tail shared by rule scripts: --json / --md, '-' = stdout."""
    md = emit_markdown(findings, consolidated=consolidated)
    if json_path:
        if json_path == "-":
            print(emit_json(findings))
        else:
            emit_json(findings, json_path)
            print(f"Wrote {len(findings)} findings -> {json_path}")
    if md_path:
        if md_path == "-":
            print(md)
        else:
            with open(md_path, "w", encoding="utf-8") as fh:
                fh.write(md + "\n")
            print(f"Wrote markdown -> {md_path}")
    if not json_path and not md_path:
        print(md)

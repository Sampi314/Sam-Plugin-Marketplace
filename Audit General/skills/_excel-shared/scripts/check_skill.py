"""check_skill.py — light verification for a Claude Code skill directory.

Usage:
    python check_skill.py <skill-dir> [<skill-dir> ...]
    python check_skill.py --all <skills-root>     # every */SKILL.md under root

Checks (FAIL = exit 1; WARN = printed, exit 0):
  1. FAIL  SKILL.md exists with YAML frontmatter containing name + description
  2. FAIL  frontmatter `name` matches the directory name exactly
  3. FAIL  description (parsed) > 1024 chars;  WARN > 900
  4. WARN  description not in folded (`>`) style (house convention)
  5. FAIL  body > 500 lines;  WARN > 150 (thin-router rule: body loads into
           context on every trigger — heavy content belongs in references/)
  6. FAIL  a relative path referenced in SKILL.md does not exist on disk
  7. FAIL  a bundled scripts/*.py fails py_compile

No third-party dependencies (frontmatter parsed with a YAML subset reader).
"""

from __future__ import annotations

import argparse
import py_compile
import re
import sys
from pathlib import Path

for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

# Paths we verify: bundled resources and cross-skill references.
PATH_RE = re.compile(
    r"`?((?:\.\./)*(?:_excel-shared|_fm-shared|references|scripts|assets|evals|"
    r"fm-[a-z0-9-]+|excel-[a-z0-9-]+|ag-[a-z0-9-]+)/[A-Za-z0-9_\-./]+)`?"
)
SKIP_CHARS = set("*<>{}[]$%")


def parse_frontmatter(text: str):
    """Minimal YAML subset: returns (dict, body_lines, raw_block, desc_style)."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, lines, "", None
    fm: dict[str, str] = {}
    desc_style = None
    i, key = 1, None
    while i < len(lines):
        line = lines[i]
        if line.strip() == "---":
            return fm, lines[i + 1:], "\n".join(lines[: i + 1]), desc_style
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if m and not line.startswith((" ", "\t")):
            key, val = m.group(1), m.group(2).strip()
            if val in (">", ">-", "|", "|-"):
                fm[key] = ""
                if key == "description":
                    desc_style = "folded"
            else:
                fm[key] = val.strip("\"'")
                if key == "description":
                    desc_style = "inline"
        elif key and line.startswith((" ", "\t")):
            fm[key] = (fm.get(key, "") + " " + line.strip()).strip()
        i += 1
    return None, lines, "", None  # never closed


def check_skill(skill_dir: Path) -> tuple[list[str], list[str]]:
    fails: list[str] = []
    warns: list[str] = []
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return [f"no SKILL.md in {skill_dir}"], []

    text = skill_md.read_text(encoding="utf-8-sig")
    fm, body, raw_block, desc_style = parse_frontmatter(text)
    if fm is None:
        return ["frontmatter missing or unclosed (--- ... ---)"], []

    name = fm.get("name", "")
    desc = fm.get("description", "")
    if not name:
        fails.append("frontmatter has no `name`")
    elif name != skill_dir.name:
        fails.append(f"name `{name}` != directory `{skill_dir.name}`")
    if not desc:
        fails.append("frontmatter has no `description`")
    else:
        if len(desc) > 1024:
            fails.append(f"description {len(desc)} chars > 1024 limit")
        elif len(desc) > 900:
            warns.append(f"description {len(desc)} chars (target <=900)")
        if desc_style != "folded":
            warns.append("description not in folded `>` style (house convention)")

    n_body = len(body)
    if n_body > 500:
        fails.append(f"body {n_body} lines > 500 hard limit")
    elif n_body > 150:
        warns.append(f"body {n_body} lines (thin-router target <=150 — move detail to references/)")

    # Referenced paths
    seen: set[str] = set()
    for m in PATH_RE.finditer(text):
        rel = m.group(1).rstrip(".,)")
        if rel in seen or SKIP_CHARS & set(rel):
            continue
        seen.add(rel)
        # Cross-skill refs may be written root-relative (fm-3-design/references/x.md)
        # or skill-relative (../fm-3-design/references/x.md) — accept either.
        if not (skill_dir / rel).exists() and not (skill_dir.parent / rel).exists():
            fails.append(f"referenced path missing: {rel}")

    # Bundled scripts compile
    for py in sorted((skill_dir / "scripts").glob("*.py")) if (skill_dir / "scripts").is_dir() else []:
        try:
            py_compile.compile(str(py), doraise=True)
        except py_compile.PyCompileError as exc:
            fails.append(f"{py.name} does not compile: {exc.msg}")

    return fails, warns


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("dirs", nargs="*", help="Skill directories to check")
    ap.add_argument("--all", metavar="ROOT", help="Check every */SKILL.md under ROOT")
    args = ap.parse_args(argv)

    targets: list[Path] = [Path(d) for d in args.dirs]
    if args.all:
        targets.extend(sorted(p.parent for p in Path(args.all).glob("*/SKILL.md")))
    if not targets:
        ap.error("Give skill dirs or --all <root>")

    any_fail = False
    for skill_dir in targets:
        fails, warns = check_skill(skill_dir)
        status = "FAIL" if fails else ("WARN" if warns else "OK")
        print(f"[{status:4}] {skill_dir.name}")
        for f in fails:
            print(f"   FAIL: {f}")
        for w in warns:
            print(f"   warn: {w}")
        any_fail |= bool(fails)
    return 1 if any_fail else 0


if __name__ == "__main__":
    sys.exit(main())

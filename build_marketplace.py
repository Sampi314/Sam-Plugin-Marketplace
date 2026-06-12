"""Build the sam-plugin-marketplace plugin folders from .claude/skills.

Copies the live (post-overhaul) skills into the two plugins, applies the ag-*
renames for Audit General, rewrites cross-references, and reports every
reference changed. Re-runnable: wipes and rebuilds the two skills/ trees.
"""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

for _s in (sys.stdout, sys.stderr):
    try:
        _s.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

ROOT = Path(__file__).resolve().parent          # sam-plugin-marketplace/
SKILLS = ROOT.parent / ".claude" / "skills"
FM_DEST = ROOT / "Financial Modelling" / "skills"
AG_DEST = ROOT / "Audit General" / "skills"

FM_SKILLS = ["fm-orchestrator", "fm-1-scope", "fm-2-plan", "fm-3-design",
             "fm-4-build", "fm-5-test", "fm-6-implement"]

AG_RENAMES = {  # old excel-* name -> new ag-* name (architect added beyond the requested 15)
    "excel-audit-manager": "ag-audit-manager",
    "excel-detailed-audit-report": "ag-detailed-audit-report",
    "excel-model-auditor": "ag-model-auditor",
    "excel-ai-auditor": "ag-ai-auditor",
    "excel-logic-auditor": "ag-logic-auditor",
    "excel-sentry-auditor": "ag-sentry-auditor",
    "excel-stylist-auditor": "ag-stylist-auditor",
    "excel-lingo-auditor": "ag-lingo-auditor",
    "excel-efficiency-auditor": "ag-efficiency-auditor",
    "excel-hyperlinks-auditor": "ag-hyperlinks-auditor",
    "excel-vba-auditor": "ag-vba-auditor",
    "excel-pq-auditor": "ag-pq-auditor",
    "excel-cartographer": "ag-cartographer",
    "excel-navigator": "ag-navigator",
    "excel-generalizer": "ag-generalizer",
    "excel-architect-auditor": "ag-architect-auditor",
}
# Longest names first so e.g. excel-audit-manager never part-matches another name.
ORDERED_OLD = sorted(AG_RENAMES, key=len, reverse=True)

IGNORE = shutil.ignore_patterns("__pycache__", "*.pyc")
changes: list[str] = []


def copy_tree(src: Path, dest: Path) -> None:
    shutil.copytree(src, dest, ignore=IGNORE)


def rewrite(path: Path, replacements: list[tuple[str, str]], regex: bool = False) -> int:
    text = path.read_text(encoding="utf-8")
    original = text
    for old, new in replacements:
        if regex:
            text, n = re.subn(old, new, text)
        else:
            n = text.count(old)
            text = text.replace(old, new)
        if n:
            changes.append(f"{path.relative_to(ROOT)}: '{old}' -> '{new}' x{n}")
    if text != original:
        path.write_text(text, encoding="utf-8")
        return 1
    return 0


def main() -> int:
    for dest in (FM_DEST, AG_DEST):
        if dest.exists():
            shutil.rmtree(dest)
        dest.mkdir(parents=True)

    # --- Financial Modelling plugin ---
    for name in FM_SKILLS:
        copy_tree(SKILLS / name, FM_DEST / name)
    copy_tree(SKILLS / "_fm-shared", FM_DEST / "_fm-shared")
    # fm-5-test points at ../../_excel-shared for the audit standards — ship a
    # copy so the plugin is self-contained.
    copy_tree(SKILLS / "_excel-shared", FM_DEST / "_excel-shared")

    # --- Audit General plugin ---
    for old, new in AG_RENAMES.items():
        copy_tree(SKILLS / old, AG_DEST / new)
    copy_tree(SKILLS / "_excel-shared", AG_DEST / "_excel-shared")

    # --- Reference rewrites: Audit General (.md files only) ---
    ag_pairs = [(old, AG_RENAMES[old]) for old in ORDERED_OLD]
    for md in AG_DEST.rglob("*.md"):
        rewrite(md, ag_pairs)

    # --- Reference rewrites: Financial Modelling ---
    # 1. Cross-plugin file paths cannot work -> collapse path refs to skill names.
    path_pairs = [(rf"`?\.\./\.\./({old})/SKILL\.md`?", f"`{AG_RENAMES[old]}`")
                  for old in ORDERED_OLD]
    # 2. Then plain name mentions -> ag-* names.
    for md in FM_DEST.rglob("*.md"):
        if "_excel-shared" in md.parts:
            continue  # shared library copy stays byte-identical to AG's copy
        rewrite(md, path_pairs, regex=True)
        rewrite(md, ag_pairs)

    # 3. Install note in the FM copy of the pointer guide.
    pointer = FM_DEST / "fm-5-test" / "references" / "audit_skills_pointer.md"
    text = pointer.read_text(encoding="utf-8")
    note = ("\n> **Plugin note:** the audit skills above ship in the separate "
            "**audit-general** plugin — install it alongside this one "
            "(`/plugin install audit-general@sam`) so fm-5-test can run "
            "the audit suite. The shared standards file is bundled with both "
            "plugins at `skills/_excel-shared/references/audit_standards.md`.\n")
    if "Plugin note" not in text:
        head, rest = text.split("\n\n", 1)
        pointer.write_text(head + "\n" + note + "\n" + rest, encoding="utf-8")
        changes.append(f"{pointer.relative_to(ROOT)}: added cross-plugin install note")

    # --- Report ---
    print(f"FM plugin: {sum(1 for _ in FM_DEST.iterdir())} entries; "
          f"AG plugin: {sum(1 for _ in AG_DEST.iterdir())} entries")
    print(f"\nReferences changed ({len(changes)}):")
    for c in changes:
        print(f"  {c}")

    # --- Residual check: any excel-* skill-name left in AG plugin? ---
    residual = []
    pattern = re.compile("|".join(re.escape(o) for o in ORDERED_OLD))
    for f in AG_DEST.rglob("*"):
        if f.suffix in (".md",) and f.is_file():
            for i, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
                if pattern.search(line):
                    residual.append(f"{f.relative_to(ROOT)}:{i}: {line.strip()[:100]}")
    print(f"\nResidual excel-* skill names in Audit General .md files: {len(residual)}")
    for r in residual[:20]:
        print(f"  {r}")
    return 0 if not residual else 1


if __name__ == "__main__":
    sys.exit(main())

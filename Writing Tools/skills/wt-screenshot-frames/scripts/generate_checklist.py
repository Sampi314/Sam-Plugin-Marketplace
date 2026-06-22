"""Generate a markdown checklist from the placeholders manifest.

Reads `placeholders-manifest.json` (produced by parse_placeholders.py)
and writes `screenshots-checklist.md` — a per-part tickable list of every
SCREENSHOT placeholder, grouped by source markdown file.

Optionally writes a second file `all-image-tasks.md` listing every type,
including GEMINI / MATPLOTLIB / MERMAID / PHOTO that this skill does not
capture itself.

Usage:
    python generate_checklist.py --root "From Claude v3/"
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--manifest", default=None, type=Path)
    parser.add_argument("--screenshots-output", default=None, type=Path)
    parser.add_argument("--all-output", default=None, type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    manifest_path = (args.manifest or (root / "placeholders-manifest.json")).resolve()
    if not manifest_path.is_file():
        sys.stderr.write(f"Manifest not found: {manifest_path}\n")
        sys.stderr.write("Run parse_placeholders.py first.\n")
        return 1

    screenshots_out = (args.screenshots_output or (root / "screenshots-checklist.md")).resolve()
    all_out = (args.all_output or (root / "all-image-tasks.md")).resolve()

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    grouped: Dict[str, List[dict]] = defaultdict(list)
    grouped_all: Dict[str, List[dict]] = defaultdict(list)
    for entry in manifest:
        grouped_all[entry["source_md"]].append(entry)
        if entry["type"] == "SCREENSHOT":
            grouped[entry["source_md"]].append(entry)

    # --- screenshots checklist ---
    lines: List[str] = []
    lines.append("# Screenshots Checklist")
    lines.append("")
    lines.append(f"Total SCREENSHOT placeholders: **{sum(len(v) for v in grouped.values())}**")
    already = sum(1 for e in manifest if e["type"] == "SCREENSHOT" and e["already_captured"])
    lines.append(f"Already captured (file exists at target path): **{already}**")
    lines.append("")
    lines.append("Run `screenshot_runner.py` to capture the remaining items interactively.")
    lines.append("")

    for md_path in sorted(grouped.keys()):
        items = sorted(grouped[md_path], key=lambda x: x["image_number"])
        lines.append(f"## `{md_path}`")
        lines.append("")
        for it in items:
            box = "[x]" if it["already_captured"] else "[ ]"
            lines.append(f"- {box} **Image {it['image_number']}** — `{it['save_as']}`")
            if it["subject"]:
                lines.append(f"  - Subject: {it['subject']}")
            if it["url"]:
                lines.append(f"  - URL: <{it['url']}>")
            if it["instructions"]:
                short = it["instructions"]
                if len(short) > 220:
                    short = short[:220].rstrip() + "..."
                lines.append(f"  - Notes: {short}")
        lines.append("")

    screenshots_out.write_text("\n".join(lines), encoding="utf-8")

    # --- all image tasks ---
    lines2: List[str] = []
    lines2.append("# All Image Tasks")
    lines2.append("")
    lines2.append(f"Total placeholders: **{len(manifest)}**")
    lines2.append("")
    by_type = defaultdict(int)
    for e in manifest:
        by_type[e["type"]] += 1
    for k in sorted(by_type.keys()):
        lines2.append(f"- {k}: {by_type[k]}")
    lines2.append("")
    lines2.append("Only SCREENSHOT items are captured by screenshot_runner.py.")
    lines2.append("Other types are handled by separate tooling.")
    lines2.append("")

    for md_path in sorted(grouped_all.keys()):
        items = sorted(grouped_all[md_path], key=lambda x: x["image_number"])
        lines2.append(f"## `{md_path}`")
        lines2.append("")
        for it in items:
            box = "[x]" if it["already_captured"] else "[ ]"
            lines2.append(f"- {box} **Image {it['image_number']} — {it['type']}** — `{it['save_as']}`")
            if it["subject"]:
                lines2.append(f"  - Subject: {it['subject']}")
            if it["url"]:
                lines2.append(f"  - URL: <{it['url']}>")
        lines2.append("")

    all_out.write_text("\n".join(lines2), encoding="utf-8")

    print(f"Wrote {screenshots_out}")
    print(f"Wrote {all_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

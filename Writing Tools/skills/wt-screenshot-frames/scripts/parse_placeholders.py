"""Parse placeholder blocks from a folder of blog markdown files.

Scans every `.md` file under the root, finds every placeholder block
(see references/placeholder-grammar.md), and writes a JSON manifest:
    placeholders-manifest.json

The manifest is the input to generate_checklist.py and
screenshot_runner.py.

Usage:
    python parse_placeholders.py --root "From Claude v3/"
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import List, Dict, Any


# Each placeholder is a markdown blockquote that begins with the line:
#   > **[IMAGE N - TYPE]**
# and continues until the first non-quoted line.
HEADER_RE = re.compile(
    r"^>\s*\*\*\[IMAGE\s+(\d+)\s*[-—]\s*([A-Z][A-Z\s/_or]*?)\s*\]\*\*",
    re.IGNORECASE,
)

KNOWN_TYPES = ("SCREENSHOT", "GEMINI", "MATPLOTLIB", "MERMAID", "PHOTO")


def normalize_type(raw: str) -> str:
    """Map a raw header type to a canonical type.

    Handles compound forms like 'PHOTO or SCREENSHOT' (returns 'SCREENSHOT'
    since that is the more automatable option) or 'SCREENSHOT/PHOTO' (same).
    Returns 'UNKNOWN' if no known type is present.
    """
    upper = raw.upper()
    # Prefer SCREENSHOT when present (most automatable).
    if "SCREENSHOT" in upper:
        return "SCREENSHOT"
    for t in KNOWN_TYPES:
        if t in upper:
            return t
    return "UNKNOWN"
URL_RE = re.compile(r"https?://[^\s`)>]+")
SUBJECT_RE = re.compile(r"^\s*\*\*Subject:\*\*\s*(.+?)\s*$", re.IGNORECASE)
INSTR_RE = re.compile(r"^\s*\*\*Capture\s*/\s*Generate:\*\*\s*(.+?)\s*$", re.IGNORECASE)
SAVE_RE = re.compile(r"^\s*\*\*Save\s+as:\*\*\s*`([^`]+)`\s*$", re.IGNORECASE)


def strip_quote(line: str) -> str:
    """Strip the leading `> ` from a blockquote line."""
    if line.startswith("> "):
        return line[2:]
    if line.startswith(">"):
        return line[1:]
    return line


def extract_blocks(text: str) -> List[Dict[str, Any]]:
    """Yield each placeholder block found in the markdown text."""
    lines = text.splitlines()
    blocks: List[Dict[str, Any]] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        m = HEADER_RE.match(line)
        if not m:
            i += 1
            continue

        image_number = int(m.group(1))
        image_type = normalize_type(m.group(2))

        body_lines = []
        j = i + 1
        while j < len(lines):
            nxt = lines[j]
            if nxt.startswith(">"):
                body_lines.append(strip_quote(nxt))
                j += 1
            elif nxt.strip() == "":
                # Allow blank lines inside the block if the next line is still quoted.
                if j + 1 < len(lines) and lines[j + 1].startswith(">"):
                    body_lines.append("")
                    j += 1
                    continue
                break
            else:
                break

        subject = ""
        instructions = ""
        save_as = ""
        for body in body_lines:
            sm = SUBJECT_RE.match(body)
            if sm:
                subject = sm.group(1)
                continue
            im = INSTR_RE.match(body)
            if im:
                instructions = im.group(1)
                continue
            sa = SAVE_RE.match(body)
            if sa:
                save_as = sa.group(1)
                continue

        url = ""
        if instructions:
            urls = URL_RE.findall(instructions)
            if urls:
                url = urls[0].rstrip(".,;:`)")

        blocks.append({
            "image_number": image_number,
            "type": image_type,
            "subject": subject,
            "instructions": instructions,
            "save_as": save_as,
            "url": url,
        })

        i = j

    return blocks


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", required=True, type=Path,
        help="Root folder containing the per-part subfolders.",
    )
    parser.add_argument(
        "--output", default=None, type=Path,
        help="Where to write the manifest. Defaults to <root>/placeholders-manifest.json.",
    )
    args = parser.parse_args()

    root = args.root.resolve()
    if not root.is_dir():
        sys.stderr.write(f"Root folder not found: {root}\n")
        return 1

    output = args.output or (root / "placeholders-manifest.json")
    output = output.resolve()

    manifest: List[Dict[str, Any]] = []

    md_files = sorted(root.rglob("*.md"))
    if not md_files:
        sys.stderr.write(f"No .md files found under {root}\n")
        return 1

    for md in md_files:
        try:
            text = md.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = md.read_text(encoding="utf-8-sig")

        blocks = extract_blocks(text)
        if not blocks:
            continue

        rel_md = md.relative_to(root)
        for block in blocks:
            save_as = block["save_as"] or f"image-{block['image_number']}.png"
            target_path = md.parent / save_as

            manifest.append({
                "source_md": str(rel_md).replace("\\", "/"),
                "source_md_abs": str(md),
                "image_number": block["image_number"],
                "type": block["type"],
                "subject": block["subject"],
                "instructions": block["instructions"],
                "save_as": save_as,
                "url": block["url"],
                "target_path": str(target_path),
                "target_relpath": str(target_path.relative_to(root)).replace("\\", "/"),
                "already_captured": target_path.exists(),
            })

    output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"Parsed {len(manifest)} placeholders across {len(md_files)} markdown files.")
    print(f"Manifest written to: {output}")

    by_type: Dict[str, int] = {}
    for entry in manifest:
        by_type[entry["type"]] = by_type.get(entry["type"], 0) + 1
    print("By type:")
    for k, v in sorted(by_type.items()):
        print(f"  {k}: {v}")

    captured = sum(1 for e in manifest if e["already_captured"])
    print(f"Already captured: {captured} / {len(manifest)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

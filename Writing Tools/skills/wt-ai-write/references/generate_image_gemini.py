"""
Generate a brand-consistent image for a daily AI blog post using Google's
Gemini 2.5 Flash Image model via the v1 stable endpoint.

Critical detail: use `/v1/` not `/v1beta/`. The v1beta endpoint has free-tier
`limit: 0` for image generation; v1 stable does not. This script uses urllib
directly (no SDK) so the endpoint and request shape are explicit.

Visual consistency across the daily series is enforced by reading the locked
style anchor from style-anchor.md (sibling file) and appending it to every
per-post prompt. There is no anchor PNG — the anchor is text.

Usage:
    python generate_image_gemini.py \
        --concept "macro shot of a folded paper structure suggesting recursion" \
        --output daily-blog-image.png

If GEMINI_API_KEY is not in the environment, the script prompts for it
interactively via getpass (input hidden, not stored).
"""

from __future__ import annotations

import argparse
import base64
import getpass
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path


REF_DIR = Path(__file__).resolve().parent
DEFAULT_ANCHOR = REF_DIR / "style-anchor.md"
DEFAULT_MODEL = "gemini-2.5-flash-image"
API_BASE = "https://generativelanguage.googleapis.com/v1/models"


def load_anchor(path: Path) -> str:
    if not path.exists():
        sys.stderr.write(
            f"\nStyle anchor not found at:\n  {path}\n\n"
            "The anchor is a markdown file with a blockquote — see the "
            "default at references/style-anchor.md.\n"
        )
        sys.exit(1)
    text = path.read_text(encoding="utf-8")
    m = re.search(
        r"^## Anchor.*?\n(.*?)(?=^---|^## |\Z)",
        text, re.MULTILINE | re.DOTALL,
    )
    if not m:
        sys.stderr.write(
            f"Could not find the anchor blockquote in {path}.\n"
            "Expected a '## Anchor ...' heading followed by a markdown "
            "blockquote (lines starting with '> ').\n"
        )
        sys.exit(1)
    lines = []
    for line in m.group(1).splitlines():
        if line.startswith("> "):
            lines.append(line[2:])
        elif line == ">":
            lines.append("")
    anchor = "\n".join(lines).strip()
    if not anchor:
        sys.stderr.write(f"Anchor blockquote in {path} appears empty.\n")
        sys.exit(1)
    return anchor


def build_prompt(concept: str, anchor: str) -> str:
    return (
        f"Create a single editorial image for an AI news blog post about: {concept}.\n\n"
        f"{anchor}\n\n"
        "The image must read instantly at small sizes and feel like part of "
        "an ongoing series — every image should look like it belongs to the "
        "same visual family as the reference."
    )


def get_api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY", "").strip()
    if key:
        return key
    sys.stderr.write("GEMINI_API_KEY not found in environment.\n")
    key = getpass.getpass("Paste your Gemini API key (input hidden): ").strip()
    if not key:
        sys.stderr.write("No key provided. Aborting.\n")
        sys.exit(1)
    return key


def generate(concept: str, output: Path, anchor_path: Path, model: str) -> None:
    api_key = get_api_key()
    anchor = load_anchor(anchor_path)
    prompt = build_prompt(concept, anchor)

    url = f"{API_BASE}/{model}:generateContent"
    body = {"contents": [{"parts": [{"text": prompt}]}]}
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": api_key,
        },
        method="POST",
    )

    print(f"Generating with {model} via v1...")
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            data = json.loads(r.read())
    except urllib.error.HTTPError as e:
        msg = e.read().decode("utf-8", errors="replace")[:500]
        sys.stderr.write(f"HTTP {e.code}: {msg}\n")
        sys.exit(2)

    parts = data.get("candidates", [{}])[0].get("content", {}).get("parts", [])
    for part in parts:
        if "inlineData" in part and part["inlineData"].get("data"):
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(base64.b64decode(part["inlineData"]["data"]))
            print(f"Saved: {output} ({output.stat().st_size:,} bytes)")
            return
        if "text" in part:
            print(f"[model text] {part['text'][:200]}")

    sys.stderr.write("No image returned by the model.\n")
    sys.exit(2)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate a brand-consistent image for a daily AI blog post."
    )
    parser.add_argument(
        "--concept", required=True,
        help="One-sentence description of the visual metaphor for this post.",
    )
    parser.add_argument(
        "--output", required=True, type=Path,
        help="Path to save the generated PNG.",
    )
    parser.add_argument(
        "--anchor", default=DEFAULT_ANCHOR, type=Path,
        help=f"Path to the style anchor markdown file (default: {DEFAULT_ANCHOR}).",
    )
    parser.add_argument(
        "--model", default=DEFAULT_MODEL,
        help=f"Gemini image model id (default: {DEFAULT_MODEL}).",
    )
    args = parser.parse_args()

    generate(
        concept=args.concept,
        output=args.output,
        anchor_path=args.anchor,
        model=args.model,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

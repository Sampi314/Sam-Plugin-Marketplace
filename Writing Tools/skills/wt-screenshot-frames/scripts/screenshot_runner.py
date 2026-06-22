"""Interactive Playwright-based screenshot runner.

Reads the placeholders manifest and walks through every SCREENSHOT
placeholder one [1] at a time. For each:
    1. Opens the URL in Microsoft Edge (visible, not headless).
    2. Sets the page zoom to 125 % (matching the screenshots-guide
       convention from AI Blog 060).
    3. Prints what the user should capture, then waits for the user
       to press Enter when the page is positioned correctly.
    4. Captures the current viewport, saves to the target path.

The first time the user runs the script, Edge will open a fresh profile.
Sign in to GitHub once and the session is reused on subsequent runs
(profile stored at <root>/.screenshot-runner/edge-profile/).

Usage:
    python screenshot_runner.py --root "From Claude v3/"

Prerequisites (one-time):
    pip install playwright
    playwright install msedge

If Edge is not installed via Playwright's channel, the script falls back
to Chromium.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright, Browser, Page, BrowserContext
except ImportError:
    sys.stderr.write(
        "Playwright is not installed.\n"
        "Run:\n"
        "  pip install playwright\n"
        "  playwright install msedge\n"
    )
    sys.exit(1)


def pause_for_user(prompt: str) -> str:
    """Print a prompt and wait for the user's response."""
    try:
        return input(prompt).strip().lower()
    except EOFError:
        return "q"


def launch_browser(p, profile_dir: Path) -> BrowserContext:
    """Launch a persistent Edge context. Falls back to Chromium."""
    profile_dir.mkdir(parents=True, exist_ok=True)
    try:
        return p.chromium.launch_persistent_context(
            user_data_dir=str(profile_dir),
            channel="msedge",
            headless=False,
            viewport={"width": 1600, "height": 1000},
            device_scale_factor=1.25,
        )
    except Exception as exc:
        sys.stderr.write(f"Edge channel unavailable: {exc}\nFalling back to Chromium.\n")
        return p.chromium.launch_persistent_context(
            user_data_dir=str(profile_dir),
            headless=False,
            viewport={"width": 1600, "height": 1000},
            device_scale_factor=1.25,
        )


def capture_one(page: Page, entry: dict, target: Path) -> bool:
    print()
    print("=" * 72)
    print(f"  Image {entry['image_number']} in {entry['source_md']}")
    print(f"  Save as: {entry['save_as']}")
    print()
    print(f"  Subject: {entry['subject']}")
    print()
    if entry["instructions"]:
        print(f"  Instructions: {entry['instructions']}")
        print()

    url = entry.get("url", "")
    if url:
        print(f"  Navigating to: {url}")
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=60000)
        except Exception as exc:
            sys.stderr.write(f"  Failed to navigate: {exc}\n")
            print("  Edit the address bar manually if needed.")
    else:
        print("  No URL provided. Bring up the page yourself.")

    print()
    print("  Adjust scroll position, login state and zoom in Edge.")
    print("  Then choose:")
    print("    [Enter]    capture viewport and save")
    print("    f          capture full page (scrolling)")
    print("    s          skip this image (do not save)")
    print("    q          quit the runner")
    print()
    choice = pause_for_user("  > ")

    if choice == "q":
        return False
    if choice == "s":
        print("  Skipped.")
        return True

    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        if choice == "f":
            page.screenshot(path=str(target), full_page=True)
        else:
            page.screenshot(path=str(target), full_page=False)
        size_kb = target.stat().st_size / 1024
        print(f"  Saved: {target}  ({size_kb:,.1f} KB)")
    except Exception as exc:
        sys.stderr.write(f"  Failed to capture: {exc}\n")

    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--manifest", default=None, type=Path)
    parser.add_argument(
        "--only-missing", action="store_true",
        help="Skip placeholders whose target file already exists.",
    )
    parser.add_argument(
        "--from-index", type=int, default=0,
        help="Resume from a specific manifest index (0-based).",
    )
    args = parser.parse_args()

    root = args.root.resolve()
    manifest_path = (args.manifest or (root / "placeholders-manifest.json")).resolve()
    if not manifest_path.is_file():
        sys.stderr.write(f"Manifest not found: {manifest_path}\n")
        sys.stderr.write("Run parse_placeholders.py first.\n")
        return 1

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    screenshot_items = [e for e in manifest if e["type"] == "SCREENSHOT"]
    if args.only_missing:
        screenshot_items = [e for e in screenshot_items if not e["already_captured"]]
    screenshot_items = screenshot_items[args.from_index:]

    if not screenshot_items:
        print("No SCREENSHOT placeholders to capture (everything done or filtered out).")
        return 0

    profile_dir = root / ".screenshot-runner" / "edge-profile"

    print(f"Will walk through {len(screenshot_items)} SCREENSHOT placeholders.")
    print(f"Edge profile: {profile_dir}")
    print()
    pause_for_user("Press Enter to launch Edge ")

    with sync_playwright() as p:
        ctx = launch_browser(p, profile_dir)
        page = ctx.pages[0] if ctx.pages else ctx.new_page()

        for idx, entry in enumerate(screenshot_items):
            target = Path(entry["target_path"])
            keep_going = capture_one(page, entry, target)
            if not keep_going:
                print()
                print(f"Quit at item {idx + 1} of {len(screenshot_items)}.")
                break

        try:
            ctx.close()
        except Exception:
            pass

    print()
    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

"""Generate USER_GUIDE.docx from a populated USER_GUIDE.md.

Usage:
    python generate_user_guide.py <input.md> <output.docx>

Delegates the actual conversion to the shared md_to_docx helper at
.claude/skills/_fm-shared/scripts/md_to_docx.py.
"""

import sys
import subprocess
from pathlib import Path


SHARED_CONVERTER = (
    Path(__file__).resolve().parents[2] / "_fm-shared" / "scripts" / "md_to_docx.py"
)


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python generate_user_guide.py <input.md> <output.docx>",
              file=sys.stderr)
        return 1
    src, dst = sys.argv[1], sys.argv[2]
    if not SHARED_CONVERTER.exists():
        print(f"Shared converter not found at {SHARED_CONVERTER}",
              file=sys.stderr)
        return 2
    return subprocess.call([sys.executable, str(SHARED_CONVERTER), src, dst])


if __name__ == "__main__":
    raise SystemExit(main())

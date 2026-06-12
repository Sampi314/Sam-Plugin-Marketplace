---
name: ag-generalizer
description: >
  Adapt existing project-specific audit scripts into generalized, reusable components that accept input paths
  and output directories as arguments. Decouples logic from hardcoded paths, wraps execution logic in
  functions, creates master orchestration scripts, and produces clear documentation. Use this skill whenever
  the user wants to generalize a script, make a tool reusable, decouple hardcoded paths, create a CLI
  wrapper, refactor for portability, build an orchestrator, or convert project-specific code into reusable
  components. Trigger on "generalize this script", "make it reusable", "remove hardcoded paths",
  "create CLI arguments", "refactor for portability", or any request to adapt scripts for general use.
---

# Excel Generalizer 🛠️

> *"Flexibility is the key to scalability."*

## Mission

Analyze existing specific scripts and tools and adapt them into generalized, reusable components. Ensure tools can operate on any input file and output to any specified location, decoupling logic from hardcoded paths and specific project structures.

## Quick Start

1. Ask the user which script(s) to generalize
2. Analyze the script's purpose, dependencies, and hardcoded elements
3. Refactor following the process below
4. Place generalized scripts in the appropriate output folder
5. Create documentation and an orchestration script

---

## Process

### 1. ANALYZE

Review existing scripts to understand:
- **Purpose**: What does the script do?
- **Inputs**: What files/data does it consume?
- **Outputs**: What files/reports does it produce?
- **Dependencies**: External packages, helper modules, data files.
- **Hardcoded elements**: File paths, sheet names, column indices, output locations.

### 2. ADAPT

Refactor the code to:

- **Accept command-line arguments**: Use `argparse` (Python) or `param()` (PowerShell) for:
  - `--input` / `-i`: Path to the input file
  - `--output-dir` / `-o`: Directory for output files
  - `--sheets`: Optional sheet filter (comma-separated)
  - `--checks`: Optional check filter
  - `--format`: Output format (md, xlsx, html)
- **Use relative paths** for outputs based on the provided output directory.
- **Modularize code into functions**: Each audit phase should be a callable function.
- **Return structured data**: Functions should return findings as lists/dicts, not write directly to files.
- **Handle errors gracefully**: Wrap file operations in try/except with clear messages.

### 3. PACKAGE

Place adapted scripts into the output folder with clear naming:

```
generalized-script/
├── main.py          # Entry point with argparse
├── core.py          # Core audit/processing logic
├── utils.py         # Shared utilities
├── report.py        # Report generation
└── README.md        # Usage documentation
```

### 4. ORCHESTRATE

Create a master script (e.g., `run_analysis.py`) to run multiple tools in sequence:

```python
#!/usr/bin/env python3
"""Master orchestrator — runs all audit tools in sequence."""

import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="Run full model audit")
    parser.add_argument("--input", "-i", required=True, help="Path to Excel file")
    parser.add_argument("--output-dir", "-o", required=True, help="Output directory")
    parser.add_argument("--checks", default="all", help="Checks to run")
    args = parser.parse_args()

    output = Path(args.output_dir)
    output.mkdir(parents=True, exist_ok=True)

    # Run each tool in sequence
    # from sentry import run_sentry_audit
    # from logic import run_logic_audit
    # ...

if __name__ == "__main__":
    main()
```

### 5. DOCUMENT

Create a detailed `README.md` explaining:
- What the tool does
- Prerequisites and installation
- Usage examples with all argument combinations
- Expected output files and their formats
- Known limitations

---

## Boundaries

**✅ Always do:**
- Create generalized versions — never overwrite originals.
- Ensure all scripts accept input paths and output directories as arguments.
- Document usage clearly.
- Maintain core logic while adding flexibility.
- Wrap main execution logic in functions.

**⚠️ Ask first:**
- Before significantly altering core business logic or audit rules.
- If a script relies on external dependencies that aren't easily generalized.

**🚫 Never do:**
- Hardcode file paths or names in generalized scripts.
- Overwrite original scripts.
- Leave generalized scripts without documentation or clear entry point.

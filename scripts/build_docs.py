#!/usr/bin/env python3
"""Build documentation: convert Markdown files to DOCX or PDF via pandoc.

Usage:
    python scripts/build_docs.py docs/04-livrables/architecture-technique.md --format pdf
    python scripts/build_docs.py --all --format docx
    python scripts/build_docs.py --init-template   # Generate reference.docx template
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

# Project root = parent of scripts/
ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = ROOT / "docs"
TEMPLATES_DIR = DOCS_DIR / "_templates"
METADATA_FILE = TEMPLATES_DIR / "metadata.yaml"
REFERENCE_DOCX = TEMPLATES_DIR / "reference.docx"
OUTPUT_DIR = ROOT / "output"

# Livrables directory — files here are the final deliverables
LIVRABLES_DIR = DOCS_DIR / "04-livrables"

# All markdown files that map to final deliverables
LIVRABLE_FILES: list[Path] = [
    LIVRABLES_DIR / "architecture-technique.md",
    LIVRABLES_DIR / "strategie-migration.md",
    LIVRABLES_DIR / "guide-depannage-toip.md",
    LIVRABLES_DIR / "note-recommandation-wms.md",
    LIVRABLES_DIR / "configs" / "vpn-ipsec.md",
    LIVRABLES_DIR / "configs" / "pare-feu.md",
]


def check_pandoc() -> bool:
    """Verify pandoc is installed and accessible."""
    return shutil.which("pandoc") is not None


def init_reference_template() -> None:
    """Generate a default reference.docx from pandoc for custom styling."""
    if not check_pandoc():
        print("ERROR: pandoc not found. Install via: choco install pandoc")
        sys.exit(1)

    TEMPLATES_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["pandoc", "--print-default-data-file", "reference.docx"],
        stdout=open(REFERENCE_DOCX, "wb"),
        check=True,
    )
    print(f"Template generated: {REFERENCE_DOCX}")
    print("You can now customize this file in Word (styles, headers, footers, logo).")


def build_file(input_path: Path, fmt: str) -> Path:
    """Convert a single Markdown file to the target format.

    Args:
        input_path: Path to the .md file.
        fmt: Output format — 'docx' or 'pdf'.

    Returns:
        Path to the generated output file.
    """
    if not input_path.exists():
        print(f"SKIP: {input_path} does not exist yet")
        return input_path

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Output filename: flatten path to avoid collisions
    # docs/04-livrables/architecture-technique.md → architecture-technique.pdf
    out_name = f"{input_path.stem}.{fmt}"
    out_path = OUTPUT_DIR / out_name

    cmd: list[str] = [
        "pandoc",
        str(input_path),
        "-o", str(out_path),
        "--from", "markdown",
        "--standalone",
        "--toc",
        "--number-sections",
        "-V", "lang=fr-FR",
        "-V", "geometry:margin=2.5cm",
    ]

    # Use metadata file if it exists
    if METADATA_FILE.exists() and fmt == "pdf":
        cmd.extend(["--metadata-file", str(METADATA_FILE)])

    # Use reference.docx for DOCX output
    if fmt == "docx" and REFERENCE_DOCX.exists():
        cmd.extend(["--reference-doc", str(REFERENCE_DOCX)])

    print(f"Building: {input_path.name} -> {out_path.name}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"ERROR building {input_path.name}:")
        print(result.stderr)
        return input_path

    print(f"  OK: {out_path}")
    return out_path


def build_all(fmt: str) -> None:
    """Build all deliverable files."""
    print(f"\nBuilding all livrables to {fmt.upper()}...\n")
    built = 0
    skipped = 0

    for livrable in LIVRABLE_FILES:
        if livrable.exists():
            build_file(livrable, fmt)
            built += 1
        else:
            print(f"SKIP: {livrable.relative_to(ROOT)} (not yet written)")
            skipped += 1

    print(f"\nDone: {built} built, {skipped} skipped")
    print(f"Output directory: {OUTPUT_DIR}")


def build_single(path: str, fmt: str) -> None:
    """Build a single file."""
    input_path = Path(path).resolve()
    if not input_path.suffix == ".md":
        print(f"ERROR: {path} is not a Markdown file")
        sys.exit(1)
    build_file(input_path, fmt)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build MSPR documentation (Markdown -> DOCX/PDF)"
    )
    parser.add_argument(
        "file",
        nargs="?",
        help="Markdown file to convert",
    )
    parser.add_argument(
        "--format", "-f",
        choices=["docx", "pdf"],
        default="docx",
        help="Output format (default: docx)",
    )
    parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Build all deliverables",
    )
    parser.add_argument(
        "--init-template",
        action="store_true",
        help="Generate reference.docx template for customization",
    )

    args = parser.parse_args()

    if not check_pandoc():
        print("ERROR: pandoc not found.")
        print("Install: choco install pandoc  (or scoop install pandoc)")
        sys.exit(1)

    if args.init_template:
        init_reference_template()
        return

    if args.all:
        build_all(args.format)
        return

    if args.file:
        build_single(args.file, args.format)
        return

    parser.print_help()


if __name__ == "__main__":
    main()

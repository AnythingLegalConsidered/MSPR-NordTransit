#!/usr/bin/env python3
"""
Notion → Git Sync Script
Synchronise la documentation Notion vers docs/ en Markdown.

Usage:
    python scripts/notion_sync.py              # Sync complète
    python scripts/notion_sync.py --dry-run    # Affiche sans écrire
    python scripts/notion_sync.py --page 00    # Sync une seule page
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

# Mapping Notion Page ID → fichier local
# IDs extraits du Notion "MSPR - NordTransit Logistics"
NOTION_PAGES = {
    # Page principale
    "2e095ddf-ecb1-8106-aee6-f23d0c83a063": {
        "name": "MSPR - NordTransit",
        "output": "OVERVIEW.md",
    },
    # PROJET
    "2e095ddf-ecb1-81da-86c1-c9981c3a329d": {
        "name": "PROJET",
        "output": "PLAN.md",
    },
    # COMPRENDRE
    "2e095ddf-ecb1-818e-abcd-ead3e781d2d2": {
        "name": "Infrastructure existante",
        "output": "comprendre/infrastructure-existante.md",
    },
    "2e095ddf-ecb1-8122-820f-ff7cc5f51fd3": {
        "name": "Sites NordTransit",
        "output": "comprendre/sites-nordtransit.md",
    },
    "2e095ddf-ecb1-81c4-abe1-c5dad2d10ffb": {
        "name": "Points de douleur",
        "output": "comprendre/points-douleur.md",
    },
    "2e095ddf-ecb1-81ef-8f4d-c56ae6c1e128": {
        "name": "Schemas reseau AVANT",
        "output": "comprendre/schemas-avant.md",
    },
    # SOLUTION
    "2e095ddf-ecb1-81b7-aaec-eea824972a7d": {
        "name": "Architecture cible",
        "output": "solution/architecture-cible.md",
    },
    "2e095ddf-ecb1-810b-bd5f-cc0d8d683a98": {
        "name": "Budget detaille",
        "output": "solution/budget.md",
    },
    "2e095ddf-ecb1-81cb-aa25-c14ba8909f4d": {
        "name": "Plan VLAN",
        "output": "solution/plan-vlan.md",
    },
    "2e095ddf-ecb1-810d-9909-e339febbbf89": {
        "name": "Strategie migration",
        "output": "solution/strategie-migration.md",
    },
    # POC
    "2e095ddf-ecb1-817d-b53c-c234eb9db2bc": {
        "name": "Guide Lab Proxmox",
        "output": "poc/guide-lab.md",
    },
    "2e095ddf-ecb1-8108-a7b6-c4b32abe3e76": {
        "name": "POC 1 - QoS VoIP",
        "output": "poc/poc1-qos-voip.md",
    },
    "2e095ddf-ecb1-8113-899b-e8a901e45587": {
        "name": "POC 2 - Failover AD",
        "output": "poc/poc2-failover-ad.md",
    },
    "2e095ddf-ecb1-813a-a933-ffbf9b2c2133": {
        "name": "POC 3 - Tunnel Azure",
        "output": "poc/poc3-tunnel-azure.md",
    },
}

DOCS_DIR = Path(__file__).parent.parent / "_specs"


def fetch_notion_page(page_id: str) -> Optional[str]:
    """
    Fetch a Notion page using Claude CLI with MCP.
    Returns the raw content or None if failed.
    """
    prompt = f'Fetch the Notion page with ID "{page_id}" and return ONLY the raw markdown content, nothing else.'

    try:
        result = subprocess.run(
            ["claude", "-p", prompt, "--allowedTools", "mcp__notion__notion-fetch"],
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode == 0:
            return result.stdout
        else:
            print(f"  [ERROR] Claude CLI failed: {result.stderr}", file=sys.stderr)
            return None
    except subprocess.TimeoutExpired:
        print(f"  [ERROR] Timeout fetching page {page_id}", file=sys.stderr)
        return None
    except FileNotFoundError:
        print("[ERROR] Claude CLI not found. Make sure 'claude' is in PATH.", file=sys.stderr)
        return None


def notion_to_markdown(content: str) -> str:
    """
    Convert Notion-flavored markdown to GitHub-flavored markdown.
    """
    if not content:
        return ""

    # Remove Notion page wrapper tags
    content = re.sub(r'<page[^>]*>', '', content)
    content = re.sub(r'</page>', '', content)
    content = re.sub(r'<ancestor-path>.*?</ancestor-path>', '', content, flags=re.DOTALL)
    content = re.sub(r'<properties>.*?</properties>', '', content, flags=re.DOTALL)
    content = re.sub(r'<content>', '', content)
    content = re.sub(r'</content>', '', content)

    # Convert Notion tables to MD tables
    def convert_table(match):
        table_content = match.group(1)
        rows = re.findall(r'<tr[^>]*>(.*?)</tr>', table_content, re.DOTALL)
        if not rows:
            return ""

        md_rows = []
        for i, row in enumerate(rows):
            cells = re.findall(r'<td[^>]*>(.*?)</td>', row, re.DOTALL)
            cells = [cell.strip().replace('\n', ' ') for cell in cells]
            md_row = "| " + " | ".join(cells) + " |"
            md_rows.append(md_row)

            # Add header separator after first row if header-row="true"
            if i == 0 and 'header-row="true"' in match.group(0):
                separator = "| " + " | ".join(["---"] * len(cells)) + " |"
                md_rows.append(separator)

        return "\n".join(md_rows)

    content = re.sub(
        r'<table[^>]*>(.*?)</table>',
        convert_table,
        content,
        flags=re.DOTALL
    )

    # Convert callouts to blockquotes
    def convert_callout(match):
        icon = match.group(1) or ""
        text = match.group(2).strip()
        # Remove nested tags and clean up
        text = re.sub(r'<[^>]+>', '', text)
        text = text.replace('\n\t', '\n> ')
        return f"> **{icon}** {text}"

    content = re.sub(
        r'<callout[^>]*icon="([^"]*)"[^>]*>(.*?)</callout>',
        convert_callout,
        content,
        flags=re.DOTALL
    )

    # Remove Notion URL references like {{https://...}}
    content = re.sub(r'\{\{[^}]+\}\}', '', content)

    # Remove mention tags
    content = re.sub(r'<mention-[^>]+>[^<]*</mention-[^>]+>', '', content)
    content = re.sub(r'<mention-[^>]+/>', '', content)

    # Clean up escaped characters
    content = content.replace('\\[', '[')
    content = content.replace('\\]', ']')
    content = content.replace('\\<', '<')
    content = content.replace('\\>', '>')

    # Remove empty lines clusters
    content = re.sub(r'\n{3,}', '\n\n', content)

    return content.strip()


def sync_page(page_id: str, config: dict, dry_run: bool = False) -> bool:
    """
    Sync a single Notion page to local file.
    Returns True if successful.
    """
    name = config["name"]
    output_path = DOCS_DIR / config["output"]

    print(f"  Fetching: {name}...")

    raw_content = fetch_notion_page(page_id)
    if raw_content is None:
        return False

    markdown = notion_to_markdown(raw_content)

    if dry_run:
        print(f"  [DRY-RUN] Would write {len(markdown)} chars to {output_path}")
        return True

    # Ensure directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Check if content changed
    if output_path.exists():
        existing = output_path.read_text(encoding="utf-8")
        if existing == markdown:
            print(f"  [SKIP] No changes: {config['output']}")
            return True

    output_path.write_text(markdown, encoding="utf-8")
    print(f"  [WROTE] {config['output']} ({len(markdown)} chars)")
    return True


def sync_all(dry_run: bool = False, page_filter: Optional[str] = None):
    """
    Sync all Notion pages to local files.
    """
    print("=" * 50)
    print("Notion → Git Sync")
    print("=" * 50)

    if dry_run:
        print("[MODE] Dry-run - no files will be written\n")

    success = 0
    failed = 0

    for page_id, config in NOTION_PAGES.items():
        # Filter by page name prefix if specified
        if page_filter and not config["name"].lower().startswith(page_filter.lower()):
            continue

        if sync_page(page_id, config, dry_run):
            success += 1
        else:
            failed += 1

    print("\n" + "=" * 50)
    print(f"Done: {success} synced, {failed} failed")
    print("=" * 50)

    return failed == 0


def main():
    parser = argparse.ArgumentParser(
        description="Sync Notion documentation to Git (docs/)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without writing files",
    )
    parser.add_argument(
        "--page",
        type=str,
        help="Sync only pages starting with this prefix (e.g., '00', '01')",
    )

    args = parser.parse_args()

    success = sync_all(dry_run=args.dry_run, page_filter=args.page)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

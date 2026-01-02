"""CLI wrapper: use `scripts.n2m` package to fetch & convert Notion pages to Markdown."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Dict

try:
    from notion_client import Client
except Exception:  # pragma: no cover - import error handled at runtime
    Client = None  # type: ignore

try:
    from dotenv import load_dotenv
    load_dotenv()
except Exception:
    pass

from scripts.n2m import api, convert, utils

NOTION_API_KEY_ENV = "NOTION_API_KEY"


def main(argv=None):
    parser = argparse.ArgumentParser(description="Download a Notion page as Markdown")
    parser.add_argument("-p", "--page", required=True, help="Notion page URL or page id")
    parser.add_argument("-o", "--output", help="Output file path (optional)")
    args = parser.parse_args(argv)

    api_key = os.getenv(NOTION_API_KEY_ENV)
    if not api_key:
        print(f"Error: set ${NOTION_API_KEY_ENV} (or put it in .env)")
        sys.exit(2)

    if Client is None:
        print("Error: `notion-client` package is required. Install with `pip install notion-client`")
        sys.exit(2)

    try:
        page_id = utils.extract_page_id(args.page)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(2)

    client = Client(auth=api_key)

    page = api.fetch_page(client, page_id)
    title = utils.get_page_title(page)

    blocks = api.fetch_blocks(client, page_id)
    md = f"# {title}\n\n" + convert.convert_blocks_to_markdown(blocks, client=client)

    out_path = Path(args.output) if args.output else Path("output") / f"{utils.slugify(title) or page_id}.md"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(md, encoding="utf-8")

    print(f"Saved Markdown to {out_path}")


if __name__ == "__main__":
    main()

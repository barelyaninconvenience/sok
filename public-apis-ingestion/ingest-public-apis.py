"""
Public APIs Catalog Ingestion — KLEM/OS v3 Custom-MCP Candidate Discovery

Fetches the public-apis/public-apis GitHub repo README, parses the category+entry
tables, and emits structured output suitable for Supabase ingestion or local
Parquet staging. Designed to feed the `custom_mcp_candidates` table so Claude
Code sessions can query-by-need when a workflow requires a specific API class.

Source: https://github.com/public-apis/public-apis
Consumed by: Supabase MCP (query_knowledge_chunks / insert_knowledge_asset tools)
Reference: `Writings/Overemployment_Stack_Integration_20260421.md` Part E

Usage:
    python ingest-public-apis.py --output staged-apis.json
    python ingest-public-apis.py --output staged-apis.json --format parquet
    python ingest-public-apis.py --fetch-fresh  # re-download README even if cached

Dependencies:
    pip install httpx markdown-it-py pyarrow  # pyarrow only for --format parquet

Author: 2026-04-21 — first draft per v3 Part E harvesting plan
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Optional

import httpx


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s public-apis-ingest %(levelname)s %(message)s",
)
log = logging.getLogger("public_apis_ingest")


PUBLIC_APIS_README_URL = "https://raw.githubusercontent.com/public-apis/public-apis/master/README.md"
CACHE_PATH = Path(__file__).parent / ".cache-public-apis-readme.md"


@dataclass
class ApiEntry:
    """Single API entry from the public-apis catalog."""
    category: str
    name: str
    description: str
    auth: str
    https: bool
    cors: str
    link: str

    # Derived fields for MCP candidacy scoring
    has_auth: bool = False
    https_enforced: bool = False
    cors_known: bool = False

    def __post_init__(self) -> None:
        self.has_auth = bool(self.auth and self.auth.lower() not in ("no", "none", "", "-"))
        self.https_enforced = self.https is True
        self.cors_known = self.cors.lower() in ("yes", "no")


def fetch_readme(force_fresh: bool = False) -> str:
    """Fetch the public-apis README.md, with caching."""
    if not force_fresh and CACHE_PATH.exists():
        log.info(f"Using cached README at {CACHE_PATH}")
        return CACHE_PATH.read_text(encoding="utf-8")

    log.info(f"Fetching fresh README from {PUBLIC_APIS_README_URL}")
    with httpx.Client(timeout=30.0) as client:
        resp = client.get(PUBLIC_APIS_README_URL, follow_redirects=True)
        resp.raise_for_status()
        content = resp.text

    CACHE_PATH.write_text(content, encoding="utf-8")
    log.info(f"Cached to {CACHE_PATH} ({len(content):,} bytes)")
    return content


def parse_readme(content: str) -> list[ApiEntry]:
    """Parse the README markdown for category headings + API tables.

    The public-apis README structure:
      ## Animals
      | API | Description | Auth | HTTPS | CORS |
      |---|---|---|---|---|
      | [Cat Facts](...) | Daily cat facts | No | Yes | No |
      | ...

    Each ## heading is a category; the following table contains entries.
    """
    entries: list[ApiEntry] = []
    current_category: Optional[str] = None

    # State machine over lines
    lines = content.split("\n")
    in_table = False
    skip_next_line = False  # skip the separator row after header

    for line in lines:
        stripped = line.strip()

        # Heading detection (## or ### level — but ## is category per the repo's convention)
        if stripped.startswith("## "):
            current_category = stripped[3:].strip()
            # Filter out non-category sections
            if current_category.lower() in ("index", "contributing", "sponsors"):
                current_category = None
            in_table = False
            continue

        # Table header detection
        if stripped.startswith("| API") and current_category:
            in_table = True
            skip_next_line = True  # next line is the separator
            continue

        # Skip separator row
        if skip_next_line:
            skip_next_line = False
            continue

        # Blank line or non-pipe line ends table
        if in_table and (not stripped or not stripped.startswith("|")):
            in_table = False
            continue

        # Parse table row
        if in_table and stripped.startswith("|"):
            try:
                # Split by | and strip; discard empty leading/trailing cells
                cells = [c.strip() for c in stripped.split("|")]
                cells = [c for c in cells if c]  # remove empties from start/end

                if len(cells) < 5:
                    continue

                api_cell, desc, auth, https, cors = cells[0], cells[1], cells[2], cells[3], cells[4]

                # Parse [Name](URL) markdown link
                link_match = re.match(r"\[([^\]]+)\]\(([^)]+)\)", api_cell)
                if not link_match:
                    continue
                name, link = link_match.group(1), link_match.group(2)

                # Normalize HTTPS field
                https_bool = https.lower() in ("yes", "✓", "true")

                entry = ApiEntry(
                    category=current_category,
                    name=name.strip(),
                    description=desc.strip(),
                    auth=auth.strip(),
                    https=https_bool,
                    cors=cors.strip(),
                    link=link.strip(),
                )
                entries.append(entry)

            except Exception as exc:  # noqa: BLE001
                log.warning(f"Failed to parse line: {stripped[:80]}... ({exc})")

    log.info(f"Parsed {len(entries)} API entries across {len(set(e.category for e in entries))} categories")
    return entries


def score_mcp_candidacy(entry: ApiEntry) -> dict[str, any]:
    """Score an API entry for custom-MCP candidacy.

    Per v3 Part E, a good MCP candidate:
    - Has auth (justifies DPAPI wrapping) — +2 points
    - HTTPS enforced (secure transport) — +1 point
    - CORS status known (well-documented API) — +1 point
    - Has a clear category (not 'Unknown' or 'Misc') — +1 point

    Score range: 0-5. Entries ≥3 warrant MCP candidacy evaluation.
    """
    score = 0
    factors: list[str] = []

    if entry.has_auth:
        score += 2
        factors.append("auth-present")
    if entry.https_enforced:
        score += 1
        factors.append("https-enforced")
    if entry.cors_known:
        score += 1
        factors.append("cors-documented")
    if entry.category and entry.category.lower() not in ("unknown", "misc", "miscellaneous"):
        score += 1
        factors.append("clear-category")

    return {
        "score": score,
        "factors": factors,
        "mcp_candidate": score >= 3,
    }


def emit_json(entries: list[ApiEntry], output_path: Path) -> None:
    """Emit entries as JSON array with candidacy scoring."""
    records = []
    for entry in entries:
        record = asdict(entry)
        record["candidacy"] = score_mcp_candidacy(entry)
        records.append(record)

    output_path.write_text(json.dumps(records, indent=2), encoding="utf-8")
    log.info(f"Wrote {len(records)} records to {output_path}")

    # Summary stats
    candidates = [r for r in records if r["candidacy"]["mcp_candidate"]]
    log.info(f"MCP candidates (score ≥3): {len(candidates)} of {len(records)}")

    categories = {}
    for r in records:
        categories.setdefault(r["category"], 0)
        categories[r["category"]] += 1
    log.info(f"Top categories: {sorted(categories.items(), key=lambda x: -x[1])[:10]}")


def emit_parquet(entries: list[ApiEntry], output_path: Path) -> None:
    """Emit entries as Parquet for bulk-loading into Supabase / DuckDB."""
    try:
        import pyarrow as pa
        import pyarrow.parquet as pq
    except ImportError:
        log.error("pyarrow not installed. Install with: pip install pyarrow")
        sys.exit(2)

    records = []
    for entry in entries:
        record = asdict(entry)
        cand = score_mcp_candidacy(entry)
        record["candidacy_score"] = cand["score"]
        record["mcp_candidate"] = cand["mcp_candidate"]
        record["candidacy_factors"] = ",".join(cand["factors"])
        records.append(record)

    table = pa.Table.from_pylist(records)
    pq.write_table(table, output_path)
    log.info(f"Wrote Parquet with {len(records)} rows to {output_path}")


def emit_supabase_sql(entries: list[ApiEntry], output_path: Path) -> None:
    """Emit SQL INSERT statements for Supabase public_apis_catalog table."""

    ddl = """
-- DDL: run once before importing data
CREATE TABLE IF NOT EXISTS public_apis_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    auth TEXT,
    https BOOLEAN,
    cors TEXT,
    link TEXT NOT NULL,
    has_auth BOOLEAN,
    https_enforced BOOLEAN,
    cors_known BOOLEAN,
    candidacy_score INT,
    mcp_candidate BOOLEAN,
    candidacy_factors TEXT[],
    ingested_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_public_apis_category ON public_apis_catalog(category);
CREATE INDEX IF NOT EXISTS idx_public_apis_mcp_candidate ON public_apis_catalog(mcp_candidate) WHERE mcp_candidate = true;

-- INSERT statements follow
"""

    lines = [ddl]
    for entry in entries:
        cand = score_mcp_candidacy(entry)
        # SQL-escape single quotes by doubling
        esc = lambda s: (s or "").replace("'", "''")

        factors_array = "ARRAY[" + ",".join(f"'{f}'" for f in cand["factors"]) + "]"

        insert = (
            f"INSERT INTO public_apis_catalog "
            f"(category, name, description, auth, https, cors, link, has_auth, https_enforced, "
            f"cors_known, candidacy_score, mcp_candidate, candidacy_factors) VALUES "
            f"('{esc(entry.category)}', '{esc(entry.name)}', '{esc(entry.description)}', "
            f"'{esc(entry.auth)}', {str(entry.https).lower()}, '{esc(entry.cors)}', "
            f"'{esc(entry.link)}', {str(entry.has_auth).lower()}, {str(entry.https_enforced).lower()}, "
            f"{str(entry.cors_known).lower()}, {cand['score']}, {str(cand['mcp_candidate']).lower()}, "
            f"{factors_array});"
        )
        lines.append(insert)

    output_path.write_text("\n".join(lines), encoding="utf-8")
    log.info(f"Wrote {len(entries)} INSERT statements to {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingest public-apis catalog for KLEM/OS MCP discovery")
    parser.add_argument("--output", default="staged-apis.json", help="Output file path")
    parser.add_argument("--format", choices=["json", "parquet", "sql"], default="json", help="Output format")
    parser.add_argument("--fetch-fresh", action="store_true", help="Force fresh download (skip cache)")
    args = parser.parse_args()

    content = fetch_readme(force_fresh=args.fetch_fresh)
    entries = parse_readme(content)

    if not entries:
        log.error("No entries parsed. README structure may have changed.")
        sys.exit(1)

    output_path = Path(args.output)

    if args.format == "json":
        emit_json(entries, output_path)
    elif args.format == "parquet":
        emit_parquet(entries, output_path)
    elif args.format == "sql":
        emit_supabase_sql(entries, output_path)

    log.info("Ingestion complete")


if __name__ == "__main__":
    main()

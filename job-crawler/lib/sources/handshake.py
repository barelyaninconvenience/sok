"""Handshake via Chrome MCP.

This module emits a plan (list of URLs + scraping instructions) rather than
executing the scraping directly. The calling script (or Claude via Chrome MCP
tools) drives the browser. This separation keeps the scraping loop testable
and allows substitution of the browser driver.
"""

from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path
from typing import Iterator

from ..normalize import NormalizedJob, make_normalized_job


def load_urls(path: Path) -> list[str]:
    """Read a file of Handshake URLs (one per line; blank lines and #-comments ignored)."""
    urls = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # Handle the format "url | label" from Clay's paste
        if "|" in line:
            url = line.split("|")[0].strip()
        else:
            url = line
        if url.startswith("http"):
            urls.append(url)
    # Dedupe while preserving order
    seen = set()
    out = []
    for u in urls:
        if u not in seen:
            seen.add(u)
            out.append(u)
    return out


def parse_chrome_extracted(
    *, source_url: str, extracted_markdown: str,
) -> NormalizedJob:
    """Parse the markdown that Chrome MCP `read_page` returns into a NormalizedJob.

    This is best-effort text parsing. The result can be hand-corrected in the DB.
    """
    lines = [l.strip() for l in extracted_markdown.splitlines() if l.strip()]
    title = ""
    company = ""
    pay_raw = ""

    # Heuristic: first H1-looking line is usually the title
    for l in lines[:30]:
        if l.startswith("# "):
            title = l.lstrip("# ").strip()
            break
    if not title and lines:
        title = lines[0][:200]

    # Heuristic: company line often follows title, often starts with "at " or is short
    for i, l in enumerate(lines[:30]):
        low = l.lower()
        if low.startswith("at ") and len(l) < 80:
            company = l[3:].strip()
            break
        if "company" in low and ":" in l:
            company = l.split(":", 1)[1].strip()
            break

    # Heuristic: pay line mentions $, hr, year, etc.
    import re as _re
    pay_line_re = _re.compile(r"(\$[\d,]+|[\d,]+\s*(per|/)\s*(hour|year|yr|hr))", _re.IGNORECASE)
    for l in lines[:60]:
        m = pay_line_re.search(l)
        if m:
            pay_raw = l
            break

    return make_normalized_job(
        source="handshake",
        source_url=source_url,
        title=title,
        company=company,
        pay_raw=pay_raw,
        description_md=extracted_markdown,
    )


def write_scraping_plan(urls: list[str], out_path: Path) -> None:
    """Write a JSON plan that a Chrome-MCP-driving script can consume."""
    plan = {
        "source": "handshake",
        "task_count": len(urls),
        "tasks": [{"url": u, "timeout_ms": 30000} for u in urls],
        "instructions": (
            "For each task: tabs_create_mcp → navigate → wait for job description "
            "to load → read_page (markdown) → save to raw/ → parse via "
            "lib.sources.handshake.parse_chrome_extracted → insert into DB."
        ),
    }
    out_path.write_text(json.dumps(plan, indent=2), encoding="utf-8")

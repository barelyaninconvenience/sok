"""LinkedIn Jobs via Chrome MCP.

LinkedIn has aggressive anti-bot measures. Rules:
- Keep request rate LOW (one job per 5-10 seconds minimum).
- Use Chrome MCP (driving real browser is least-detectable).
- Limit to ~30 jobs per session.
- If CAPTCHA appears, abort the session.
"""

from __future__ import annotations

import json
from pathlib import Path

from ..normalize import NormalizedJob, make_normalized_job


def build_search_url(
    *, keywords: str = "remote", location: str = "United States",
    remote_only: bool = True, salary_min: int | None = None,
    page: int = 1,
) -> str:
    """Build a LinkedIn Jobs search URL with filters."""
    import urllib.parse as up
    params = {
        "keywords": keywords,
        "location": location,
        "f_WT": "2" if remote_only else "",   # 2 = remote
        "start": (page - 1) * 25,
    }
    if salary_min:
        params["f_SB2"] = str(salary_min)
    query = up.urlencode({k: v for k, v in params.items() if v != ""})
    return f"https://www.linkedin.com/jobs/search/?{query}"


def parse_chrome_extracted(
    *, source_url: str, extracted_markdown: str,
) -> NormalizedJob:
    """Parse LinkedIn job page markdown into NormalizedJob."""
    lines = [l.strip() for l in extracted_markdown.splitlines() if l.strip()]

    title = ""
    company = ""
    pay_raw = ""
    location = ""

    # LinkedIn job pages typically have:
    # - Job title as H1
    # - Company name + location near the top
    # - "Apply" button, then job description

    for i, l in enumerate(lines[:40]):
        if l.startswith("# ") and not title:
            title = l.lstrip("# ").strip()
        elif not company and l and not l.startswith("#") and i < 10:
            # LinkedIn often puts company as the line after title
            if len(l) < 120 and not l.startswith("$") and "apply" not in l.lower():
                company = l
        if "$" in l and not pay_raw:
            pay_raw = l[:200]

    return make_normalized_job(
        source="linkedin",
        source_url=source_url,
        title=title,
        company=company,
        pay_raw=pay_raw,
        description_md=extracted_markdown,
    )


def write_scraping_plan(urls: list[str], out_path: Path) -> None:
    plan = {
        "source": "linkedin",
        "task_count": len(urls),
        "rate_limit_seconds": 8,
        "max_per_session": 30,
        "tasks": [{"url": u, "timeout_ms": 30000} for u in urls],
        "abort_conditions": ["captcha detected", "login redirect", "rate limit page"],
    }
    out_path.write_text(json.dumps(plan, indent=2), encoding="utf-8")

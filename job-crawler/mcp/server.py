"""MCP server exposing the job-crawler DB as queryable tools.

This makes the scored-jobs corpus queryable from any Claude session that has
the MCP server registered. Tools exposed:
    - list_top_jobs(min_score, limit, source_filter)
    - get_job(job_id)
    - get_company_jobs(company)
    - set_application_status(job_id, status, notes)
    - scraping_stats()
    - dry_score_preview(title, company, pay, description)

Register in .mcp.json:

    {
      "mcpServers": {
        "job-crawler": {
          "command": "python",
          "args": ["-m", "mcp.server"],
          "cwd": "C:\\\\Users\\\\shelc\\\\Documents\\\\Journal\\\\Projects\\\\scripts\\\\job-crawler"
        }
      }
    }

Requires `fastmcp` (pip install fastmcp).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

try:
    from fastmcp import FastMCP
except ImportError:
    print("fastmcp not installed. pip install fastmcp", file=sys.stderr)
    sys.exit(1)

from lib.storage import connect, DEFAULT_DB
from lib.dry_score import dry_score as _dry_score
from lib.apply_tracker import set_status as _set_status, VALID_STATUSES
from lib.stats import corpus_summary

mcp = FastMCP("job-crawler")


@mcp.tool()
def list_top_jobs(
    min_score: int = 9,
    limit: int = 20,
    source_filter: Optional[str] = None,
) -> list[dict]:
    """List top-scoring jobs from the pipeline DB.

    Args:
        min_score: Minimum score_total (0-12). Default 9 (candidate threshold).
        limit: Max rows to return. Default 20.
        source_filter: Optional source (e.g., 'remoteok', 'handshake'). Default: all.
    """
    conn = connect(DEFAULT_DB)
    sql = """
        SELECT r.id, r.source, r.title, r.company, r.pay_raw, r.pay_min,
               r.remote_status, s.score_total, s.recommend, s.verdict,
               s.red_flags, s.green_flags
        FROM raw_jobs r
        JOIN scored_jobs s ON s.id = r.id
        WHERE s.score_total >= ?
    """
    params: list = [min_score]
    if source_filter:
        sql += " AND r.source = ?"
        params.append(source_filter)
    sql += " ORDER BY s.score_total DESC, r.scraped_at DESC LIMIT ?"
    params.append(limit)

    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return [
        {
            "id": r["id"],
            "source": r["source"],
            "title": r["title"],
            "company": r["company"],
            "pay_raw": r["pay_raw"],
            "pay_min": r["pay_min"],
            "remote_status": r["remote_status"],
            "score_total": r["score_total"],
            "recommend": r["recommend"],
            "verdict": r["verdict"],
            "red_flags": json.loads(r["red_flags"]) if r["red_flags"] else [],
            "green_flags": json.loads(r["green_flags"]) if r["green_flags"] else [],
        }
        for r in rows
    ]


@mcp.tool()
def get_job(job_id: str) -> dict:
    """Fetch full details for a specific job by ID."""
    conn = connect(DEFAULT_DB)
    row = conn.execute(
        """SELECT r.*, s.*, a.status as application_status, a.notes as application_notes
           FROM raw_jobs r
           LEFT JOIN scored_jobs s ON s.id = r.id
           LEFT JOIN applications a ON a.job_id = r.id
           WHERE r.id = ?""",
        (job_id,),
    ).fetchone()
    conn.close()
    if not row:
        return {"error": f"job {job_id} not found"}
    return dict(row)


@mcp.tool()
def get_company_jobs(company: str, limit: int = 10) -> list[dict]:
    """Find all jobs from a specific company (fuzzy match)."""
    conn = connect(DEFAULT_DB)
    rows = conn.execute(
        """SELECT r.id, r.source, r.title, r.company, r.pay_raw, s.score_total
           FROM raw_jobs r
           LEFT JOIN scored_jobs s ON s.id = r.id
           WHERE r.company LIKE ?
           ORDER BY s.score_total DESC
           LIMIT ?""",
        (f"%{company}%", limit),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


@mcp.tool()
def set_application_status(
    job_id: str, status: str, notes: str = "",
) -> dict:
    """Update the application tracking status for a job.

    Valid statuses: not_applied, applied, phone_screen, interview, offer,
    rejected, withdrawn, ghosted.
    """
    if status not in VALID_STATUSES:
        return {
            "error": f"invalid status: {status}",
            "valid_statuses": VALID_STATUSES,
        }
    conn = connect(DEFAULT_DB)
    try:
        _set_status(conn, job_id, status, notes)
        return {"ok": True, "job_id": job_id, "status": status}
    except Exception as e:
        return {"error": str(e)}
    finally:
        conn.close()


@mcp.tool()
def scraping_stats() -> dict:
    """Return corpus-level statistics."""
    conn = connect(DEFAULT_DB)
    try:
        return corpus_summary(conn)
    finally:
        conn.close()


@mcp.tool()
def dry_score_preview(
    title: str, company: str, pay: str, description: str,
    remote_status: str = "unclear",
) -> dict:
    """Score a hypothetical job posting against the rubric heuristically.

    Useful for evaluating a job posting before scraping / storing it.
    Returns the 6-dimension scores + recommendation.
    """
    return _dry_score(
        title=title,
        description=description,
        pay_raw=pay,
        remote_status=remote_status,
    )


if __name__ == "__main__":
    mcp.run()

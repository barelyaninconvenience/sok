"""Aggregate statistics / reporting over the scored job database."""

from __future__ import annotations

from collections import Counter


def corpus_summary(conn) -> dict:
    """Return a summary dict of the scored corpus."""
    total = conn.execute("SELECT COUNT(*) FROM raw_jobs").fetchone()[0]
    scored = conn.execute("SELECT COUNT(*) FROM scored_jobs").fetchone()[0]
    by_source = dict(conn.execute(
        "SELECT source, COUNT(*) FROM raw_jobs GROUP BY source ORDER BY 2 DESC"
    ).fetchall())
    by_recommend = dict(conn.execute(
        "SELECT recommend, COUNT(*) FROM scored_jobs GROUP BY recommend"
    ).fetchall())
    shortlist_count = conn.execute(
        "SELECT COUNT(*) FROM scored_jobs WHERE score_total >= 9"
    ).fetchone()[0]

    avg_score = conn.execute("SELECT AVG(score_total) FROM scored_jobs").fetchone()[0] or 0
    top_companies = dict(conn.execute(
        """SELECT company, COUNT(*) FROM v_shortlist GROUP BY company
           ORDER BY 2 DESC LIMIT 10"""
    ).fetchall())

    return {
        "total_jobs_scraped": total,
        "total_jobs_scored": scored,
        "by_source": by_source,
        "by_recommendation": by_recommend,
        "shortlist_count": shortlist_count,
        "average_score": round(avg_score, 2),
        "top_companies_on_shortlist": top_companies,
    }


def format_summary(summary: dict) -> str:
    """Pretty-print the summary."""
    lines = []
    lines.append(f"Total jobs scraped: {summary['total_jobs_scraped']}")
    lines.append(f"Total jobs scored:  {summary['total_jobs_scored']}")
    lines.append(f"Average score:      {summary['average_score']}/12")
    lines.append(f"Shortlist (>=9):    {summary['shortlist_count']}")
    lines.append("")
    lines.append("By source:")
    for src, n in summary["by_source"].items():
        lines.append(f"  {src:20} {n}")
    lines.append("")
    lines.append("By recommendation:")
    for rec, n in (summary["by_recommendation"] or {}).items():
        lines.append(f"  {rec:10} {n}")
    if summary["top_companies_on_shortlist"]:
        lines.append("")
        lines.append("Top companies on shortlist:")
        for company, n in summary["top_companies_on_shortlist"].items():
            lines.append(f"  {company:40} {n}")
    return "\n".join(lines)

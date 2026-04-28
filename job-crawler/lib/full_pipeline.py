"""Run the full pipeline end-to-end.

Stages:
    1. Scrape all public sources
    2. Dry-score everything (free)
    3. LLM-score anything above heuristic threshold
    4. Dedupe
    5. Export shortlist CSV

Not Chrome-MCP-dependent; use bin/scrape.py --source handshake separately
for auth'd sites.
"""

from __future__ import annotations

import time
from pathlib import Path

from .storage import connect, insert_job, unscored_jobs, save_score, DEFAULT_DB, backup_raw
from .dry_score import dry_score
from .dedupe_run import run_dedupe
from .sources.remoteok import fetch_all as fetch_remoteok
from .sources.wwr import fetch_all as fetch_wwr


def run_pipeline(
    *,
    remoteok_limit: int = 100,
    wwr_limit: int = 100,
    llm_threshold: int = 7,
    llm_model: str = "claude-sonnet-4-6",
    use_llm: bool = True,
) -> dict:
    """Run pipeline. Returns stats dict."""
    stats = {
        "scraped": {"remoteok": 0, "wwr": 0},
        "inserted": {"remoteok": 0, "wwr": 0},
        "dry_scored": 0,
        "llm_scored": 0,
        "dedup_groups": 0,
    }

    conn = connect(DEFAULT_DB)

    # 1. Scrape
    print("[1/5] scraping RemoteOK...")
    raw_dir = DEFAULT_DB.parent / "raw" / "remoteok"
    for job in fetch_remoteok(limit=remoteok_limit):
        stats["scraped"]["remoteok"] += 1
        job.raw_html_path = backup_raw(raw_dir, job.id, job.description_md)
        if insert_job(conn, job):
            stats["inserted"]["remoteok"] += 1
    print(f"   inserted {stats['inserted']['remoteok']} new jobs")

    print("[2/5] scraping WeWorkRemotely...")
    raw_dir = DEFAULT_DB.parent / "raw" / "wwr"
    for job in fetch_wwr(limit=wwr_limit):
        stats["scraped"]["wwr"] += 1
        job.raw_html_path = backup_raw(raw_dir, job.id, job.description_md)
        if insert_job(conn, job):
            stats["inserted"]["wwr"] += 1
    print(f"   inserted {stats['inserted']['wwr']} new jobs")

    # 2. Dry-score
    print("[3/5] dry-scoring...")
    jobs = unscored_jobs(conn)
    to_llm = []
    for row in jobs:
        result = dry_score(
            title=row["title"],
            description=(row["description_md"] or "")[:4000],
            pay_raw=row["pay_raw"] or "",
            remote_status=row["remote_status"] or "unclear",
            pay_min=row["pay_min"],
            pay_type=row["pay_type"] or "unknown",
        )
        if result["score_total"] < llm_threshold:
            save_score(conn, row["id"], result, model_used="heuristic")
            stats["dry_scored"] += 1
        else:
            to_llm.append(row)
    print(f"   filtered out {stats['dry_scored']} low-score jobs via heuristic")
    print(f"   {len(to_llm)} jobs flagged for LLM scoring")

    # 3. LLM score
    if use_llm and to_llm:
        print("[4/5] LLM scoring...")
        from .score import score_job
        for i, row in enumerate(to_llm, 1):
            try:
                result = score_job(
                    title=row["title"],
                    company=row["company"] or "",
                    pay=row["pay_raw"] or "",
                    remote=row["remote_status"] or "unclear",
                    description=(row["description_md"] or "")[:4000],
                    model=llm_model,
                )
                save_score(conn, row["id"], result, model_used=llm_model)
                stats["llm_scored"] += 1
                if i % 10 == 0:
                    print(f"   scored {i}/{len(to_llm)}")
                time.sleep(0.3)  # polite
            except Exception as e:
                print(f"   ! error on {row['id']}: {e}")
    else:
        print("[4/5] skipping LLM scoring")

    # 4. Dedupe
    print("[5/5] deduplicating...")
    stats["dedup_groups"] = run_dedupe(conn)
    print(f"   created {stats['dedup_groups']} dedup groups")

    conn.close()
    return stats

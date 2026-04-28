#!/usr/bin/env python3
"""Score unscored jobs against rubric v2 (overemployment-stack-tuned).

Parallel CLI to bin/score.py (v1). Uses lib/score_v2 (8-dimension weighted
rubric + Detection Risk multiplier + 3 vetoes + Clay's stack-goal-relative
Pay Position) and persists to v2 columns via lib.storage.save_score_v2.

Both rubrics coexist in the DB via the rubric_version column.

Usage:
  py -3.14 bin/score_v2.py                              # score all unscored
  py -3.14 bin/score_v2.py --limit 25                   # score first 25 only
  py -3.14 bin/score_v2.py --model claude-haiku-4-5     # cheaper model
  py -3.14 bin/score_v2.py --delay 1.0                  # 1s between calls
  py -3.14 bin/score_v2.py --rescore                    # re-score even if v2 row exists
  py -3.14 bin/score_v2.py --dry-run                    # print scores; do not write
"""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from lib.score_v2 import score_job_v2, load_config
from lib.storage import connect, unscored_jobs, save_score_v2, DEFAULT_DB


def _v2_unscored(conn, limit=None, rescore=False):
    """Return jobs that need v2 scoring.

    Default: any job not yet in scored_jobs.
    With --rescore: any job not yet scored with rubric_version='2.0'
    (so jobs that have a v1 score but no v2 score get re-scored).
    """
    if rescore:
        sql = """
            SELECT r.*
            FROM raw_jobs r
            LEFT JOIN scored_jobs s
              ON s.id = r.id AND s.rubric_version = '2.0'
            WHERE s.id IS NULL
            ORDER BY r.scraped_at ASC
        """
        if limit:
            sql += f" LIMIT {int(limit)}"
        return list(conn.execute(sql).fetchall())
    return unscored_jobs(conn, limit=limit)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--model", default="claude-sonnet-4-6",
                    help="Anthropic model id (default: claude-sonnet-4-6)")
    ap.add_argument("--limit", type=int, default=None,
                    help="max jobs to score in this run")
    ap.add_argument("--delay", type=float, default=0.5,
                    help="seconds between API calls (default: 0.5)")
    ap.add_argument("--rescore", action="store_true",
                    help="score jobs that have v1 but no v2 row "
                         "(default: only score jobs with no row at all)")
    ap.add_argument("--dry-run", action="store_true",
                    help="print scores; do NOT write to DB")
    args = ap.parse_args()

    config = load_config()
    print(f"v2 rubric · stack_goal=${config['stack_goal']:,} · "
          f"N={config['n_stack']} · per-job target=${config['per_job_target']:,} · "
          f"risk_tolerance={config['risk_tolerance']}")

    conn = connect(DEFAULT_DB)
    jobs = _v2_unscored(conn, limit=args.limit, rescore=args.rescore)
    print(f"found {len(jobs)} jobs to score with v2"
          + (" (--rescore mode)" if args.rescore else "")
          + (" [DRY RUN — no DB writes]" if args.dry_run else ""))

    n_apply = n_maybe = n_skip = n_vetoed = n_error = 0

    for i, row in enumerate(jobs, 1):
        title_short = (row["title"] or "")[:60]
        print(f"[{i}/{len(jobs)}] scoring {row['id']}: {title_short}")
        try:
            result = score_job_v2(
                title=row["title"] or "",
                company=row["company"] or "",
                pay=row["pay_raw"] or "",
                remote=row["remote_status"] or "unclear",
                description=(row["description_md"] or "")[:4000],
                model=args.model,
                config=config,
            )

            if not args.dry_run:
                save_score_v2(conn, row["id"], result, model_used=args.model)

            rec = result.get("recommend", "?")
            final = result.get("final_score", 0.0)
            vetoed = result.get("vetoed", False)
            veto_reason = result.get("veto_reason", "")
            verdict = (result.get("verdict", "") or "")[:80]

            tag = "VETO" if vetoed else rec.upper()
            extra = f" [{veto_reason}]" if vetoed and veto_reason else ""
            print(f"   → final={final:.1f}/42 [{tag}]{extra} {verdict}")

            if vetoed:
                n_vetoed += 1
            elif rec == "apply":
                n_apply += 1
            elif rec == "maybe":
                n_maybe += 1
            else:
                n_skip += 1

        except Exception as e:
            print(f"   ! error: {e}")
            n_error += 1

        time.sleep(args.delay)

    conn.close()

    print()
    print("=" * 60)
    print(f"v2 scoring complete: {len(jobs)} jobs processed")
    print(f"  apply : {n_apply}")
    print(f"  maybe : {n_maybe}")
    print(f"  skip  : {n_skip}")
    print(f"  vetoed: {n_vetoed}")
    if n_error:
        print(f"  ERRORS: {n_error}")
    if args.dry_run:
        print("DRY RUN — no rows written to scored_jobs.")


if __name__ == "__main__":
    main()

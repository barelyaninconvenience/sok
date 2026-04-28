"""SQLite storage helpers."""

from __future__ import annotations

import json
import sqlite3
from pathlib import Path
from typing import Optional

from .normalize import NormalizedJob

SCHEMA_PATH = Path(__file__).resolve().parent.parent / "schema.sql"
DEFAULT_DB = Path(__file__).resolve().parent.parent / "data" / "jobs.db"


def connect(db_path: Path = DEFAULT_DB) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


def init_db(db_path: Path = DEFAULT_DB) -> None:
    schema = SCHEMA_PATH.read_text(encoding="utf-8")
    conn = connect(db_path)
    try:
        conn.executescript(schema)
        conn.commit()
    finally:
        conn.close()


def insert_job(conn: sqlite3.Connection, job: NormalizedJob) -> bool:
    """Insert a new job. Returns True if inserted, False if already present."""
    try:
        conn.execute(
            """
            INSERT INTO raw_jobs (
                id, source, source_url, title, company, pay_raw,
                pay_min, pay_max, pay_type, remote_status, location,
                description_md, posted_date, scraped_at, raw_html_path
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                job.id, job.source, job.source_url, job.title, job.company,
                job.pay_raw, job.pay_min, job.pay_max, job.pay_type,
                job.remote_status, job.location, job.description_md,
                job.posted_date, job.scraped_at, job.raw_html_path,
            ),
        )
        conn.commit()
        return True
    except sqlite3.IntegrityError:
        return False


def unscored_jobs(conn: sqlite3.Connection, limit: Optional[int] = None) -> list[sqlite3.Row]:
    sql = """
        SELECT r.*
        FROM raw_jobs r
        LEFT JOIN scored_jobs s ON s.id = r.id
        WHERE s.id IS NULL
        ORDER BY r.scraped_at ASC
    """
    if limit:
        sql += f" LIMIT {int(limit)}"
    return list(conn.execute(sql).fetchall())


def save_score(
    conn: sqlite3.Connection,
    job_id: str,
    scores: dict,
    model_used: str,
) -> None:
    """scores: dict with keys score_automatability, score_oversight, score_pay,
    score_remote, score_stakes, score_flexibility, red_flags (list),
    green_flags (list), verdict, recommend."""
    total = sum(
        scores.get(k, 0) for k in (
            "score_automatability", "score_oversight", "score_pay",
            "score_remote", "score_stakes", "score_flexibility",
        )
    )
    from datetime import datetime, timezone
    conn.execute(
        """
        INSERT OR REPLACE INTO scored_jobs (
            id, score_automatability, score_oversight, score_pay,
            score_remote, score_stakes, score_flexibility, score_total,
            red_flags, green_flags, verdict, recommend, scored_at, model_used
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            job_id,
            scores.get("score_automatability", 0),
            scores.get("score_oversight", 0),
            scores.get("score_pay", 0),
            scores.get("score_remote", 0),
            scores.get("score_stakes", 0),
            scores.get("score_flexibility", 0),
            total,
            json.dumps(scores.get("red_flags", [])),
            json.dumps(scores.get("green_flags", [])),
            scores.get("verdict", ""),
            scores.get("recommend", "maybe"),
            datetime.now(timezone.utc).isoformat(),
            model_used,
        ),
    )
    conn.commit()


def save_score_v2(
    conn: sqlite3.Connection,
    job_id: str,
    scores: dict,
    model_used: str,
) -> None:
    """Persist a v2 scoring result to scored_jobs.

    Writes to v2 columns added by schema_v2_migration.sql. Tags
    rubric_version='2.0' so the v_shortlist_v2 view picks it up.
    Coexists with v1 rows (different rubric_version).
    """
    from datetime import datetime, timezone
    conn.execute(
        """
        INSERT OR REPLACE INTO scored_jobs (
            id,
            rubric_version,
            score_remote_depth, score_synchronous_oversight, score_detection_risk,
            score_time_flexibility, score_task_surface_area, score_pay_position,
            score_stakes, score_onboarding_gauntlet,
            weighted_sum, detection_multiplier, final_score,
            vetoed, veto_reason,
            red_flags, green_flags, verdict, recommend,
            scored_at, model_used
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            job_id,
            scores.get("rubric_version", "2.0"),
            scores.get("score_remote_depth", 0),
            scores.get("score_synchronous_oversight", 0),
            scores.get("score_detection_risk", 0),
            scores.get("score_time_flexibility", 0),
            scores.get("score_task_surface_area", 0),
            scores.get("score_pay_position", 0),
            scores.get("score_stakes", 0),
            scores.get("score_onboarding_gauntlet", 0),
            float(scores.get("weighted_sum", 0.0)),
            float(scores.get("detection_multiplier", 0.0)),
            float(scores.get("final_score", 0.0)),
            int(bool(scores.get("vetoed", False))),
            scores.get("veto_reason", "") or "",
            json.dumps(scores.get("red_flags", [])),
            json.dumps(scores.get("green_flags", [])),
            scores.get("verdict", ""),
            scores.get("recommend", "maybe"),
            datetime.now(timezone.utc).isoformat(),
            model_used,
        ),
    )
    conn.commit()


def shortlist(conn: sqlite3.Connection, min_score: int = 9) -> list[sqlite3.Row]:
    return list(conn.execute(
        "SELECT * FROM v_shortlist WHERE score_total >= ? ORDER BY score_total DESC",
        (min_score,),
    ).fetchall())


def backup_raw(raw_dir: Path, job_id: str, content: str, suffix: str = "md") -> str:
    raw_dir.mkdir(parents=True, exist_ok=True)
    path = raw_dir / f"{job_id}.{suffix}"
    path.write_text(content, encoding="utf-8")
    return str(path)

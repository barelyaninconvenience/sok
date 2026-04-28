"""Dedupe pass: detect near-duplicate postings across sources and group them."""

from __future__ import annotations

import hashlib
from datetime import datetime, timezone

from .dedup import find_duplicates


def run_dedupe(conn, threshold: float = 85.0) -> int:
    """Scan raw_jobs for near-duplicates, populate dedupe_groups, and mark
    member jobs' dedup_group_id. Returns number of new groups created."""
    rows = list(conn.execute(
        "SELECT id, title, company FROM raw_jobs WHERE dedup_group_id IS NULL"
    ).fetchall())
    jobs = [(r["id"], r["title"] or "", r["company"] or "") for r in rows]
    groups = find_duplicates(jobs, threshold=threshold)

    created = 0
    for group in groups:
        # Canonical = first member
        first_id = group[0]
        first = conn.execute(
            "SELECT title, company FROM raw_jobs WHERE id = ?", (first_id,)
        ).fetchone()
        signature = f"{first['title']}|{first['company']}".lower()
        group_id = hashlib.sha256(signature.encode("utf-8")).hexdigest()[:16]

        # Upsert group
        conn.execute(
            """INSERT OR IGNORE INTO dedupe_groups
               (group_id, canonical_title, canonical_company, member_count, created_at)
               VALUES (?, ?, ?, ?, ?)""",
            (group_id, first["title"], first["company"], len(group),
             datetime.now(timezone.utc).isoformat()),
        )
        # Assign members
        for member_id in group:
            conn.execute(
                "UPDATE raw_jobs SET dedup_group_id = ? WHERE id = ?",
                (group_id, member_id),
            )
        created += 1

    conn.commit()
    return created

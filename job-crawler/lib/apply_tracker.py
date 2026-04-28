"""Application status tracking helpers."""

from __future__ import annotations

from datetime import datetime, timezone


VALID_STATUSES = [
    "not_applied", "applied", "phone_screen", "interview",
    "offer", "rejected", "withdrawn", "ghosted",
]


def set_status(conn, job_id: str, status: str, notes: str = "") -> None:
    if status not in VALID_STATUSES:
        raise ValueError(f"invalid status: {status}. valid: {VALID_STATUSES}")

    now = datetime.now(timezone.utc).isoformat()
    applied_at = now if status == "applied" else None

    existing = conn.execute(
        "SELECT * FROM applications WHERE job_id = ?", (job_id,)
    ).fetchone()

    if existing:
        # Preserve applied_at if already applied
        if existing["applied_at"] and not applied_at:
            applied_at = existing["applied_at"]
        new_notes = (existing["notes"] or "")
        if notes:
            new_notes = (new_notes + f"\n[{now}] {notes}").strip()
        conn.execute(
            """UPDATE applications SET status = ?, applied_at = ?,
               last_contact = ?, notes = ? WHERE job_id = ?""",
            (status, applied_at, now, new_notes, job_id),
        )
    else:
        conn.execute(
            """INSERT INTO applications (job_id, status, applied_at, last_contact, notes)
               VALUES (?, ?, ?, ?, ?)""",
            (job_id, status, applied_at, now, notes),
        )
    conn.commit()


def pipeline_report(conn) -> list[dict]:
    """Return the current applications pipeline grouped by status."""
    rows = list(conn.execute(
        """SELECT a.status, a.job_id, r.title, r.company, r.pay_raw,
                  a.applied_at, a.last_contact, a.notes
           FROM applications a
           JOIN raw_jobs r ON r.id = a.job_id
           ORDER BY
             CASE a.status
               WHEN 'offer' THEN 1
               WHEN 'interview' THEN 2
               WHEN 'phone_screen' THEN 3
               WHEN 'applied' THEN 4
               WHEN 'not_applied' THEN 5
               WHEN 'ghosted' THEN 6
               WHEN 'rejected' THEN 7
               WHEN 'withdrawn' THEN 8
             END"""
    ).fetchall())
    return [dict(r) for r in rows]

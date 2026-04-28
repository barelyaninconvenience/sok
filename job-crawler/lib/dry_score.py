"""Heuristic (free) pre-scoring to cut obviously-bad jobs before paying the LLM.

This uses the red-flag / green-flag keyword lists from rubric.md to produce a
coarse score. Jobs scoring below a threshold are marked 'skip' without an LLM
call, saving cost.

Use this as a first-pass filter:
    for job in jobs:
        dry = dry_score(job)
        if dry['score_total'] >= 4:
            # send to LLM scoring
        else:
            # save as 'skip' with dry result
"""

from __future__ import annotations

import re
from typing import Optional


# Red-flag patterns (case-insensitive regex → penalty dimension)
RED_FLAGS = [
    (r"\bhubstaff\b", "oversight"),
    (r"\btime[- ]doctor\b", "oversight"),
    (r"\bmonitoring software\b", "oversight"),
    (r"\bdaily\s+stand[- ]?up", "oversight"),
    (r"\bmust be available (during|from)\b", "flexibility"),
    (r"\bcore hours\b", "flexibility"),
    (r"\bclient[- ]facing\b", "stakes"),
    (r"\bface of the company\b", "stakes"),
    (r"\blicensed\b", "automatability"),
    (r"\bcertified\b", "automatability"),
    (r"\bvideo\s+calls?\b", "automatability"),
    (r"\bhybrid\b", "remote"),
    (r"\bin[- ]office\b", "remote"),
    (r"\bquarterly\s+in[- ]office\b", "remote"),
    (r"\bon[- ]call\b", "flexibility"),
    (r"\b24/7\b", "flexibility"),
    (r"\b24\s+hour\s+response\b", "flexibility"),
]

# Green-flag patterns
GREEN_FLAGS = [
    (r"\basync[- ]first\b", "oversight"),
    (r"\basync\s+communication\b", "oversight"),
    (r"\bresults[- ]only\b", "oversight"),
    (r"\bROWE\b", "oversight"),
    (r"\bfully\s+remote\b", "remote"),
    (r"\bwork from anywhere\b", "remote"),
    (r"\bflexible\s+hours\b", "flexibility"),
    (r"\bown your schedule\b", "flexibility"),
    (r"\bindependent contributor\b", "oversight"),
    (r"\bdocumentation[- ]heavy\b", "automatability"),
    (r"\bwriting[- ]focused\b", "automatability"),
    (r"\btext[- ]based\b", "automatability"),
]


def dry_score(
    *, title: str, description: str, pay_raw: str, remote_status: str,
    pay_min: Optional[int] = None, pay_type: str = "unknown",
) -> dict:
    """Heuristic score based on keyword matching. Each dimension starts at 1 (unknown)
    and is bumped up/down by flag matches."""
    text = f"{title}\n{description}\n{pay_raw}".lower()

    scores = {
        "score_automatability": 1,
        "score_oversight": 1,
        "score_pay": 1,
        "score_remote": 1,
        "score_stakes": 1,
        "score_flexibility": 1,
    }
    red_flags = []
    green_flags = []

    for pattern, dim in RED_FLAGS:
        if re.search(pattern, text):
            key = f"score_{dim}"
            scores[key] = max(0, scores[key] - 1)
            red_flags.append(pattern.strip(r"\b"))

    for pattern, dim in GREEN_FLAGS:
        if re.search(pattern, text):
            key = f"score_{dim}"
            scores[key] = min(2, scores[key] + 1)
            green_flags.append(pattern.strip(r"\b"))

    # Pay: use annual equivalent if available
    if pay_min:
        annual = pay_min * 2080 if pay_type == "hourly" else pay_min
        if 50_000 <= annual <= 100_000:
            scores["score_pay"] = 2
        elif 35_000 <= annual < 50_000 or 100_000 < annual <= 130_000:
            scores["score_pay"] = 1
        else:
            scores["score_pay"] = 0

    # Remote: from parsed status
    if remote_status == "fully_remote":
        scores["score_remote"] = 2
    elif remote_status == "hybrid":
        scores["score_remote"] = 0
    elif remote_status == "onsite":
        scores["score_remote"] = 0
    # unclear: leave at 1

    total = sum(scores.values())

    if total >= 10:
        recommend = "apply"
    elif total >= 7:
        recommend = "maybe"
    else:
        recommend = "skip"

    return {
        **scores,
        "score_total": total,
        "red_flags": red_flags,
        "green_flags": green_flags,
        "verdict": f"Heuristic pre-score: {total}/12 ({recommend})",
        "recommend": recommend,
    }

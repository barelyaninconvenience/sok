"""LLM scoring against rubric v2.

Parallel to lib/score.py (v1). v2 implements:
- 8 dimensions instead of 6
- Weighted sum instead of equal-weighted
- Detection Risk as multiplier (not summand)
- Three veto dimensions
- Pay Position stack-goal-relative
- Tagged with rubric_version so mixed-version DBs are tractable
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Optional

import anthropic

ROOT = Path(__file__).resolve().parent.parent
RUBRIC_PATH = ROOT / "rubric_v2.md"
CONFIG_PATH = ROOT / "config" / "scoring_defaults.json"


def load_config() -> dict:
    """Load Clay's current scoring defaults."""
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


SYSTEM_PROMPT = """You are scoring a job posting against rubric v2 for the overemployment endeavor.

Apply the 8-dimension weighted rubric. Respect all three vetoes (Remote Depth 0, Synchronous Oversight 0, Detection Risk 0 → reject regardless of other scores). Detection Risk is a MULTIPLIER not a summand. Return strict JSON with no markdown fences."""


def _build_user_prompt(
    job_title: str, job_company: str, job_pay: str, job_remote: str,
    job_description: str, config: dict,
) -> str:
    rubric = RUBRIC_PATH.read_text(encoding="utf-8")
    target = config["per_job_target"]
    return f"""Here is rubric v2:

{rubric}

Clay's current parameters:
- Stack goal: ${config['stack_goal']:,}/year total
- N stack: {config['n_stack']}
- Per-job target: ${target:,}
- Risk tolerance: {config['risk_tolerance']} (Detection Risk must score 3 for final acceptance)

Here is the job:

Title: {job_title}
Company: {job_company}
Pay: {job_pay}
Remote status: {job_remote}
Description:
{job_description}

Score this job on the 8 dimensions. Apply all three vetoes (Remote Depth, Synchronous Oversight, Detection Risk at 0 → skip regardless of other scores).

Compute:
- weighted_sum = sum of (score × weight) for all 7 non-detection dimensions
- detection_multiplier from Detection Risk score (3→1.0, 2→0.85, 1→0.6, 0→0.0 with VETO)
- final_score = weighted_sum × detection_multiplier

Return ONLY a JSON object with this exact structure:

{{
  "rubric_version": "2.0",
  "score_remote_depth": <0-3>,
  "score_synchronous_oversight": <0-3>,
  "score_detection_risk": <0-3>,
  "score_time_flexibility": <0-3>,
  "score_task_surface_area": <0-3>,
  "score_pay_position": <0-3>,
  "score_stakes": <0-3>,
  "score_onboarding_gauntlet": <0-3>,
  "weighted_sum": <sum of (score×weight) for non-detection dimensions, max 42>,
  "detection_multiplier": <1.0 | 0.85 | 0.6 | 0.0>,
  "final_score": <weighted_sum × detection_multiplier, max 42>,
  "vetoed": <true if any of remote_depth/synchronous_oversight/detection_risk scored 0, else false>,
  "veto_reason": "<dimension name or empty string>",
  "red_flags": ["short string", "..."],
  "green_flags": ["short string", "..."],
  "verdict": "one sentence, under 150 chars",
  "recommend": "apply" | "maybe" | "skip"
}}

Recommendation thresholds (post-multiplier):
- final_score >= 38: "apply" (Tier 1 priority)
- final_score 30-37: "apply" (Tier 2)
- final_score 22-29: "maybe" (Tier 3)
- final_score < 22: "skip"
- vetoed=true: "skip" (regardless of other scores)
- detection_multiplier < {config['risk_tolerance']}: "skip" (Clay's risk tolerance)

Default missing info to middle score (1-2). If info is genuinely absent, note it in verdict."""


def score_job_v2(
    *,
    title: str,
    company: str,
    pay: str,
    remote: str,
    description: str,
    model: str = "claude-sonnet-4-6",
    client: Optional[anthropic.Anthropic] = None,
    config: Optional[dict] = None,
) -> dict:
    if client is None:
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            raise RuntimeError("ANTHROPIC_API_KEY not set")
        client = anthropic.Anthropic(api_key=api_key)

    if config is None:
        config = load_config()

    msg = client.messages.create(
        model=model,
        max_tokens=1200,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": _build_user_prompt(
            title, company, pay, remote, description, config)}],
    )
    text = msg.content[0].text.strip()
    if text.startswith("```"):
        text = text.split("\n", 1)[1]
        if text.endswith("```"):
            text = text.rsplit("```", 1)[0]
        if text.startswith("json"):
            text = text[4:].lstrip()

    try:
        result = json.loads(text)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Model returned non-JSON: {text[:500]}") from e

    # Enforce Clay's risk tolerance locally (belt-and-suspenders)
    if result.get("detection_multiplier", 0) < config["risk_tolerance"]:
        if result.get("recommend") != "skip":
            result["recommend"] = "skip"
            result["verdict"] = f"{result.get('verdict', '')} [Below risk tolerance {config['risk_tolerance']}]".strip()

    return result

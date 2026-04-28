---
name: overemployment-job-filter-v2
description: Use this skill when scoring jobs against the v2.1 overemployment rubric — the stack-tuned 8-dimension weighted version with 3 vetoes and Detection Risk as multiplier. Triggers include explicit mentions of "v2 rubric," "score with v2," "use the new rubric," or any context where Clay's stack goal ($311,108 across 7 roles, $44,444/role target, $160K max, 0.85 risk tolerance) is the operative frame. For general job filtering without overemployment-specific tuning, use overemployment-job-filter (v1) instead. Both skills coexist; pick by intent.
---

# Overemployment Job Filter — v2.1

Score a job posting on **8 dimensions** with weighted sum (max 42), then multiply by Detection Risk (0.0–1.0). Apply 3 vetoes that override all other scores. Calibrated to Clay's stack-goal-relative parameters.

**v1 still available at `skills/overemployment-job-filter/SKILL.md`.** Use v2 for overemployment-specific stacking strategy; v1 for general single-role filtering.

## When invoked

The user will provide (or you will fetch from `data/jobs.db`) one or more job postings. Apply the rubric below. For batch scoring against the live DB, use `bin/score_v2.py` (built 2026-04-23).

## Clay's current parameters

Loaded from `config/scoring_defaults.json` at runtime:

| Parameter | Value | Meaning |
|---|---|---|
| `stack_goal` | $311,108/year | Total income target across all stacked roles |
| `n_stack` | 7 | Number of concurrent roles being stacked |
| `per_job_target` | $44,444/year | Target per role (= stack_goal / n_stack) |
| `pay_max` | $160,000 | Absolute pay ceiling; higher → Pay Position 0 |
| `risk_tolerance` | 0.85 | Detection Risk multiplier must be ≥ 0.85 (Detection Risk score 2 or 3 qualifies) |

## The 8 dimensions

### 1. Remote Depth (weight ×3 · VETO at 0)
- **3** — Fully remote, enforced by culture (asynchronous, no office-visit, distributed leadership)
- **2** — Fully remote, stated in posting, no visible enforcement mechanism
- **1** — Remote-first with stated travel or occasional on-site (quarterly summit)
- **0** — Hybrid, onsite, or tied to specific metro — **VETO**

### 2. Synchronous Oversight (weight ×3 · VETO at 0)
- **3** — Async-first / ROWE / results-only; no time-tracking, no camera, no daily check-ins
- **2** — Monthly sync; otherwise async
- **1** — Weekly sync; some deadlines but flexible cadence
- **0** — Daily standups, camera-on meetings, or monitoring software — **VETO**

### 3. Detection Risk (MULTIPLIER · VETO at 0)
- **3** — Minimal: 1099 contractor + non-exclusivity + personal hardware + no public presence → **×1.0**
- **2** — Low: 1099 with no moonlighting clause OR W-2 in large anonymous industry + no public identity → **×0.85**
- **1** — Moderate: W-2 with shared benefits brokers OR 1099 with soft "must disclose" → **×0.6**
- **0** — High: W-2 + benefits + public identity + small industry + hard non-compete — **VETO · ×0**

### 4. Time Flexibility (weight ×2)
- **3** — Truly async (no required hours at all)
- **2** — Core hours < 4 hrs/day
- **1** — Core hours 4-6 hrs/day
- **0** — Strict 9-5 specific timezone, mandatory synchronous hours, on-call

### 5. Task Surface Area (weight ×2)
- **3** — Pure text output; high AI leverage; nobody watches each deliverable (docs, code reviews, reports, research)
- **2** — Mixed async + AI-assistable with moderate visibility
- **1** — Mixed sync + async; visible but not continuously audited
- **0** — Live responsiveness required; immediate quality detection

### 6. Pay Position (weight ×1.5 · STACK-GOAL RELATIVE)

Target = $44,444/year. Max ceiling = $160,000.

- **3** — 0.9–1.1× target = **$40,000 – $48,889** (sweet spot)
- **2** — 0.7–0.9× target OR 1.1–1.8× target = **$31,111 – $40,000 OR $48,889 – $80,000**
- **1** — 0.4–0.7× target OR 1.8× up to max = **$17,778 – $31,111 OR $80,000 – $160,000**
- **0** — < 0.4× target OR above pay_max = **< $17,778 OR > $160,000**

### 7. Stakes (weight ×1.5)
- **3** — Zero blast radius; bad output costs nothing critical
- **2** — Small real consequences (worse deliverables) but no legal/safety
- **1** — Moderate (deadline misses cost reputation)
- **0** — High: legal, medical, financial, safety-critical, public-facing reputation

### 8. Onboarding Gauntlet (weight ×1)
- **3** — < 1 day onboarding, ticket-driven from day 1
- **2** — < 1 week onboarding
- **1** — 2-4 week onboarding with milestones
- **0** — Multi-week immersive onboarding with deep org-context buildout

## Scoring formula

```
weighted_sum = (remote_depth × 3) + (sync_oversight × 3) + (time_flex × 2)
             + (task_surface × 2) + (pay_position × 1.5) + (stakes × 1.5)
             + (onboarding × 1)
# max weighted_sum = 42

detection_multiplier = {3 → 1.0, 2 → 0.85, 1 → 0.6, 0 → 0.0 with VETO}

final_score = weighted_sum × detection_multiplier
# max final_score = 42 (only when detection_risk = 3)
```

## Veto enforcement (overrides all other scores)

If ANY of the following hits 0, set `vetoed = true`, `recommend = "skip"`, regardless of weighted_sum or final_score:

1. **Remote Depth = 0** (hybrid / onsite)
2. **Synchronous Oversight = 0** (monitoring software / camera meetings / daily standups)
3. **Detection Risk = 0** (W-2 + public identity + small industry + hard non-compete)

## Recommendation thresholds (post-multiplier)

- **final_score ≥ 38** → `"apply"` (Tier 1 priority)
- **final_score 30 – 37** → `"apply"` (Tier 2)
- **final_score 22 – 29** → `"maybe"` (Tier 3 — worth deeper review)
- **final_score < 22** → `"skip"`
- **vetoed = true** → `"skip"` regardless
- **detection_multiplier < risk_tolerance (0.85)** → `"skip"` (Clay's risk tolerance enforcement)

## Output format

Return a JSON object matching the structure consumed by `lib/storage.py:save_score_v2`:

```json
{
  "rubric_version": "2.0",
  "score_remote_depth": 0-3,
  "score_synchronous_oversight": 0-3,
  "score_detection_risk": 0-3,
  "score_time_flexibility": 0-3,
  "score_task_surface_area": 0-3,
  "score_pay_position": 0-3,
  "score_stakes": 0-3,
  "score_onboarding_gauntlet": 0-3,
  "weighted_sum": 0.0-42.0,
  "detection_multiplier": 0.0|0.6|0.85|1.0,
  "final_score": 0.0-42.0,
  "vetoed": true|false,
  "veto_reason": "remote_depth"|"synchronous_oversight"|"detection_risk"|"",
  "red_flags": ["short string", ...],
  "green_flags": ["short string", ...],
  "verdict": "one sentence under 150 chars",
  "recommend": "apply"|"maybe"|"skip"
}
```

## Calibration notes

- **Default missing info to 1-2** (middle scores), never 0. Note absent info in `verdict`.
- **Conservative bias** — better to skip a borderline candidate than waste application cycles. With 0.85 risk tolerance and Clay's $44,444 sweet spot, expected corpus acceptance is ~10.6% (per `Corpus_Acceptance_Analysis_20260423.md`) — ~1,060 candidates from a 10K-job corpus.
- **Pay Position above $80K** scores only 1, intentionally. Higher pay typically correlates with higher oversight + higher stakes; the rubric is calibrated against the empirical observation that the $44,444 sweet spot maximizes the pay ÷ scrutiny ratio.
- **Detection Risk is the load-bearing dimension.** The multiplier means even a perfect 42-weighted-sum job with Detection Risk 1 ends up at final_score 25 (= 42 × 0.6) — borderline maybe. Detection Risk 0 vetoes everything regardless of pay or async-ness.

## Batch workflow

For corpus scoring (Clay's typical use case):

```bash
# Apply schema_v2 migration first (idempotent, additive)
sqlite3 data/jobs.db < schema_v2_migration.sql

# Smoke-test against 5 jobs without DB writes
py -3.14 bin/score_v2.py --dry-run --limit 5

# Live run, score 100 jobs
py -3.14 bin/score_v2.py --limit 100

# Re-score jobs that have v1 row but no v2 row (cross-validate)
py -3.14 bin/score_v2.py --rescore --limit 100

# View v2 shortlist (final_score ≥ 30, not vetoed, multiplier ≥ 0.85)
sqlite3 data/jobs.db "SELECT * FROM v_shortlist_v2 LIMIT 25"
```

## v1 vs v2 — when to use each

| Context | Use |
|---|---|
| General job-search, single-role filtering | **v1** (`overemployment-job-filter`) |
| Overemployment stacking, Clay's specific parameters | **v2** (this skill) |
| Quick triage of 100+ jobs by simple "is this remote and async" check | **v1** (faster mental model) |
| Final scoring before application investment | **v2** (8-dim rigor + multiplier nuance) |
| Comparing across diverse rubric versions in DB | Both via `rubric_version` column |

## Context

This skill is part of the `overemployment-pipeline` plugin. Full pipeline at `scripts/job-crawler/`:
- **Scraping:** `bin/scrape.py` against multiple sources (RemoteOK, WWR, Handshake CDP, LinkedIn, Indeed, Wellfound, ZipRecruiter, crawl4ai_generic, kaggle_dataset)
- **v1 scoring:** `bin/score.py` → `lib/score.py` → 6-dim equal-weighted
- **v2 scoring:** `bin/score_v2.py` → `lib/score_v2.py` → 8-dim weighted + multiplier + vetoes
- **Storage:** `lib/storage.py:save_score_v2` writes to v2 columns added by `schema_v2_migration.sql`
- **Shortlist:** `bin/shortlist.py` (v1) + `v_shortlist_v2` view (v2)
- **Cover letters:** `bin/cover_letter.py` for tailored generation against shortlist

This skill is the rubric-application core; the pipeline is the end-to-end automation.

---

*v2.1 skill packaged 2026-04-23. Built parallel to v1 per `RUBRIC_V2_DEPLOYMENT.md` recommendation. Both skills coexist; users choose by intent.*

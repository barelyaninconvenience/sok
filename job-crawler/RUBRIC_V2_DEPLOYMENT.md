# Rubric v2 — Deployment Notes
## 2026-04-23

## What shipped

- **`rubric_v2.md`** — full v2 rubric text with Clay's defaults baked in
- **`config/scoring_defaults.json`** — editable config ($333,333 / 6 / 0.96)
- **`lib/score_v2.py`** — scoring function with v2 prompt + veto enforcement + Clay-tolerance local belt-and-suspenders
- **`schema_v2_migration.sql`** — additive migration (v1 data preserved; v2 columns added)
- v1 rubric + scoring code unchanged; rubric_version column distinguishes

## To deploy on the live DB

```bash
cd scripts/job-crawler
sqlite3 data/jobs.db < schema_v2_migration.sql
```

Idempotent; safe to run multiple times.

## To score a new batch with v2

```python
from lib.score_v2 import score_job_v2, load_config
config = load_config()  # Clay's defaults
result = score_job_v2(
    title="...", company="...", pay="...", remote="...", description="...",
    model="claude-sonnet-4-6",
    config=config,
)
# result['final_score'] = weighted_sum × detection_multiplier
# result['recommend'] = 'apply' | 'maybe' | 'skip'
# result['vetoed'] = True if any veto dimension scored 0
```

**Wired to `bin/score_v2.py` (CLI tool) — BUILT 2026-04-23.** Mirrors `bin/score.py` but invokes `score_job_v2` and persists to v2 columns via `lib.storage.save_score_v2`. Supports `--dry-run` (no DB writes), `--rescore` (re-score jobs with v1 row but no v2 row), `--limit`, `--delay`, `--model` flags.

Usage:
```bash
cd scripts/job-crawler
py -3.14 bin/score_v2.py --help                # see all flags
py -3.14 bin/score_v2.py --dry-run --limit 5   # smoke test against 5 jobs, no writes
py -3.14 bin/score_v2.py --limit 100           # score 100 jobs, persist to v2 columns
py -3.14 bin/score_v2.py --rescore --limit 100 # re-score v1-only jobs with v2
```

## Skill update

`skills/overemployment-job-filter/SKILL.md` currently documents v1. Should be updated to v2 before packaging the plugin for redistribution. Recommendation: create `skills/overemployment-job-filter-v2/SKILL.md` as a parallel skill; let Clay choose v1 or v2 depending on context. Backburner.

## Calibration consequences for Clay's specific parameters

With `stack_goal=$333,333`, `N=6`, `risk_tolerance=0.96`:

- **Target pay per role**: $55,556/year
- **Max acceptable pay**: $111,111 (anything higher = Pay Position score 0, usually auto-skip in practice)
- **Min viable pay**: $22,222 (below = 0, skip)
- **Detection Risk**: **must be 3** for any job to clear (strict)
  - This eliminates essentially all W-2 positions with benefits
  - Requires explicit 1099 contractor + non-exclusivity + personal hardware + no public identity
  - Expected acceptance rate: 5-10% of total corpus

This is a very tight set of parameters. If this filters too hard in practice, consider relaxing `risk_tolerance` to 0.85 (admit Detection Risk 2 jobs) for a broader candidate pool; re-tighten once a few are placed.

## v1 vs v2 — when to use each

- **v1**: general job-search filtering, broader acceptance, conventional single-role application
- **v2**: overemployment-specific stacking strategy; tighter filter calibrated to Clay's exact parameters

Both rubrics can coexist in the DB via the `rubric_version` column.

---

*Deployment notes · 2026-04-23 · Claude Opus 4.7.*

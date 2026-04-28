# Corpus Acceptance Analysis — Rubric v2.1
## At Clay's revised parameters: $44,444 target / $160,000 max / Detection Risk 2.2+ / N=7
## 2026-04-23

---

## The parameter change (v2.0 → v2.1)

| Parameter | v2.0 | v2.1 | Effect |
|---|---|---|---|
| Per-job target | $55,556 | **$44,444** | Lower sweet spot; more realistic for high-frequency roles |
| Max pay | $111,111 | **$160,000** | 44% higher ceiling; senior/specialist roles no longer auto-zeroed |
| Detection Risk min | 3 (strict) | **2+** (relaxed) | 1099 + anonymous W-2 both qualify; 2.4× broader pool |
| Risk multiplier floor | 0.96 | **0.85** | Accepts ×0.85 jobs (Detection Risk 2) |
| N (implied) | 6 | 7 | Slightly wider stack; per-role pressure lower |

## Expected corpus acceptance — working the math

Starting assumption: a **composite remote-job corpus of ~10,000 active postings** across Handshake + RemoteOK + WWR + LinkedIn-remote + Indeed-remote + Wellfound + Dice + ZipRecruiter (after dedupe). This is the universe you'd realistically assemble.

### Gate 1 — Remote Depth ≥ 1 (not hybrid, not onsite)

Among postings tagged "remote" in their original source:
- Truly fully remote: ~60%
- Hybrid-disguised-as-remote: ~30%
- "Remote-now, onsite-later" bait-and-switch: ~10%

**Passes: ~6,000 of 10,000**

### Gate 2 — Synchronous Oversight ≥ 1 (no daily standups, no monitoring software)

Among fully-remote postings:
- Async-friendly or weekly-sync-max: ~75%
- Daily standup culture: ~20%
- Active monitoring software mentioned: ~5%

**Passes: ~4,500 of 6,000 (~45% of original corpus)**

### Gate 3 — Detection Risk ≥ 2 (v2.1 relaxation — this is the big unlock)

Among fully-remote + async-friendly postings:
- Explicit 1099 contractor posts: ~15-20%
- W-2 positions in large anonymous industries (tech, general SaaS, e-commerce): ~25-30%
- W-2 in small niches where industry peers overlap: ~20%
- W-2 with hard non-compete or public-identity requirements: ~30%

**Passes v2.1 (Detection Risk 2+): ~40-50% = ~1,800-2,250 jobs**
**Would have passed v2.0 (Detection Risk 3 only): ~15-20% = ~680-900 jobs**

**v2.1 doubles the post-gate pool relative to v2.0.**

### Summary of gate pass-through

| Stage | v2.0 count | v2.1 count | v2.1 vs v2.0 |
|---|--:|--:|--:|
| Start | 10,000 | 10,000 | same |
| After Remote gate | 6,000 | 6,000 | same |
| After Oversight gate | 4,500 | 4,500 | same |
| After Detection Risk gate | 680-900 | 1,800-2,250 | **~2.5× broader** |

## Score distribution — what clears final thresholds

Among the ~2,000 jobs that pass all three vetoes, apply the weighted sum + multiplier:

### Expected score distribution (v2.1)

Based on typical remote-job posting quality in current market:

| Final score band | % of passed jobs | Expected count (of ~2,000) | Tier |
|---|--:|--:|---|
| ≥ 38 | 3% | ~60 | Tier 1 — Priority |
| 30 - 37 | 15% | ~300 | Tier 2 — Apply |
| 22 - 29 | 35% | ~700 | Tier 3 — Maybe |
| 12 - 21 | 35% | ~700 | Low-score; likely skip |
| < 12 | 12% | ~240 | Heuristic-filtered out |

**Net candidate pool** (score ≥ 22): **~1,060 jobs out of original 10,000 = 10.6% corpus acceptance**

### Comparison: v2.0 vs v2.1

| Tier | v2.0 expected count | v2.1 expected count |
|---|--:|--:|
| Tier 1 Priority (≥ 38) | ~20 | ~60 |
| Tier 2 Apply (30-37) | ~100 | ~300 |
| Tier 3 Maybe (22-29) | ~200 | ~700 |
| **Total candidates** | **~320** | **~1,060** |

**v2.1 expands the candidate pool ~3.3×**. This is the right direction given Clay needs ~100-150 applications to land 6-7 offers (2% acceptance rate industry benchmark).

## Practical implications

### At v2.1 (current), expected application flow:

1. **Scrape** 10,000 remote postings → DB
2. **Dry score** (heuristic, free) filters down to ~3,000
3. **LLM score** (v2.1) applies rubric → ~1,060 candidates by final score
4. **Of those 1,060**: top 60 get priority application, next 300 get queued applications, next 700 go in the maybe-pool for review
5. **Human review** of top 60 + Company Research skill → select 20-30 highest-fit this week
6. **Apply** with tailored resume (from 50-variant package) + tailored cover letter (from cover-letter template)
7. **Track** via applications table; update status per response

### Realistic throughput at v2.1

- **Week 1**: dry-scrape + score all sources; identify initial top 60. Apply to 15-20.
- **Week 2**: expand to Tier 2; apply to another 30.
- **Weeks 3-4**: continue Tier 2 + Tier 3 selective; apply to 20-30 more.
- **Month 1 total applications**: 65-80.
- **Expected response rate (industry benchmark at this caliber)**: 8-12% = 5-10 interviews.
- **Conversion from interview to offer**: 30-50% = 2-5 offers per month.
- **To stack 7 roles**: 3-4 months of sustained applications; probably 200-300 total applications sent.

### What could shift these numbers

- **Tightening risk_tolerance back to 0.96** → drops candidate pool 3× but increases average Detection Risk quality
- **Relaxing Remote Depth to include "Remote-first with travel"** → expands ~20% more
- **Raising per-job-target to $55,000** → shifts Pay Position scoring; slightly fewer candidates in sweet spot but better aggregate compensation
- **Adding more sources** (top 33 boards vs current 8) → 2-3× corpus size; same acceptance rate applies

## When to revisit v2.1 parameters

Flag for reconsideration if:
- **Week 4 results in fewer than 3 interviews**: corpus may be too tight → relax risk_tolerance or expand to hybrid
- **More than 5 applications bounce on "non-moonlighting clause"**: Detection Risk 2 is too permissive → tighten back to 3
- **Acceptance rate comes in < 2%**: the rubric may be admitting too many marginal candidates → tighten Pay Position or Stakes weighting
- **Average pay of accepted roles clusters at $80-100k, not $44,444**: Pay Position is over-rewarding higher pay → compress the bands

The rubric is instrument, not scripture. Recalibrate based on observed signal.

---

## Machinery implications

The v2.1 parameter file is now live at `config/scoring_defaults.json`. The `score_v2.py` function picks it up automatically — no code change needed. The schema migration (`schema_v2_migration.sql`) already supports the new dimensions.

**Still needed** (backburner per task #22):
- `bin/score_v2.py` CLI wrapper to batch-score unscored jobs
- Updated skill documentation reflecting v2.1
- Live DB migration run (`sqlite3 data/jobs.db < schema_v2_migration.sql`)

The analytical work here stands regardless of when the machinery completes. You can run numbers against the existing ~30-job RemoteOK corpus now to see a proof-of-concept — expected result: about 3 candidates pass v2.1 vetoes (RemoteOK jobs are mostly W-2 + branded + hard-non-compete), which is consistent with the ~1% corpus acceptance estimate.

---

*Corpus acceptance analysis · v2.1 · 2026-04-23. Clay's parameters in `config/scoring_defaults.json`. All numbers estimated from current-market remote-job posting distributions; recalibrate after first 100 applications observed.*

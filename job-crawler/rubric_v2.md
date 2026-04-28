# Overemployment Scoring Rubric — v2.1
## Deployed 2026-04-23 with Clay's revised defaults: per_job_target=$44,444, N=7, pay_max=$160,000, risk_tolerance=0.85 (Detection Risk 2+)
## See `Corpus_Acceptance_Analysis_20260423.md` for expected filtering behavior at these parameters.

**v1 still available at `rubric.md`.** This is v2. Tag each scored job with `rubric_version`.

## Clay's current parameters (from `config/scoring_defaults.json`)

- `per_job_target`: **$44,444**
- `n_stack`: 7 (implied: $44,444 × 7 ≈ $311,108 stack goal)
- `pay_max`: **$160,000** (absolute ceiling; higher = Pay Position 0)
- `risk_tolerance`: **0.85** (Detection Risk multiplier required to be ≥ 0.85; Detection Risk score 2 or 3 both qualify — "2.2+" guidance means interpret Detection Risk 2 conservatively)

## Scoring structure

8 dimensions, each 0-3. Weighted sum max: **42**. Detection Risk is a multiplier (not in sum).
Three vetoes: Remote=0, Oversight=0, Detection Risk=0 → skip regardless of other scores.

## The 8 dimensions

### 1. Remote Depth (weight ×3 · VETO at 0)
- **3** — Fully remote, enforced by culture (asynchronous, no office-visit requirement, distributed leadership)
- **2** — Fully remote, stated in posting, no visible enforcement mechanism
- **1** — Remote-first with stated travel or occasional on-site (quarterly, annual summit)
- **0** — Hybrid, onsite, or tied to specific metro — **VETO**

### 2. Synchronous Oversight (weight ×3 · VETO at 0)
- **3** — Async-first / ROWE / results-only; no time-tracking, no camera meetings, no daily check-ins
- **2** — Monthly sync; otherwise async
- **1** — Weekly sync meetings; some deadlines but flexible cadence
- **0** — Daily standups, camera-on meetings, or monitoring software (Hubstaff, Time Doctor) — **VETO**

### 3. Detection Risk (MULTIPLIER · VETO at 0)
- **3** — Minimal: 1099 contractor with explicit non-exclusivity; personal hardware; no public presence → **×1.0** multiplier
- **2** — Low: 1099 with no non-moonlighting clause OR W-2 in large anonymous industry + no public identity → **×0.85**
- **1** — Moderate: W-2 with shared benefits brokers, OR 1099 with soft "must disclose" clause → **×0.6**
- **0** — High: W-2 + benefits + public identity + small industry + hard non-compete — **VETO** · ×0

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

### 6. Pay Position (weight ×1.5 · STACK-GOAL RELATIVE) — v2.1 EXTENDED BANDS

Target = **$44,444** annual per role. Max ceiling = **$160,000** (Clay's v2.1 defaults).

Compare to annual-equivalent pay (hourly × 2080 if hourly):

- **3** — 0.9 to 1.1 × target = **$40,000 - $48,889** (sweet spot; exact per-role allocation)
- **2** — 0.7-0.9 × target OR 1.1-1.8 × target = **$31,111 - $40,000 OR $48,889 - $80,000**
- **1** — 0.4-0.7 × target OR 1.8 × target up to max = **$17,778 - $31,111 OR $80,000 - $160,000**
- **0** — < 0.4 × target OR above pay_max = **< $17,778 OR > $160,000**

Note: v2.1 extends the upper band to include jobs up to $160K (scoring 1) rather than auto-zeroing them at the 2× target line. This accommodates senior/specialist roles that remain viable stack components even at higher-than-ideal pay.

### 7. Stakes (weight ×1.5)
- **3** — Low-stakes internal work (internal docs, research, analytics)
- **2** — Internal with reputation risk but not legal/safety
- **1** — Client-facing or externally visible work
- **0** — Legal / medical / safety-critical / regulated

### 8. Onboarding Gauntlet (weight ×1)
- **3** — No formal onboarding; figure-it-out culture
- **2** — Self-directed onboarding with light structure
- **1** — Quarterly review first year; standard corporate onboarding
- **0** — 90-day PIP culture; intensive performance-improvement program during ramp

## Max weighted sum

3×3 + 3×3 + 2×3 + 2×3 + 1.5×3 + 1.5×3 + 1×3 = 9+9+6+6+4.5+4.5+3 = **42**

## Recommendation thresholds (post-multiplier, calibrated to Clay's 0.96 tolerance)

Final score = `weighted_sum × detection_multiplier`

| Final score | Tier | Action |
|---|---|---|
| ≥ 38 | Tier 1 | Priority apply — same day |
| 30 - 37 | Tier 2 | Apply — queue in next batch |
| 22 - 29 | Tier 3 | Maybe — review manually for edge cases |
| < 22 | Skip | Not worth the cycle |

**Additionally**: if detection_multiplier < 0.85, reject regardless of score. This means Detection Risk 2 or 3 qualify.

## Practical filter consequences (v2.1)

With `risk_tolerance = 0.85` and `pay_max = $160,000`:
- Detection Risk 2+ accepted (1099 contractors OR W-2 in large anonymous industries)
- Filters out: W-2 with shared benefits brokers; small-industry positions; hard non-compete clauses
- Pay ceiling extended to $160K (senior/specialist roles remain in play)
- Expected corpus acceptance: **~10-11% of total remote-job corpus** passes all gates and scores ≥ 22 (Tier 3+)
- Of that ~10%, about 1/3 reach Tier 2 (apply) and ~5% reach Tier 1 (priority)
- See `Corpus_Acceptance_Analysis_20260423.md` for detailed estimates

This is a high bar — and correctly so, given stacking-six-roles is itself extreme risk-tolerance in the other direction. The rubric is internally consistent: tight Detection Risk gate + aggressive Pay Position band.

## Red flag keywords (auto-penalty) — unchanged from v1

See `rubric.md` for the full keyword list; all apply to v2.

## Green flag keywords (auto-bonus) — unchanged from v1

See `rubric.md`.

---

*Rubric v2.0 · 2026-04-23 · Clay's defaults baked in. Update `config/scoring_defaults.json` to change parameters without editing the rubric.*

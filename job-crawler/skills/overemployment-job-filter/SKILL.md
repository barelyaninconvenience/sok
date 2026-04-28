---
name: overemployment-job-filter
description: Use this skill whenever the user asks to score, filter, rank, or evaluate a job posting for overemployment suitability (stackable remote work, automatable tasks, low oversight, moderate pay). Triggers include mentions of "score this job," "is this a good overemployment target," "rank these jobs," "apply the rubric," "filter jobs," or when pasting a job description and asking for an evaluation. Also use when asked to compare multiple job postings or produce a shortlist from a job corpus. Do NOT use for general career advice, resume review, or interview prep — those are separate concerns.
---

# Overemployment Job Filter

Score a job posting on 6 dimensions (0-2 each, total /12) for suitability as an overemployment candidate. Criteria target jobs that are automatable, loosely supervised, moderately paid, fully remote, low-stakes, and time-flexible.

## When invoked

The user will provide (or you will fetch from the job-crawler DB) one or more job postings. Apply the rubric below to each.

## The 6-dimension rubric

### 1. Automatability (0-2)
- **2** — Core deliverable is text output: writing, data entry, summarization, email, reports, SOPs, code. AI can do 70%+.
- **1** — Mix; AI does 30-60%.
- **0** — Requires human presence: live video as core, physical work, real-time responsive work, licensed/regulated judgment.

### 2. Oversight (0-2)
- **2** — Async, output-graded, no time-tracking software, no camera-on meetings, no daily standups.
- **1** — Weekly sync meetings, some deadlines, occasional spot-check.
- **0** — Time-tracking software (Hubstaff, Time Doctor), camera surveillance, daily standups, micromanaged.

### 3. Pay (0-2)
- **2** — $50-100k base annual (or $25-50/hr). Moderate sweet spot.
- **1** — $35-50k or $100-130k.
- **0** — Under $35k (not worth it) or over $130k (usually high-stakes/high-oversight).

### 4. Remote authenticity (0-2)
- **2** — "Fully remote", no location language, no office-visit requirement.
- **1** — "Remote-first with occasional travel" — usually fine, flag for follow-up.
- **0** — "Hybrid", "remote with quarterly in-office", tied to a specific metro.

### 5. Stakes (0-2)
- **2** — If you're 20% worse than a normal employee, nothing bad happens.
- **1** — Small real consequences (worse deliverables) but not legal/safety.
- **0** — High stakes: legal, medical, financial, safety-critical, or client-facing where reputation damage compounds.

### 6. Time flexibility (0-2)
- **2** — No set hours; "40 hrs/week when they happen"; no core-hours overlap required.
- **1** — Core hours of 4-6 hrs/day but otherwise flexible.
- **0** — Strict 9-5 in a specific timezone, mandatory synchronous hours, on-call.

## Red flag keywords (auto-penalty)

- "Hubstaff", "Time Doctor", "monitoring software" → oversight 0
- "Daily standup" → oversight ≤ 1
- "Core hours required", "must be available during" → flexibility ≤ 1
- "Client-facing", "face of the company" → stakes 0
- "Licensed professional", "certified" → automatability ≤ 1
- "Video calls" as core responsibility → automatability ≤ 1
- "Hybrid", "in-office quarterly" → remote ≤ 1
- "On-call", "24/7" → flexibility 0

## Green flag keywords (auto-bonus)

- "Async-first", "async communication" → oversight 2
- "Results-only", "ROWE" → oversight 2
- "Fully remote", "work from anywhere" → remote 2
- "Flexible hours", "own your schedule" → flexibility 2
- "Independent contributor", "solo ownership" → oversight +1
- "Documentation-heavy", "writing-focused" → automatability +1

## Output format

For each scored job, return a JSON object:

```json
{
  "score_automatability": 0|1|2,
  "score_oversight": 0|1|2,
  "score_pay": 0|1|2,
  "score_remote": 0|1|2,
  "score_stakes": 0|1|2,
  "score_flexibility": 0|1|2,
  "score_total": 0-12,
  "red_flags": ["short string", "..."],
  "green_flags": ["short string", "..."],
  "verdict": "one sentence, under 150 characters",
  "recommend": "apply" | "maybe" | "skip"
}
```

## Recommendation thresholds

- **≥ 10**: "apply" — strong candidate, prioritize.
- **7-9**: "maybe" — worth deeper review; look at company Glassdoor + recent news.
- **≤ 6**: "skip" — not worth the application time.

## Calibration notes

- If info is missing from the posting, default that dimension to 1 (the middle score), not 0.
- If the job is clearly not remote, `score_remote` must be 0 regardless of other flags.
- The rubric is CONSERVATIVE — better to skip a borderline candidate than to waste application cycles on a poor fit.
- For a shortlist of many jobs, prioritize diversity of company/industry over absolute top-scoring (a shortlist of ten 11/12 jobs all at one company is worse than ten 10/12 jobs across ten companies).

## Batch workflow

When scoring multiple jobs:

1. First-pass quick-filter: read 20 jobs in 5 minutes using only the fast-filter heuristics below. Separate into CUT / MAYBE / PROMOTE buckets.
2. Second-pass rubric: apply the full 6-dimension rubric to MAYBE + PROMOTE only.
3. Third-pass review: for the top 20-30 scored jobs, do company research (Glassdoor, Crunchbase, recent news) before applying.

### Fast-filter instant-cut keywords

- "sales" or "business development" in title
- clinical healthcare role
- "senior" in title (usually higher stakes + oversight)
- "video calls" or "client calls" as core
- "hybrid" or specific office location required

### Fast-filter instant-promote keywords

- technical writing / copywriting
- data entry / data processing
- backend / documentation engineering
- async QA / software testing with ticket-based work
- instructional design
- grant writing

## Context

This skill is part of the `overemployment-pipeline` plugin. The full pipeline lives at `scripts/job-crawler/` and includes scraping (Handshake via CDP, RemoteOK via API, WWR via RSS, etc.), LLM scoring, deduplication, shortlist export, and tailored cover-letter generation. This skill is the rubric-application core; the pipeline is the end-to-end automation.

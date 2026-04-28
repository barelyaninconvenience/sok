---
description: Score a job posting against the overemployment 6-dimension rubric
---

# /score-job

Paste a job posting below (title, company, pay, description). I'll apply the overemployment rubric and return a structured score.

## What happens

1. I invoke the `overemployment-job-filter` skill.
2. I apply the 6-dimension rubric (automatability, oversight, pay, remote, stakes, flexibility).
3. I return JSON with scores, red flags, green flags, verdict, and recommendation.

## Usage

```
/score-job
```

Then paste the job posting text. Or pipe a URL if you want me to fetch (requires access).

## Example input

```
Title: Remote Technical Writer
Company: Acme Docs
Pay: $70,000 - $85,000
Description:
We're a fully-remote, async-first documentation team. Write developer-facing docs, API references, and tutorials. No client calls. Flexible hours, results-only work environment. Monthly team meeting only.
```

## Example output

```json
{
  "score_automatability": 2,
  "score_oversight": 2,
  "score_pay": 2,
  "score_remote": 2,
  "score_stakes": 2,
  "score_flexibility": 2,
  "score_total": 12,
  "red_flags": [],
  "green_flags": ["async-first", "results-only", "fully-remote", "flexible hours", "no client calls"],
  "verdict": "Ideal target: text output, async, fully remote, moderate pay, low stakes.",
  "recommend": "apply"
}
```

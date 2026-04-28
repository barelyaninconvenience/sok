---
name: company-research
description: Use this skill when the user wants to research a company before applying to a job, including checking Glassdoor reviews, company size, recent news, funding status, layoffs history, or red flags. Triggers include "research this company," "is Company X a good place to work," "Glassdoor rating," "is this company legit," "background check this company." Use BEFORE finalizing an application decision for any job that passed the rubric (score ≥ 9). Do NOT use for companies clearly in the user's existing network or for well-known brands where research is redundant.
---

# Company Research

Evaluate a company across 6 axes before an application is sent. Fast-pass research: 10-15 minutes per company.

## When invoked

User names a company (from a scored job posting, usually). Apply the checklist below.

## The 6-axis check

### 1. Size + stability
- How many employees? (LinkedIn, Crunchbase)
- Public / private / startup / growth stage?
- Revenue / funding if disclosed?
- Time in market (founded year)?

**Red flag**: <10 employees for a non-technical role you're remotely auditioning for.

### 2. Glassdoor sentiment
- Overall rating (out of 5)
- CEO approval rating
- Sample of reviews: look for repeated patterns in 1-2-star reviews
- Interview-difficulty rating

**Red flag**: < 3.0 overall, or CEO approval < 50%, or consistent "management chaos" in recent reviews.

### 3. Recent news + layoffs
- Recent press (company name + "news" + current year)
- Layoffs in the past 12 months? (layoffs.fyi is authoritative)
- M&A activity — being acquired usually means upheaval
- Funding rounds, valuation shifts

**Red flag**: Layoffs in last 6 months + you'd be in the same department that was cut.

### 4. Remote-work authenticity
- Do employees on LinkedIn actually have remote as location?
- Is remote policy written in job posting vs. implied?
- Any mentions of "remote-first" vs "remote-friendly" in company materials?
- Is the CEO remote? (signal about culture)

**Red flag**: "Remote" in job posting but 90%+ of employees list the HQ city.

### 5. Manager / team signal
- If the job posting lists a manager/recruiter name, search them on LinkedIn
- Check tenure — is the manager new? (sometimes a signal of churn)
- What does their previous team say about working with them?
- Mutual connections you could ask?

**Red flag**: Manager has cycled through 3+ companies in 2 years, or has notable public drama.

### 6. Financial stability (for private/startup roles)
- Last funding round (Crunchbase)
- Estimated runway based on round size + reported burn
- Recent fundraising pace (accelerating = healthy, slowing = concern)
- News of CFO or CEO departures

**Red flag**: Last fundraise > 24 months ago + no revenue growth narrative.

## Sources to hit (priority order)

1. **LinkedIn** — company page, employee count, recent posts, leadership bios
2. **Glassdoor** — overall rating, sample reviews, interview process descriptions
3. **Crunchbase** — funding, founding date, acquisitions, board
4. **layoffs.fyi** — layoff database
5. **Google News** — recent coverage (last 6 months)
6. **Reddit** (subreddits: r/cscareerquestions, r/jobs, company-specific subs if any)
7. **Company's own careers page** — does it match the posting? Are they hiring across many roles (growth) or just this one (desperation)?

## Output format

For each company researched, return a structured report:

```markdown
## Company Research: [Company Name]

**Stage**: [Startup / Growth / Public / Private Enterprise]
**Employees (LinkedIn)**: [N]
**Founded**: [Year]

### Signals

| Axis | Rating | Notes |
|---|---|---|
| Size + stability | 🟢/🟡/🔴 | One-line |
| Glassdoor sentiment | 🟢/🟡/🔴 | Overall + recent trend |
| News / layoffs | 🟢/🟡/🔴 | Any recent events |
| Remote authenticity | 🟢/🟡/🔴 | Actual remote or in-name-only |
| Team / manager | 🟢/🟡/🔴 | If identifiable |
| Financial | 🟢/🟡/🔴 | For private/startup |

### Top red flags

- ...

### Top green flags

- ...

### Recommendation

**Apply** / **Apply with caveats** / **Skip**

[One-paragraph rationale]
```

## Calibration

- 4-6 green signals + 0-1 red: **Apply**.
- 2-3 green + 1-2 yellow: **Apply with caveats** (flag the yellows during interview).
- 2+ red signals, or 1 red + multiple yellows: **Skip**.
- When in doubt: skip. Application time is finite; the next company is 15 minutes away.

## What NOT to spend time on

- Stock price movements for public companies (not relevant to IC roles)
- Sentiment analysis of social media (too noisy)
- Detailed financial modeling (beyond signal-level)
- Product reviews (you're evaluating the company as employer, not as customer)

The research should take 10-15 minutes per company. If it's taking 45 minutes, you're over-investing. Finite time = finite research budget.

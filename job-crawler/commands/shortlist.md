---
description: Export the current shortlist of scored jobs from the pipeline DB
---

# /shortlist

Export the current shortlist (score ≥ 9) from the job-crawler DB to a CSV, then summarize the top 10.

## What happens

1. Runs `python scripts/job-crawler/bin/shortlist.py --min-score 9`.
2. Reads the resulting CSV.
3. Returns a markdown table of the top 10 with: company, title, pay, score, recommendation, red flags.

## Usage

```
/shortlist [--min-score N]
```

Default min-score is 9. For a broader sweep: `/shortlist --min-score 7`.

## When to use

- After running a scrape + score pass and wanting a prioritized application queue.
- Before a weekly application-sending session.
- To review how the corpus has shifted after new scraping runs.

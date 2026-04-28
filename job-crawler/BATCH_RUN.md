# Running the 1000-Job Handshake Batch

## What this does

Scrapes all remote jobs from Handshake (up to 1000), dry-scores them (free, heuristic), LLM-scores the ones that pass heuristic, dedupes, and emits a shortlist CSV.

Expected timing:
- **Scraping**: ~45-60 minutes (2.5s per job × 1000 jobs)
- **Dry scoring**: ~1 minute (free)
- **LLM scoring**: ~5-10 minutes, ~$2-5 (only the ~20-30% that pass heuristic threshold)
- **Dedupe + shortlist**: ~1 minute

Total: ~1 hour end to end.

## Prerequisites

```bash
cd scripts/job-crawler
pip install -r requirements.txt
pip install playwright
playwright install chromium

# One-time: initialize DB
python bin/scrape.py --source remoteok --limit 1 --init-db   # creates jobs.db with schema

# Set API key (one-time per session)
export ANTHROPIC_API_KEY="..."   # or set in Windows: $env:ANTHROPIC_API_KEY="..."
```

## Step-by-step

### 1. Launch Chrome with debugging port

Close all Chrome windows first (important — Chrome can only have one debugging session per profile).

PowerShell:
```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" `
    --remote-debugging-port=9222 `
    --user-data-dir="$env:LOCALAPPDATA\Google\Chrome\User Data"
```

You should see your usual Chrome with all your tabs and extensions.

### 2. Log into Handshake

In this Chrome, navigate to `https://app.joinhandshake.com/` and log in through UC SSO. Keep the tab open; the script will use this same authenticated session.

### 3. Pick a search URL

Go to Handshake's job search, apply filters (remote, your desired pay range, etc.), and copy the URL. Example:

```
https://app.joinhandshake.com/job-search/?pay[salaryType]=1&remoteWork=remote&per_page=25&page=1
```

### 4. Run the scraper (background)

PowerShell:
```powershell
cd C:\Users\shelc\Documents\Journal\Projects\scripts\job-crawler
Start-Process pwsh -ArgumentList @(
    "-NoProfile",
    "-Command",
    "py -3.14 lib/sources/handshake_playwright.py --search-url 'https://app.joinhandshake.com/job-search/?pay[salaryType]=1&remoteWork=remote&per_page=25&page=1' --max-jobs 1000 --delay 2.5 > data/handshake_batch_$(Get-Date -Format 'yyyyMMdd-HHmm').log 2>&1"
) -WindowStyle Hidden
```

The log file tracks progress. You can monitor it with:
```powershell
Get-Content data\handshake_batch_*.log -Tail 10 -Wait
```

### 5. While scraping runs — dry-score incrementally (optional)

In a separate terminal you can run `python bin/dry_score.py` to pre-filter as jobs come in.

### 6. When scraping finishes

```bash
# See how many jobs landed
python bin/stats.py

# Dry-score everything unscored (free)
python bin/dry_score.py --threshold 7

# LLM-score whatever dry-score flagged (cost: ~$2-5)
python bin/score.py --model claude-sonnet-4-6

# Dedupe
python bin/dedupe.py

# Export shortlist
python bin/shortlist.py --min-score 10 --out data/handshake_shortlist.csv
```

### 7. Review the shortlist

Open `data/handshake_shortlist.csv` in Excel or `csvkit`. Sort by `score_total` descending. For the top 20-30, inspect the `description_md` field in the DB to decide which to apply to.

## Troubleshooting

**"Failed to connect to Chrome at localhost:9222"** — Chrome isn't running with the debugging port, or a different Chrome session is using it. Close all Chrome and restart with the command in step 1.

**Scraper stops after 50 jobs** — Handshake may be throttling. Increase `--delay` to 5.0 and retry. If it fails again, reduce `--max-jobs` and run multiple smaller batches.

**Titles / companies empty in DB** — the CSS selectors in `handshake_playwright.py` may need tuning. Open one Handshake job page, right-click → Inspect, find the actual selectors, and update `SELECTORS` dict in that file.

**Out of API budget** — use `--no-llm` on the pipeline to get heuristic scores only; those are free.

## Running as a true background job (overnight-safe)

```powershell
# As a scheduled task
$action = New-ScheduledTaskAction -Execute "pwsh" -Argument "-File C:\Users\shelc\Documents\Journal\Projects\scripts\job-crawler\run_batch.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "HandshakeBatch-Once"
```

But for a one-off run, `Start-Process` with `-WindowStyle Hidden` is simpler.

## Alternatives if Playwright path doesn't work

**Fallback 1: Chrome MCP driven by Claude Code.** Slower (one URL per Claude turn) but works without Playwright. Ask Claude to drive the plan at `data/raw/handshake/plan.json`.

**Fallback 2: Paste + parse.** Open each Handshake page, copy-paste the description into a file, and call `ingest_handshake_chrome()` per file. Laborious but always works.

# Overemployment Pipeline (Job Crawler + Plugin)

**Status**: MVP complete, smoke-tested (5/5 pass), packaged as a Claude Code plugin with 2 skills + 3 slash commands + MCP server. 2026-04-23.

**Quick links**:
- **[BATCH_RUN.md](BATCH_RUN.md)** — 1000-job Handshake batch via Playwright-over-CDP
- **[INSTALL_AS_PLUGIN.md](INSTALL_AS_PLUGIN.md)** — Install as a Claude Code plugin
- **[rubric.md](rubric.md)** — The 6-dimension scoring rubric
- **[skills/overemployment-job-filter/SKILL.md](skills/overemployment-job-filter/SKILL.md)** — Skill definition of the rubric
- **[mcp/server.py](mcp/server.py)** — MCP server exposing the DB as 6 Claude-callable tools

A multi-site job-posting crawler + LLM-based scoring + shortlist + cover-letter pipeline for the overemployment endeavor.

## Architecture

```
Chrome MCP (authed)   crawl4ai (public)
        \                /
         ↓              ↓
       normalize.py (common schema)
             ↓
       score.py (LLM rubric)
             ↓
       storage.py (SQLite + JSONL)
             ↓
       shortlist.py (CSV export)
             ↓
       cover_letter.py (tailored materials)
```

## Quick start

```bash
cd scripts/job-crawler
python -m venv .venv
.venv\Scripts\activate       # Windows
# source .venv/bin/activate  # macOS/Linux
pip install -r requirements.txt

# Initialize DB
sqlite3 data/jobs.db < schema.sql

# Scrape a source (public)
python bin/scrape.py --source remoteok --limit 50

# Scrape Handshake (Chrome MCP — requires authenticated browser session)
python bin/scrape.py --source handshake --urls data/handshake_urls.txt

# Score unscored jobs
python bin/score.py --unscored --model claude-sonnet-4-6

# Export shortlist (score >= 9)
python bin/shortlist.py --min-score 9 --out data/shortlist_$(date +%Y%m%d).csv

# Generate cover letter for a specific job
python bin/cover_letter.py --job-id abc123 --resume my_resume.md
```

## Components

- `lib/normalize.py` — NormalizedJob dataclass, parsers for pay / remote / location
- `lib/score.py` — LLM scoring against the 6-dimension rubric
- `lib/storage.py` — SQLite helpers (init, insert, query, update)
- `lib/sources/handshake.py` — Chrome MCP driver for Handshake
- `lib/sources/remoteok.py` — RemoteOK API client (public)
- `lib/sources/crawl4ai_generic.py` — Generic crawl4ai wrapper
- `lib/dedup.py` — Detect same job across sites
- `lib/cover_letter.py` — Generate tailored application materials
- `bin/scrape.py` — Unified scraping CLI
- `bin/score.py` — Batch scoring CLI
- `bin/shortlist.py` — Shortlist export CLI
- `bin/cover_letter.py` — Cover letter generation CLI
- `schema.sql` — SQLite schema
- `rubric.md` — The 6-dimension scoring rubric (from `Writings/Handshake_Job_Filter_Framework_20260423.md`)

## Data model

- **sources**: metadata for each job board
- **raw_jobs**: normalized scraped data
- **scored_jobs**: jobs with LLM rubric scores
- **applications**: tracking for Clay's actual applications (status, dates, notes)
- **dedupe_groups**: groups of near-duplicate postings across sites

## Chrome MCP usage

For authenticated sites (Handshake, LinkedIn, Indeed, Wellfound):
1. Open Chrome manually, log into each site
2. Launch Claude Code with Chrome MCP loaded
3. Run `bin/scrape.py --source <site>` which invokes Chrome MCP tools
4. The script reuses Clay's browser session — no credential management

## Design principles

- **Non-destructive**: never deletes previously-scraped data; new runs append
- **Resumable**: scraping can be interrupted and resumed
- **Rate-limited**: respects `time.sleep` between requests to avoid anti-bot flags
- **Auditable**: raw HTML / markdown backup for every scraped job
- **Reversible**: every scrape is timestamped; can roll back to a prior snapshot

## Not yet implemented

- LinkedIn / Indeed / Wellfound source modules (Phase 3)
- Daily digest email (Phase 4)
- Application-tracker UI (Phase 4)
- Cover-letter module is scaffolded but needs a resume to operate on

## See also

- `Writings/Handshake_Job_Filter_Framework_20260423.md` — the scoring rubric
- `Writings/Job_Crawler_Pipeline_Design_20260423.md` — architectural design

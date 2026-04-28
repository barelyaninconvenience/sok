# n8n Future Workflow Specifications

**Authored:** 2026-04-21
**Purpose:** detailed specs for the 4 future n8n workflows noted in `README.md` — daily-digest / knowledge-base-health / monitoring / content-pipeline. Each spec is implementation-ready; import-and-adapt when the corresponding use case activates.

---

## Workflow 1: daily-digest-workflow

**Trigger:** cron daily at 07:00
**Purpose:** generate a morning briefing summarizing yesterday's Claude Code session activity + git commits + completed tasks + upcoming priorities for today.
**Alignment:** per `Writings/Async_Communication_Patterns_20260421.md` Pattern 1 (voluntary status updates — self-applied) + Operating Stack section 1 cost-awareness (audit what you spent)

### Node sequence

```
cron-0700
  │
  ├─► fetch-claude-code-sessions (gather session logs from prior day)
  │     - Source: ~/.claude/projects/*/conversations/ (JSONL session files)
  │     - Filter: last 24h mtime
  │     - Output: list of session IDs + tokens + artifact counts
  │
  ├─► fetch-git-activity (commits across Clay's repos in last 24h)
  │     - Source: GitHub API via gh CLI (credential: gh-token from Windows Cred Manager)
  │     - Query: commits by shelc / caddellhomestead across their repos
  │     - Output: commit messages + repos + timestamps
  │
  ├─► fetch-calendar-priorities (today's calendar events + this-week open tasks)
  │     - Source: Google Calendar API
  │     - Query: today's events + next-7-day events
  │     - Output: event list with role-labels
  │
  ├─► merge-all-signals (combine claude + git + calendar)
  │
  ├─► synthesize-via-claude (generate digest)
  │     - Model: Claude Haiku 4.5 (cheap, appropriate for digest summarization)
  │     - SINC-format preamble (see template in prompt below)
  │     - Max tokens: 500
  │
  ├─► post-to-notion (Briefmatic task or Notion daily log)
  │     - Destination: Notion page for daily logs
  │
  └─► notify-via-ntfy (push to phone)
        - Topic: daily-digest
        - Title: "Daily Digest [YYYY-MM-DD]"
```

### SINC-formatted Claude prompt for the digest

```
[PERSONA] You are a chief-of-staff writing a 200-word morning brief for a technical operator.

[CONTEXT] The operator juggles multiple role-projects. He reads this brief while drinking coffee. It must be scannable in 60 seconds.

[DATA] The following signals cover the last 24 hours:
- Claude Code sessions: {{ session_data }}
- Git activity: {{ git_data }}
- Today's calendar: {{ calendar_data }}

[CONSTRAINTS] No filler. No "good morning!" greetings. No hedging. Use active voice.

[FORMAT]
- Yesterday's top 3 outputs (1 line each, bullet)
- Today's top 3 priorities (1 line each, bullet)
- 1 flag / concern (if any, else omit)

[TASK] Produce the brief.
```

### Credentials required

- `CLAUDE_CODE_SESSIONS_PATH` env var
- GitHub PAT in Windows Credential Manager (via gh auth)
- Google Calendar OAuth (n8n credential)
- Notion API token (Set-SOKSecret -Name 'NOTION_API_TOKEN')
- Anthropic API key (or route via Claude Code MCP)
- ntfy.sh topic name

### Expected output

Single Notion page per day + ntfy push to phone. <500 tokens of LLM generation per day = negligible cost.

---

## Workflow 2: knowledge-base-health-workflow

**Trigger:** cron weekly Sunday at 21:00
**Purpose:** monitor Supabase knowledge_assets + knowledge_chunks health. Flag stale documents, domain coverage gaps, retrieval-quality drift.
**Alignment:** per `KLEM_OS_Unified_20260420.html` §I.7.4 (Knowledge Base Health Monitoring)

### Node sequence

```
cron-sunday-21
  │
  ├─► query-supabase-stats
  │     - Count total knowledge_assets, knowledge_chunks
  │     - Aggregate by domain + source_type
  │     - Flag assets with updated_at > 6 months old
  │     - Identify domains with <threshold chunk count
  │
  ├─► run-retrieval-quality-test (sample queries)
  │     - Execute 5-10 canonical queries against knowledge_chunks
  │     - Compare top-10 results against expected gold set (stored in Supabase test table)
  │     - Calculate precision@5, recall@10
  │
  ├─► synthesize-report-via-claude
  │     - Model: Claude Sonnet 4.6 (mid-tier for analysis)
  │     - Inputs: stats + quality metrics + flagged items
  │     - SINC-format preamble for health-report structure
  │
  ├─► post-report-to-supabase (health_reports table)
  │     - Stores weekly snapshot for trend tracking
  │
  └─► email-weekly-report (if concerning patterns)
        - Email Clay: "Knowledge Base Health Week-Of-[Date]"
        - Trigger: only if quality dropped >5% or coverage gap flagged
```

### Alerting thresholds

- Precision@5 drop >5% WoW → notify
- Recall@10 drop >5% WoW → notify
- Any domain with 0 chunks added in >60 days → flag as coverage gap
- Embedding model version mismatch (mixed embeddings from different generations) → flag for re-embed

---

## Workflow 3: monitoring-workflow

**Trigger:** cron daily at 06:00
**Purpose:** check external sources for Clay's research domains; dedup; ingest new into knowledge base; briefing summary.
**Alignment:** per `KLEM_OS_Unified_20260420.html` §I.5.1 Monitoring Workflows

### Node sequence

```
cron-0600
  │
  ├─► check-job-boards (via Exa or Bardeen)
  │     - ClearanceJobs.com + USAJobs.gov + Indeed.com for target roles
  │     - Keyword list in Supabase config table
  │     - Output: new postings matching keywords + filter (last-24h)
  │
  ├─► check-nist-ieee-iso (regulatory + research feeds)
  │     - Source: RSS feeds / API polling
  │     - Domains: AI governance, cybersecurity, acoustic side-channels
  │     - Output: new publications since last check
  │
  ├─► check-regulatory-feeds
  │     - AI Act updates, right-to-repair, cleared-hiring policy changes
  │     - Source: specific .gov RSS / API endpoints
  │     - Output: new items
  │
  ├─► dedup-against-knowledge-base
  │     - Check each new item against knowledge_assets (by URL + title hash)
  │     - Skip already-ingested
  │
  ├─► ingest-new-items (RAG pipeline)
  │     - Parse via Unstructured MCP
  │     - Chunk + embed via OpenAI text-embedding-3-small
  │     - Insert into Supabase via supabase-mcp
  │
  ├─► generate-briefing-summary (Claude Haiku)
  │     - For each new item: 1-sentence summary + relevance-to-Clay's-work score (0-5)
  │
  └─► email-daily-intelligence-brief (if ≥3 relevance-score-3+ items)
        - "Daily Intelligence Brief [YYYY-MM-DD]"
        - Ranked by relevance score
```

### Relevance-score heuristics

- Score 5: directly matches Clay's PhD research (acoustic side-channels, autonomous covert channels)
- Score 4: matches Substrate Thesis vertical (FKS / SCC / SRD / degraded ops)
- Score 3: matches cleared-cyber or defense-AI career path
- Score 2: matches broader AI/governance
- Score 1: tangentially relevant

Only scores 3+ fire the brief. Lower scores ingest silently.

### Credentials

- Exa API key (via exa-mcp after credential remediation)
- NIST/IEEE feed URLs (public)
- Job board API keys or Bardeen playbook config
- OpenAI API key (embeddings)

---

## Workflow 4: content-pipeline-workflow

**Trigger:** cron weekly Sunday at 20:00
**Purpose:** review new knowledge base ingestions + highest-rated sessions from the week → generate content drafts for LinkedIn / Twitter / blog.
**Alignment:** per `KLEM_OS_Unified_20260420.html` §II.3 Content Pipeline

### Node sequence

```
cron-sunday-20
  │
  ├─► query-new-knowledge-assets (last 7 days)
  │     - Filter: created_at >= 7 days ago
  │     - Include: title + domain + summary + source_type
  │
  ├─► query-top-rated-sessions (last 7 days)
  │     - From session_logs: quality_score top 5
  │     - Include: prompt_summary + response_summary
  │
  ├─► identify-content-candidates (Claude Sonnet)
  │     - Prompt: "From these inputs, identify 2-3 insights worth publishing.
  │              For each: what audience, what format (LinkedIn/Twitter/blog),
  │              what's the core claim?"
  │     - Output: candidate list with targeting
  │
  ├─► generate-drafts (Claude Sonnet, per candidate)
  │     - LinkedIn: 300-500 words, professional tone, soft CTA
  │     - Twitter thread: 5-8 tweets, punchy, no filler
  │     - Blog topic: outline + first 200 words if substantive
  │     - SIR quality gate applied via post-generation check
  │
  ├─► store-drafts-in-supabase (content_pipeline table, status=draft)
  │
  └─► email-operator-for-review
        - "Weekly Content Drafts [YYYY-MM-DD]"
        - Links to drafts + one-paragraph summary each
```

### Publishing flow (post-operator-review)

The workflow stops at drafts. Clay reviews, edits, approves. A separate workflow (not specced here) handles approved-drafts → platform-specific posting via Zapier or platform APIs.

This human-in-the-loop gating is per `Writings/Async_Communication_Patterns_20260421.md` discipline.

---

## Deployment sequencing

Recommended order (lowest complexity first):

1. **daily-digest** — single-day scope, low credential complexity, immediate daily value
2. **knowledge-base-health** — requires Supabase MCP + test-set curation; ~2 weeks after daily-digest
3. **monitoring** — requires external feed subscriptions + relevance-scoring calibration; ~1 month
4. **content-pipeline** — requires all prior workflows + Clay's content approval pattern; ~2 months

None of these are urgent. Deploy when specific needs justify them.

---

## Cross-references

- `Projects/scripts/n8n-workflows/README.md` — overview
- `Projects/scripts/n8n-workflows/calendar-control-workflow.json` — first concrete workflow (implemented)
- `Writings/KLEM_OS_Cost_and_Architecture_v3_20260421.md` — architectural context
- `Writings/Async_Communication_Patterns_20260421.md` — discipline alignment
- `Projects/scripts/custom-mcps/n8n-control-mcp/` — MCP for orchestrating these workflows from Claude Code

---

*Four specs. Each activates independently when justified. n8n handles async; Claude Code handles sync. Together they cover both axes.*

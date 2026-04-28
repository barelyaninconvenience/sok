# n8n Workflows — KLEM/OS v3 Asynchronous Orchestration

**Purpose:** staging for n8n workflow definitions that handle asynchronous / cron-triggered / unattended workflows. Complements Claude Code (synchronous, operator-attended) per KLEM/OS v3 Part E (n8n narrowed to async/cron after custom MCPs cover synchronous integration).

---

## Workflow inventory

### calendar-control-workflow.json

**Purpose:** hourly audit of multi-role calendars to detect block violations. Per `Writings/Multi_Role_Calendar_Setup_20260421.md` + `Writings/Operating_Stack_v1_4_L15_Delta_20260421.md`.

**Detects:**
- Cross-role contamination (Job A event in Job B block or vice versa)
- Deep-work-block intrusion (meeting during declared focus window)
- Back-to-back events (<15min gap, breaks L-15 ramp-up)

**Notifies:** Clay via ntfy.sh topic (or Slack / email with credential swap)

**Activation:**

1. Import workflow into n8n (copy `calendar-control-workflow.json` content into n8n Import Workflow UI)
2. Create Google Calendar OAuth credentials per role:
   - Job A OAuth (scoped to Job A Google account)
   - Job B OAuth (scoped to Job B Google account)
3. Configure n8n env vars:
   - `JOBA_CALENDAR_ID` — Job A primary calendar ID
   - `JOBB_CALENDAR_ID` — Job B primary calendar ID
   - `NTFY_TOPIC` — your ntfy.sh topic name (or swap to Slack webhook URL)
4. Activate the workflow

**Single-role operation:** disable the Job B branch (delete `fetch-jobb-events` node or set inactive). Workflow still detects deep-work-block intrusions + back-to-back violations on the single role.

**Customization points:**

- Block definitions (JOBA_BLOCK_START / etc.) in `detect-violations` function node — adjust to match your actual schedule
- Minimum gap between events (MIN_GAP_MIN, default 15) — adjust based on your personal L-15 ramp-up measurement
- Notification channel (currently ntfy.sh) — swap for Slack / Teams / email per preference

---

## Future workflows (planned, not yet authored)

### daily-digest-workflow.json

Per async Pattern 1 (voluntary status updates) + Operating_Stack orchestration:

- Morning trigger (7am)
- Gather previous-day Claude Code session logs + git commits + completed tasks
- Synthesize via Claude Haiku (cheap LLM for digest generation)
- Post to Notion / Slack / email

### knowledge-base-health-workflow.json

Per KLEM_OS_Unified §I.7.4 (Knowledge Base Health Monitoring):

- Weekly trigger (Sunday evening)
- Query Supabase for knowledge_assets + knowledge_chunks statistics
- Flag stale documents (>6 months no update)
- Detect domain coverage gaps
- Generate monthly "Knowledge Base Health Report"

### monitoring-workflow.json

Per KLEM_OS_Unified §I.5.1 (Monitoring Workflows):

- Daily trigger (6am)
- Check job boards for target role keywords (web scrape via Bardeen API or Exa MCP)
- Check NIST/IEEE/ISO for new AI governance publications
- Dedup against existing knowledge base
- Ingest new items + generate briefing summary

### content-pipeline-workflow.json

Per KLEM_OS_Unified §II.3 (Content Pipeline):

- Weekly trigger (Sunday 8am)
- Query knowledge base for new ingestions + highest-rated sessions
- Generate content drafts (LinkedIn post / Twitter thread / blog topic)
- Store in Supabase content_pipeline table
- Email Clay: "Weekly content drafts ready for review"

These are specified but not yet authored. Build on demand as specific roles / workflows activate.

---

## Design principles

### 1. n8n handles async; Claude Code handles sync

Per KLEM/OS v3 Part E: custom MCPs + Claude Code are for interactive/synchronous work. n8n handles:

- Cron-triggered workflows (nothing needs a human present)
- Long-running ingestions
- Monitoring / alerting
- Multi-step orchestrations that would consume too much Claude Code context

### 2. Self-hosted for data sovereignty

Per Operating Stack + KLEM/OS v3: n8n runs self-hosted on VPS (Hetzner / DigitalOcean / Linode $6-12/mo). No n8n Cloud lock-in.

### 3. Stack-compliant workflow design

- Use Claude Haiku ($0.80/MTok input) for high-volume low-complexity workflow tasks (classification, summarization, triage)
- Use Claude Sonnet ($3/MTok input) for analysis / synthesis / content generation
- Reserve Claude Opus ($15/MTok input) for critical-path outputs only
- Per v3 Part B: route through Claude Code / Max subscription for interactive work; direct API for nightly cron where Max session isn't active

### 4. Role-scoped where applicable

For overemployment scenarios: workflows that touch role-specific data (Job A calendar, Job B CRM) must use role-scoped credentials. Store per-role credentials in DPAPI via `Set-SOKSecret -Name '<ROLE>_<SECRET>'`.

---

## Deployment

### Self-hosted n8n (recommended)

```bash
# On VPS
docker run -d --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=<strong-password> \
  n8nio/n8n
```

Access at `http://<vps-ip>:5678` (or behind Tailscale for security).

### Credentials

n8n's credential system stores OAuth tokens + API keys encrypted on disk. Use n8n UI to create:

- Google Calendar OAuth per role
- Supabase API (for knowledge-base workflows)
- Anthropic API (for LLM-driven workflows)
- OpenAI API (for embedding-driven workflows)
- ntfy.sh / Slack / email (for notifications)

Prefer creating per-workflow credentials over shared credentials — easier to rotate, easier to scope.

---

## Monitoring n8n itself

- **n8n execution history** built into the UI — review weekly for failed workflows
- **n8n webhook status** — any workflow triggered via webhook should log success/failure
- **Disk usage** on VPS — n8n logs can grow; rotate periodically

---

## Cross-references

- `Writings/KLEM_OS_Cost_and_Architecture_v3_20260421.md` Part E — n8n role in v3 stack
- `Writings/Multi_Role_Calendar_Setup_20260421.md` — calendar-control context
- `Writings/Async_Communication_Patterns_20260421.md` Pattern 5 — calendar discipline source
- `Writings/Operating_Stack_v1_4_L15_Delta_20260421.md` — L-15 back-to-back constraint source
- `Projects/scripts/custom-mcps/n8n-control-mcp/` — MCP for orchestrating n8n workflows from Claude Code
- `Projects/scripts/role-scoped-deployments/` — per-role credential namespacing pattern

---

*Asynchronous orchestration is n8n. Synchronous interaction is Claude Code. Together they cover both axes.*

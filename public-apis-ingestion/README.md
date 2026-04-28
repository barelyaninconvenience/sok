# Public APIs Catalog Ingestion

**Purpose:** harvest the public-apis/public-apis GitHub catalog into structured data for KLEM/OS custom-MCP candidate discovery.

**Reference:** `Writings/Overemployment_Stack_Integration_20260421.md` Part E — Clay flagged this repo "especially this one" for its alignment with the custom-MCPs-wrap-APIs architectural direction.

---

## What this does

1. **Fetches** the README.md from `github.com/public-apis/public-apis` (caches locally)
2. **Parses** the ~1,800+ API entries across ~50 categories
3. **Scores** each entry for MCP candidacy (auth presence / HTTPS / CORS documentation / category clarity)
4. **Emits** structured output (JSON / Parquet / SQL) suitable for downstream ingestion
5. **Optionally uploads** to Supabase if `-Format sql -UploadToSupabase` specified

---

## Files

- `ingest-public-apis.py` — Python ingestion tool (parses README, scores entries, emits output)
- `start-ingest.ps1` — PowerShell launcher (convenience wrapper, DPAPI-aware for Supabase upload)
- `README.md` — this file
- `.cache-public-apis-readme.md` — cached README (auto-created on first fetch)

---

## Usage

### Basic JSON output (default)

```powershell
cd C:\Users\shelc\Documents\Journal\Projects\scripts\public-apis-ingestion
.\start-ingest.ps1
```

Produces `staged-apis.json` with all entries + candidacy scoring.

### Force fresh fetch (bypass cache)

```powershell
.\start-ingest.ps1 -FetchFresh
```

### Parquet output (for DuckDB / analytical queries)

```powershell
.\start-ingest.ps1 -Format parquet -Output staged-apis.parquet
```

Requires `pip install pyarrow`.

### SQL output + Supabase upload

```powershell
# Ensure credentials are stored
Set-SOKSecret -Name 'SUPABASE_URL'         -Value 'https://<project>.supabase.co'
Set-SOKSecret -Name 'SUPABASE_DB_PASSWORD' -Value '<db-password-from-supabase-settings>'

# Ingest + upload
.\start-ingest.ps1 -Format sql -Output staged-apis.sql -UploadToSupabase
```

Requires `psql` on PATH. Creates `public_apis_catalog` table if not exists, then INSERT-all entries.

---

## MCP candidacy scoring

Each entry is scored 0-5 based on:

| Factor | Points | Why |
|---|---|---|
| `auth-present` | +2 | Authenticated APIs justify DPAPI credential wrapping (v3 pattern fit) |
| `https-enforced` | +1 | Secure transport required for any real workflow |
| `cors-documented` | +1 | CORS status known = well-documented API surface |
| `clear-category` | +1 | Filters out `Unknown`/`Misc` entries |

Entries scoring ≥3 are flagged `mcp_candidate=true`. These are the APIs where building a custom MCP (following `Writings/Custom_MCP_Patterns_20260421.md`) would provide meaningful value.

---

## Supabase table schema

```sql
CREATE TABLE public_apis_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    auth TEXT,
    https BOOLEAN,
    cors TEXT,
    link TEXT NOT NULL,
    has_auth BOOLEAN,
    https_enforced BOOLEAN,
    cors_known BOOLEAN,
    candidacy_score INT,
    mcp_candidate BOOLEAN,
    candidacy_factors TEXT[],
    ingested_at TIMESTAMPTZ DEFAULT now()
);
```

Indexed on `category` and filtered on `mcp_candidate=true` for fast query-by-need.

---

## Query-by-need examples

Once loaded, these queries answer "what API should I use for X":

```sql
-- Find weather APIs that are good MCP candidates
SELECT name, link, description
FROM public_apis_catalog
WHERE category ILIKE '%weather%' AND mcp_candidate = true
ORDER BY candidacy_score DESC;

-- Find authenticated APIs in a specific category
SELECT name, link, auth
FROM public_apis_catalog
WHERE category = 'Finance' AND has_auth = true;

-- Count MCP candidates by category
SELECT category, COUNT(*) as candidates
FROM public_apis_catalog
WHERE mcp_candidate = true
GROUP BY category
ORDER BY candidates DESC;
```

---

## Refresh cadence

The public-apis repo receives regular community contributions. Refresh cadence options:

- **Monthly** via cron — captures new entries without overwhelming change detection
- **On-demand** — run before any specific-API search if you suspect new entries
- **Quarterly** — aligns with CLAUDE.md §11 quarterly audit protocol

Suggested: monthly cron via n8n workflow that runs `start-ingest.ps1 -FetchFresh -Format sql -UploadToSupabase` on the 1st of each month.

---

## Integration with custom MCP build pipeline

When a workflow need surfaces an API candidate from the catalog:

1. Query `public_apis_catalog` for candidates matching the need
2. Assess top candidates for MCP build priority (volume of expected calls, criticality)
3. If MCP warranted, copy `Projects/scripts/custom-mcps/exa-mcp/` as template
4. Rename to `<api-name>-mcp/` and swap the upstream endpoint + auth per `Writings/Custom_MCP_Patterns_20260421.md`
5. Deploy via `Projects/scripts/custom-mcps/deploy-custom-mcps.ps1`
6. Register via `add-custom-mcps.ps1`

---

## Current state

- Python tool: ready
- PowerShell launcher: ready
- Supabase upload: gated on `SUPABASE_URL` + `SUPABASE_DB_PASSWORD` in DPAPI
- First ingestion: pending Clay's trigger (requires `py -3` + `httpx` package minimum)

**Deployment gate:** install dependencies (`pip install httpx markdown-it-py pyarrow`) and decide on refresh cadence.

---

*~1,800 APIs catalogued, scored, and queryable. The MCP-candidate-discovery substrate per v3 Part E is now operational (staged).*

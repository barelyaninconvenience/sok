# Projects/scripts — Hierarchy Navigation Index

**Purpose:** navigation for the growing scripts hierarchy. Complements the existing `README.md` (which documents SOK specifically) by providing top-level orientation for all subdirectory trees.

**Authored:** 2026-04-21 (session continued post-perpetual-continuation window)
**Canonical root:** `C:\Users\shelc\Documents\Journal\Projects\scripts\`

---

## Top-level structure

```
Projects/scripts/
├── README.md                    — SOK primary documentation (existing)
├── SCRIPTS_HIERARCHY.md         — this file (hierarchy navigation)
├── common/                       — shared modules (SOK-Secrets etc.)
├── custom-mcps/                  — v3 Part F custom MCP roster
├── role-scoped-deployments/      — multi-role Claude Code scaffolding
├── public-apis-ingestion/        — public-apis catalog harvester
├── n8n-workflows/                — async orchestration workflow specs
├── Utilities/                    — miscellaneous scripts
└── [SOK-*.ps1 scripts]           — SOK automation suite (at root)
```

---

## Subdirectory purposes

### `common/`

Shared modules imported across scripts.

- **`SOK-Secrets.psm1`** — DPAPI-backed secret storage. Provides `Set-SOKSecret` / `Get-SOKSecret` / `Remove-SOKSecret`. Load-bearing: every credential-requiring script imports this.

### `custom-mcps/` (v3 Part F roster)

Per KLEM/OS v3 architectural direction (`Writings/KLEM_OS_Cost_and_Architecture_v3_20260421.md` Part F). Each subdirectory is a standalone MCP wrapper Claude Code consumes via stdio.

| Subdir | Pattern | Layer | Status |
|---|---|---|---|
| `exa-mcp/` | stdio-to-HTTP proxy | L2 retrieval | SCAFFOLDED |
| `supabase-mcp/` | Python SDK direct-wrap | L1 data | SCAFFOLDED |
| `ollama-mcp/` | no-credential localhost | L3 inference | SCAFFOLDED |
| `unstructured-mcp/` | library-direct-wrap | L2 parsing | SCAFFOLDED |
| `n8n-control-mcp/` | REST-proxy | L4 orchestration | SCAFFOLDED |
| `gamma-mcp/` | beta-API variant | L5 content | SCAFFOLDED |

Plus helpers:
- **`add-custom-mcps.ps1`** — registration helper (prints JSON blocks for `~/.mcp.json`; `-ShowExisting` audit mode)
- **`deploy-custom-mcps.ps1`** — staging→production deployment with backup
- **`README.md`** — roster tracker + pattern documentation

**Companion references:**
- `Writings/Custom_MCP_Patterns_20260421.md` — 4 architectural patterns
- `Writings/KLEM_OS_Cost_and_Architecture_v3_20260421.md` Part F
- `Writings/MCP_Config_Audit_20260421.md` — current config audit + deprecations

### `role-scoped-deployments/` (v3.1 overemployment scaffolding)

Per-role Claude Code deployment scaffolding for multi-concurrent-remote-role operation.

- **`start-role-session.ps1`** — launcher sets ROLE_CONTEXT + changes working dir + loads role-scoped MCP config
- **`role-config.template.json`** — config template (customize to role-config.json)
- **`README.md`** — deployment guide + column-A/B two-layer model

**Companion references:**
- `Writings/Overemployment_Stack_Integration_20260421.md`
- `Writings/Multi_Role_Calendar_Setup_20260421.md`
- `Writings/Operating_Stack_v1_4_L15_Delta_20260421.md` (L-15 cost layer)

### `public-apis-ingestion/` (v3 Part E implementation)

Harvester for the `public-apis/public-apis` GitHub catalog (~1,800 APIs → Supabase-indexed MCP candidate discovery).

- **`ingest-public-apis.py`** — Python tool (parse → score candidacy → emit JSON/Parquet/SQL)
- **`start-ingest.ps1`** — PS launcher with optional Supabase upload
- **`README.md`** — usage + candidacy-scoring model + Supabase schema DDL

### `n8n-workflows/` (async orchestration)

n8n workflow definitions. Complements Claude Code (sync) per KLEM/OS v3 division-of-labor.

- **`calendar-control-workflow.json`** — hourly multi-role calendar-violation detector (IMPLEMENTED)
- **`future-workflow-specs.md`** — 4 specs for future workflows (daily-digest / knowledge-base-health / monitoring / content-pipeline)
- **`README.md`** — overview + stack-compliance discipline

### `Utilities/`

Miscellaneous non-themed scripts:
- `html_to_chrome.py` (relocated 2026-04-20 from Projects/Python/)
- `Position-DesktopIcons.ps1` + `Desktop_Layout_Before_*.json`

### SOK suite (at `scripts/` root)

The SOK PowerShell automation suite — infrastructure automation for Clay's workstation. Documented in `README.md` (existing at this directory root).

---

## Convention reminders (CLAUDE.md §2 + §9)

### Credential discipline

- Secrets → DPAPI at `~/.sok-secrets/*.sec` via `Set-SOKSecret`
- Retrieved at runtime via `Get-SOKSecret -Name '<X>'` from `common/SOK-Secrets.psm1`
- GitHub PATs → Windows Credential Manager via `gh auth login` / retrieved via `gh auth token`
- **Never plaintext** in any config file

### DryRun mandate

- Every destructive script: `[switch]$DryRun` as first param
- Gates ALL destructive operations (write, delete, move, junction, registry, package install)
- DryRun-first, not execute-first

### Deprecate-never-delete

- Old versions → `Deprecated/` subdirectory with timestamp
- Never `Remove-Item -Recurse`

### Triple-Layer Test DB Safety

- Scripts deleting/truncating/dropping DB state require `-TestDb` switch OR `TEST_DB=true` env var
- Pre-op assertion: target not a production path
- Triple-check cleanup fails-closed

---

## Sessions contributing major additions

- **2026-04-18**: Operating Stack v1 + SOK v1 structural completion
- **2026-04-20**: Perpetual-mode cultivation + SOK remediation + KLEM/OS v1 unified + projects audit
- **2026-04-21**: Custom MCP roster (6 MCPs) + role-scoped-deployments + public-apis-ingestion + n8n-workflows + overemployment v3.1/v3.2

---

## Execution environments

- PowerShell 7+ (primary; many scripts require `#Requires -Version 7.0`)
- Python 3.11+ (for Python MCPs / ingestion tools); via `py -3` launcher
- uv / uvx (for Python package running without explicit venv)
- Node.js 20+ (for npm-packaged MCPs)
- Windows 10/11 (DPAPI is Windows-specific)

---

## Cold-start orientation for Claude Code in this directory

When a new Claude Code session opens in `scripts/`:

1. Load relevant memory files per `memory/protocol_cold_start.md`
2. Task-specific reading:
   - SOK work → `memory/project_sok.md` + this directory's `README.md`
   - Custom MCP work → `custom-mcps/README.md` + `Writings/Custom_MCP_Patterns_20260421.md`
   - Overemployment scaffolding → `role-scoped-deployments/README.md` + `Writings/Overemployment_Stack_Integration_20260421.md`
   - n8n orchestration → `n8n-workflows/README.md` + `n8n-workflows/future-workflow-specs.md`
3. Verify `common/SOK-Secrets.psm1` importable
4. Proceed with task

---

*Hierarchy navigation index. Each subdirectory has its own README or equivalent documentation with specifics. CLAUDE.md §2 + §9 apply throughout.*

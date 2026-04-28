# Supabase MCP Server

**Purpose:** Layer 1 data-access MCP for KLEM/OS — wraps Supabase (PostgreSQL + pgvector) with MCP tools for CRUD on the KLEM/OS schema + semantic similarity search + arbitrary SQL/RPC.

**KLEM/OS v3 roster entry:** Part F Priority P1 (core data-substrate).

## Exposed MCP tools

| Tool | Purpose |
|---|---|
| `query_knowledge_chunks` | Semantic similarity search via `match_knowledge_chunks` RPC |
| `insert_knowledge_asset` | Append a row to `knowledge_assets` |
| `log_session` | Append a row to `session_logs` |
| `list_projects` | List `projects` rows, optionally filtered by status |
| `exec_sql` | Arbitrary SQL via `exec_sql` RPC (destructive patterns blocked unless `allow_unsafe=true`) |

## Deployment

**Prerequisites:** Supabase project with KLEM/OS schema provisioned (see `KLEM_OS_Unified_20260420.html` §I.2.1 for schema DDL). `match_knowledge_chunks` + `exec_sql` RPCs must exist server-side.

1. Store credentials in DPAPI:
   ```powershell
   Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force
   Set-SOKSecret -Name 'SUPABASE_URL'                -Value 'https://<project>.supabase.co'
   Set-SOKSecret -Name 'SUPABASE_SERVICE_ROLE_KEY'   -Value '<service-role-key>'
   ```
   *Service role key bypasses Row Level Security. Never expose publicly.*

2. Deploy to `~/.supabase-mcp/`:
   ```powershell
   Copy-Item -Recurse -Force `
     'C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps\supabase-mcp\*' `
     'C:\Users\shelc\.supabase-mcp\'
   ```

3. Add to `~/.mcp.json`:
   ```json
   "supabase": {
     "type": "stdio",
     "command": "pwsh",
     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
              "C:\\Users\\shelc\\.supabase-mcp\\start-supabase-mcp.ps1"]
   }
   ```

4. Restart Claude Code. Verify via `list_projects` tool call.

## Pattern

Follows the custom-MCPs-wrap-APIs pattern per KLEM/OS v3. Template source: `custom-mcps/exa-mcp/`. Credential handling identical. Bridge pattern differs: Exa proxies upstream MCP; Supabase wraps the Supabase Python SDK directly (no upstream MCP to proxy).

## Safety

- **Destructive SQL guard** in `exec_sql` blocks DROP/TRUNCATE/DELETE/ALTER unless `allow_unsafe=true` explicitly passed. Aligns with CLAUDE.md §4 destructive-ops discipline + §2 Triple-Layer Test Database Safety rule (forced opt-in for destructive paths).
- **Service role key zeroed** in PS1 launcher after env var injection (standard pattern).

---

*Second custom-MCP exemplar. First non-proxy pattern (direct Python SDK wrap). Template for other direct-wrap MCPs: Gamma, Unstructured.*

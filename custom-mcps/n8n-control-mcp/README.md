# n8n-control MCP Server

**Purpose:** Layer 4 workflow orchestration control — wraps n8n REST API so Claude Code can observe + trigger + administer n8n workflows without leaving the Claude session.

**KLEM/OS v3 roster entry:** Part F Priority P2. Complements (doesn't replace) n8n — n8n remains the cron/monitoring workflow engine; this MCP is the Claude Code operator interface.

## Exposed MCP tools

| Tool | Purpose |
|---|---|
| `list_workflows` | Enumerate workflows (all or active-only) |
| `get_workflow` | Fetch workflow definition by ID |
| `activate_workflow` | Enable a workflow |
| `deactivate_workflow` | Disable a workflow |
| `list_executions` | Recent execution history, filterable by workflow + status |
| `get_execution` | Full detail of a specific execution |

## Deployment

1. Store credentials:
   ```powershell
   Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force
   Set-SOKSecret -Name 'N8N_BASE_URL'  -Value 'http://localhost:5678'
   Set-SOKSecret -Name 'N8N_API_TOKEN' -Value '<token-from-n8n-settings-API>'
   ```

2. Copy to production:
   ```powershell
   Copy-Item -Recurse -Force `
     'C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps\n8n-control-mcp\*' `
     'C:\Users\shelc\.n8n-control-mcp\'
   ```

3. Add to `~/.mcp.json`:
   ```json
   "n8n-control": {
     "type": "stdio",
     "command": "pwsh",
     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
              "C:\\Users\\shelc\\.n8n-control-mcp\\start-n8n-control-mcp.ps1"]
   }
   ```

## Design notes

- n8n REST API is the official stable interface; prefer it over scraping the UI
- Workflow *creation/editing* is out of scope for this MCP — use the n8n UI or CLI for that
- Consider this MCP primarily an *observer/operator* tool: Claude Code uses it to check status + trigger existing workflows

---

*Fifth custom-MCP exemplar. REST-proxy variant with simple HTTP auth.*

# Gamma MCP Server

**Purpose:** Layer 5 content-pipeline MCP — wraps Gamma API for AI-generated presentations/documents/social posts from Claude-authored content.

**KLEM/OS v3 roster entry:** Part F Priority P2.

## Exposed MCP tools

| Tool | Purpose |
|---|---|
| `generate_presentation` | Create a new Gamma deck/doc/social from markdown text |
| `get_generation_status` | Poll a running generation job |

## Deployment

1. Store API key (Gamma API is in beta as of early 2026):
   ```powershell
   Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force
   Set-SOKSecret -Name 'GAMMA_API_KEY' -Value '<gamma-api-key>'
   ```

2. Copy to production:
   ```powershell
   Copy-Item -Recurse -Force `
     'C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps\gamma-mcp\*' `
     'C:\Users\shelc\.gamma-mcp\'
   ```

3. Add to `~/.mcp.json`:
   ```json
   "gamma": {
     "type": "stdio",
     "command": "pwsh",
     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
              "C:\\Users\\shelc\\.gamma-mcp\\start-gamma-mcp.ps1"]
   }
   ```

## Caveat — beta API

Gamma's public API is in beta. Endpoint paths (`/v0.2/generations`) may change at stable v1. If this MCP stops working after a Gamma API update, check:
- `GAMMA_API_BASE` env var can override the default (set in PS1 or `.mcp.json` env block)
- Endpoint paths in `__main__.py` may need version bumps
- Gamma docs: https://developers.gamma.app/

## Use case in KLEM/OS

Per Feb 2026 unified HTML §II.3 Content Pipeline:
- Substrate Thesis whitepaper → Gamma slide deck for speaking engagements
- SIR technique findings → Medium-style presentation format
- Workshop chapters → academic-conference-ready decks

Per KLEM/OS v3: Gamma is "buy" verdict per §II.4 build-vs-buy — design quality is the moat. MCP wrapper brings that capability into Claude Code sessions.

---

*Sixth custom-MCP exemplar. Beta-API variant — design explicitly anticipates endpoint evolution.*

# Ollama MCP Server

**Purpose:** Layer 3 local-inference fallback — wraps the local Ollama HTTP API for sensitive-data processing, offline operation, and bulk classification at near-zero cost.

**KLEM/OS v3 roster entry:** Part F Priority P3. No credential required (localhost by default).

## Exposed MCP tools

| Tool | Purpose |
|---|---|
| `ollama_generate` | Single-turn text completion (/api/generate) |
| `ollama_chat` | Multi-turn chat completion (/api/chat) |
| `ollama_embed` | Local embedding generation (/api/embeddings, e.g. nomic-embed-text) |
| `ollama_list_models` | List locally-installed models (/api/tags) |

## Prerequisites

- Ollama installed (https://ollama.com) + `ollama serve` running
- Target models pulled, e.g.:
  ```powershell
  ollama pull llama3.1:8b
  ollama pull nomic-embed-text
  ```

## Deployment

1. Copy staging to production:
   ```powershell
   Copy-Item -Recurse -Force `
     'C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps\ollama-mcp\*' `
     'C:\Users\shelc\.ollama-mcp\'
   ```

2. Add to `~/.mcp.json`:
   ```json
   "ollama": {
     "type": "stdio",
     "command": "pwsh",
     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
              "C:\\Users\\shelc\\.ollama-mcp\\start-ollama-mcp.ps1"]
   }
   ```

3. Restart Claude Code. Verify via `ollama_list_models` tool call.

## Remote Ollama (optional)

If Ollama runs on a remote host (BOC homelab, for example), set:
```powershell
$env:OLLAMA_BASE_URL = 'http://boc.tailscale:11434'
```
before launching, or edit `start-ollama-mcp.ps1` to hardcode the remote URL.

---

*Third custom-MCP exemplar. No-credential variant — cheapest to deploy; valuable for sovereignty-bounded workflows.*

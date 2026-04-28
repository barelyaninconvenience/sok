# Exa MCP Bridge — Custom MCP Wrapper Exemplar

**Purpose:** stdio-to-HTTP MCP bridge that proxies Claude Code MCP requests to Exa's HTTP MCP endpoint (`https://mcp.exa.ai/mcp`) with `Authorization: Bearer` header injection from DPAPI-stored credential.

**Why this exists:**
1. **Eliminates plaintext credential exposure** — the previous `.claude.json` config stored the Exa API key as a URL query parameter, violating CLAUDE.md §2 Credential Storage.
2. **Exemplar of the KLEM/OS v3 custom-MCPs-wrap-APIs pattern** — first concrete implementation of the architectural direction Clay ratified 2026-04-21. Template for the Supabase / n8n-control / Gamma / Ollama / Unstructured MCPs per v3 Part F.

---

## Architecture

```
  Claude Code
     │ stdio (JSON-RPC)
     ▼
┌─────────────────┐
│ start-exa-mcp.ps1│  ◄── Reads EXA_API_KEY from DPAPI via Get-SOKSecret
│   (PS1 launcher)│      Sets env var; execs Python bridge
└────────┬────────┘
         │ exec
         ▼
┌─────────────────┐
│  exa_mcp_bridge │  ◄── Reads EXA_API_KEY from env
│  (Python)       │      Forwards stdio MCP to HTTP MCP w/ Bearer auth
└────────┬────────┘
         │ HTTPS + Authorization: Bearer
         ▼
  mcp.exa.ai/mcp    (Exa's official HTTP MCP endpoint)
```

No credential in any config file. Credential retrieved at session start, lives in process env vars only, and disappears when the bridge exits.

---

## Files in this directory

| File | Purpose |
|---|---|
| `start-exa-mcp.ps1` | Entry-point PS1 launcher. Reads DPAPI, sets env, execs Python. |
| `pyproject.toml` | Python package metadata for `uvx` |
| `exa_mcp_bridge/__init__.py` | Package marker + version |
| `exa_mcp_bridge/__main__.py` | stdio-to-HTTP MCP bridge implementation |
| `README.md` | This file |

---

## Deployment sequence

**Prerequisites:**
- PowerShell 7+ (verified via `#Requires -Version 7.0` in launcher)
- `uvx` available on PATH (via `uv` or `pip install uv`)
- `common/SOK-Secrets.psm1` present at `C:\Users\shelc\Documents\Journal\Projects\scripts\common\`

**Step 1 — Rotate the exposed Exa API key**

1. Visit [dashboard.exa.ai](https://dashboard.exa.ai/)
2. Generate a new API key
3. Revoke the previous key (currently embedded in `.claude.json` as plaintext URL parameter)

**Step 2 — Store the new key in DPAPI**

```powershell
Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force
Set-SOKSecret -Name 'EXA_API_KEY' -Value '<new-api-key-here>'
```

Verify storage:

```powershell
Get-SOKSecret -Name 'EXA_API_KEY'    # should return the key string
```

**Step 3 — Deploy this directory to `~/.exa-mcp/`**

```powershell
# From this staging location:
Copy-Item -Recurse -Force `
    'C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps\exa-mcp\*' `
    'C:\Users\shelc\.exa-mcp\'
```

Or alternatively, leave staged and point the .claude.json config to the staging location directly.

**Step 4 — Update `.claude.json` to use the stdio launcher**

Current `.claude.json` top-level `mcpServers.exa` block (replace):

```json
"exa": {
  "type": "http",
  "url": "https://mcp.exa.ai/mcp?exaApiKey=<PLAINTEXT-KEY>&tools=..."
}
```

Replacement:

```json
"exa": {
  "type": "stdio",
  "command": "pwsh",
  "args": [
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File",
    "C:\\Users\\shelc\\.exa-mcp\\start-exa-mcp.ps1"
  ]
}
```

**Step 5 — Zero the old plaintext URL**

After confirming step 4 is saved, the old URL with the plaintext key is gone from active config. **Also check backups** for the old URL and key:
- OneDrive version history of `.claude.json`
- Windows shadow copies
- Any git-tracked commits of `.claude.json`

If the old URL appears in any of these, the rotated-away key is fine (it's revoked), but as a habit, check for additional leaked copies.

**Step 6 — Test**

Restart Claude Code. Verify Exa tools are still callable:
- `mcp__exa__web_search_exa` and related should respond normally
- Check stderr of the Python bridge (visible in Claude Code's MCP diagnostics) for any auth errors

If `Get-SOKSecret` returns null, the PS1 launcher will fail fast with exit code 3 and print the remediation instructions.

---

## Troubleshooting

### "SOK-Secrets module not found"

The module must exist at `scripts/common/SOK-Secrets.psm1`. Verify:

```powershell
Test-Path 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
```

If missing, the scripts project directory may have moved. Update the `$secretsModule` path in `start-exa-mcp.ps1`.

### "Exa API key not found in DPAPI store"

Either the key was never stored (run Step 2 above) or DPAPI decryption failed (occurs if running under a different user account than the one that stored the key). DPAPI-encrypted blobs are user-scoped.

### "exa-mcp-bridge" command not found

`uvx` needs the directory structure recognized. Verify `pyproject.toml` is in the same directory as `exa_mcp_bridge/__main__.py`, and that the script entry point matches:

```toml
[project.scripts]
exa-mcp-bridge = "exa_mcp_bridge.__main__:main"
```

Try invoking directly:

```powershell
uvx --from 'C:\Users\shelc\.exa-mcp' exa-mcp-bridge
```

### Bridge exits immediately with exit code 11

Python exception in `_run_bridge()`. Check stderr output — the bridge logs all errors to stderr before exiting. Most common cause: upstream Exa MCP is unreachable or returning non-200 responses (rate limiting, account suspended, etc.).

---

## Alternative: HTTP MCP with headers (if Claude Code supports it)

If Claude Code's HTTP MCP type supports a `headers` field with env-var expansion, a simpler path is:

```json
"exa": {
  "type": "http",
  "url": "https://mcp.exa.ai/mcp?tools=...",
  "headers": {
    "Authorization": "Bearer ${EXA_API_KEY}"
  }
}
```

Combined with a PS1 wrapper that sets `EXA_API_KEY` in the parent-process environment before launching Claude Code. This avoids the Python bridge entirely.

**Verify whether this works** in your Claude Code version before committing to this path. As of early 2026, this pattern is documented for some MCP implementations but not universally supported.

The full stdio bridge (this implementation) is the more-portable fallback — it works regardless of HTTP MCP header support.

---

## Template for other custom MCPs (v3 Part F roster)

This bridge pattern generalizes to the 4 other high-ROI custom MCPs planned per KLEM/OS v3:

| MCP | Upstream transport | Credential source | Bridge type needed |
|---|---|---|---|
| **Supabase** | REST / Postgres client | Supabase service role key → DPAPI | Python stdio MCP that calls Supabase client SDK |
| **n8n-control** | n8n HTTP API | API token → DPAPI | Python stdio MCP proxying to n8n REST |
| **Gamma** | Gamma API | API key → DPAPI | Python stdio MCP proxying to Gamma REST |
| **Ollama** | Ollama local HTTP (localhost:11434) | No credential (local only) | Simple Python stdio MCP proxying to local Ollama |
| **Unstructured** | Python library (no remote call) | No credential | Python stdio MCP wrapping Unstructured library directly |

For each: copy this directory, rename the package + entry point, swap the upstream endpoint + credential retrieval + protocol shape. The PS1 launcher pattern, DPAPI integration pattern, and stdio-MCP-server pattern all transfer.

---

## Status

- **Staged at:** `Projects/scripts/custom-mcps/exa-mcp/` (this directory)
- **Production location:** `~/.exa-mcp/` (target after Step 3)
- **Companion v3 docs:** `Writings/KLEM_OS_Cost_and_Architecture_v3_20260421.md` Part F
- **MCP audit source:** `Writings/MCP_Config_Audit_20260421.md` §D (credential exposure detail)

**Deployment gate:** Step 1 (key rotation) and Step 2 (DPAPI storage) are Clay's pen. Steps 3-6 are either Clay-executable or Claude-executable given appropriate authorization.

---

*First custom-MCP wrapper exemplar. The pattern is now template-ready for the remaining v3 Part F MCP roster build-out.*

# Custom MCPs — KLEM/OS Architecture Layer

**Purpose:** staging + source-of-truth for Clay's custom MCP server implementations per the KLEM/OS v3 architectural directive ("custom MCPs wrap APIs; Claude Max Code is the runtime; Anthropic API outsourcing mitigated").

**Canonical v3 context:** `Writings/KLEM_OS_Cost_and_Architecture_v3_20260421.md` Part F
**MCP audit baseline:** `Writings/MCP_Config_Audit_20260421.md`

---

## The pattern

Each custom MCP follows the workspace-mcp + github-mcp convention Clay already uses:

```
~/.<name>-mcp/                   # production location
├── start-<name>-mcp.ps1        # PS1 launcher (reads DPAPI via Get-SOKSecret)
├── <package>/                  # Python (or Go) MCP server source
├── pyproject.toml              # if Python
└── README.md                   # deployment + troubleshooting + template docs
```

**Staging location** (before promotion to `~/.<name>-mcp/`): `Projects/scripts/custom-mcps/<name>-mcp/` (this tree).

### PS1 launcher responsibilities

1. Import `common/SOK-Secrets.psm1`
2. Retrieve credential via `Get-SOKSecret -Name '<UPPER_SNAKE_NAME>'`
3. Fail fast with remediation instructions if credential missing
4. Set env var(s) for the child process
5. Zero local credential references
6. `& <command>` stdio MCP server with `exit $LASTEXITCODE`

### MCP server responsibilities

1. Read credential(s) from env var at startup (not config file)
2. Fail fast if env var missing
3. Log operational messages to **stderr** (stdout is reserved for MCP JSON-RPC)
4. Forward or implement the MCP tool surface expected by Claude Code
5. Exit cleanly on SIGINT / KeyboardInterrupt

---

## Roster (v3 Part F + audit findings)

| MCP | Priority | Status | Notes |
|---|---|---|---|
| **exa-mcp** | P1 (credential-exposure remediation) | **SCAFFOLDED** 2026-04-21 | See `exa-mcp/`. Awaits Clay's DPAPI key storage + `.claude.json` config swap. stdio-to-HTTP proxy pattern. |
| **supabase-mcp** | P1 (core data-substrate access) | **SCAFFOLDED** 2026-04-21 | See `supabase-mcp/`. 5 tools (query_knowledge_chunks / insert_knowledge_asset / log_session / list_projects / exec_sql with destructive-SQL guard). Python SDK direct-wrap pattern. |
| **n8n-control-mcp** | P2 (workflow orchestration) | **SCAFFOLDED** 2026-04-21 | See `n8n-control-mcp/`. 6 tools (list/get/activate/deactivate workflows + list/get executions). REST-proxy pattern. |
| **gamma-mcp** | P2 (content pipeline) | **SCAFFOLDED** 2026-04-21 | See `gamma-mcp/`. 2 tools (generate_presentation / get_generation_status). Beta-API variant — endpoint evolution expected. |
| **ollama-mcp** | P3 (local inference) | **SCAFFOLDED** 2026-04-21 | See `ollama-mcp/`. 4 tools (generate / chat / embed / list_models). No-credential variant (localhost by default). |
| **unstructured-mcp** | P3 (ingestion) | **SCAFFOLDED** 2026-04-21 | See `unstructured-mcp/`. 2 tools (parse_document / parse_directory). Library-direct-wrap pattern. |
| **postman-mcp** | P4 (as-needed) | Pending | L4 API dev/test. 2-4 hours |
| **elevenlabs-mcp** | P4 (pending HeyGen deprecation decision) | Pending | L5 voice synthesis if HeyGen replaced |
| **langfuse-mcp** | P4 (pending Langfuse BOC deployment) | Pending | L6 observability |

### Deprecation watchlist

| MCP | Reason |
|---|---|
| **puppeteer** (in `~/.mcp.json`) | Redundant with claude-in-chrome auto-loaded MCP |
| **google_workspace** duplicate in `.claude.json` top-level | Duplicates workspace-mcp from `~/.mcp.json` |
| **google_workspace** in `~/.claude/claude_desktop_config.json` | Duplicates workspace-mcp (pre-convergence) |
| **exa HTTP config** in `.claude.json` top-level | Replaced by stdio wrapper (this directory's `exa-mcp/`) |

Deprecations: pending Clay's confirmation + Claude-executable edits.

---

## Template usage

To build a new custom MCP following the pattern:

1. Copy `exa-mcp/` directory, rename to `<new-name>-mcp/`
2. Rename `start-exa-mcp.ps1` → `start-<new-name>-mcp.ps1`, update credential name + upstream URL in the script
3. Rename `exa_mcp_bridge/` package directory → `<new_name>_mcp_server/` (underscores OK in Python package names)
4. Update `pyproject.toml` name + script entry point
5. Rewrite `__main__.py` with the new upstream protocol (may be REST proxy, library wrapper, local IPC, etc.)
6. Update `README.md` with the new tool surface + deployment instructions
7. Deploy to `~/.<new-name>-mcp/` after testing
8. Register in `~/.mcp.json` or `.claude.json` as appropriate

---

## Token-tax management

Per the MCP audit (~170-270K tokens of schema context loaded per session at worst case), custom MCPs should be designed with schema-size awareness:

- **Prefer proxying-to-existing-HTTP-MCP** over reimplementing tools — inherits upstream schema without our duplication cost
- **Expose minimal tool surface** — if 3 of 8 Exa tools are never used, omit them from the proxy layer (server-side filtering via `tools=` param)
- **Consider code-execution-with-MCP** (Anthropic Nov 2025 pattern) for high-call-volume integrations — bypasses schema-in-context by having the model write TypeScript chains. Candidates: Supabase, Exa, GitHub.

---

## Cross-references

- **Architectural direction:** `Writings/KLEM_OS_Cost_and_Architecture_v3_20260421.md`
- **Current-state audit:** `Writings/MCP_Config_Audit_20260421.md`
- **Credential discipline:** `CLAUDE.md` §2 + `memory/feedback_credential_storage.md`
- **SOK-Secrets module:** `scripts/common/SOK-Secrets.psm1` (provides Get-SOKSecret / Set-SOKSecret)
- **Existing pattern exemplars:** `~/.workspace-mcp/start-workspace-mcp.ps1` + `~/.github-mcp/start-github-mcp.ps1`

---

## Version history

- **2026-04-21:** Directory created. `exa-mcp/` scaffolded as the first custom-MCP wrapper exemplar following the v3 architectural direction. This file authored to document the overall pattern + roster progress tracking.
- **2026-04-21 (later):** Full v3 Part F P1-P3 roster scaffolded — `supabase-mcp`, `ollama-mcp`, `unstructured-mcp`, `n8n-control-mcp`, `gamma-mcp` all land with launchers + Python bridges + READMEs. Six total exemplars covering four distinct patterns (stdio-to-HTTP proxy / Python SDK direct-wrap / REST-proxy / library-direct-wrap / no-credential-localhost / beta-API-variant). P4 MCPs (Postman, ElevenLabs, Langfuse) remain pending — deploy when trigger conditions met (e.g., HeyGen deprecation decision for ElevenLabs; BOC Phase 2 for Langfuse).

---

*The custom-MCP layer is the KLEM/OS bridge between Claude Max Code (cornerstone LLM runtime) and the external API ecosystem. Every MCP wraps one or more external services with DPAPI-secured credentials and a stable stdio interface. The result: Clay's $200/mo Max subscription becomes the anchor; direct Anthropic API billing collapses toward zero; external API costs pass through transparently; and credential discipline stays consistent across the stack.*

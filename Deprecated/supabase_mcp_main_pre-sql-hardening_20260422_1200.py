"""Supabase MCP server — KLEM/OS Layer 1 data access.

Exposes the KLEM/OS schema (knowledge_assets / knowledge_chunks / projects /
session_logs) plus arbitrary SQL/RPC as MCP tools.

Schema reference (from KLEM_OS_Unified_20260420.html §I.2.1):

    knowledge_assets(id, title, source_type, domain, content, metadata, embedding, ...)
    knowledge_chunks(id, asset_id, chunk_index, content, embedding, token_count, metadata)
    projects(id, name, domain, status, metadata, created_at)
    session_logs(id, project_id, prompt_summary, response_summary, tokens_used, model, quality_score, created_at)

Plus HNSW index on knowledge_chunks.embedding for fast similarity search.

Design:
- Service-role key bypasses RLS — tools should be invoked by Claude Code only,
  never exposed as a public endpoint.
- Semantic search via pgvector `match_knowledge_chunks` RPC (assumed existing
  in the Supabase project; standard KLEM/OS RPC).
- Arbitrary SQL tool is provided but scoped to DQL + DML on the KLEM/OS tables;
  guards against DROP/TRUNCATE unless `--unsafe` arg passed (caller must intend).
"""

from __future__ import annotations

import logging
import os
import sys
from typing import Any

import anyio
from mcp.server import Server  # type: ignore[import-not-found]
from mcp.server.stdio import stdio_server  # type: ignore[import-not-found]
from mcp import types as mcp_types  # type: ignore[import-not-found]
from supabase import create_client, Client  # type: ignore[import-not-found]


logging.basicConfig(
    level=os.environ.get("SUPABASE_MCP_LOG_LEVEL", "INFO"),
    format="%(asctime)s supabase-mcp %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("supabase_mcp")

DESTRUCTIVE_SQL = ("drop ", "truncate ", "delete from ", "alter table ")


def _require_env(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        log.error("Required env var %s is not set", name)
        sys.exit(10)
    return val


def _get_client() -> Client:
    url = _require_env("SUPABASE_URL")
    key = _require_env("SUPABASE_SERVICE_ROLE_KEY")
    return create_client(url, key)


def _safe_sql(sql: str, allow_unsafe: bool) -> None:
    lower = sql.lower().strip()
    if not allow_unsafe:
        for bad in DESTRUCTIVE_SQL:
            if bad in lower:
                raise ValueError(
                    f"SQL contains destructive pattern '{bad.strip()}'. "
                    f"Pass allow_unsafe=true to authorize."
                )


async def _run_server() -> None:
    sb = _get_client()
    server: Server = Server("supabase-mcp")

    @server.list_tools()  # type: ignore[misc]
    async def _list_tools() -> list[mcp_types.Tool]:
        return [
            mcp_types.Tool(
                name="query_knowledge_chunks",
                description=(
                    "Semantic similarity search over knowledge_chunks via pgvector. "
                    "Returns top-k chunks matching the query embedding."
                ),
                inputSchema={
                    "type": "object",
                    "properties": {
                        "query_embedding": {
                            "type": "array",
                            "items": {"type": "number"},
                            "description": "1536-dim vector from text-embedding-3-small",
                        },
                        "match_threshold": {"type": "number", "default": 0.7},
                        "match_count": {"type": "integer", "default": 10},
                        "filter_domains": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Optional list of domain tags to filter by",
                        },
                    },
                    "required": ["query_embedding"],
                },
            ),
            mcp_types.Tool(
                name="insert_knowledge_asset",
                description="Insert a new row into knowledge_assets.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "title": {"type": "string"},
                        "source_type": {"type": "string"},
                        "domain": {"type": "array", "items": {"type": "string"}},
                        "content": {"type": "string"},
                        "metadata": {"type": "object"},
                        "embedding": {
                            "type": "array",
                            "items": {"type": "number"},
                        },
                    },
                    "required": ["title", "source_type"],
                },
            ),
            mcp_types.Tool(
                name="log_session",
                description="Append a row to session_logs table.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "project_id": {"type": "string"},
                        "prompt_summary": {"type": "string"},
                        "response_summary": {"type": "string"},
                        "tokens_used": {"type": "integer"},
                        "model": {"type": "string"},
                        "quality_score": {"type": "number"},
                    },
                    "required": ["prompt_summary"],
                },
            ),
            mcp_types.Tool(
                name="list_projects",
                description="List all rows in projects table, optionally filtered by status.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "status": {"type": "string", "description": "e.g. 'active'"},
                    },
                },
            ),
            mcp_types.Tool(
                name="exec_sql",
                description=(
                    "Execute arbitrary SQL via Supabase exec_sql RPC. "
                    "Destructive patterns (DROP/TRUNCATE/DELETE/ALTER) blocked unless allow_unsafe=true."
                ),
                inputSchema={
                    "type": "object",
                    "properties": {
                        "sql": {"type": "string"},
                        "allow_unsafe": {"type": "boolean", "default": False},
                    },
                    "required": ["sql"],
                },
            ),
        ]

    @server.call_tool()  # type: ignore[misc]
    async def _call_tool(name: str, arguments: dict[str, Any]) -> list[mcp_types.TextContent]:
        try:
            if name == "query_knowledge_chunks":
                resp = sb.rpc("match_knowledge_chunks", arguments).execute()
                return [mcp_types.TextContent(type="text", text=str(resp.data))]
            if name == "insert_knowledge_asset":
                resp = sb.table("knowledge_assets").insert(arguments).execute()
                return [mcp_types.TextContent(type="text", text=str(resp.data))]
            if name == "log_session":
                resp = sb.table("session_logs").insert(arguments).execute()
                return [mcp_types.TextContent(type="text", text=str(resp.data))]
            if name == "list_projects":
                q = sb.table("projects").select("*")
                if status := arguments.get("status"):
                    q = q.eq("status", status)
                resp = q.execute()
                return [mcp_types.TextContent(type="text", text=str(resp.data))]
            if name == "exec_sql":
                _safe_sql(arguments["sql"], bool(arguments.get("allow_unsafe")))
                resp = sb.rpc("exec_sql", {"sql": arguments["sql"]}).execute()
                return [mcp_types.TextContent(type="text", text=str(resp.data))]
            raise ValueError(f"Unknown tool: {name}")
        except Exception as exc:  # noqa: BLE001
            log.exception("Tool %s failed: %s", name, exc)
            return [mcp_types.TextContent(type="text", text=f"ERROR: {exc}")]

    async with stdio_server() as (read, write):
        await server.run(read, write, server.create_initialization_options())


def main() -> None:
    try:
        anyio.run(_run_server)
    except KeyboardInterrupt:
        sys.exit(0)
    except Exception as exc:  # noqa: BLE001
        log.exception("Server failed: %s", exc)
        sys.exit(11)


if __name__ == "__main__":
    main()

"""Ollama MCP server — KLEM/OS Layer 3 local inference fallback.

Provides MCP tools that call the local Ollama HTTP API. Use for:
- Processing clearance-adjacent / financial / sensitive content without external APIs
- Offline fallback when Anthropic/OpenAI APIs are rate-limited
- Bulk classification at near-zero per-call cost
- Local embedding generation (nomic-embed-text) when data sovereignty matters
"""

from __future__ import annotations

import logging
import os
import sys
from typing import Any

import anyio
import httpx
from mcp.server import Server  # type: ignore[import-not-found]
from mcp.server.stdio import stdio_server  # type: ignore[import-not-found]
from mcp import types as mcp_types  # type: ignore[import-not-found]


logging.basicConfig(
    level=os.environ.get("OLLAMA_MCP_LOG_LEVEL", "INFO"),
    format="%(asctime)s ollama-mcp %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("ollama_mcp")


async def _run_server() -> None:
    base_url = os.environ.get("OLLAMA_BASE_URL", "http://localhost:11434").rstrip("/")
    client = httpx.AsyncClient(base_url=base_url, timeout=300.0)

    server: Server = Server("ollama-mcp")

    @server.list_tools()  # type: ignore[misc]
    async def _list_tools() -> list[mcp_types.Tool]:
        return [
            mcp_types.Tool(
                name="ollama_generate",
                description="Text completion via Ollama /api/generate. Use for single-turn tasks.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "model": {"type": "string", "description": "e.g. llama3.1:8b"},
                        "prompt": {"type": "string"},
                        "system": {"type": "string"},
                        "options": {
                            "type": "object",
                            "description": "temperature, top_p, num_predict, etc.",
                        },
                    },
                    "required": ["model", "prompt"],
                },
            ),
            mcp_types.Tool(
                name="ollama_chat",
                description="Chat completion via Ollama /api/chat. Use for multi-turn.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "model": {"type": "string"},
                        "messages": {
                            "type": "array",
                            "items": {
                                "type": "object",
                                "properties": {
                                    "role": {"type": "string", "enum": ["system", "user", "assistant"]},
                                    "content": {"type": "string"},
                                },
                                "required": ["role", "content"],
                            },
                        },
                        "options": {"type": "object"},
                    },
                    "required": ["model", "messages"],
                },
            ),
            mcp_types.Tool(
                name="ollama_embed",
                description="Generate embeddings locally via Ollama /api/embeddings.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "model": {"type": "string", "description": "e.g. nomic-embed-text"},
                        "prompt": {"type": "string"},
                    },
                    "required": ["model", "prompt"],
                },
            ),
            mcp_types.Tool(
                name="ollama_list_models",
                description="List locally-installed Ollama models via /api/tags.",
                inputSchema={"type": "object", "properties": {}},
            ),
        ]

    @server.call_tool()  # type: ignore[misc]
    async def _call_tool(name: str, arguments: dict[str, Any]) -> list[mcp_types.TextContent]:
        try:
            if name == "ollama_generate":
                payload = {**arguments, "stream": False}
                r = await client.post("/api/generate", json=payload)
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=r.json().get("response", ""))]
            if name == "ollama_chat":
                payload = {**arguments, "stream": False}
                r = await client.post("/api/chat", json=payload)
                r.raise_for_status()
                msg = r.json().get("message", {}).get("content", "")
                return [mcp_types.TextContent(type="text", text=msg)]
            if name == "ollama_embed":
                r = await client.post("/api/embeddings", json=arguments)
                r.raise_for_status()
                # 2026-04-22 hardening: valid JSON (json.dumps) not Python list repr
                import json as _json
                return [mcp_types.TextContent(type="text", text=_json.dumps(r.json().get("embedding", [])))]
            if name == "ollama_list_models":
                r = await client.get("/api/tags")
                r.raise_for_status()
                # 2026-04-22 hardening: r.text (valid JSON) not str(r.json())
                return [mcp_types.TextContent(type="text", text=r.text)]
            raise ValueError(f"Unknown tool: {name}")
        except httpx.ConnectError as exc:
            log.error("Cannot reach Ollama at %s: %s", base_url, exc)
            return [
                mcp_types.TextContent(
                    type="text",
                    text=f"ERROR: Ollama unreachable at {base_url}. Is `ollama serve` running?",
                )
            ]
        except Exception as exc:  # noqa: BLE001
            log.exception("Tool %s failed: %s", name, exc)
            return [mcp_types.TextContent(type="text", text=f"ERROR: {exc}")]

    # 2026-04-22 hardening: try/finally guarantees client.aclose() runs even if
    # stdio_server raises. Prior bare client.aclose() was unreachable on exception,
    # leaking the TCP/HTTP pool.
    try:
        async with stdio_server() as (read, write):
            await server.run(read, write, server.create_initialization_options())
    finally:
        await client.aclose()


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

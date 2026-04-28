"""Gamma MCP server — generate presentations from Claude-authored content.

NOTE (2026-04-21): Gamma's public API is in beta. Endpoint URLs/shapes below
are BEST-KNOWN from Gamma's docs as of authorship; update when Gamma ships
stable v1 or changes the schema.
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
    level=os.environ.get("GAMMA_MCP_LOG_LEVEL", "INFO"),
    format="%(asctime)s gamma-mcp %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("gamma_mcp")

GAMMA_API_BASE = os.environ.get("GAMMA_API_BASE", "https://public-api.gamma.app/v0.2")


def _require_env(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        log.error("Required env var %s is not set", name)
        sys.exit(10)
    return val


async def _run_server() -> None:
    api_key = _require_env("GAMMA_API_KEY")

    client = httpx.AsyncClient(
        base_url=GAMMA_API_BASE,
        headers={"X-API-KEY": api_key, "Content-Type": "application/json"},
        timeout=120.0,
    )

    server: Server = Server("gamma-mcp")

    @server.list_tools()  # type: ignore[misc]
    async def _list_tools() -> list[mcp_types.Tool]:
        return [
            mcp_types.Tool(
                name="generate_presentation",
                description=(
                    "Generate a Gamma presentation from text content. "
                    "Content should be markdown or plain text; Gamma parses "
                    "headings/sections into slides."
                ),
                inputSchema={
                    "type": "object",
                    "properties": {
                        "input_text": {
                            "type": "string",
                            "description": "Markdown or plain text content",
                        },
                        "text_mode": {
                            "type": "string",
                            "enum": ["generate", "condense", "preserve"],
                            "default": "preserve",
                            "description": "How Gamma treats the input: generate adds content; condense summarizes; preserve uses verbatim",
                        },
                        "format": {
                            "type": "string",
                            "enum": ["presentation", "document", "social"],
                            "default": "presentation",
                        },
                        "num_cards": {
                            "type": "integer",
                            "description": "Target slide count; Gamma may adjust",
                        },
                        "additional_instructions": {
                            "type": "string",
                            "description": "Style/tone/audience hints for Gamma's generation",
                        },
                        "export_as": {
                            "type": "string",
                            "enum": ["pdf", "pptx", "none"],
                            "default": "pdf",
                        },
                    },
                    "required": ["input_text"],
                },
            ),
            mcp_types.Tool(
                name="get_generation_status",
                description="Poll the status of a running generation job.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "generation_id": {"type": "string"},
                    },
                    "required": ["generation_id"],
                },
            ),
        ]

    @server.call_tool()  # type: ignore[misc]
    async def _call_tool(name: str, arguments: dict[str, Any]) -> list[mcp_types.TextContent]:
        try:
            if name == "generate_presentation":
                payload = {
                    "inputText": arguments["input_text"],
                    "textMode": arguments.get("text_mode", "preserve"),
                    "format": arguments.get("format", "presentation"),
                }
                if nc := arguments.get("num_cards"):
                    payload["numCards"] = nc
                if ai := arguments.get("additional_instructions"):
                    payload["additionalInstructions"] = ai
                if ea := arguments.get("export_as"):
                    if ea != "none":
                        payload["exportAs"] = ea
                r = await client.post("/generations", json=payload)
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=str(r.json()))]
            if name == "get_generation_status":
                r = await client.get(f"/generations/{arguments['generation_id']}")
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=str(r.json()))]
            raise ValueError(f"Unknown tool: {name}")
        except Exception as exc:  # noqa: BLE001
            log.exception("Tool %s failed: %s", name, exc)
            return [mcp_types.TextContent(type="text", text=f"ERROR: {exc}")]

    async with stdio_server() as (read, write):
        await server.run(read, write, server.create_initialization_options())

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

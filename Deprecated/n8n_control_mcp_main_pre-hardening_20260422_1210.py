"""n8n-control MCP server — observe + orchestrate n8n workflows from Claude Code."""

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
    level=os.environ.get("N8N_MCP_LOG_LEVEL", "INFO"),
    format="%(asctime)s n8n-control-mcp %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("n8n_control_mcp")


def _require_env(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        log.error("Required env var %s is not set", name)
        sys.exit(10)
    return val


async def _run_server() -> None:
    base_url = _require_env("N8N_BASE_URL").rstrip("/")
    token = _require_env("N8N_API_TOKEN")

    client = httpx.AsyncClient(
        base_url=f"{base_url}/api/v1",
        headers={"X-N8N-API-KEY": token},
        timeout=60.0,
    )

    server: Server = Server("n8n-control-mcp")

    @server.list_tools()  # type: ignore[misc]
    async def _list_tools() -> list[mcp_types.Tool]:
        return [
            mcp_types.Tool(
                name="list_workflows",
                description="List all workflows in the n8n instance.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "active_only": {"type": "boolean", "default": False},
                    },
                },
            ),
            mcp_types.Tool(
                name="get_workflow",
                description="Get a workflow definition by ID.",
                inputSchema={
                    "type": "object",
                    "properties": {"id": {"type": "string"}},
                    "required": ["id"],
                },
            ),
            mcp_types.Tool(
                name="activate_workflow",
                description="Activate a workflow by ID.",
                inputSchema={
                    "type": "object",
                    "properties": {"id": {"type": "string"}},
                    "required": ["id"],
                },
            ),
            mcp_types.Tool(
                name="deactivate_workflow",
                description="Deactivate a workflow by ID.",
                inputSchema={
                    "type": "object",
                    "properties": {"id": {"type": "string"}},
                    "required": ["id"],
                },
            ),
            mcp_types.Tool(
                name="list_executions",
                description="List recent workflow executions, optionally filtered by workflowId.",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "workflowId": {"type": "string"},
                        "limit": {"type": "integer", "default": 20},
                        "status": {
                            "type": "string",
                            "enum": ["success", "error", "waiting"],
                        },
                    },
                },
            ),
            mcp_types.Tool(
                name="get_execution",
                description="Get full execution detail by execution ID.",
                inputSchema={
                    "type": "object",
                    "properties": {"id": {"type": "string"}},
                    "required": ["id"],
                },
            ),
        ]

    @server.call_tool()  # type: ignore[misc]
    async def _call_tool(name: str, arguments: dict[str, Any]) -> list[mcp_types.TextContent]:
        try:
            if name == "list_workflows":
                params = {"active": "true"} if arguments.get("active_only") else {}
                r = await client.get("/workflows", params=params)
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=str(r.json()))]
            if name == "get_workflow":
                r = await client.get(f"/workflows/{arguments['id']}")
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=str(r.json()))]
            if name == "activate_workflow":
                r = await client.post(f"/workflows/{arguments['id']}/activate")
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=str(r.json()))]
            if name == "deactivate_workflow":
                r = await client.post(f"/workflows/{arguments['id']}/deactivate")
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=str(r.json()))]
            if name == "list_executions":
                params: dict[str, Any] = {"limit": arguments.get("limit", 20)}
                if wid := arguments.get("workflowId"):
                    params["workflowId"] = wid
                if st := arguments.get("status"):
                    params["status"] = st
                r = await client.get("/executions", params=params)
                r.raise_for_status()
                return [mcp_types.TextContent(type="text", text=str(r.json()))]
            if name == "get_execution":
                r = await client.get(f"/executions/{arguments['id']}")
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

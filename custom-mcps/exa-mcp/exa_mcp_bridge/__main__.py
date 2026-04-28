"""Entry point for `uvx --from <dir> exa-mcp-bridge`.

This module runs as a Claude Code MCP stdio server. Every request Claude Code
sends via stdio is forwarded to Exa's HTTP MCP endpoint (with Authorization:
Bearer header injected from the EXA_API_KEY env var), and the response is
streamed back on stdout.

Design decisions:

1. **Transparent proxy, not reimplementation.** Exa provides the MCP protocol
   implementation at mcp.exa.ai/mcp. We don't reimplement their 8 tool schemas;
   we forward stdio JSON-RPC messages to their HTTP endpoint verbatim.
   Tradeoff: if Exa changes tool schemas, we inherit the change; if Exa's
   HTTP MCP breaks, our bridge breaks. Benefits: minimal maintenance surface;
   no tool-schema drift; automatic availability of new Exa tools.

2. **Credential via env var, not config.** EXA_API_KEY is set by the PS1
   launcher (start-exa-mcp.ps1) from the DPAPI store. If env is unset or empty,
   we error early with remediation instructions.

3. **Pure proxy, not transformation.** We do not modify request/response payloads
   beyond header injection. If future requirements demand per-tool transformation
   (e.g., rate limiting, logging, response filtering), add it here.

4. **Failure modes**: connection failure to mcp.exa.ai, auth failure (invalid
   key), upstream MCP errors — all propagate to Claude Code via the stdio
   transport. Claude Code surfaces these as tool-call errors.
"""

from __future__ import annotations

import logging
import os
import sys

import anyio
import httpx

# MCP SDK — Anthropic's official Python MCP library.
# For streamable HTTP client, see: https://github.com/modelcontextprotocol/python-sdk
from mcp.client.streamable_http import streamablehttp_client  # type: ignore[import-not-found]
from mcp.server import Server  # type: ignore[import-not-found]
from mcp.server.stdio import stdio_server  # type: ignore[import-not-found]
from mcp.shared.session import ClientSession  # type: ignore[import-not-found]
from mcp import types as mcp_types  # type: ignore[import-not-found]


# Emit operational logs to stderr. stdout is reserved for MCP JSON-RPC.
logging.basicConfig(
    level=os.environ.get("EXA_MCP_LOG_LEVEL", "INFO"),
    format="%(asctime)s exa-mcp-bridge %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("exa_mcp_bridge")


def _require_env(name: str) -> str:
    """Fetch required env var or exit with actionable message."""
    val = os.environ.get(name, "").strip()
    if not val:
        log.error(
            "Required env var %s is not set. "
            "The PS1 launcher (start-exa-mcp.ps1) should populate this from "
            "DPAPI via Get-SOKSecret. If running manually, export it first.",
            name,
        )
        sys.exit(10)
    return val


async def _run_bridge() -> None:
    """Run the stdio-MCP server and proxy all requests to the upstream HTTP MCP.

    Architecture:

        Claude Code ──stdio──> [this bridge] ──HTTPS+Bearer──> mcp.exa.ai/mcp

    Messages are round-tripped without payload transformation; only the
    Authorization header is injected.
    """
    api_key = _require_env("EXA_API_KEY")
    upstream = os.environ.get("EXA_MCP_UPSTREAM", "https://mcp.exa.ai/mcp").strip()
    tools = os.environ.get("EXA_TOOLS", "").strip()

    # Exa's HTTP MCP accepts a `tools` query parameter for server-side tool
    # filtering. We preserve this if provided.
    if tools:
        separator = "&" if "?" in upstream else "?"
        upstream_url = f"{upstream}{separator}tools={tools}"
    else:
        upstream_url = upstream

    headers = {"Authorization": f"Bearer {api_key}"}

    log.info(
        "Starting Exa MCP bridge. Upstream: %s (tools=%s)",
        upstream,  # log without query string
        tools if tools else "<all>",
    )

    # Open the HTTP client session to Exa MCP.
    async with streamablehttp_client(
        url=upstream_url,
        headers=headers,
    ) as (read_stream, write_stream, _):
        async with ClientSession(read_stream, write_stream) as exa_session:
            # Initialize the upstream session so we can enumerate tools/resources.
            await exa_session.initialize()

            # Fetch upstream tool manifest and resources so our stdio server can
            # expose them to Claude Code.
            upstream_tools = await exa_session.list_tools()
            log.info("Exa upstream exposed %d tools", len(upstream_tools.tools))

            # --- Build our stdio MCP server that proxies to the upstream session ---
            server: Server = Server("exa-mcp-bridge")

            @server.list_tools()  # type: ignore[misc]
            async def _list_tools() -> list[mcp_types.Tool]:
                """Return the upstream tool manifest verbatim."""
                return list(upstream_tools.tools)

            @server.call_tool()  # type: ignore[misc]
            async def _call_tool(name: str, arguments: dict) -> list[mcp_types.TextContent]:
                """Forward a tool call to the upstream Exa MCP session."""
                log.debug("Forwarding tool call %s", name)
                result = await exa_session.call_tool(name, arguments)
                # Exa's tool responses come back as MCP content objects.
                # MCP SDK normalizes these to TextContent / ImageContent etc.
                return [
                    c for c in result.content
                    if isinstance(c, mcp_types.TextContent)
                ]

            # --- Run the stdio server. Claude Code speaks to us on stdin/stdout. ---
            async with stdio_server() as (stdio_read, stdio_write):
                await server.run(
                    stdio_read,
                    stdio_write,
                    server.create_initialization_options(),
                )


def main() -> None:
    """Sync entry point — invoked by pyproject.toml [project.scripts]."""
    try:
        anyio.run(_run_bridge)
    except KeyboardInterrupt:
        log.info("Bridge interrupted by user")
        sys.exit(0)
    except Exception as exc:  # noqa: BLE001 — top-level unexpected error handler
        log.exception("Bridge failed: %s", exc)
        sys.exit(11)


if __name__ == "__main__":
    main()

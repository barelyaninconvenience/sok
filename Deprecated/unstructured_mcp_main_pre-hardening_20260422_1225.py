"""Unstructured MCP server — document parsing for the RAG ingestion pipeline."""

from __future__ import annotations

import logging
import os
import sys
from pathlib import Path
from typing import Any

import anyio
from mcp.server import Server  # type: ignore[import-not-found]
from mcp.server.stdio import stdio_server  # type: ignore[import-not-found]
from mcp import types as mcp_types  # type: ignore[import-not-found]
from unstructured.partition.auto import partition  # type: ignore[import-not-found]


logging.basicConfig(
    level=os.environ.get("UNSTRUCTURED_MCP_LOG_LEVEL", "INFO"),
    format="%(asctime)s unstructured-mcp %(levelname)s %(message)s",
    stream=sys.stderr,
)
log = logging.getLogger("unstructured_mcp")


def _element_to_dict(el: Any) -> dict[str, Any]:
    """Normalize an Unstructured element to a JSON-serializable dict."""
    return {
        "category": getattr(el, "category", el.__class__.__name__),
        "text": str(el.text) if hasattr(el, "text") else str(el),
        "metadata": el.metadata.to_dict() if hasattr(el, "metadata") and el.metadata else {},
    }


async def _run_server() -> None:
    server: Server = Server("unstructured-mcp")

    @server.list_tools()  # type: ignore[misc]
    async def _list_tools() -> list[mcp_types.Tool]:
        return [
            mcp_types.Tool(
                name="parse_document",
                description=(
                    "Parse a document (PDF/DOCX/PPTX/HTML/Markdown/image/email) into "
                    "structured elements (Title, NarrativeText, ListItem, Table, ...) "
                    "preserving hierarchy metadata for downstream RAG chunking."
                ),
                inputSchema={
                    "type": "object",
                    "properties": {
                        "file_path": {"type": "string", "description": "Absolute path to document file"},
                        "include_metadata": {"type": "boolean", "default": True},
                        "strategy": {
                            "type": "string",
                            "enum": ["auto", "fast", "hi_res", "ocr_only"],
                            "default": "auto",
                        },
                    },
                    "required": ["file_path"],
                },
            ),
            mcp_types.Tool(
                name="parse_directory",
                description="Parse all supported documents in a directory (non-recursive).",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "dir_path": {"type": "string"},
                        "extensions": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "e.g. ['pdf', 'docx', 'html']",
                        },
                    },
                    "required": ["dir_path"],
                },
            ),
        ]

    @server.call_tool()  # type: ignore[misc]
    async def _call_tool(name: str, arguments: dict[str, Any]) -> list[mcp_types.TextContent]:
        try:
            if name == "parse_document":
                path = Path(arguments["file_path"])
                if not path.exists():
                    return [mcp_types.TextContent(type="text", text=f"ERROR: File not found: {path}")]
                strategy = arguments.get("strategy", "auto")
                elements = partition(filename=str(path), strategy=strategy)
                result = [_element_to_dict(el) for el in elements]
                if not arguments.get("include_metadata", True):
                    for r in result:
                        r.pop("metadata", None)
                return [mcp_types.TextContent(type="text", text=str(result))]

            if name == "parse_directory":
                directory = Path(arguments["dir_path"])
                if not directory.is_dir():
                    return [mcp_types.TextContent(type="text", text=f"ERROR: Not a directory: {directory}")]
                exts = arguments.get("extensions") or ["pdf", "docx", "pptx", "html", "md", "txt"]
                exts = [e.lower().lstrip(".") for e in exts]
                results: dict[str, list[dict[str, Any]]] = {}
                for child in directory.iterdir():
                    if child.is_file() and child.suffix.lower().lstrip(".") in exts:
                        try:
                            elements = partition(filename=str(child))
                            results[child.name] = [_element_to_dict(el) for el in elements]
                        except Exception as exc:  # noqa: BLE001
                            results[child.name] = [{"error": str(exc)}]
                return [mcp_types.TextContent(type="text", text=str(results))]

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

"""Unstructured MCP server — document parsing for the RAG ingestion pipeline."""

from __future__ import annotations

import json
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


# 2026-04-22 hardening: path-traversal prevention.
# Prior behavior accepted any file_path — an attacker (or a misguided Claude
# prompt) could exfiltrate ~/.sok-secrets/*.sec, ~/.ssh/*, private keys, etc.
# Now gated to a configurable allowlist of root directories. Default roots:
# the operator's Documents subtree (where legitimate documents live). Override
# via UNSTRUCTURED_ALLOWED_ROOTS env var (semicolon-separated absolute paths).
def _default_allowed_roots() -> list[Path]:
    roots: list[Path] = []
    home = os.environ.get("USERPROFILE") or os.environ.get("HOME")
    if home:
        # Documents subtree covers Journal/Projects/Readings/etc — the legitimate
        # ingest surface. Explicitly excludes AppData, .ssh, .sok-secrets, etc.
        roots.append(Path(home) / "Documents")
        roots.append(Path(home) / "Downloads")
    return roots


def _allowed_roots() -> list[Path]:
    env = os.environ.get("UNSTRUCTURED_ALLOWED_ROOTS", "").strip()
    if not env:
        return [r.resolve() for r in _default_allowed_roots() if r.exists()]
    roots = [Path(p).resolve() for p in env.split(";") if p.strip()]
    return [r for r in roots if r.exists()]


def _require_allowed_path(path: Path) -> Path:
    """Resolve path (follow symlinks/junctions) and verify it's under an allowed root.

    Returns the resolved path if allowed; raises PermissionError otherwise.
    """
    resolved = path.resolve()
    roots = _allowed_roots()
    if not roots:
        raise PermissionError(
            "No allowed roots configured. Set UNSTRUCTURED_ALLOWED_ROOTS "
            "(semicolon-separated absolute paths) or ensure "
            f"{_default_allowed_roots()} exists."
        )
    for root in roots:
        try:
            resolved.relative_to(root)
            return resolved
        except ValueError:
            continue
    raise PermissionError(
        f"Path is outside allowed roots: {resolved}. "
        f"Allowed: {[str(r) for r in roots]}. "
        f"Override via UNSTRUCTURED_ALLOWED_ROOTS env var if intended."
    )


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
                # 2026-04-22 hardening: path-traversal prevention via allowlist check
                path = _require_allowed_path(Path(arguments["file_path"]))
                if not path.exists():
                    return [mcp_types.TextContent(type="text", text=f"ERROR: File not found: {path}")]
                strategy = arguments.get("strategy", "auto")
                elements = partition(filename=str(path), strategy=strategy)
                result = [_element_to_dict(el) for el in elements]
                if not arguments.get("include_metadata", True):
                    for r in result:
                        r.pop("metadata", None)
                # 2026-04-22 hardening: json.dumps produces valid JSON (not Python repr)
                return [mcp_types.TextContent(type="text", text=json.dumps(result, default=str))]

            if name == "parse_directory":
                directory = _require_allowed_path(Path(arguments["dir_path"]))
                if not directory.is_dir():
                    return [mcp_types.TextContent(type="text", text=f"ERROR: Not a directory: {directory}")]
                exts = arguments.get("extensions") or ["pdf", "docx", "pptx", "html", "md", "txt"]
                exts = [e.lower().lstrip(".") for e in exts]
                results: dict[str, list[dict[str, Any]]] = {}
                for child in directory.iterdir():
                    if child.is_file() and child.suffix.lower().lstrip(".") in exts:
                        try:
                            # Per-file allowlist check in case iterdir surfaces a
                            # file via a symlink/junction that escapes the root
                            _require_allowed_path(child)
                            elements = partition(filename=str(child))
                            results[child.name] = [_element_to_dict(el) for el in elements]
                        except Exception as exc:  # noqa: BLE001
                            results[child.name] = [{"error": str(exc)}]
                return [mcp_types.TextContent(type="text", text=json.dumps(results, default=str))]

            raise ValueError(f"Unknown tool: {name}")
        except PermissionError as exc:
            log.warning("Path-access denied: %s", exc)
            return [mcp_types.TextContent(type="text", text=f"ERROR: path not in allowed roots — {exc}")]
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

"""Gamma MCP server — KLEM/OS Layer 5 content pipeline.

Wraps Gamma API for presentation/document generation from structured content.
Gamma converts Claude-generated outlines into polished slide decks.

API surface: expect iteration as Gamma's API evolves (beta → GA). Endpoint
paths in __main__.py may need updating when Gamma ships stable v1.
"""

__version__ = "1.0.0"

"""Exa MCP stdio-to-HTTP bridge.

Proxies Claude Code stdio MCP requests to Exa's HTTP MCP endpoint
(https://mcp.exa.ai/mcp) with Authorization: Bearer header, eliminating
the plaintext-credential-in-URL pattern from pre-2026-04-21 configuration.

Author: Clay Caddell (Apex Analytics / KLEM/OS custom-MCP-wrap-APIs exemplar)
License: MIT
"""

__version__ = "1.0.0"

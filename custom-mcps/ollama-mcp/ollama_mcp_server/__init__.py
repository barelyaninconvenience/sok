"""Ollama MCP server for KLEM/OS Layer 3 local inference fallback.

Wraps the local Ollama HTTP API (default http://localhost:11434) for:
- generate: text completion via /api/generate
- chat: chat completion via /api/chat
- list_models: installed models via /api/tags
- embed: local embeddings via /api/embeddings (e.g. nomic-embed-text)

No credential required — Ollama is localhost-only by default. Use for
sensitive-data processing that shouldn't touch external APIs.
"""

__version__ = "1.0.0"

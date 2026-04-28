"""Supabase MCP server for KLEM/OS Layer 1 data access.

Wraps Supabase (PostgreSQL + pgvector) with tools for:
- CRUD on knowledge_assets, knowledge_chunks, projects, session_logs tables
- Semantic similarity search via pgvector match_knowledge_chunks RPC
- Arbitrary SQL via exec_sql RPC (service-role-key only)

Credentials (SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY) read from env vars,
populated by start-supabase-mcp.ps1 from DPAPI store via Get-SOKSecret.
"""

__version__ = "1.0.0"

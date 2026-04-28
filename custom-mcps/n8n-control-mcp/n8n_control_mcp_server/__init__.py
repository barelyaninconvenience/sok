"""n8n-control MCP server — KLEM/OS Layer 4 workflow orchestration control.

Wraps n8n's REST API so Claude Code can:
- list workflows
- trigger workflows by ID
- read execution history + statuses
- activate/deactivate workflows

For use cases where synchronous workflows live in Claude Code (Agent Teams)
but asynchronous/cron workflows still live in n8n — this MCP lets Claude
Code observe + orchestrate the n8n side without leaving the Claude session.
"""

__version__ = "1.0.0"

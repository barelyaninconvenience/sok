"""Unstructured MCP server — KLEM/OS Layer 2 document parsing.

Wraps the unstructured Python library for PDF/DOCX/PPTX/HTML/Markdown/OCR/email
parsing. Returns structured elements (Title, NarrativeText, ListItem, Table, ...)
as MCP tool responses for downstream RAG chunking + embedding workflows.

Runs entirely local by default. Hosted API fallback via UNSTRUCTURED_API_KEY
env var if set.
"""

__version__ = "1.0.0"

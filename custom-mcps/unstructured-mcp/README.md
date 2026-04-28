# Unstructured MCP Server

**Purpose:** Layer 2 document parsing — wraps `unstructured.io` Python library for PDF/DOCX/PPTX/HTML/Markdown/OCR/email parsing into structured elements.

**KLEM/OS v3 roster entry:** Part F Priority P3. No credential required (local library).

## Exposed MCP tools

| Tool | Purpose |
|---|---|
| `parse_document` | Parse single file into elements (Title / NarrativeText / ListItem / Table / ...) |
| `parse_directory` | Parse all supported docs in a directory |

## Output shape

Each parsed element is a dict:
```json
{
  "category": "Title|NarrativeText|ListItem|Table|...",
  "text": "<content>",
  "metadata": { "page_number": 3, "parent_id": "...", "coordinates": {...} }
}
```

Preserves document hierarchy — critical for later RAG retrieval (chunks tagged with section headings retrieve more accurately than orphan paragraphs).

## Deployment

1. Copy to production:
   ```powershell
   Copy-Item -Recurse -Force `
     'C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps\unstructured-mcp\*' `
     'C:\Users\shelc\.unstructured-mcp\'
   ```

2. Add to `~/.mcp.json`:
   ```json
   "unstructured": {
     "type": "stdio",
     "command": "pwsh",
     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
              "C:\\Users\\shelc\\.unstructured-mcp\\start-unstructured-mcp.ps1"]
   }
   ```

3. Restart Claude Code. Verify via `parse_document` against any PDF in Documents/.

## Performance notes

- `strategy=auto` — default; chooses fast/hi_res based on document type
- `strategy=fast` — text extraction only, no OCR; sub-second for clean PDFs
- `strategy=hi_res` — layout-preserving, slower; use when tables/columns matter
- `strategy=ocr_only` — force OCR; needed for scanned documents + images

First run downloads OCR models (~few GB) if `hi_res` or OCR used.

## Optional hosted API fallback

If `UNSTRUCTURED_API_KEY` is set in DPAPI (`Set-SOKSecret -Name 'UNSTRUCTURED_API_KEY'`), launcher populates env var. Current server implementation uses local library only — hosted-API support is a ~20-line extension if needed.

---

*Fourth custom-MCP exemplar. Library-wrap variant (no network, no credential).*

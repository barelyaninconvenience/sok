"""Smoke test weasyprint on Windows."""
import sys
from pathlib import Path

try:
    from weasyprint import HTML
except ImportError as e:
    print(f"FAIL: import error: {e}")
    sys.exit(1)

test_html = """<!DOCTYPE html>
<html><head><title>weasyprint smoke test</title>
<style>body { font-family: sans-serif; padding: 2em; }
h1 { color: #444; } table { border-collapse: collapse; }
td, th { border: 1px solid #999; padding: 4px 8px; }</style>
</head><body>
<h1>weasyprint smoke test</h1>
<p>If this PDF renders with proper typography, tables, and CSS, weasyprint works on Windows.</p>
<table><tr><th>Col A</th><th>Col B</th></tr><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>
</body></html>"""

out_dir = Path(r"C:\Users\shelc\Documents\Journal\Projects\scripts\Deprecated")
html_path = out_dir / "weasyprint-test.html"
pdf_path = out_dir / "weasyprint-test.pdf"

html_path.write_text(test_html, encoding="utf-8")
print(f"Wrote test HTML: {html_path}")

try:
    HTML(string=test_html).write_pdf(str(pdf_path))
    size = pdf_path.stat().st_size
    print(f"PDF generated: {pdf_path} ({size} bytes)")
    print("SUCCESS" if size > 500 else f"SUSPECT: PDF too small ({size} bytes)")
except Exception as e:
    print(f"FAIL: {type(e).__name__}: {e}")
    sys.exit(2)

"""Smoke test: playwright HTML to PDF."""
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

test_html = """<!DOCTYPE html>
<html><head><title>playwright smoke test</title>
<style>body { font-family: sans-serif; padding: 2em; }
h1 { color: #444; } table { border-collapse: collapse; }
td, th { border: 1px solid #999; padding: 4px 8px; }</style>
</head><body>
<h1>playwright smoke test</h1>
<p>If this PDF renders with proper typography, tables, and CSS, playwright works on Windows.</p>
<table><tr><th>Col A</th><th>Col B</th></tr><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>
</body></html>"""

out_dir = Path(r"C:\Users\shelc\Documents\Journal\Projects\scripts\Deprecated")
html_path = out_dir / "playwright-test.html"
pdf_path = out_dir / "playwright-test.pdf"
html_path.write_text(test_html, encoding="utf-8")
print(f"Wrote HTML: {html_path}")

try:
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        page.goto(f"file:///{html_path.as_posix()}")
        page.pdf(path=str(pdf_path), format="Letter", margin={"top": "0.5in", "bottom": "0.5in", "left": "0.5in", "right": "0.5in"})
        browser.close()
    size = pdf_path.stat().st_size
    print(f"PDF generated: {pdf_path} ({size} bytes)")
    print("SUCCESS" if size > 500 else f"SUSPECT: PDF too small ({size})")
except Exception as e:
    print(f"FAIL: {type(e).__name__}: {e}")
    sys.exit(1)

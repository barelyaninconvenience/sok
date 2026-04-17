"""Background watcher: convert Canvas_Captures .html files to .pdf via playwright.

Polls all `Canvas_Captures/` subdirectories under `UC MS-IS/` recursively.
For each .html file without a matching .pdf sibling, converts via playwright.

- Single playwright browser instance, reused across conversions (fast)
- Settle-check: waits until HTML file size is stable for 3s before converting
  (avoids race with the capture process still writing)
- Logs to file + stderr, one line per action
- Polls every 5 seconds; idle when nothing to do
- Graceful per-file error handling: one bad HTML doesn't crash the loop

Invoked by Claude at session start via run_in_background=true. Lives for the
duration of the session; killed when the parent Bash terminates.
"""

import sys
import time
import traceback
from pathlib import Path
from datetime import datetime

try:
    from playwright.sync_api import sync_playwright
except ImportError as e:
    print(f"FATAL: playwright not available: {e}", file=sys.stderr)
    sys.exit(1)

ROOT = Path(r"C:\Users\shelc\Documents\UC MS-IS")
LOG_PATH = Path(r"C:\Users\shelc\Documents\UC MS-IS\canvas-pdf-watcher.log")
POLL_INTERVAL_SEC = 5
SETTLE_CHECK_SEC = 3

def log(msg):
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{stamp}] {msg}"
    print(line, file=sys.stderr, flush=True)
    try:
        with LOG_PATH.open("a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception:
        pass

def find_pending_html() -> list[Path]:
    """Find all .html files in Canvas_Captures/ subdirs without a matching .pdf."""
    pending = []
    for capture_dir in ROOT.rglob("Canvas_Captures"):
        if not capture_dir.is_dir():
            continue
        for html in capture_dir.rglob("*.html"):
            pdf = html.with_suffix(".pdf")
            if not pdf.exists():
                pending.append(html)
    return pending

def is_settled(path: Path) -> bool:
    """Return True if file size has been stable for SETTLE_CHECK_SEC."""
    try:
        s1 = path.stat().st_size
        time.sleep(SETTLE_CHECK_SEC)
        s2 = path.stat().st_size
        return s1 == s2 and s1 > 0
    except FileNotFoundError:
        return False

def convert_html_to_pdf(page, html_path: Path) -> bool:
    """Convert one HTML file to PDF beside it. Returns True on success."""
    pdf_path = html_path.with_suffix(".pdf")
    try:
        page.goto(f"file:///{html_path.as_posix()}", wait_until="domcontentloaded", timeout=30000)
        page.pdf(
            path=str(pdf_path),
            format="Letter",
            margin={"top": "0.5in", "bottom": "0.5in", "left": "0.5in", "right": "0.5in"},
            print_background=True,
        )
        size = pdf_path.stat().st_size
        log(f"CONVERTED {html_path.name} -> {pdf_path.name} ({size} bytes)")
        return True
    except Exception as e:
        log(f"FAILED {html_path.name}: {type(e).__name__}: {e}")
        return False

def main():
    log(f"canvas-html-to-pdf-watcher starting. root={ROOT}")
    if not ROOT.exists():
        log(f"FATAL: root does not exist: {ROOT}")
        sys.exit(2)
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        log("Browser ready (playwright chromium headless)")
        try:
            while True:
                pending = find_pending_html()
                if pending:
                    log(f"Found {len(pending)} pending HTML file(s)")
                    for html in pending:
                        if is_settled(html):
                            convert_html_to_pdf(page, html)
                        else:
                            log(f"Skipping (not settled): {html.name}")
                time.sleep(POLL_INTERVAL_SEC)
        except KeyboardInterrupt:
            log("Interrupted by signal")
        except Exception as e:
            log(f"Loop exception: {type(e).__name__}: {e}")
            log(traceback.format_exc())
        finally:
            try:
                browser.close()
            except Exception:
                pass
            log("Watcher exiting")

if __name__ == "__main__":
    main()

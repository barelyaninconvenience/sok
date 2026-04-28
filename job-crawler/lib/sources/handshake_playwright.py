"""Playwright-based Handshake scraper for batch runs.

This connects to an already-running Chrome instance via the DevTools Protocol
(CDP). Clay launches Chrome manually with --remote-debugging-port=9222, logs
into Handshake, and then this script attaches to that browser and drives
the scraping without interfering with Clay's other tabs.

Launch Chrome with CDP (in PowerShell):
    & "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe" `
        --remote-debugging-port=9222 `
        --user-data-dir="$env:LOCALAPPDATA\\Google\\Chrome\\User Data"

Then log into Handshake in one tab, and run:
    python lib/sources/handshake_playwright.py --search-url "https://app.joinhandshake.com/..." --max-jobs 1000
"""

from __future__ import annotations

import argparse
import asyncio
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from lib.normalize import make_normalized_job
from lib.storage import connect, insert_job, backup_raw, DEFAULT_DB


# Handshake job-detail selectors. Brittle — may need tuning.
SELECTORS = {
    "job_card_links": "a[href*='/jobs/']",
    "job_title": "h1, [data-hook='job-title']",
    "company_name": "[data-hook='employer-name'], .employer-name",
    "job_description": "[data-hook='job-description'], .job-description, main",
    "pay_info": "[data-hook='pay-info'], .pay-range",
    "location": "[data-hook='location-label']",
}


async def scrape_handshake_batch(
    search_url: str,
    max_jobs: int = 1000,
    cdp_endpoint: str = "http://localhost:9222",
    delay_seconds: float = 2.5,
) -> None:
    try:
        from playwright.async_api import async_playwright
    except ImportError:
        print("Playwright not installed. Run: pip install playwright && playwright install chromium")
        sys.exit(1)

    async with async_playwright() as p:
        # Connect to existing Chrome via CDP
        try:
            browser = await p.chromium.connect_over_cdp(cdp_endpoint)
        except Exception as e:
            print(f"Failed to connect to Chrome at {cdp_endpoint}: {e}")
            print("Ensure Chrome is running with --remote-debugging-port=9222")
            sys.exit(1)

        # Use the first available context (already-authenticated)
        contexts = browser.contexts
        if not contexts:
            print("No Chrome contexts found. Open a browser window first.")
            sys.exit(1)
        context = contexts[0]

        # Open a new page for our scraping
        page = await context.new_page()

        # Phase 1: Collect job URLs from search results
        print(f"Navigating to search: {search_url}")
        await page.goto(search_url, wait_until="networkidle", timeout=60000)
        await page.wait_for_timeout(2000)

        job_urls = set()
        page_num = 1
        empty_page_count = 0

        while len(job_urls) < max_jobs and empty_page_count < 2:
            print(f"Search page {page_num}: collecting URLs...")

            # Extract job URLs from current search page
            links = await page.query_selector_all(SELECTORS["job_card_links"])
            new_urls_this_page = 0
            for link in links:
                href = await link.get_attribute("href")
                if href and "/jobs/" in href:
                    # Normalize: handle relative URLs
                    if href.startswith("/"):
                        full_url = f"https://app.joinhandshake.com{href}"
                    else:
                        full_url = href
                    # Filter to job-detail pages (not search)
                    if "/jobs/" in full_url and "job-search" not in full_url:
                        if full_url not in job_urls:
                            job_urls.add(full_url)
                            new_urls_this_page += 1

            print(f"  +{new_urls_this_page} new URLs (total: {len(job_urls)})")

            if new_urls_this_page == 0:
                empty_page_count += 1
            else:
                empty_page_count = 0

            if len(job_urls) >= max_jobs:
                break

            # Try to click Next page button
            next_button = await page.query_selector(
                "a[aria-label='Next'], button[aria-label='Next'], a.pagination__next"
            )
            if not next_button:
                # Try URL-based pagination
                current_url = page.url
                if "page=" in current_url:
                    from urllib.parse import urlparse, parse_qs, urlencode, urlunparse
                    parsed = urlparse(current_url)
                    qs = parse_qs(parsed.query)
                    current_page = int(qs.get("page", ["1"])[0])
                    qs["page"] = [str(current_page + 1)]
                    new_url = urlunparse(parsed._replace(query=urlencode(qs, doseq=True)))
                    await page.goto(new_url, wait_until="networkidle", timeout=30000)
                else:
                    print("No pagination control found; stopping search collection.")
                    break
            else:
                await next_button.click()
                await page.wait_for_load_state("networkidle", timeout=30000)
            page_num += 1
            await page.wait_for_timeout(int(delay_seconds * 1000))

        print(f"Collected {len(job_urls)} job URLs")

        # Phase 2: Scrape each job detail page
        conn = connect(DEFAULT_DB)
        raw_dir = DEFAULT_DB.parent / "raw" / "handshake"
        raw_dir.mkdir(parents=True, exist_ok=True)

        inserted = 0
        skipped = 0
        errors = 0

        for i, url in enumerate(sorted(job_urls), 1):
            if i % 20 == 0:
                print(f"[{i}/{len(job_urls)}] inserted={inserted} skipped={skipped} errors={errors}")

            try:
                await page.goto(url, wait_until="networkidle", timeout=45000)
                await page.wait_for_timeout(1500)

                # Extract fields
                title_el = await page.query_selector(SELECTORS["job_title"])
                title = await title_el.inner_text() if title_el else ""
                company_el = await page.query_selector(SELECTORS["company_name"])
                company = await company_el.inner_text() if company_el else ""
                desc_el = await page.query_selector(SELECTORS["job_description"])
                description = await desc_el.inner_text() if desc_el else ""
                pay_el = await page.query_selector(SELECTORS["pay_info"])
                pay_raw = await pay_el.inner_text() if pay_el else ""

                if not title:
                    errors += 1
                    continue

                job = make_normalized_job(
                    source="handshake",
                    source_url=url,
                    title=title.strip(),
                    company=company.strip() if company else "",
                    pay_raw=pay_raw.strip() if pay_raw else "",
                    description_md=description.strip() if description else "",
                )
                job.raw_html_path = backup_raw(raw_dir, job.id, job.description_md)
                if insert_job(conn, job):
                    inserted += 1
                else:
                    skipped += 1
            except Exception as e:
                errors += 1
                print(f"  ! error on {url}: {type(e).__name__}: {e}")

            await page.wait_for_timeout(int(delay_seconds * 1000))

        conn.close()
        await page.close()
        print(f"\nComplete: inserted={inserted} skipped={skipped} errors={errors} total={len(job_urls)}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--search-url", required=True,
                    help="Handshake search URL (remote filter, etc.)")
    ap.add_argument("--max-jobs", type=int, default=1000)
    ap.add_argument("--cdp", default="http://localhost:9222",
                    help="Chrome DevTools endpoint")
    ap.add_argument("--delay", type=float, default=2.5,
                    help="Seconds between requests (rate-limiting)")
    args = ap.parse_args()

    asyncio.run(scrape_handshake_batch(
        search_url=args.search_url,
        max_jobs=args.max_jobs,
        cdp_endpoint=args.cdp,
        delay_seconds=args.delay,
    ))


if __name__ == "__main__":
    main()

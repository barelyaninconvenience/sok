"""Build search URLs across sites for batch seeding."""

from __future__ import annotations

from .sources import linkedin, indeed, wellfound


def build_all(
    *,
    keywords: str = "remote",
    location: str = "United States",
    salary_min: int | None = None,
    pages_per_site: int = 3,
) -> dict[str, list[str]]:
    """Return a dict of source → list of search URLs (paginated).

    This is not a list of job URLs — these are search-result pages that,
    when scraped, yield job URLs.
    """
    urls: dict[str, list[str]] = {}

    urls["linkedin"] = [
        linkedin.build_search_url(
            keywords=keywords, location=location, remote_only=True,
            salary_min=salary_min, page=p,
        )
        for p in range(1, pages_per_site + 1)
    ]
    urls["indeed"] = [
        indeed.build_search_url(
            q=keywords, l=location, remotejob=True,
            salary_min=salary_min, page=p,
        )
        for p in range(1, pages_per_site + 1)
    ]
    urls["wellfound"] = [wellfound.build_search_url(role=keywords, remote_only=True)]

    return urls

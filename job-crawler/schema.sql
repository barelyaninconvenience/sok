-- Job Crawler SQLite schema
-- 2026-04-23

CREATE TABLE IF NOT EXISTS sources (
    source_id TEXT PRIMARY KEY,      -- 'handshake', 'remoteok', 'wwr', etc.
    display_name TEXT NOT NULL,
    auth_required INTEGER NOT NULL,  -- 0 or 1
    crawler_type TEXT NOT NULL,      -- 'chrome_mcp', 'crawl4ai', 'api', 'rss'
    notes TEXT
);

INSERT OR IGNORE INTO sources VALUES
    ('handshake', 'Handshake', 1, 'chrome_mcp', 'UC-scoped; requires logged-in session'),
    ('linkedin', 'LinkedIn Jobs', 1, 'chrome_mcp', 'Aggressive anti-bot; rate-limit heavy'),
    ('indeed', 'Indeed', 1, 'chrome_mcp', 'Semi-auth; login improves quality'),
    ('wellfound', 'Wellfound', 1, 'chrome_mcp', 'Startup focus'),
    ('remoteok', 'RemoteOK', 0, 'api', 'Public JSON API at remoteok.com/api'),
    ('wwr', 'We Work Remotely', 0, 'rss', 'RSS feed available'),
    ('builtin', 'BuiltIn', 0, 'crawl4ai', 'City-specific search'),
    ('ziprecruiter', 'ZipRecruiter', 0, 'crawl4ai', 'Public search');

CREATE TABLE IF NOT EXISTS raw_jobs (
    id TEXT PRIMARY KEY,             -- SHA256 hash of (source_url + title + company)[:16]
    source TEXT NOT NULL REFERENCES sources(source_id),
    source_url TEXT NOT NULL,
    title TEXT NOT NULL,
    company TEXT,
    pay_raw TEXT,
    pay_min INTEGER,
    pay_max INTEGER,
    pay_type TEXT,                   -- 'hourly', 'annual', 'unknown'
    remote_status TEXT,              -- 'fully_remote', 'hybrid', 'onsite', 'unclear'
    location TEXT,
    description_md TEXT,             -- markdown; extracted via crawl4ai or Chrome MCP
    posted_date TEXT,
    scraped_at TEXT NOT NULL,        -- ISO 8601
    raw_html_path TEXT,              -- path to backup
    dedup_group_id TEXT REFERENCES dedupe_groups(group_id)
);

CREATE INDEX IF NOT EXISTS idx_raw_jobs_source ON raw_jobs(source);
CREATE INDEX IF NOT EXISTS idx_raw_jobs_company ON raw_jobs(company);
CREATE INDEX IF NOT EXISTS idx_raw_jobs_scraped ON raw_jobs(scraped_at);

CREATE TABLE IF NOT EXISTS scored_jobs (
    id TEXT PRIMARY KEY REFERENCES raw_jobs(id),
    score_automatability INTEGER,
    score_oversight INTEGER,
    score_pay INTEGER,
    score_remote INTEGER,
    score_stakes INTEGER,
    score_flexibility INTEGER,
    score_total INTEGER,             -- sum of above, /12
    red_flags TEXT,                  -- JSON array
    green_flags TEXT,                -- JSON array
    verdict TEXT,
    recommend TEXT,                  -- 'apply', 'maybe', 'skip'
    scored_at TEXT NOT NULL,
    model_used TEXT
);

CREATE INDEX IF NOT EXISTS idx_scored_total ON scored_jobs(score_total DESC);
CREATE INDEX IF NOT EXISTS idx_scored_recommend ON scored_jobs(recommend);

CREATE TABLE IF NOT EXISTS applications (
    job_id TEXT PRIMARY KEY REFERENCES raw_jobs(id),
    status TEXT NOT NULL,            -- 'not_applied', 'applied', 'phone_screen', 'interview', 'offer', 'rejected', 'withdrawn'
    applied_at TEXT,
    last_contact TEXT,
    notes TEXT,
    cover_letter_path TEXT,
    resume_path TEXT
);

CREATE TABLE IF NOT EXISTS dedupe_groups (
    group_id TEXT PRIMARY KEY,       -- hash of canonical (title + company) signature
    canonical_title TEXT,
    canonical_company TEXT,
    member_count INTEGER DEFAULT 1,
    created_at TEXT NOT NULL
);

-- Convenience view: top candidates
CREATE VIEW IF NOT EXISTS v_shortlist AS
SELECT
    r.id,
    r.source,
    r.title,
    r.company,
    r.pay_raw,
    r.pay_min,
    r.remote_status,
    s.score_total,
    s.recommend,
    s.verdict,
    s.red_flags,
    s.green_flags,
    COALESCE(a.status, 'not_applied') as application_status
FROM raw_jobs r
JOIN scored_jobs s ON s.id = r.id
LEFT JOIN applications a ON a.job_id = r.id
WHERE s.score_total >= 9
ORDER BY s.score_total DESC, r.scraped_at DESC;

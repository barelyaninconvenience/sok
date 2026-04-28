-- Schema v2 migration: add v2 columns to scored_jobs WITHOUT dropping v1 data.
-- Safe to run multiple times (uses ADD COLUMN IF NOT EXISTS via PRAGMA).
-- 2026-04-23.

-- Clay's policy: do NOT auto-migrate v1 scores. Keep them as historical record.
-- New jobs scored with v2 get tagged with rubric_version='2.0'.

-- Add columns for v2 dimensions (SQLite ADD COLUMN is idempotent if column doesn't exist)
ALTER TABLE scored_jobs ADD COLUMN rubric_version TEXT DEFAULT '1.0';

ALTER TABLE scored_jobs ADD COLUMN score_remote_depth INTEGER;
ALTER TABLE scored_jobs ADD COLUMN score_synchronous_oversight INTEGER;
ALTER TABLE scored_jobs ADD COLUMN score_detection_risk INTEGER;
ALTER TABLE scored_jobs ADD COLUMN score_time_flexibility INTEGER;
ALTER TABLE scored_jobs ADD COLUMN score_task_surface_area INTEGER;
ALTER TABLE scored_jobs ADD COLUMN score_pay_position INTEGER;
ALTER TABLE scored_jobs ADD COLUMN score_stakes INTEGER;
ALTER TABLE scored_jobs ADD COLUMN score_onboarding_gauntlet INTEGER;

ALTER TABLE scored_jobs ADD COLUMN weighted_sum REAL;
ALTER TABLE scored_jobs ADD COLUMN detection_multiplier REAL;
ALTER TABLE scored_jobs ADD COLUMN final_score REAL;
ALTER TABLE scored_jobs ADD COLUMN vetoed INTEGER DEFAULT 0;
ALTER TABLE scored_jobs ADD COLUMN veto_reason TEXT;

-- Update existing v1 rows to be explicit about their version
UPDATE scored_jobs SET rubric_version = '1.0' WHERE rubric_version IS NULL;

-- Create v2 shortlist view (final_score >= 30, not vetoed, above risk tolerance)
CREATE VIEW IF NOT EXISTS v_shortlist_v2 AS
SELECT
    r.id,
    r.source,
    r.title,
    r.company,
    r.pay_raw,
    r.pay_min,
    r.remote_status,
    s.final_score,
    s.weighted_sum,
    s.detection_multiplier,
    s.recommend,
    s.verdict,
    s.red_flags,
    s.green_flags,
    s.vetoed,
    s.veto_reason,
    s.rubric_version,
    COALESCE(a.status, 'not_applied') as application_status
FROM raw_jobs r
JOIN scored_jobs s ON s.id = r.id
LEFT JOIN applications a ON a.job_id = r.id
WHERE s.rubric_version = '2.0'
  AND s.vetoed = 0
  AND s.detection_multiplier >= 0.96
  AND s.final_score >= 30
ORDER BY s.final_score DESC, r.scraped_at DESC;

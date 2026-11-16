-- ============================================================
-- FIX: applications_count on jobs table is stale / always 0
-- Run this ONCE in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. Backfill: update every job's applications_count to the real value
UPDATE jobs
SET applications_count = (
  SELECT COUNT(*) FROM applications WHERE applications.job_id = jobs.id
);

-- 2. Trigger function: keep applications_count in sync automatically
CREATE OR REPLACE FUNCTION sync_applications_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE jobs SET applications_count = applications_count + 1
    WHERE id = NEW.job_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE jobs SET applications_count = GREATEST(applications_count - 1, 0)
    WHERE id = OLD.job_id;
  END IF;
  RETURN NULL;
END;
$$;

-- 3. Attach trigger to applications table
DROP TRIGGER IF EXISTS trg_sync_applications_count ON applications;
CREATE TRIGGER trg_sync_applications_count
  AFTER INSERT OR DELETE ON applications
  FOR EACH ROW EXECUTE FUNCTION sync_applications_count();

-- ============================================================
-- SkillConnect — Make every seeded student apply to every job
-- Run in Supabase SQL Editor, AFTER:
--   1. reset_and_seed_professional_users.sql
--   2. add_10_professional_jobs.sql
--
-- Creates one application per (student × job) pair — 10 students
-- × 10 jobs = 100 applications — with varied statuses (applied /
-- shortlisted / interview / offer / rejected) and staggered dates
-- so the Recruiter Dashboard, "Your Job Postings" applicant
-- counts, and each Applicants screen are all populated with real,
-- realistic-looking data. Also creates the matching `conversations`
-- row per application (same pattern the app itself uses when a
-- student applies) so chat between recruiter and applicant works.
--
-- Safe to re-run — skips any (job, student) pair that already has
-- an application.
-- ============================================================

WITH new_apps AS (
  INSERT INTO applications (job_id, applicant_id, status, cover_letter, applied_at)
  SELECT
    j.id,
    p.id,
    -- applications.status is the Postgres enum "app_status", not plain
    -- text — needs an explicit cast or Postgres rejects it (42804).
    (ARRAY['applied','applied','shortlisted','interview','applied','rejected','applied','shortlisted','offer','applied']::app_status[])
      [1 + (row_number() OVER (ORDER BY j.id, p.id)::int % 10)],
    'Excited to apply for the ' || j.title || ' role at ' || COALESCE(c.name, 'your company')
      || ' — I believe my background in ' || COALESCE(p.headline, 'this field') || ' makes me a strong fit.',
    NOW() - ((random() * 20)::int || ' days')::interval - ((random() * 23)::int || ' hours')::interval
  FROM jobs j
  JOIN companies c ON c.id = j.company_id
  CROSS JOIN public.profiles p
  WHERE p.role = 'student'
    AND j.posted_by IN (
      SELECT id FROM public.profiles
      WHERE username IN ('kavitha.ramesh', 'suresh.babu', 'meena.krishnan', 'arjun.nair', 'deepa.venkatesh')
    )
    AND NOT EXISTS (
      SELECT 1 FROM applications a WHERE a.job_id = j.id AND a.applicant_id = p.id
    )
  RETURNING id
)
INSERT INTO conversations (id)
SELECT id FROM new_apps
ON CONFLICT (id) DO NOTHING;

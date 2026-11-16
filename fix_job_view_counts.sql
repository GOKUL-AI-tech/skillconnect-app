-- ============================================================
-- SkillConnect — Make job view counts realistic
-- Run in Supabase SQL Editor, AFTER add_10_professional_jobs.sql
--
-- The 10 seeded jobs carried over view counts (874, 1105, etc.)
-- from an older demo dataset — way too high for postings that are
-- only minutes old ("43m ago" showing 1527 total views doesn't
-- add up). This resets each job's `views` to a small, believable
-- number for a freshly-posted listing instead.
--
-- "Total Views" on the Recruiter Dashboard is a live sum of each
-- job's views column, so this is the only place that needs fixing.
-- ============================================================

UPDATE public.jobs j SET views = v.views
FROM (VALUES
  ('Flutter Developer — Google Pay',        92),
  ('Backend Engineer — Payments Core',      61),
  ('React Native Developer',                78),
  ('Product Manager — Growth',             134),
  ('Java Full Stack Developer',             47),
  ('DevOps Engineer — Platform',            85),
  ('Android Developer — Seller App',        39),
  ('Fullstack Engineer — Investments',     102),
  ('Senior Product Designer',               88),
  ('Part-Time Python Tutor',                56)
) AS v(title, views)
WHERE j.title = v.title;

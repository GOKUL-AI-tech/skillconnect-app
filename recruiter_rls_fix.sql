-- ============================================================
-- RLS FIX: Allow recruiters to read & manage applications
-- Run this in your Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. Recruiters can SELECT applications for jobs they posted
DROP POLICY IF EXISTS "Recruiter can view applications for own jobs" ON applications;
CREATE POLICY "Recruiter can view applications for own jobs"
  ON applications FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = applications.job_id
        AND jobs.posted_by = auth.uid()
    )
  );

-- 2. Recruiters can UPDATE status on applications for their jobs
DROP POLICY IF EXISTS "Recruiter can update status on own job applications" ON applications;
CREATE POLICY "Recruiter can update status on own job applications"
  ON applications FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = applications.job_id
        AND jobs.posted_by = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = applications.job_id
        AND jobs.posted_by = auth.uid()
    )
  );

-- 3. Any authenticated user can read public profile info
--    (needed so applicant name/avatar shows in recruiter view)
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
  ON profiles FOR SELECT
  USING (auth.role() = 'authenticated');

-- 4. Applicants can still read their own applications (keep existing)
DROP POLICY IF EXISTS "Users can view own applications" ON applications;
CREATE POLICY "Users can view own applications"
  ON applications FOR SELECT
  USING (applicant_id = auth.uid());

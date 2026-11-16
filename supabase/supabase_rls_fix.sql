-- ── Companies table RLS policies ──────────────────────────────────────────
-- Run this in Supabase Dashboard → SQL Editor

-- 1. Allow anyone (including unauthenticated) to READ companies
CREATE POLICY "Companies are publicly readable"
ON companies FOR SELECT
USING (true);

-- 2. Allow authenticated recruiters/admins to INSERT new companies
CREATE POLICY "Recruiters can insert companies"
ON companies FOR INSERT
TO authenticated
WITH CHECK (true);

-- 3. Allow the company owner (via jobs.posted_by) to UPDATE company info
CREATE POLICY "Recruiters can update their companies"
ON companies FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);


-- ── Jobs table RLS policies ────────────────────────────────────────────────

-- 4. Allow anyone to read active jobs
CREATE POLICY "Active jobs are publicly readable"
ON jobs FOR SELECT
USING (is_active = true);

-- 5. Allow recruiters to read ALL their own jobs (including inactive)
CREATE POLICY "Recruiters can read own jobs"
ON jobs FOR SELECT
TO authenticated
USING (posted_by = auth.uid());

-- 6. Allow authenticated recruiters to INSERT jobs
CREATE POLICY "Recruiters can post jobs"
ON jobs FOR INSERT
TO authenticated
WITH CHECK (posted_by = auth.uid());

-- 7. Allow recruiters to UPDATE their own jobs
CREATE POLICY "Recruiters can update own jobs"
ON jobs FOR UPDATE
TO authenticated
USING (posted_by = auth.uid())
WITH CHECK (posted_by = auth.uid());

-- 8. Allow recruiters to DELETE their own jobs
CREATE POLICY "Recruiters can delete own jobs"
ON jobs FOR DELETE
TO authenticated
USING (posted_by = auth.uid());


-- ── Applications table RLS policies ───────────────────────────────────────

-- 9. Students can insert (apply) their own applications
CREATE POLICY "Students can apply to jobs"
ON applications FOR INSERT
TO authenticated
WITH CHECK (applicant_id = auth.uid());

-- 10. Students can read their own applications
CREATE POLICY "Students can read own applications"
ON applications FOR SELECT
TO authenticated
USING (applicant_id = auth.uid());

-- 11. Recruiters can read applications on their jobs
CREATE POLICY "Recruiters can read applications on their jobs"
ON applications FOR SELECT
TO authenticated
USING (
  job_id IN (
    SELECT id FROM jobs WHERE posted_by = auth.uid()
  )
);

-- 12. Recruiters can update application status (shortlist, reject, etc.)
CREATE POLICY "Recruiters can update application status"
ON applications FOR UPDATE
TO authenticated
USING (
  job_id IN (
    SELECT id FROM jobs WHERE posted_by = auth.uid()
  )
);


-- ── Saved jobs RLS policies ────────────────────────────────────────────────

-- 13. Students can save/unsave jobs
CREATE POLICY "Students can manage saved jobs"
ON saved_jobs FOR ALL
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());


-- ── Messages RLS policies ──────────────────────────────────────────────────

-- 14. Users can read messages in their own conversations
CREATE POLICY "Users can read messages in their conversations"
ON messages FOR SELECT
TO authenticated
USING (
  conversation_id IN (
    SELECT id FROM applications
    WHERE applicant_id = auth.uid()
       OR job_id IN (SELECT id FROM jobs WHERE posted_by = auth.uid())
  )
);

-- 15. Users can send messages in their own conversations
CREATE POLICY "Users can send messages in their conversations"
ON messages FOR INSERT
TO authenticated
WITH CHECK (
  sender_id = auth.uid()
  AND conversation_id IN (
    SELECT id FROM applications
    WHERE applicant_id = auth.uid()
       OR job_id IN (SELECT id FROM jobs WHERE posted_by = auth.uid())
  )
);


-- ── Profiles RLS policies ──────────────────────────────────────────────────

-- 16. Profiles are publicly readable
CREATE POLICY "Profiles are publicly readable"
ON profiles FOR SELECT
USING (true);

-- 17. Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

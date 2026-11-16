-- ============================================================
-- SkillConnect — Reset Dummy Data & Create Professional Users
-- Run in Supabase SQL Editor (Dashboard → SQL Editor)
--
-- What this does:
--   1. Deletes ALL existing jobs, applications, messages,
--      conversations, saved jobs, notifications, and companies.
--   2. Deletes every non-admin profile (role = student/recruiter)
--      along with their auth login accounts — this removes the
--      test/dummy accounts ("no", "test", etc.) along with
--      everything they created.
--   3. Creates 15 fresh professional-looking accounts:
--        • 10 Student (Employee) accounts
--        •  5 HR (Recruiter) accounts
--      Every account uses the app's colored-initials avatar —
--      no photo file is set, so nothing extra to upload.
--
-- Any existing profile with role = 'admin' is left untouched.
--
-- Full login list is at the bottom of this file (also printed
-- via NOTICE when the script finishes).
-- ============================================================

-- ── 1. Wipe existing data — children before parents ─────────
DELETE FROM messages;
DELETE FROM conversations;
DELETE FROM applications;
DELETE FROM saved_jobs;
DELETE FROM notifications;
DELETE FROM jobs;
DELETE FROM companies;

-- Delete non-admin auth accounts + their profiles
DELETE FROM auth.identities
WHERE user_id IN (SELECT id FROM public.profiles WHERE role <> 'admin');

DELETE FROM auth.users
WHERE id IN (SELECT id FROM public.profiles WHERE role <> 'admin');

DELETE FROM public.profiles WHERE role <> 'admin';

-- ── 2. Helper: create one login account + profile ───────────
-- (dropped again at the bottom — this is scaffolding, not a
--  permanent addition to your schema)
CREATE OR REPLACE FUNCTION _sc_create_user(
  p_id UUID, p_email TEXT, p_password TEXT, p_full_name TEXT,
  p_username TEXT, p_role TEXT, p_headline TEXT, p_location TEXT,
  p_profile_score INT, p_open_to_work BOOLEAN
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_super_admin,
    -- These default to NULL if omitted, and Supabase's auth server
    -- (GoTrue) errors with "Database error querying schema" on login
    -- when it tries to scan NULL into these — they must be ''.
    confirmation_token, email_change, email_change_token_new,
    email_change_token_current, recovery_token, reauthentication_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    p_id, 'authenticated', 'authenticated',
    p_email, crypt(p_password, gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    format('{"full_name":"%s"}', p_full_name)::jsonb,
    false,
    '', '', '', '', '', ''
  );

  INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, created_at, updated_at)
  VALUES (
    gen_random_uuid(), p_email, p_id,
    format('{"sub":"%s","email":"%s"}', p_id, p_email)::jsonb,
    'email', NOW(), NOW()
  );

  INSERT INTO public.profiles (
    id, role, full_name, username, headline, location,
    is_verified, open_to_work, profile_score, created_at
  ) VALUES (
    -- profiles.role is the Postgres enum "user_role", not plain text —
    -- needs an explicit cast or Postgres rejects the insert (42804).
    p_id, p_role::public.user_role, p_full_name, p_username, p_headline, p_location,
    true, p_open_to_work, p_profile_score, NOW()
  )
  -- This project has an auth.users trigger that auto-creates a stub
  -- profiles row the instant the auth account is inserted above, so by
  -- the time we get here the row already exists (id already taken) —
  -- update it in place instead of a plain insert (matches the same
  -- pattern already used in create_test_users.sql).
  ON CONFLICT (id) DO UPDATE SET
    role          = EXCLUDED.role,
    full_name     = EXCLUDED.full_name,
    username      = EXCLUDED.username,
    headline      = EXCLUDED.headline,
    location      = EXCLUDED.location,
    is_verified   = EXCLUDED.is_verified,
    open_to_work  = EXCLUDED.open_to_work,
    profile_score = EXCLUDED.profile_score;
END;
$$;

-- ── 3. Create the 15 accounts ────────────────────────────────
DO $$
BEGIN
  -- ── Students / Employees (10) ──────────────────────────────
  PERFORM _sc_create_user(gen_random_uuid(), 'arun.kumar@skillconnect.com',        'Arun@123',    'Arun Kumar',           'arun.kumar',        'student', 'Final Year B.Tech, Computer Science',   'Chennai, Tamil Nadu',   82, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'priya.sharma@skillconnect.com',      'Priya@123',   'Priya Sharma',         'priya.sharma',      'student', 'Aspiring Frontend Developer',           'Bengaluru, Karnataka',  88, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'karthik.raja@skillconnect.com',      'Karthik@123', 'Karthik Raja',         'karthik.raja',      'student', 'Software Engineering Graduate',         'Coimbatore, Tamil Nadu',79, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'divya.menon@skillconnect.com',       'Divya@123',   'Divya Menon',          'divya.menon',       'student', 'UI/UX Design Enthusiast',               'Kochi, Kerala',         85, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'rahul.verma@skillconnect.com',       'Rahul@123',   'Rahul Verma',          'rahul.verma',       'student', 'Data Science Student',                  'Hyderabad, Telangana',  76, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'sneha.iyer@skillconnect.com',        'Sneha@123',   'Sneha Iyer',           'sneha.iyer',        'student', 'Full Stack Developer',                  'Chennai, Tamil Nadu',   91, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'vignesh.s@skillconnect.com',         'Vignesh@123', 'Vignesh Subramaniam',  'vignesh.s',         'student', 'Mobile App Developer — Flutter',        'Madurai, Tamil Nadu',   84, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'ananya.reddy@skillconnect.com',      'Ananya@123',  'Ananya Reddy',         'ananya.reddy',      'student', 'Machine Learning Enthusiast',           'Hyderabad, Telangana',  80, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'faizal.mohammed@skillconnect.com',   'Faizal@123',  'Mohammed Faizal',      'faizal.mohammed',   'student', 'Backend Developer — Node.js',           'Chennai, Tamil Nadu',   87, true);
  PERFORM _sc_create_user(gen_random_uuid(), 'lakshmi.n@skillconnect.com',         'Lakshmi@123', 'Lakshmi Narayanan',    'lakshmi.n',         'student', 'QA & Automation Testing',               'Bengaluru, Karnataka',  90, true);

  -- ── HR / Recruiters (5) ─────────────────────────────────────
  PERFORM _sc_create_user(gen_random_uuid(), 'kavitha.ramesh@skillconnect.com',    'Kavitha@123', 'Kavitha Ramesh',       'kavitha.ramesh',    'recruiter', 'HR Manager, Talent Acquisition',      'Chennai, Tamil Nadu',   92, false);
  PERFORM _sc_create_user(gen_random_uuid(), 'suresh.babu@skillconnect.com',       'Suresh@123',  'Suresh Babu',          'suresh.babu',       'recruiter', 'Senior Technical Recruiter',          'Bengaluru, Karnataka',  89, false);
  PERFORM _sc_create_user(gen_random_uuid(), 'meena.krishnan@skillconnect.com',    'Meena@123',   'Meena Krishnan',       'meena.krishnan',    'recruiter', 'Head of People Operations',           'Coimbatore, Tamil Nadu',95, false);
  PERFORM _sc_create_user(gen_random_uuid(), 'arjun.nair@skillconnect.com',        'Arjun@123',   'Arjun Nair',           'arjun.nair',        'recruiter', 'Talent Acquisition Specialist',       'Hyderabad, Telangana',  86, false);
  PERFORM _sc_create_user(gen_random_uuid(), 'deepa.venkatesh@skillconnect.com',   'Deepa@123',   'Deepa Venkatesh',      'deepa.venkatesh',   'recruiter', 'HR Business Partner',                 'Chennai, Tamil Nadu',   93, false);

  RAISE NOTICE 'Done — 10 student + 5 recruiter accounts created. See the credential list in this .sql file for usernames/passwords.';
END $$;

-- ── 4. Clean up the helper function ──────────────────────────
DROP FUNCTION _sc_create_user(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INT, BOOLEAN);

-- ============================================================
-- LOGIN CREDENTIALS — username / password
-- (username or the full email, e.g. arun.kumar@skillconnect.com,
--  both work on the login screen)
--
-- STUDENTS (Employee)
--   arun.kumar        / Arun@123
--   priya.sharma      / Priya@123
--   karthik.raja      / Karthik@123
--   divya.menon       / Divya@123
--   rahul.verma       / Rahul@123
--   sneha.iyer        / Sneha@123
--   vignesh.s         / Vignesh@123
--   ananya.reddy      / Ananya@123
--   faizal.mohammed   / Faizal@123
--   lakshmi.n         / Lakshmi@123
--
-- HR (Recruiter)
--   kavitha.ramesh    / Kavitha@123
--   suresh.babu       / Suresh@123
--   meena.krishnan    / Meena@123
--   arjun.nair        / Arjun@123
--   deepa.venkatesh   / Deepa@123
-- ============================================================

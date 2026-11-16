-- ============================================================
-- SkillConnect — Create Test Login Accounts
-- Run in Supabase SQL Editor (Dashboard → SQL Editor)
--
--   Student      → username: user    password: User124
--   HR/Recruiter → username: admin   password: Admin123
-- ============================================================

DO $$
DECLARE
  user_id  UUID := gen_random_uuid();
  admin_id UUID := gen_random_uuid();
BEGIN

  -- ── Clean up any previous failed attempts ──────────────────
  -- Remove old identities and auth users with these emails
  DELETE FROM auth.identities
  WHERE provider_id IN ('user@skillconnect.com', 'admin@skillconnect.com');

  DELETE FROM auth.users
  WHERE email IN ('user@skillconnect.com', 'admin@skillconnect.com');

  -- Remove any profiles that already claimed these usernames
  DELETE FROM public.profiles
  WHERE username IN ('user', 'admin');

  -- ────────────────────────────────────────────────────────────
  -- STUDENT ACCOUNT  |  username: user  |  password: User124
  -- ────────────────────────────────────────────────────────────

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_super_admin
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    user_id, 'authenticated', 'authenticated',
    'user@skillconnect.com',
    crypt('User124', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"User"}'::jsonb,
    false
  );

  INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, created_at, updated_at)
  VALUES (
    gen_random_uuid(), 'user@skillconnect.com', user_id,
    format('{"sub":"%s","email":"user@skillconnect.com"}', user_id)::jsonb,
    'email', NOW(), NOW()
  );

  INSERT INTO public.profiles (id, role, full_name, username, created_at)
  VALUES (user_id, 'student', 'User', 'user', NOW())
  ON CONFLICT (id) DO UPDATE
    SET role = 'student', full_name = 'User', username = 'user';

  -- ────────────────────────────────────────────────────────────
  -- HR ACCOUNT  |  username: admin  |  password: Admin123
  -- ────────────────────────────────────────────────────────────

  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data, is_super_admin
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    admin_id, 'authenticated', 'authenticated',
    'admin@skillconnect.com',
    crypt('Admin123', gen_salt('bf')),
    NOW(), NOW(), NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Admin"}'::jsonb,
    false
  );

  INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, created_at, updated_at)
  VALUES (
    gen_random_uuid(), 'admin@skillconnect.com', admin_id,
    format('{"sub":"%s","email":"admin@skillconnect.com"}', admin_id)::jsonb,
    'email', NOW(), NOW()
  );

  INSERT INTO public.profiles (id, role, full_name, username, created_at)
  VALUES (admin_id, 'recruiter', 'Admin', 'admin', NOW())
  ON CONFLICT (id) DO UPDATE
    SET role = 'recruiter', full_name = 'Admin', username = 'admin';

  -- Reassign all seed jobs to this HR account
  UPDATE public.jobs
  SET posted_by = admin_id
  WHERE posted_by IS NULL
     OR posted_by = '10145c5b-5f43-407c-94ec-a8cc53352098';

  RAISE NOTICE 'Done — username: user / User124  |  username: admin / Admin123';

END $$;

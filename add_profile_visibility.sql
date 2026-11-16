-- Run this ONCE in Supabase SQL Editor to add the is_public column
-- (backs the "Profile Visibility" toggle in Settings)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_public BOOLEAN NOT NULL DEFAULT true;

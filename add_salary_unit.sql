-- Run this ONCE in Supabase SQL Editor to add salary_unit column
ALTER TABLE jobs
  ADD COLUMN IF NOT EXISTS salary_unit TEXT NOT NULL DEFAULT 'lpa'
  CHECK (salary_unit IN ('lpa', 'thousands'));

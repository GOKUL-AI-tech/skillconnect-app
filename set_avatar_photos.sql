-- ============================================================
-- SkillConnect — Set professional headshot photos for seeded users
-- Run in Supabase SQL Editor, AFTER reset_and_seed_professional_users.sql
--
-- Sets each seeded account's avatar_url to a real, professional-
-- looking headshot photo (via randomuser.me's public portrait
-- photo set — stable URLs, gender-matched, free, no API key,
-- no expiry). Note: true generative-AI face synthesis isn't
-- something this sandbox can produce or fetch (no image-gen tool,
-- no external network access here) — these are real stock
-- headshot photos, which is the closest achievable "professional
-- human photo" result without one.
--
-- No storage bucket needed — avatar_url just points at the public
-- photo URL directly, same as any other image link. The existing
-- AvatarWidget in the app already renders any non-empty avatar_url
-- via CachedNetworkImage.
-- ============================================================

UPDATE public.profiles p SET avatar_url = v.url
FROM (VALUES
  -- Students / Employees
  ('arun.kumar',       'https://randomuser.me/api/portraits/men/32.jpg'),
  ('priya.sharma',     'https://randomuser.me/api/portraits/women/44.jpg'),
  ('karthik.raja',     'https://randomuser.me/api/portraits/men/45.jpg'),
  ('divya.menon',      'https://randomuser.me/api/portraits/women/68.jpg'),
  ('rahul.verma',      'https://randomuser.me/api/portraits/men/22.jpg'),
  ('sneha.iyer',       'https://randomuser.me/api/portraits/women/33.jpg'),
  ('vignesh.s',        'https://randomuser.me/api/portraits/men/56.jpg'),
  ('ananya.reddy',     'https://randomuser.me/api/portraits/women/50.jpg'),
  ('faizal.mohammed',  'https://randomuser.me/api/portraits/men/71.jpg'),
  ('lakshmi.n',        'https://randomuser.me/api/portraits/women/12.jpg'),
  -- HR / Recruiters
  ('kavitha.ramesh',   'https://randomuser.me/api/portraits/women/65.jpg'),
  ('suresh.babu',      'https://randomuser.me/api/portraits/men/60.jpg'),
  ('meena.krishnan',   'https://randomuser.me/api/portraits/women/28.jpg'),
  ('arjun.nair',       'https://randomuser.me/api/portraits/men/18.jpg'),
  ('deepa.venkatesh',  'https://randomuser.me/api/portraits/women/76.jpg')
) AS v(username, url)
WHERE p.username = v.username;

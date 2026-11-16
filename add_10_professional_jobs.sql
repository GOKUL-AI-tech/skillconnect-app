-- ============================================================
-- SkillConnect — Add 10 Professional Job Postings
-- Run in Supabase SQL Editor, AFTER reset_and_seed_professional_users.sql
-- (needs the 5 recruiter accounts it creates: kavitha.ramesh,
--  suresh.babu, meena.krishnan, arjun.nair, deepa.venkatesh)
--
-- Creates 10 real-brand companies and one well-written job post
-- under each, split evenly across your 5 recruiter accounts (2
-- jobs each) so the "My Postings" Jobs tab shows a realistic,
-- scoped set per recruiter instead of everything from everyone.
-- ============================================================

DO $$
DECLARE
  c_google     UUID := gen_random_uuid();
  c_razorpay   UUID := gen_random_uuid();
  c_flipkart   UUID := gen_random_uuid();
  c_zomato     UUID := gen_random_uuid();
  c_infosys    UUID := gen_random_uuid();
  c_swiggy     UUID := gen_random_uuid();
  c_meesho     UUID := gen_random_uuid();
  c_groww      UUID := gen_random_uuid();
  c_byju       UUID := gen_random_uuid();
  c_freshworks UUID := gen_random_uuid();

  r_kavitha UUID := (SELECT id FROM public.profiles WHERE username = 'kavitha.ramesh');
  r_suresh  UUID := (SELECT id FROM public.profiles WHERE username = 'suresh.babu');
  r_meena   UUID := (SELECT id FROM public.profiles WHERE username = 'meena.krishnan');
  r_arjun   UUID := (SELECT id FROM public.profiles WHERE username = 'arjun.nair');
  r_deepa   UUID := (SELECT id FROM public.profiles WHERE username = 'deepa.venkatesh');
BEGIN

  IF r_kavitha IS NULL OR r_suresh IS NULL OR r_meena IS NULL OR r_arjun IS NULL OR r_deepa IS NULL THEN
    RAISE EXCEPTION 'Recruiter accounts not found — run reset_and_seed_professional_users.sql first.';
  END IF;

  -- ── Companies ────────────────────────────────────────────────────────────
  INSERT INTO companies (id, name, slug, industry, location, website, description, is_verified)
  VALUES
    (c_google,     'Google India', 'google-india', 'Technology',      'Bengaluru, Karnataka', 'https://careers.google.com', 'Google is a global technology company specializing in internet-related services and products, including online advertising, search engine, cloud computing, and software.', true),
    (c_razorpay,   'Razorpay',     'razorpay',     'FinTech',         'Bengaluru, Karnataka', 'https://razorpay.com',        'Razorpay is India''s leading full-stack financial solutions company helping businesses with payments, banking, payroll, and more.', true),
    (c_flipkart,   'Flipkart',     'flipkart',     'E-Commerce',      'Bengaluru, Karnataka', 'https://flipkart.com',        'Flipkart is India''s largest e-commerce marketplace offering a wide range of products including electronics, fashion, and groceries.', true),
    (c_zomato,     'Zomato',       'zomato',       'Food Technology', 'Gurugram, Haryana',    'https://zomato.com',          'Zomato is India''s leading food delivery and restaurant discovery platform, connecting millions of users with local restaurants.', true),
    (c_infosys,    'Infosys',      'infosys',      'IT Services',     'Bengaluru, Karnataka', 'https://infosys.com',         'Infosys is a global leader in next-generation digital services and consulting with over 300,000 employees worldwide.', true),
    (c_swiggy,     'Swiggy',       'swiggy',       'Food Technology', 'Bengaluru, Karnataka', 'https://swiggy.com',          'Swiggy is India''s leading on-demand delivery platform delivering food, groceries, and more from thousands of restaurant and store partners.', true),
    (c_meesho,     'Meesho',       'meesho',       'Social Commerce', 'Bengaluru, Karnataka', 'https://meesho.com',          'Meesho is India''s fastest growing social commerce platform empowering small businesses and individuals to start their online stores.', true),
    (c_groww,      'Groww',        'groww',        'FinTech',         'Bengaluru, Karnataka', 'https://groww.in',            'Groww is India''s largest investment platform with over 10 million users investing in stocks, mutual funds, and digital gold.', true),
    (c_byju,       'BYJU''S',      'byjus',        'EdTech',          'Bengaluru, Karnataka', 'https://byjus.com',           'BYJU''S is the world''s most valuable EdTech company, offering personalised learning programs for students from K-12 through competitive exams.', false),
    (c_freshworks, 'Freshworks',   'freshworks',   'SaaS / CRM',      'Chennai, Tamil Nadu',  'https://freshworks.com',      'Freshworks creates cloud-based business software that helps teams work together smarter, offering tools for customer support, CRM, and HR management.', true)
  ON CONFLICT (slug) DO NOTHING;

  -- ── Jobs ─────────────────────────────────────────────────────────────────
  INSERT INTO jobs (
    id, title, description, type, mode, level,
    location, salary_min, salary_max,
    skills_required, openings, is_active, is_featured, views,
    company_id, posted_by
  ) VALUES

  -- Kavitha Ramesh — Google, Razorpay
  (gen_random_uuid(), 'Flutter Developer — Google Pay',
   E'Join the Google Pay team as a Flutter Developer and help build the next generation of payment experiences for India.\n\nYou''ll work closely with our product, design, and backend teams to ship high-quality features to millions of users.\n\nResponsibilities:\n• Build and maintain Flutter features across iOS and Android\n• Optimize app performance and reduce load times\n• Write clean, testable code with unit and widget tests\n• Collaborate with design to implement pixel-perfect UIs\n\nRequirements:\n• 2+ years of Flutter/Dart experience\n• Familiarity with REST APIs and state management (Riverpod, BLoC)\n• Good understanding of mobile performance optimisation\n• Experience with CI/CD pipelines',
   'full_time', 'remote', 'mid', 'Bengaluru, Karnataka', 1800000, 3200000,
   ARRAY['Flutter', 'Dart', 'Riverpod', 'REST APIs', 'Firebase', 'Git'],
   3, true, true, 874, c_google, r_kavitha),

  (gen_random_uuid(), 'Backend Engineer — Payments Core',
   E'Razorpay is looking for a passionate Backend Engineer to work on our high-throughput Payments Core infrastructure.\n\nOur systems process millions of transactions daily. You will work on performance-critical services that power payments for India''s leading businesses.\n\nResponsibilities:\n• Design and build scalable microservices in Go and Java\n• Work on transaction reliability and idempotency\n• Optimise database queries across MySQL and Redis\n• Build real-time dashboards and alerting systems\n\nRequirements:\n• 3+ years of backend engineering experience\n• Proficiency in Go, Java, or Node.js\n• Experience with high-volume, low-latency distributed systems\n• Knowledge of payment protocols and security standards',
   'full_time', 'hybrid', 'mid', 'Bengaluru, Karnataka', 2000000, 4000000,
   ARRAY['Go', 'Java', 'MySQL', 'Redis', 'Kafka', 'Docker', 'Kubernetes'],
   4, true, true, 653, c_razorpay, r_kavitha),

  -- Suresh Babu — Flipkart, Zomato
  (gen_random_uuid(), 'React Native Developer',
   E'Flipkart is looking for a talented React Native Developer to join our Mobile Engineering team.\n\nYou will work on the Flipkart consumer app — one of the most downloaded shopping apps in India with 300M+ registered users.\n\nResponsibilities:\n• Build high-performance React Native features\n• Optimise JS bundle size and startup time\n• Work with native modules for camera, payments, and biometrics\n• Participate in code reviews and architecture discussions\n\nRequirements:\n• 2+ years of React Native development experience\n• Solid JavaScript / TypeScript knowledge\n• Experience bridging native Android/iOS modules\n• Familiarity with Redux or Zustand for state management',
   'full_time', 'hybrid', 'mid', 'Bengaluru, Karnataka', 1600000, 3000000,
   ARRAY['React Native', 'TypeScript', 'Redux', 'JavaScript', 'Android', 'iOS'],
   5, true, false, 729, c_flipkart, r_suresh),

  (gen_random_uuid(), 'Product Manager — Growth',
   E'Zomato is hiring a Product Manager to drive user acquisition and engagement on our platform.\n\nYou''ll own the full product lifecycle for growth features — from ideation and user research to launch and iteration.\n\nResponsibilities:\n• Define and drive the product roadmap for growth features\n• Run experiments and analyse data to drive decisions\n• Work closely with design, engineering, and marketing\n• Define success metrics and track KPIs\n\nRequirements:\n• 3+ years of product management experience at a consumer tech company\n• Strong analytical skills — comfortable with SQL and BI tools\n• Experience running A/B experiments\n• Excellent communication and stakeholder management skills',
   'full_time', 'hybrid', 'mid', 'Gurugram, Haryana', 2500000, 4500000,
   ARRAY['Product Strategy', 'Data Analysis', 'SQL', 'A/B Testing', 'Agile', 'User Research'],
   1, true, true, 1105, c_zomato, r_suresh),

  -- Meena Krishnan — Infosys, Swiggy
  (gen_random_uuid(), 'Java Full Stack Developer',
   E'Infosys is seeking Java Full Stack Developers to work on enterprise application development for our global clients.\n\nYou''ll deliver end-to-end solutions — from database design to frontend development — for clients across banking, insurance, and retail industries.\n\nResponsibilities:\n• Design and develop Java microservices using Spring Boot\n• Build frontend features with Angular or React\n• Write and maintain unit tests\n• Work in an Agile / Scrum environment\n\nRequirements:\n• 2-5 years of Java development experience\n• Experience with Spring Boot and RESTful APIs\n• Knowledge of Angular or React\n• Familiarity with cloud platforms (AWS, Azure)',
   'full_time', 'hybrid', 'mid', 'Bengaluru, Karnataka', 700000, 1400000,
   ARRAY['Java', 'Spring Boot', 'Angular', 'MySQL', 'AWS', 'REST APIs', 'Docker'],
   10, true, false, 432, c_infosys, r_meena),

  (gen_random_uuid(), 'DevOps Engineer — Platform',
   E'Swiggy is hiring a DevOps Engineer to join the Platform Engineering team.\n\nYou''ll be responsible for the reliability and scalability of Swiggy''s microservices infrastructure that handles millions of orders daily.\n\nResponsibilities:\n• Manage and optimise Kubernetes clusters on AWS\n• Build and maintain CI/CD pipelines\n• Implement monitoring, alerting, and on-call workflows\n• Automate infrastructure provisioning with Terraform\n\nRequirements:\n• 3+ years of DevOps / SRE experience\n• Strong knowledge of Kubernetes and Docker\n• Experience with AWS (EKS, RDS, S3, Lambda)\n• Proficiency with Terraform or Ansible\n• Familiarity with observability tools (Prometheus, Grafana, Datadog)',
   'full_time', 'hybrid', 'senior', 'Bengaluru, Karnataka', 2000000, 3800000,
   ARRAY['Kubernetes', 'Docker', 'AWS', 'Terraform', 'CI/CD', 'Prometheus', 'Grafana'],
   2, true, true, 687, c_swiggy, r_meena),

  -- Arjun Nair — Meesho, Groww
  (gen_random_uuid(), 'Android Developer — Seller App',
   E'Meesho is hiring an Android Developer to build the Supplier / Seller app used by millions of small business owners across India.\n\nThis is a high-impact role — your work directly helps India''s small businesses grow online.\n\nResponsibilities:\n• Build and own features in the Meesho Supplier Android app\n• Improve app performance, crash rates, and ANRs\n• Work closely with the product and design team\n• Write thorough unit and instrumentation tests\n\nRequirements:\n• 1-3 years of Android development (Kotlin)\n• Experience with Jetpack libraries (Room, WorkManager, Navigation)\n• Good understanding of MVVM and Clean Architecture\n• Experience with dependency injection (Hilt or Dagger)',
   'full_time', 'remote', 'entry', 'Bengaluru, Karnataka', 1000000, 2000000,
   ARRAY['Android', 'Kotlin', 'Jetpack', 'MVVM', 'Hilt', 'Room', 'Coroutines'],
   4, true, false, 398, c_meesho, r_arjun),

  (gen_random_uuid(), 'Fullstack Engineer — Investments',
   E'Groww is looking for a Fullstack Engineer to build the next-generation investing experience for India.\n\nYou''ll work on features that make investing accessible to millions of first-time investors — from stock trading to mutual funds.\n\nResponsibilities:\n• Build backend services in Go / Node.js\n• Develop React / Next.js frontend features\n• Work on real-time stock price feeds and portfolio calculations\n• Participate in on-call rotations and incident response\n\nRequirements:\n• 2+ years of fullstack engineering experience\n• Proficiency in React and one backend language (Go, Node.js, or Python)\n• Experience with databases (PostgreSQL, Redis)\n• Understanding of financial systems a plus',
   'full_time', 'hybrid', 'mid', 'Bengaluru, Karnataka', 2000000, 4000000,
   ARRAY['React', 'Node.js', 'Go', 'PostgreSQL', 'Redis', 'TypeScript'],
   3, true, true, 812, c_groww, r_arjun),

  -- Deepa Venkatesh — Freshworks, BYJU'S
  (gen_random_uuid(), 'Senior Product Designer',
   E'Freshworks is looking for a Senior Product Designer to lead design for our Freshdesk customer support platform used by 60,000+ businesses globally.\n\nYou''ll own end-to-end design for complex enterprise workflows, from discovery through delivery.\n\nResponsibilities:\n• Lead design sprints and discovery workshops\n• Create flows, wireframes, and high-fidelity prototypes\n• Evolve Freshworks'' enterprise design system\n• Present design decisions to leadership and stakeholders\n\nRequirements:\n• 5+ years of product design experience, ideally at a SaaS company\n• Expert-level Figma skills\n• Track record of shipping complex enterprise features\n• Strong design critique and mentoring ability',
   'full_time', 'hybrid', 'senior', 'Chennai, Tamil Nadu', 2500000, 4500000,
   ARRAY['Figma', 'Design Systems', 'Enterprise UX', 'Prototyping', 'User Research'],
   1, true, true, 761, c_freshworks, r_deepa),

  (gen_random_uuid(), 'Part-Time Python Tutor',
   E'BYJU''S is looking for part-time Python instructors to teach programming to students aged 14-18 through live online sessions.\n\nThis is a flexible, remote role perfect for working professionals or graduate students.\n\nResponsibilities:\n• Conduct 1-on-1 and small group live coding sessions (2-4 hrs/day)\n• Prepare lesson plans and practice exercises\n• Track student progress and share reports with parents\n• Conduct doubt-clearing sessions\n\nRequirements:\n• Strong Python fundamentals\n• Prior teaching or tutoring experience preferred\n• Patience and ability to explain concepts simply\n• Reliable internet connection and a quiet environment',
   'part_time', 'remote', 'entry', NULL, 25000, 45000,
   ARRAY['Python', 'Teaching', 'Communication', 'Patience', 'Problem Solving'],
   8, true, false, 521, c_byju, r_deepa);

  RAISE NOTICE '10 professional jobs created across 10 companies, 2 per recruiter.';
END $$;

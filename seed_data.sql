-- ============================================================
-- SkillConnect — Dummy Seed Data
-- Run in Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

DO $$
DECLARE
  recruiter_id UUID := '10145c5b-5f43-407c-94ec-a8cc53352098';

  -- Company IDs
  c_google    UUID := gen_random_uuid();
  c_razorpay  UUID := gen_random_uuid();
  c_flipkart  UUID := gen_random_uuid();
  c_zomato    UUID := gen_random_uuid();
  c_infosys   UUID := gen_random_uuid();
  c_swiggy    UUID := gen_random_uuid();
  c_meesho    UUID := gen_random_uuid();
  c_groww     UUID := gen_random_uuid();
  c_byju      UUID := gen_random_uuid();
  c_freshworks UUID := gen_random_uuid();

BEGIN

-- ── Companies ──────────────────────────────────────────────────────────────

INSERT INTO companies (id, name, slug, industry, location, website, description, is_verified)
VALUES
  (c_google,     'Google India',     'google-india',     'Technology',       'Bengaluru, Karnataka', 'https://careers.google.com',   'Google is a global technology company specializing in internet-related services and products, including online advertising, search engine, cloud computing, and software.',         true),
  (c_razorpay,   'Razorpay',         'razorpay',         'FinTech',          'Bengaluru, Karnataka', 'https://razorpay.com',          'Razorpay is India''s leading full-stack financial solutions company helping businesses with payments, banking, payroll, and more.',                                              true),
  (c_flipkart,   'Flipkart',         'flipkart',         'E-Commerce',       'Bengaluru, Karnataka', 'https://flipkart.com',          'Flipkart is India''s largest e-commerce marketplace offering a wide range of products including electronics, fashion, and groceries.',                                         true),
  (c_zomato,     'Zomato',           'zomato',           'Food Technology',  'Gurugram, Haryana',    'https://zomato.com',            'Zomato is India''s leading food delivery and restaurant discovery platform, connecting millions of users with local restaurants.',                                           true),
  (c_infosys,    'Infosys',          'infosys',          'IT Services',      'Bengaluru, Karnataka', 'https://infosys.com',           'Infosys is a global leader in next-generation digital services and consulting with over 300,000 employees worldwide.',                                                        true),
  (c_swiggy,     'Swiggy',           'swiggy',           'Food Technology',  'Bengaluru, Karnataka', 'https://swiggy.com',            'Swiggy is India''s leading on-demand delivery platform delivering food, groceries, and more from thousands of restaurant and store partners.',                              true),
  (c_meesho,     'Meesho',           'meesho',           'Social Commerce',  'Bengaluru, Karnataka', 'https://meesho.com',            'Meesho is India''s fastest growing social commerce platform empowering small businesses and individuals to start their online stores.',                                      true),
  (c_groww,      'Groww',            'groww',            'FinTech',          'Bengaluru, Karnataka', 'https://groww.in',              'Groww is India''s largest investment platform with over 10 million users investing in stocks, mutual funds, and digital gold.',                                             true),
  (c_byju,       'BYJU''S',          'byjus',            'EdTech',           'Bengaluru, Karnataka', 'https://byjus.com',             'BYJU''S is the world''s most valuable EdTech company, offering personalised learning programs for students from K-12 through competitive exams.',                           false),
  (c_freshworks, 'Freshworks',       'freshworks',       'SaaS / CRM',       'Chennai, Tamil Nadu',  'https://freshworks.com',        'Freshworks creates cloud-based business software that helps teams work together smarter, offering tools for customer support, CRM, and HR management.',                       true)
ON CONFLICT (slug) DO NOTHING;

-- ── Jobs ───────────────────────────────────────────────────────────────────

INSERT INTO jobs (
  id, title, description, type, mode, level,
  location, salary_min, salary_max,
  skills_required, openings, is_active, is_featured, views,
  company_id, posted_by
)
VALUES

-- Google India
(gen_random_uuid(),
 'Senior Software Engineer — Android',
 E'We are looking for a Senior Android Engineer to join our Google Maps team in Bengaluru.\n\nYou will work on the core Maps Android application used by over a billion people globally. This is a high-impact role where your work will directly affect the everyday lives of users.\n\nResponsibilities:\n• Lead the design and implementation of new features for Google Maps Android\n• Collaborate with product managers and designers to build exceptional user experiences\n• Mentor junior engineers and conduct code reviews\n• Participate in technical roadmap planning\n\nRequirements:\n• 5+ years of Android development experience\n• Deep knowledge of Kotlin and Java\n• Experience with large-scale apps (1M+ users)\n• Strong understanding of architecture patterns (MVVM, Clean Architecture)',
 'full_time', 'hybrid', 'senior',
 'Bengaluru, Karnataka', 3000000, 5500000,
 ARRAY['Android', 'Kotlin', 'Java', 'Jetpack Compose', 'MVVM', 'Git'],
 2, true, true, 1240,
 c_google, recruiter_id),

(gen_random_uuid(),
 'Flutter Developer — Google Pay',
 E'Join the Google Pay team as a Flutter Developer and help build the next generation of payment experiences for India.\n\nYou''ll work closely with our product, design, and backend teams to ship high-quality features to millions of users.\n\nResponsibilities:\n• Build and maintain Flutter features across iOS and Android\n• Optimize app performance and reduce load times\n• Write clean, testable code with unit and widget tests\n• Collaborate with design to implement pixel-perfect UIs\n\nRequirements:\n• 2+ years of Flutter/Dart experience\n• Familiarity with REST APIs and state management (Riverpod, BLoC)\n• Good understanding of mobile performance optimisation\n• Experience with CI/CD pipelines',
 'full_time', 'remote', 'mid',
 'Bengaluru, Karnataka', 1800000, 3200000,
 ARRAY['Flutter', 'Dart', 'Riverpod', 'REST APIs', 'Firebase', 'Git'],
 3, true, true, 874,
 c_google, recruiter_id),

-- Razorpay
(gen_random_uuid(),
 'Backend Engineer — Payments Core',
 E'Razorpay is looking for a passionate Backend Engineer to work on our high-throughput Payments Core infrastructure.\n\nOur systems process millions of transactions daily. You will work on performance-critical services that power payments for India''s leading businesses.\n\nResponsibilities:\n• Design and build scalable microservices in Go and Java\n• Work on transaction reliability and idempotency\n• Optimise database queries across MySQL and Redis\n• Build real-time dashboards and alerting systems\n\nRequirements:\n• 3+ years of backend engineering experience\n• Proficiency in Go, Java, or Node.js\n• Experience with high-volume, low-latency distributed systems\n• Knowledge of payment protocols and security standards',
 'full_time', 'hybrid', 'mid',
 'Bengaluru, Karnataka', 2000000, 4000000,
 ARRAY['Go', 'Java', 'MySQL', 'Redis', 'Kafka', 'Docker', 'Kubernetes'],
 4, true, true, 653,
 c_razorpay, recruiter_id),

(gen_random_uuid(),
 'iOS Developer Intern',
 E'Razorpay is offering a 6-month internship for iOS developers who are passionate about building fintech products.\n\nYou''ll work alongside experienced engineers on our Razorpay iOS SDK and merchant-facing apps.\n\nWhat you''ll do:\n• Build new features for the Razorpay iOS merchant app\n• Write automated UI tests\n• Fix bugs and improve app stability\n• Learn from experienced iOS engineers\n\nRequirements:\n• Knowledge of Swift and UIKit/SwiftUI\n• Basic understanding of REST APIs\n• Strong debugging skills\n• Currently pursuing B.Tech / M.Tech in Computer Science or related field',
 'internship', 'hybrid', 'entry',
 'Bengaluru, Karnataka', 50000, 70000,
 ARRAY['Swift', 'SwiftUI', 'UIKit', 'REST APIs', 'Git', 'XCode'],
 2, true, false, 412,
 c_razorpay, recruiter_id),

-- Flipkart
(gen_random_uuid(),
 'React Native Developer',
 E'Flipkart is looking for a talented React Native Developer to join our Mobile Engineering team.\n\nYou will work on the Flipkart consumer app — one of the most downloaded shopping apps in India with 300M+ registered users.\n\nResponsibilities:\n• Build high-performance React Native features\n• Optimise JS bundle size and startup time\n• Work with native modules for camera, payments, and biometrics\n• Participate in code reviews and architecture discussions\n\nRequirements:\n• 2+ years of React Native development experience\n• Solid JavaScript / TypeScript knowledge\n• Experience bridging native Android/iOS modules\n• Familiarity with Redux or Zustand for state management',
 'full_time', 'hybrid', 'mid',
 'Bengaluru, Karnataka', 1600000, 3000000,
 ARRAY['React Native', 'TypeScript', 'Redux', 'JavaScript', 'Android', 'iOS'],
 5, true, false, 729,
 c_flipkart, recruiter_id),

(gen_random_uuid(),
 'Data Scientist — Recommendation Engine',
 E'Join Flipkart''s AI/ML team to build the personalisation engine that drives product recommendations for 300 million users.\n\nYou''ll apply state-of-the-art ML techniques to real-world e-commerce challenges at massive scale.\n\nResponsibilities:\n• Develop and deploy ML models for product recommendations\n• A/B test recommendation strategies\n• Work with petabyte-scale datasets using Spark and Hive\n• Collaborate with engineering to productionise models\n\nRequirements:\n• 2+ years of industry ML experience\n• Proficiency in Python and ML frameworks (scikit-learn, PyTorch, TensorFlow)\n• Experience with large-scale data processing (Spark, Hadoop)\n• Strong statistics and mathematics foundation',
 'full_time', 'onsite', 'mid',
 'Bengaluru, Karnataka', 2200000, 4500000,
 ARRAY['Python', 'Machine Learning', 'TensorFlow', 'PyTorch', 'Spark', 'SQL'],
 2, true, true, 918,
 c_flipkart, recruiter_id),

-- Zomato
(gen_random_uuid(),
 'Product Manager — Growth',
 E'Zomato is hiring a Product Manager to drive user acquisition and engagement on our platform.\n\nYou''ll own the full product lifecycle for growth features — from ideation and user research to launch and iteration.\n\nResponsibilities:\n• Define and drive the product roadmap for growth features\n• Run experiments and analyse data to drive decisions\n• Work closely with design, engineering, and marketing\n• Define success metrics and track KPIs\n\nRequirements:\n• 3+ years of product management experience at a consumer tech company\n• Strong analytical skills — comfortable with SQL and BI tools\n• Experience running A/B experiments\n• Excellent communication and stakeholder management skills',
 'full_time', 'hybrid', 'mid',
 'Gurugram, Haryana', 2500000, 4500000,
 ARRAY['Product Strategy', 'Data Analysis', 'SQL', 'A/B Testing', 'Agile', 'User Research'],
 1, true, true, 1105,
 c_zomato, recruiter_id),

(gen_random_uuid(),
 'Frontend Developer — Web',
 E'Zomato is looking for a Frontend Developer to join our web engineering team.\n\nYou''ll build the restaurant discovery and ordering experience on zomato.com, one of India''s most visited consumer websites.\n\nResponsibilities:\n• Build performant, accessible React components\n• Optimise Core Web Vitals and page load times\n• Collaborate with designers using Figma\n• Write unit and integration tests\n\nRequirements:\n• 1-3 years of frontend development experience\n• Strong React.js and TypeScript skills\n• Good knowledge of CSS, responsive design, and accessibility\n• Familiarity with Next.js a plus',
 'full_time', 'remote', 'entry',
 'Gurugram, Haryana', 900000, 1800000,
 ARRAY['React', 'TypeScript', 'Next.js', 'CSS', 'HTML', 'GraphQL'],
 3, true, false, 548,
 c_zomato, recruiter_id),

-- Infosys
(gen_random_uuid(),
 'Java Full Stack Developer',
 E'Infosys is seeking Java Full Stack Developers to work on enterprise application development for our global clients.\n\nYou''ll deliver end-to-end solutions — from database design to frontend development — for clients across banking, insurance, and retail industries.\n\nResponsibilities:\n• Design and develop Java microservices using Spring Boot\n• Build frontend features with Angular or React\n• Write and maintain unit tests\n• Work in an Agile / Scrum environment\n\nRequirements:\n• 2-5 years of Java development experience\n• Experience with Spring Boot and RESTful APIs\n• Knowledge of Angular or React\n• Familiarity with cloud platforms (AWS, Azure)',
 'full_time', 'hybrid', 'mid',
 'Bengaluru, Karnataka', 700000, 1400000,
 ARRAY['Java', 'Spring Boot', 'Angular', 'MySQL', 'AWS', 'REST APIs', 'Docker'],
 10, true, false, 432,
 c_infosys, recruiter_id),

(gen_random_uuid(),
 'System Engineer — Fresher',
 E'Infosys is hiring fresh graduates for our System Engineer programme across India.\n\nYou''ll go through Infosys'' award-winning training programme (Foundation Programme) before joining a project team.\n\nWhat to expect:\n• 5-month intensive technical and soft-skills training\n• Placement in a project based on your skills and interests\n• Exposure to global clients and technologies\n• Regular performance reviews and fast-track promotion opportunities\n\nEligibility:\n• B.E / B.Tech / M.Tech / MCA with 60%+ marks\n• Graduating in 2024 or 2025\n• No active backlogs\n• Strong communication skills',
 'full_time', 'onsite', 'entry',
 'Multiple Locations, India', 350000, 500000,
 ARRAY['Java', 'Python', 'SQL', 'Communication', 'Problem Solving'],
 50, true, false, 2874,
 c_infosys, recruiter_id),

-- Swiggy
(gen_random_uuid(),
 'DevOps Engineer — Platform',
 E'Swiggy is hiring a DevOps Engineer to join the Platform Engineering team.\n\nYou''ll be responsible for the reliability and scalability of Swiggy''s microservices infrastructure that handles millions of orders daily.\n\nResponsibilities:\n• Manage and optimise Kubernetes clusters on AWS\n• Build and maintain CI/CD pipelines\n• Implement monitoring, alerting, and on-call workflows\n• Automate infrastructure provisioning with Terraform\n\nRequirements:\n• 3+ years of DevOps / SRE experience\n• Strong knowledge of Kubernetes and Docker\n• Experience with AWS (EKS, RDS, S3, Lambda)\n• Proficiency with Terraform or Ansible\n• Familiarity with observability tools (Prometheus, Grafana, Datadog)',
 'full_time', 'hybrid', 'senior',
 'Bengaluru, Karnataka', 2000000, 3800000,
 ARRAY['Kubernetes', 'Docker', 'AWS', 'Terraform', 'CI/CD', 'Prometheus', 'Grafana'],
 2, true, true, 687,
 c_swiggy, recruiter_id),

(gen_random_uuid(),
 'UI/UX Designer',
 E'Swiggy is looking for a UI/UX Designer to join the consumer product team.\n\nYou''ll design delightful, intuitive experiences for millions of users who use Swiggy every day to order food, groceries, and more.\n\nResponsibilities:\n• Conduct user research and usability testing\n• Create wireframes, prototypes, and high-fidelity designs in Figma\n• Collaborate with PMs and engineers to ship polished products\n• Maintain and evolve Swiggy''s design system\n\nRequirements:\n• 2+ years of product design experience\n• Strong Figma skills\n• Portfolio demonstrating mobile and web design\n• Familiarity with motion design a plus',
 'full_time', 'hybrid', 'mid',
 'Bengaluru, Karnataka', 1200000, 2400000,
 ARRAY['Figma', 'User Research', 'Prototyping', 'Design Systems', 'Usability Testing'],
 1, true, false, 523,
 c_swiggy, recruiter_id),

-- Meesho
(gen_random_uuid(),
 'Android Developer — Seller App',
 E'Meesho is hiring an Android Developer to build the Supplier / Seller app used by millions of small business owners across India.\n\nThis is a high-impact role — your work directly helps India''s small businesses grow online.\n\nResponsibilities:\n• Build and own features in the Meesho Supplier Android app\n• Improve app performance, crash rates, and ANRs\n• Work closely with the product and design team\n• Write thorough unit and instrumentation tests\n\nRequirements:\n• 1-3 years of Android development (Kotlin)\n• Experience with Jetpack libraries (Room, WorkManager, Navigation)\n• Good understanding of MVVM and Clean Architecture\n• Experience with dependency injection (Hilt or Dagger)',
 'full_time', 'remote', 'entry',
 'Bengaluru, Karnataka', 1000000, 2000000,
 ARRAY['Android', 'Kotlin', 'Jetpack', 'MVVM', 'Hilt', 'Room', 'Coroutines'],
 4, true, false, 398,
 c_meesho, recruiter_id),

-- Groww
(gen_random_uuid(),
 'Fullstack Engineer — Investments',
 E'Groww is looking for a Fullstack Engineer to build the next-generation investing experience for India.\n\nYou''ll work on features that make investing accessible to millions of first-time investors — from stock trading to mutual funds.\n\nResponsibilities:\n• Build backend services in Go / Node.js\n• Develop React / Next.js frontend features\n• Work on real-time stock price feeds and portfolio calculations\n• Participate in on-call rotations and incident response\n\nRequirements:\n• 2+ years of fullstack engineering experience\n• Proficiency in React and one backend language (Go, Node.js, or Python)\n• Experience with databases (PostgreSQL, Redis)\n• Understanding of financial systems a plus',
 'full_time', 'hybrid', 'mid',
 'Bengaluru, Karnataka', 2000000, 4000000,
 ARRAY['React', 'Node.js', 'Go', 'PostgreSQL', 'Redis', 'TypeScript'],
 3, true, true, 812,
 c_groww, recruiter_id),

-- Freshworks
(gen_random_uuid(),
 'Technical Support Engineer',
 E'Freshworks is hiring Technical Support Engineers to help our global customers succeed with Freshdesk, Freshsales, and our suite of SaaS products.\n\nYou''ll be the technical expert customers turn to when they need help configuring, troubleshooting, or getting the most out of Freshworks products.\n\nResponsibilities:\n• Resolve complex technical issues via tickets, chat, and phone\n• Write and maintain knowledge base articles\n• Reproduce bugs and work with engineering teams to resolve them\n• Onboard new enterprise customers\n\nRequirements:\n• 1-3 years of technical support or customer success experience\n• Basic knowledge of APIs and web technologies (HTML, JavaScript)\n• Excellent verbal and written English communication\n• Customer-first mindset with strong problem-solving skills',
 'full_time', 'onsite', 'entry',
 'Chennai, Tamil Nadu', 600000, 1000000,
 ARRAY['Technical Support', 'REST APIs', 'JavaScript', 'SQL', 'Communication'],
 6, true, false, 344,
 c_freshworks, recruiter_id),

(gen_random_uuid(),
 'Senior Product Designer',
 E'Freshworks is looking for a Senior Product Designer to lead design for our Freshdesk customer support platform used by 60,000+ businesses globally.\n\nYou''ll own end-to-end design for complex enterprise workflows, from discovery through delivery.\n\nResponsibilities:\n• Lead design sprints and discovery workshops\n• Create flows, wireframes, and high-fidelity prototypes\n• Evolve Freshworks'' enterprise design system\n• Present design decisions to leadership and stakeholders\n\nRequirements:\n• 5+ years of product design experience, ideally at a SaaS company\n• Expert-level Figma skills\n• Track record of shipping complex enterprise features\n• Strong design critique and mentoring ability',
 'full_time', 'hybrid', 'senior',
 'Chennai, Tamil Nadu', 2500000, 4500000,
 ARRAY['Figma', 'Design Systems', 'Enterprise UX', 'Prototyping', 'User Research'],
 1, true, true, 761,
 c_freshworks, recruiter_id),

-- Remote / Freelance jobs
(gen_random_uuid(),
 'Freelance Mobile Developer (React Native)',
 E'We are looking for a freelance React Native developer to help build a fitness tracking app over 3 months.\n\nThis is a fully remote, contract engagement with flexible working hours.\n\nScope:\n• Build 8-10 screens from provided Figma designs\n• Integrate with a REST API backend (Node.js)\n• Implement push notifications and local storage\n• Deliver clean, documented code\n\nRequirements:\n• At least 2 completed React Native apps in your portfolio\n• Comfortable working independently with minimal supervision\n• Available for 4-6 hours per day\n• Good English communication for async collaboration',
 'freelance', 'remote', 'mid',
 NULL, 150000, 300000,
 ARRAY['React Native', 'JavaScript', 'Redux', 'REST APIs', 'Push Notifications'],
 1, true, false, 287,
 c_meesho, recruiter_id),

(gen_random_uuid(),
 'Part-Time Python Tutor',
 E'BYJU''S is looking for part-time Python instructors to teach programming to students aged 14-18 through live online sessions.\n\nThis is a flexible, remote role perfect for working professionals or graduate students.\n\nResponsibilities:\n• Conduct 1-on-1 and small group live coding sessions (2-4 hrs/day)\n• Prepare lesson plans and practice exercises\n• Track student progress and share reports with parents\n• Conduct doubt-clearing sessions\n\nRequirements:\n• Strong Python fundamentals\n• Prior teaching or tutoring experience preferred\n• Patience and ability to explain concepts simply\n• Reliable internet connection and a quiet environment',
 'part_time', 'remote', 'entry',
 NULL, 25000, 45000,
 ARRAY['Python', 'Teaching', 'Communication', 'Patience', 'Problem Solving'],
 8, true, false, 521,
 c_byju, recruiter_id);

RAISE NOTICE 'Seed data inserted successfully! % companies and jobs created.', 10;

END $$;

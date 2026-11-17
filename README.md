# SkillConnect – Where Talent Meets Opportunity

A Flutter + Supabase job-portal app that connects students and job seekers with recruiters. Browse and apply for jobs, manage your profile and resume, chat with recruiters and track every application in one place.

## Features

- **Three roles** – Student, Recruiter and Admin
- **Jobs** – search and filter listings, view job details and post new jobs (recruiters)
- **Applications** – apply with a resume and follow your application status
- **Profile** – avatar, resume upload and profile-visibility control
- **Chat** – conversations between candidates and recruiters
- **Dashboard & analytics** – charts and activity overview
- **Notifications** and **settings**
- **Row Level Security** policies and storage buckets for avatars and resumes (SQL included)

## Tech Stack

| Layer | Tools |
|-------|-------|
| App | Flutter, Riverpod, GoRouter, `fl_chart`, Google Fonts |
| Backend | Supabase (Postgres, Auth, Storage, RLS) |
| Config | `flutter_dotenv` |

## Project Structure

```
lib/
├── core/        # theme, utils
├── data/        # models, services
├── features/    # applications, auth, chat, dashboard, jobs, landing,
│                # notifications, profile, settings
├── providers/   # Riverpod providers
└── shared/      # reusable widgets
supabase/ + *.sql  # schema fixes, RLS, storage buckets, seed data
```

## Getting Started

1. Create a Supabase project and run the SQL scripts (storage buckets, RLS fixes and seed data) in the SQL Editor.
2. Copy the env template and fill in your project's values from **Settings → API**:
   ```bash
   cp .env.example .env
   ```
   ```env
   SUPABASE_URL=https://YOUR-PROJECT.supabase.co
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```
3. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

See [FLUTTER_SETUP.md](FLUTTER_SETUP.md) for the full walkthrough. The demo accounts in the seed scripts are for local testing only.

## Author

**Gokul G** – B.Sc. AI & ML · [GitHub](https://github.com/GOKUL-AI-tech) · [LinkedIn](https://www.linkedin.com/in/gokul-g-ai-ml)

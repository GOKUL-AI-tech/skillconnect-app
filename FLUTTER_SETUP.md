# SkillConnect Flutter — Setup Guide

## Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| Flutter SDK | 3.24+ | https://docs.flutter.dev/get-started/install |
| Android Studio | Latest | https://developer.android.com/studio |
| Dart SDK | 3.2+ | Bundled with Flutter |

---

## Step 1 — Configure Supabase

Edit `.env` in the project root:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Get these from your Supabase project → **Settings → API**.

---

## Step 2 — Install dependencies

```bash
cd skillconnect_flutter
flutter pub get
```

---

## Step 3 — Run on Android

Connect your phone (USB debugging on) or start an emulator in Android Studio, then:

```bash
flutter run
```

Or open the project in Android Studio:
```
File → Open → select skillconnect_flutter/
```
Then click the **▶ Run** button.

---

## Step 4 — Build a release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

To install directly on a connected device:
```bash
flutter install
```

---

## Project Structure

```
lib/
├── main.dart                    ← Entry point, Supabase init
├── app.dart                     ← MaterialApp + GoRouter
├── core/
│   ├── theme/app_theme.dart     ← Design tokens (colors, typography)
│   └── utils/helpers.dart       ← timeAgo, formatSalary, etc.
├── data/
│   ├── models/models.dart       ← Dart data classes
│   └── services/
│       ├── auth_service.dart    ← Supabase Auth
│       └── database_service.dart← All DB queries + Realtime
├── providers/
│   ├── auth_provider.dart       ← Riverpod auth state
│   └── theme_provider.dart      ← Dark/light mode
├── shared/widgets/              ← Reusable widgets
└── features/
    ├── auth/                    ← Login, Signup, Forgot Password
    ├── dashboard/               ← Student + Recruiter dashboards
    ├── jobs/                    ← Jobs list + filters
    ├── applications/            ← Application tracker with tabs
    ├── chat/                    ← Real-time messaging
    ├── notifications/           ← Notification centre
    ├── profile/                 ← User profile
    ├── settings/                ← Dark mode, account settings
    └── layout/                  ← Bottom navigation shell
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3 + Material 3 |
| Language | Dart 3 |
| State Management | Riverpod 2 |
| Navigation | go_router |
| Backend | Supabase (Auth + PostgreSQL + Storage + Realtime) |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |
| Images | cached_network_image |

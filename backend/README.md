# Supabase Backend Setup

## 1. Create Supabase project
- Create a new project in Supabase.
- Credentials have been configured in `lib/config/supabase_config.dart`.

## 2. Run SQL
- Open SQL Editor in Supabase.
- Run `backend/schema.sql` (includes tables, triggers, and row-level security policies).

## 3. Flutter run
Simply run:

```bash
flutter run
```

Credentials are now hardcoded in the app configuration.

## 4. Notes
- Schema includes: profiles, daily_motives, routine_completions, badges_earned, journal_entries, meditation_sessions, focus_sessions, smart_goals.
- Row-level security ensures users can only access their own data using `auth.uid()`.
- Migration from Firebase to Supabase is complete for core services.

-- MindNest Supabase schema
-- Run in Supabase SQL Editor.

create extension if not exists pgcrypto;

-- Profiles (replaces users collection)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text not null default '',
  photo_url text,
  sign_in_method text,
  created_at timestamptz not null default now(),
  last_login timestamptz,
  login_dates timestamptz[] default '{}',
  primary_motive text,
  secondary_motives text[] default '{}',
  support_areas text[] default '{}',
  preferred_time text,
  daily_commitment text,
  experience_level text,
  onboarding_completed boolean not null default false,
  routine jsonb default '{}'::jsonb,
  routine_activities text[] default '{}',
  routine_schedule jsonb default '{}'::jsonb,
  temporary_schedule jsonb default '{}'::jsonb,
  additional_activities text[] default '{}',
  base_routine text[] default '{}',
  sleep_data jsonb default '{}'::jsonb,
  last_generated_date timestamptz,
  updated_at timestamptz not null default now()
);

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_profiles_updated_at();

-- Daily motives
create table if not exists public.daily_motives (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  motive_date date not null,
  motive text not null,
  created_at timestamptz not null default now(),
  unique(user_id, motive_date)
);

-- Routine completions
create table if not exists public.routine_completions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  completion_date date not null,
  completed_activities text[] not null default '{}',
  total_activities int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, completion_date)
);

drop trigger if exists trg_routine_completions_updated_at on public.routine_completions;
create trigger trg_routine_completions_updated_at
before update on public.routine_completions
for each row execute function public.set_profiles_updated_at();

-- Badges
create table if not exists public.badges_earned (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_id text not null,
  badge_name text not null,
  badge_description text,
  icon text,
  earned_date timestamptz not null default now(),
  unique(user_id, badge_id)
);

-- Journals
create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  content text not null,
  mood text,
  created_at timestamptz not null default now()
);

-- Meditation sessions
create table if not exists public.meditation_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  duration_minutes int not null default 0,
  start_time timestamptz not null default now(),
  completed boolean not null default true
);

-- Focus sessions
create table if not exists public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  duration_minutes int not null default 0,
  start_time timestamptz not null default now(),
  completed boolean not null default true
);

-- Smart goals
create table if not exists public.smart_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  deadline timestamptz,
  is_completed boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- Row Level Security Policies
-- ============================================================

-- Enable RLS on all tables
alter table public.profiles enable row level security;
alter table public.daily_motives enable row level security;
alter table public.routine_completions enable row level security;
alter table public.badges_earned enable row level security;
alter table public.journal_entries enable row level security;
alter table public.meditation_sessions enable row level security;
alter table public.focus_sessions enable row level security;
alter table public.smart_goals enable row level security;

-- Drop existing policies if they exist (for clean re-runs)
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "daily_motives_all_own" on public.daily_motives;
drop policy if exists "routine_completions_all_own" on public.routine_completions;
drop policy if exists "badges_earned_all_own" on public.badges_earned;
drop policy if exists "journal_entries_all_own" on public.journal_entries;
drop policy if exists "meditation_sessions_all_own" on public.meditation_sessions;
drop policy if exists "focus_sessions_all_own" on public.focus_sessions;
drop policy if exists "smart_goals_all_own" on public.smart_goals;

-- Profiles policies
create policy "profiles_select_own"
on public.profiles for select
using (auth.uid() = id);

create policy "profiles_insert_own"
on public.profiles for insert
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- Daily motives policies
create policy "daily_motives_all_own"
on public.daily_motives for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Routine completions policies
create policy "routine_completions_all_own"
on public.routine_completions for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Badges earned policies
create policy "badges_earned_all_own"
on public.badges_earned for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Journal entries policies
create policy "journal_entries_all_own"
on public.journal_entries for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Meditation sessions policies
create policy "meditation_sessions_all_own"
on public.meditation_sessions for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Focus sessions policies
create policy "focus_sessions_all_own"
on public.focus_sessions for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Smart goals policies
create policy "smart_goals_all_own"
on public.smart_goals for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Security Logbook: run once in Supabase SQL Editor
create table if not exists public.security_logbook_entries (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  subject text not null,
  details text not null,
  action_taken text,
  created_by uuid not null references auth.users(id) on delete restrict,
  employee_code text,
  full_name text,
  created_at timestamptz not null default now()
);
create index if not exists security_logbook_entries_created_at_idx
  on public.security_logbook_entries (created_at desc);
alter table public.security_logbook_entries enable row level security;
drop policy if exists "Authenticated staff can read logbook" on public.security_logbook_entries;
create policy "Authenticated staff can read logbook"
  on public.security_logbook_entries for select to authenticated using (true);
drop policy if exists "Authenticated staff can create logbook entries" on public.security_logbook_entries;
create policy "Authenticated staff can create logbook entries"
  on public.security_logbook_entries for insert to authenticated
  with check (auth.uid() = created_by);

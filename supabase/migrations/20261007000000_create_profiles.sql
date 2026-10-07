-- ============================================================================
-- Migration: Application Profile & Role Schema (Jangana)
-- ============================================================================

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique not null references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('ADMIN', 'ENUMERATOR', 'SUPERVISOR', 'District Administrator', 'Enumerator')),
  employee_code text,
  mobile text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- Profiles Policies:
-- 1. Read access for authenticated users and anon (for demo verification)
drop policy if exists "allow_read_profiles" on public.profiles;
create policy "allow_read_profiles" on public.profiles
  for select using (true);

-- 2. Authenticated users can insert/update their profile
drop policy if exists "auth_write_profiles" on public.profiles;
create policy "auth_write_profiles" on public.profiles
  for all to authenticated
  using (true)
  with check (true);

-- Trigger to keep profiles in sync with auth.users
create or replace function public.handle_profile_sync()
returns trigger as $$
begin
  insert into public.profiles (
    auth_user_id,
    full_name,
    role,
    employee_code,
    mobile,
    is_active
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'ENUMERATOR'),
    coalesce(new.raw_user_meta_data->>'employee_code', 'OFF-' || substr(new.id::text, 1, 8)),
    new.phone,
    true
  )
  on conflict (auth_user_id) do update
  set
    full_name = excluded.full_name,
    role = excluded.role,
    employee_code = excluded.employee_code,
    updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_profile_sync on auth.users;
create trigger on_auth_user_profile_sync
  after insert or update on auth.users
  for each row execute function public.handle_profile_sync();

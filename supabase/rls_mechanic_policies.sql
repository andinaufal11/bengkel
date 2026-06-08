-- RLS policies for the mechanic-first flow.
-- Run this in the Supabase SQL editor.

alter table public.profiles enable row level security;
alter table public.mechanics enable row level security;
alter table public.bengkels enable row level security;
alter table public.home_service_tasks enable row level security;
alter table public.service_reports enable row level security;

-- PROFILES: allow a user to read and update their own profile row.
drop policy if exists "profiles can read own row" on public.profiles;
create policy "profiles can read own row"
on public.profiles
for select
using (auth.uid() = id);

drop policy if exists "profiles can insert own row" on public.profiles;
create policy "profiles can insert own row"
on public.profiles
for insert
with check (auth.uid() = id);

drop policy if exists "profiles can update own row" on public.profiles;
create policy "profiles can update own row"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

-- MECHANICS: allow the mechanic to read/update their mechanic row by auth uid.
drop policy if exists "mechanics can read own row" on public.mechanics;
create policy "mechanics can read own row"
on public.mechanics
for select
using (auth.uid() = user_id);

drop policy if exists "mechanics can insert own row" on public.mechanics;
create policy "mechanics can insert own row"
on public.mechanics
for insert
with check (auth.uid() = user_id);

drop policy if exists "mechanics can update own row" on public.mechanics;
create policy "mechanics can update own row"
on public.mechanics
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- BENGKELS: allow owner to read/update their bengkel row.
drop policy if exists "bengkels can read own row" on public.bengkels;
create policy "bengkels can read own row"
on public.bengkels
for select
using (auth.uid() = owner_id);

drop policy if exists "bengkels can insert own row" on public.bengkels;
create policy "bengkels can insert own row"
on public.bengkels
for insert
with check (auth.uid() = owner_id);

drop policy if exists "bengkels can update own row" on public.bengkels;
create policy "bengkels can update own row"
on public.bengkels
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

-- HOME SERVICE TASKS: allow mechanics to read tasks assigned to their mechanic row.
-- Assumes home_service_tasks.mechanic_id references public.mechanics.id.
drop policy if exists "mechanics can read assigned tasks" on public.home_service_tasks;
create policy "mechanics can read assigned tasks"
on public.home_service_tasks
for select
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = mechanic_id
      and m.user_id = auth.uid()
  )
);

-- SERVICE REPORTS: allow mechanics to insert reports for tasks assigned to them.
drop policy if exists "mechanics can create service reports" on public.service_reports;
create policy "mechanics can create service reports"
on public.service_reports
for insert
with check (
  exists (
    select 1
    from public.home_service_tasks t
    join public.mechanics m on m.id = t.mechanic_id
    where t.id = task_id
      and m.user_id = auth.uid()
  )
);

drop policy if exists "mechanics can read own service reports" on public.service_reports;
create policy "mechanics can read own service reports"
on public.service_reports
for select
using (
  exists (
    select 1
    from public.home_service_tasks t
    join public.mechanics m on m.id = t.mechanic_id
    where t.id = task_id
      and m.user_id = auth.uid()
  )
);

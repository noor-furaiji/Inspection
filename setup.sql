-- AutoMatch inspection: run once in Supabase → SQL Editor
create table if not exists public.reports (
  id uuid primary key,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  plate text,
  model text,
  data jsonb not null
);
create table if not exists public.sends (
  id bigint generated always as identity primary key,
  report_id uuid not null references public.reports(id) on delete cascade,
  buyer_name text,
  buyer_phone text,
  sent_at timestamptz not null default now()
);
alter table public.reports enable row level security;
alter table public.sends enable row level security;

create or replace function public.is_admin() returns boolean
language sql stable as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'admin@automatchkorea.com'
$$;

-- inspector + admin can submit; only admin can read, change or delete
create policy "submit reports" on public.reports for insert to authenticated with check (true);
create policy "admin reads reports" on public.reports for select to authenticated using (public.is_admin());
create policy "admin updates reports" on public.reports for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin deletes reports" on public.reports for delete to authenticated using (public.is_admin());
create policy "admin sends" on public.sends for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- read-only report by link (buyer view, no login)
create or replace function public.get_report(rid uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('data', data, 'created_at', created_at) from public.reports where id = rid
$$;
grant execute on function public.get_report(uuid) to anon, authenticated;
grant select, insert, update, delete on public.reports, public.sends to authenticated;

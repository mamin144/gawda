-- Profiles, sites, the user-to-site mapping, and the private authorization
-- helpers that every later RLS policy uses.

-- ---------------------------------------------------------------------------
-- Non-exposed schema for security definer helpers and trigger functions.
-- ---------------------------------------------------------------------------
create schema private;
revoke all on schema private from public;
grant usage on schema private to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete restrict,
  full_name text not null,
  role public.user_role not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.sites (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  is_active boolean not null default true,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_sites (
  user_id uuid not null references public.profiles (id),
  site_id uuid not null references public.sites (id),
  created_at timestamptz not null default now(),
  primary key (user_id, site_id)
);

-- The primary key covers lookups by user_id; site_id needs its own index.
create index user_sites_site_id_idx on public.user_sites (site_id);

alter table public.profiles enable row level security;
alter table public.sites enable row level security;
alter table public.user_sites enable row level security;

-- ---------------------------------------------------------------------------
-- Authorization helpers (security definer, non-exposed schema).
-- They only ever look at the calling user, (select auth.uid()).
-- ---------------------------------------------------------------------------
create function private.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.is_active
  );
$$;

create function private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.is_active
      and p.role = 'admin'
  );
$$;

create function private.has_site_access(p_site uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.is_active
      and (
        p.role = 'admin'
        or (
          p.role = 'site_user'
          and exists (
            select 1
            from public.user_sites us
            where us.user_id = p.id
              and us.site_id = p_site
          )
        )
      )
  );
$$;

revoke execute on function private.is_active_user() from public, anon;
revoke execute on function private.is_admin() from public, anon;
revoke execute on function private.has_site_access(uuid) from public, anon;
grant execute on function private.is_active_user() to authenticated;
grant execute on function private.is_admin() to authenticated;
grant execute on function private.has_site_access(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------
create function private.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function private.set_updated_at() from public, anon, authenticated;

create trigger set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

create trigger set_updated_at
before update on public.sites
for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS policies (all to authenticated)
-- ---------------------------------------------------------------------------

-- profiles: own row (while active) or admin. Admin-only update. No insert or
-- delete policy: profiles are created by the Edge Function (service_role).
create policy profiles_select_own_or_admin
on public.profiles
for select
to authenticated
using (
  (id = (select auth.uid()) and (select private.is_active_user()))
  or (select private.is_admin())
);

create policy profiles_update_admin
on public.profiles
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

-- sites: visible with site access. Admin insert/update. No delete (archive).
create policy sites_select_with_access
on public.sites
for select
to authenticated
using (private.has_site_access(id));

create policy sites_insert_admin
on public.sites
for insert
to authenticated
with check ((select private.is_admin()));

create policy sites_update_admin
on public.sites
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

-- user_sites: own rows (while active) or admin. Admin insert/delete.
create policy user_sites_select_own_or_admin
on public.user_sites
for select
to authenticated
using (
  (user_id = (select auth.uid()) and (select private.is_active_user()))
  or (select private.is_admin())
);

create policy user_sites_insert_admin
on public.user_sites
for insert
to authenticated
with check ((select private.is_admin()));

create policy user_sites_delete_admin
on public.user_sites
for delete
to authenticated
using ((select private.is_admin()));

-- ---------------------------------------------------------------------------
-- Grants: only what the policies allow. Nothing for anon.
-- ---------------------------------------------------------------------------
revoke all on table public.profiles, public.sites, public.user_sites from public, anon, authenticated;

grant select on table public.profiles to authenticated;
grant update (full_name, role, is_active) on table public.profiles to authenticated;

grant select, insert on table public.sites to authenticated;
grant update (code, name, is_active, archived_at) on table public.sites to authenticated;

grant select, insert, delete on table public.user_sites to authenticated;

grant select, insert, update, delete on table public.profiles, public.sites, public.user_sites to service_role;

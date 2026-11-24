-- P3 admin management: guards on profiles and sites, audit triggers for
-- admin management actions, and the admin RPCs.
--   Q15: no self demote/deactivate; never zero active admins.
--   Q16: archived_at is set <=> is_active is false.
--   Q17: admins are never linked to sites.
--   Q18: a site user may have zero sites.
--   Q19: admin management actions are audited.
--   Q20: a site code is editable only while the site has no certificates.
--
-- Functions in schema private are not executable by PUBLIC by default (see
-- 20261123081000_certificates.sql); every function below still revokes and
-- grants explicitly.

-- ---------------------------------------------------------------------------
-- Existing site codes are normalized before the normalizing trigger exists
-- (R4). A clash between two codes that only differ by case or padding fails
-- the migration with a unique violation.
-- ---------------------------------------------------------------------------
update public.sites
set code = upper(btrim(code))
where code is distinct from upper(btrim(code));

-- Existing rows must already satisfy Q16; fail loudly otherwise.
do $$
begin
  if exists (
    select 1 from public.sites s
    where (s.archived_at is not null) = s.is_active
  ) then
    raise exception 'archive_inconsistent: existing sites violate archived_at <=> not is_active';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles_guard (Q15). Security definer so the active-admin count sees every
-- profile regardless of the caller's RLS. auth.uid() is null for postgres and
-- service_role, so cannot_change_self only applies to signed-in callers;
-- last_admin applies to every role.
-- ---------------------------------------------------------------------------
create function private.profiles_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.id = (select auth.uid())
     and (new.role is distinct from old.role or new.is_active is distinct from old.is_active) then
    raise exception 'cannot_change_self';
  end if;

  if old.role = 'admin' and old.is_active
     and not (new.role = 'admin' and new.is_active) then
    -- Serialize concurrent removals of active admins so two transactions
    -- cannot each remove "another" admin and leave zero.
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext('public.profiles:last_admin'));
    if not exists (
      select 1 from public.profiles p
      where p.role = 'admin' and p.is_active and p.id <> old.id
    ) then
      raise exception 'last_admin';
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function private.profiles_guard() from public, anon, authenticated, service_role;

create trigger profiles_guard
before update on public.profiles
for each row execute function private.profiles_guard();

-- ---------------------------------------------------------------------------
-- sites_archive_consistency (Q16) and code normalization. Before insert or
-- update; it fires before sites_code_lock (triggers fire in name order), so
-- the code lock compares normalized codes.
-- ---------------------------------------------------------------------------
create function private.sites_archive_consistency()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.code := upper(btrim(new.code));
  if (new.archived_at is not null) = new.is_active then
    raise exception 'archive_inconsistent';
  end if;
  return new;
end;
$$;

revoke execute on function private.sites_archive_consistency() from public, anon, authenticated, service_role;

create trigger sites_archive_consistency
before insert or update on public.sites
for each row execute function private.sites_archive_consistency();

-- ---------------------------------------------------------------------------
-- sites_code_lock (Q20). Any certificate row (soft-deleted included) locks
-- the code. Security definer so the check sees certificates hidden by RLS.
-- ---------------------------------------------------------------------------
create function private.sites_code_lock()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.code is distinct from old.code
     and exists (select 1 from public.certificates c where c.site_id = old.id) then
    raise exception 'code_locked';
  end if;
  return new;
end;
$$;

revoke execute on function private.sites_code_lock() from public, anon, authenticated, service_role;

create trigger sites_code_lock
before update of code on public.sites
for each row execute function private.sites_code_lock();

-- ---------------------------------------------------------------------------
-- Audit triggers (Q19). The actor is auth.uid(); when it is null (postgres,
-- or the service_role path of the admin-create-user Edge Function, which
-- audits through public.audit_user_created) nothing is written (R2).
-- ---------------------------------------------------------------------------
create function private.audit_sites()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    return null;
  end if;
  if tg_op = 'INSERT' then
    perform private.write_audit('site_created', 'site', new.id, null, to_jsonb(new), null);
  else
    perform private.write_audit('site_updated', 'site', new.id, to_jsonb(old), to_jsonb(new), null);
  end if;
  return null;
end;
$$;

create function private.audit_profiles()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    return null;
  end if;
  perform private.write_audit('profile_updated', 'profile', new.id, to_jsonb(old), to_jsonb(new), null);
  return null;
end;
$$;

-- user_sites rows are audited against the user's profile, so a user's
-- history is one (entity, entity_id) lookup.
create function private.audit_user_sites()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    return null;
  end if;
  if tg_op = 'INSERT' then
    perform private.write_audit(
      'user_site_added', 'profile', new.user_id, null, jsonb_build_object('site_id', new.site_id), null
    );
  else
    perform private.write_audit(
      'user_site_removed', 'profile', old.user_id, jsonb_build_object('site_id', old.site_id), null, null
    );
  end if;
  return null;
end;
$$;

revoke execute on function private.audit_sites() from public, anon, authenticated, service_role;
revoke execute on function private.audit_profiles() from public, anon, authenticated, service_role;
revoke execute on function private.audit_user_sites() from public, anon, authenticated, service_role;

create trigger audit_sites
after insert or update on public.sites
for each row execute function private.audit_sites();

create trigger audit_profiles
after update on public.profiles
for each row execute function private.audit_profiles();

create trigger audit_user_sites
after insert or delete on public.user_sites
for each row execute function private.audit_user_sites();

-- ---------------------------------------------------------------------------
-- public.admin_list_users(): every profile with its auth email, invite state
-- and site ids. Active admins only.
-- ---------------------------------------------------------------------------
create function public.admin_list_users()
returns table (
  id uuid,
  email text,
  full_name text,
  role public.user_role,
  is_active boolean,
  invite_pending boolean,
  site_ids uuid[]
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (select private.is_admin()) then
    raise exception 'forbidden';
  end if;

  return query
  select
    p.id,
    u.email::text,
    p.full_name,
    p.role,
    p.is_active,
    u.email_confirmed_at is null,
    coalesce(
      (select array_agg(us.site_id order by us.site_id)
       from public.user_sites us
       where us.user_id = p.id),
      '{}'::uuid[]
    )
  from public.profiles p
  join auth.users u on u.id = p.id
  order by p.full_name, p.id;
end;
$$;

revoke execute on function public.admin_list_users() from public, anon;
grant execute on function public.admin_list_users() to authenticated;

-- ---------------------------------------------------------------------------
-- public.admin_set_user_sites(p_user, p_site_ids): replaces a site user's
-- sites with exactly p_site_ids (duplicates ignored; empty allowed, Q18).
-- Only removed and added links are touched, so the audit rows show the real
-- change. Active admins only; the target must be a site_user (Q17); every id
-- must be an active, non-archived site.
-- ---------------------------------------------------------------------------
create function public.admin_set_user_sites(p_user uuid, p_site_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ids uuid[] := coalesce(p_site_ids, '{}'::uuid[]);
begin
  if not (select private.is_admin()) then
    raise exception 'forbidden';
  end if;

  -- Lock the target row so concurrent calls for the same user serialize.
  perform 1 from public.profiles p
  where p.id = p_user and p.role = 'site_user'
  for update;
  if not found then
    raise exception 'invalid_target';
  end if;

  if exists (
    select 1
    from unnest(v_ids) as x (site_id)
    where x.site_id is null
       or not exists (
         select 1 from public.sites s
         where s.id = x.site_id and s.is_active and s.archived_at is null
       )
  ) then
    raise exception 'invalid_sites';
  end if;

  delete from public.user_sites us
  where us.user_id = p_user
    and us.site_id <> all (v_ids);

  insert into public.user_sites (user_id, site_id)
  select distinct p_user, x.site_id
  from unnest(v_ids) as x (site_id)
  on conflict (user_id, site_id) do nothing;
end;
$$;

revoke execute on function public.admin_set_user_sites(uuid, uuid[]) from public, anon;
grant execute on function public.admin_set_user_sites(uuid, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- public.auth_user_exists(p_email): case-insensitive email lookup in
-- auth.users for the admin-create-user Edge Function. service_role only.
-- ---------------------------------------------------------------------------
create function public.auth_user_exists(p_email text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from auth.users u
    where lower(u.email) = lower(p_email)
  );
$$;

revoke execute on function public.auth_user_exists(text) from public, anon, authenticated;
grant execute on function public.auth_user_exists(text) to service_role;

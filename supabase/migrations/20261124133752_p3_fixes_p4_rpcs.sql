-- P3 review fixes and the P4 remove_attachment RPC.
-- Plan: docs/superpowers/plans/2026-11-24-p3-fixes-p4-site-user.md (Task 1).
--   * user_sites may only link site users (invalid_target), and a site user
--     with linked sites cannot be promoted to admin (has_sites).
--   * audit_sites / audit_profiles skip no-op updates (R4: compare rows
--     without updated_at, which set_updated_at always changes).
--   * sites.archived_at is derived by the server (R3): now() when a site
--     becomes inactive, kept while it stays inactive, null when active. The
--     client value is ignored.
--   * remove_attachment (R1): soft delete of an attachment while its
--     certificate is draft or returned and not deleted. The storage object
--     is kept.

-- ---------------------------------------------------------------------------
-- user_sites: only site users can be linked to sites.
-- ---------------------------------------------------------------------------
create function private.user_sites_target_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.profiles p
    where p.id = new.user_id and p.role = 'site_user'
  ) then
    raise exception 'invalid_target';
  end if;
  return new;
end;
$$;

revoke execute on function private.user_sites_target_guard() from public, anon, authenticated, service_role;

create trigger user_sites_target_guard
before insert on public.user_sites
for each row execute function private.user_sites_target_guard();

-- ---------------------------------------------------------------------------
-- profiles_guard: adds has_sites (a site user with links cannot become admin).
-- ---------------------------------------------------------------------------
create or replace function private.profiles_guard()
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

  if old.role = 'site_user' and new.role = 'admin'
     and exists (select 1 from public.user_sites us where us.user_id = old.id) then
    raise exception 'has_sites';
  end if;

  if old.role = 'admin' and old.is_active
     and not (new.role = 'admin' and new.is_active) then
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

-- ---------------------------------------------------------------------------
-- Audit triggers: skip no-op updates (R4).
-- ---------------------------------------------------------------------------
create or replace function private.audit_sites()
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
  elsif (to_jsonb(old) - 'updated_at') is distinct from (to_jsonb(new) - 'updated_at') then
    perform private.write_audit('site_updated', 'site', new.id, to_jsonb(old), to_jsonb(new), null);
  end if;
  return null;
end;
$$;

create or replace function private.audit_profiles()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    return null;
  end if;
  if (to_jsonb(old) - 'updated_at') is distinct from (to_jsonb(new) - 'updated_at') then
    perform private.write_audit('profile_updated', 'profile', new.id, to_jsonb(old), to_jsonb(new), null);
  end if;
  return null;
end;
$$;

-- ---------------------------------------------------------------------------
-- sites.archived_at is derived by the server (R3).
-- ---------------------------------------------------------------------------
create or replace function private.sites_archive_consistency()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.code := upper(btrim(new.code));
  if new.is_active then
    new.archived_at := null;
  elsif tg_op = 'INSERT' or old.is_active then
    new.archived_at := now();
  else
    new.archived_at := old.archived_at;
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- remove_attachment (R1): soft delete while the certificate is editable.
-- Same check order as the transitions: not_found, forbidden, already_deleted,
-- invalid_transition.
-- ---------------------------------------------------------------------------
create function private.remove_attachment(p_id uuid, p_reason text default null)
returns public.attachments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.attachments;
  v_new public.attachments;
  v_cert public.certificates;
begin
  select * into v_old from public.attachments where id = p_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  select * into v_cert from public.certificates where id = v_old.certificate_id;
  if not (select private.is_admin()) and not (select private.has_site_access(v_cert.site_id)) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    raise exception 'already_deleted';
  end if;
  if v_cert.deleted_at is not null or v_cert.status not in ('draft', 'returned') then
    raise exception 'invalid_transition';
  end if;

  update public.attachments
  set deleted_at = now(), deleted_by = (select auth.uid()), delete_reason = p_reason
  where id = p_id
  returning * into v_new;

  perform private.write_audit(
    (select auth.uid()), 'remove_attachment', 'attachment', p_id,
    jsonb_build_object('certificate_id', v_old.certificate_id, 'storage_path', v_old.storage_path,
                       'sha256', v_old.sha256),
    null,
    p_reason
  );
  return v_new;
end;
$$;

create function public.remove_attachment(p_id uuid, p_reason text default null)
returns public.attachments
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return private.remove_attachment(p_id, p_reason);
end;
$$;

revoke execute on function private.remove_attachment(uuid, text) from public, anon, service_role;
revoke execute on function public.remove_attachment(uuid, text) from public, anon, service_role;
grant execute on function private.remove_attachment(uuid, text) to authenticated;
grant execute on function public.remove_attachment(uuid, text) to authenticated;

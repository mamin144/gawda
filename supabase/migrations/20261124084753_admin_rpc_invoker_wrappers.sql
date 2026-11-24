-- Moves the bodies of admin_list_users and admin_set_user_sites into the
-- non-exposed private schema (security definer) and turns the public
-- functions into security invoker wrappers with the same signatures, as in
-- 20261123083117_transitions.sql. This clears advisor lint 0029
-- (authenticated_security_definer_function_executable) for the Data API.
-- Additive: create or replace keeps the public signatures and return types.

-- ---------------------------------------------------------------------------
-- private.admin_list_users(): every profile with its auth email, invite
-- state and site ids. Active admins only.
-- ---------------------------------------------------------------------------
create function private.admin_list_users()
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

-- ---------------------------------------------------------------------------
-- private.admin_set_user_sites(p_user, p_site_ids): replaces a site user's
-- sites with exactly p_site_ids (duplicates ignored; empty allowed, Q18).
-- Only removed and added links are touched, so the audit rows show the real
-- change. Check order: forbidden (caller not an active admin) ->
-- invalid_target (not a site_user, Q17) -> invalid_sites (null, unknown,
-- inactive or archived site).
-- ---------------------------------------------------------------------------
create function private.admin_set_user_sites(p_user uuid, p_site_ids uuid[])
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

-- ---------------------------------------------------------------------------
-- Public wrappers (security invoker) exposed over the Data API.
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_users()
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
security invoker
set search_path = ''
as $$
begin
  return query select * from private.admin_list_users();
end;
$$;

create or replace function public.admin_set_user_sites(p_user uuid, p_site_ids uuid[])
returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  perform private.admin_set_user_sites(p_user, p_site_ids);
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: only authenticated may execute either layer (per-function revoke;
-- Supabase grants new public functions to anon/service_role by default).
-- ---------------------------------------------------------------------------
revoke execute on function private.admin_list_users() from public, anon, service_role;
revoke execute on function private.admin_set_user_sites(uuid, uuid[]) from public, anon, service_role;
revoke execute on function public.admin_list_users() from public, anon, service_role;
revoke execute on function public.admin_set_user_sites(uuid, uuid[]) from public, anon, service_role;

grant execute on function private.admin_list_users() to authenticated;
grant execute on function private.admin_set_user_sites(uuid, uuid[]) to authenticated;
grant execute on function public.admin_list_users() to authenticated;
grant execute on function public.admin_set_user_sites(uuid, uuid[]) to authenticated;

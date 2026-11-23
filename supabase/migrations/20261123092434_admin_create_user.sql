-- Service RPC for the admin-create-user Edge Function: records the audit row
-- for a user the function has just invited and stored (profile and
-- user_sites). Security definer in public, executable by service_role only:
-- the Edge Function validates the caller's JWT and passes the caller's id as
-- p_actor. As auth.uid() is null for service_role, the actor is checked here
-- explicitly against profiles (an active admin); private.is_admin() is not
-- used because it reads auth.uid().

create function public.audit_user_created(p_user uuid, p_actor uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  select * into v_profile from public.profiles p where p.id = p_user;
  if not found then
    raise exception 'not_found';
  end if;
  if p_actor is null or not exists (
    select 1
    from public.profiles p
    where p.id = p_actor
      and p.is_active
      and p.role = 'admin'
  ) then
    raise exception 'forbidden';
  end if;

  perform private.write_audit(
    p_actor, 'audit_user_created', 'profile', p_user,
    null,
    jsonb_build_object(
      'role', v_profile.role,
      'full_name', v_profile.full_name,
      'is_active', v_profile.is_active,
      'site_ids', coalesce(
        (select jsonb_agg(us.site_id order by us.site_id)
         from public.user_sites us
         where us.user_id = p_user),
        '[]'::jsonb
      )
    ),
    null
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: service_role only (R14: per-function revoke; Supabase grants new
-- public functions to anon/authenticated/service_role by default).
-- ---------------------------------------------------------------------------
revoke execute on function public.audit_user_created(uuid, uuid) from public, anon, authenticated;
grant execute on function public.audit_user_created(uuid, uuid) to service_role;

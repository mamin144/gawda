-- Status-transition RPCs. Each transition is a security definer function in
-- the non-exposed private schema (it bypasses RLS and the edit guard, so it
-- enforces role, site access and status itself) plus a security invoker
-- wrapper in public with the same signature for the Data API.
--
-- Check order in every private function: lock the row; missing -> not_found;
-- wrong caller -> forbidden; soft-deleted -> not_found (already_deleted for
-- delete_certificate); wrong from-status -> invalid_transition; then the
-- argument checks. Every successful call writes one audit row.

-- ---------------------------------------------------------------------------
-- submit_certificate: site_user with site access, draft/returned -> in_review.
-- ---------------------------------------------------------------------------
create function private.submit_certificate(p_id uuid)
returns public.certificates
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.certificates;
  v_new public.certificates;
begin
  select * into v_old from public.certificates where id = p_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  if (select private.is_admin()) or not (select private.has_site_access(v_old.site_id)) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    raise exception 'not_found';
  end if;
  if v_old.status not in ('draft', 'returned') then
    raise exception 'invalid_transition';
  end if;

  update public.certificates
  set status = 'in_review', submitted_at = now()
  where id = p_id
  returning * into v_new;

  perform private.write_audit(
    (select auth.uid()), 'submit_certificate', 'certificate', p_id,
    jsonb_build_object('status', v_old.status, 'return_note', v_old.return_note),
    jsonb_build_object('status', v_new.status, 'return_note', v_new.return_note),
    null
  );
  return v_new;
end;
$$;

-- ---------------------------------------------------------------------------
-- return_certificate: admin, in_review -> returned, sets return_note.
-- ---------------------------------------------------------------------------
create function private.return_certificate(p_id uuid, p_note text)
returns public.certificates
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.certificates;
  v_new public.certificates;
begin
  select * into v_old from public.certificates where id = p_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not (select private.is_admin()) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    raise exception 'not_found';
  end if;
  if v_old.status <> 'in_review' then
    raise exception 'invalid_transition';
  end if;
  if coalesce(btrim(p_note), '') = '' then
    raise exception 'return_note_required';
  end if;

  update public.certificates
  set status = 'returned', return_note = p_note
  where id = p_id
  returning * into v_new;

  perform private.write_audit(
    (select auth.uid()), 'return_certificate', 'certificate', p_id,
    jsonb_build_object('status', v_old.status, 'return_note', v_old.return_note),
    jsonb_build_object('status', v_new.status, 'return_note', v_new.return_note),
    null
  );
  return v_new;
end;
$$;

-- ---------------------------------------------------------------------------
-- approve_for_signing: admin, in_review -> awaiting_signature.
-- ---------------------------------------------------------------------------
create function private.approve_for_signing(p_id uuid)
returns public.certificates
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.certificates;
  v_new public.certificates;
begin
  select * into v_old from public.certificates where id = p_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not (select private.is_admin()) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    raise exception 'not_found';
  end if;
  if v_old.status <> 'in_review' then
    raise exception 'invalid_transition';
  end if;

  update public.certificates
  set status = 'awaiting_signature'
  where id = p_id
  returning * into v_new;

  perform private.write_audit(
    (select auth.uid()), 'approve_for_signing', 'certificate', p_id,
    jsonb_build_object('status', v_old.status, 'return_note', v_old.return_note),
    jsonb_build_object('status', v_new.status, 'return_note', v_new.return_note),
    null
  );
  return v_new;
end;
$$;

-- ---------------------------------------------------------------------------
-- reopen_certificate: admin, approved -> returned, clears locked_at. The
-- reason goes to the audit row only.
-- ---------------------------------------------------------------------------
create function private.reopen_certificate(p_id uuid, p_reason text)
returns public.certificates
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.certificates;
  v_new public.certificates;
begin
  select * into v_old from public.certificates where id = p_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  if not (select private.is_admin()) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    raise exception 'not_found';
  end if;
  if v_old.status <> 'approved' then
    raise exception 'invalid_transition';
  end if;
  if coalesce(btrim(p_reason), '') = '' then
    raise exception 'reopen_reason_required';
  end if;

  update public.certificates
  set status = 'returned', locked_at = null
  where id = p_id
  returning * into v_new;

  perform private.write_audit(
    (select auth.uid()), 'reopen_certificate', 'certificate', p_id,
    jsonb_build_object('status', v_old.status, 'return_note', v_old.return_note),
    jsonb_build_object('status', v_new.status, 'return_note', v_new.return_note),
    p_reason
  );
  return v_new;
end;
$$;

-- ---------------------------------------------------------------------------
-- delete_certificate: soft delete (status unchanged). A site_user with site
-- access may delete a non-approved certificate; an admin may delete only an
-- approved one (Q13). Attachments and files are kept.
-- ---------------------------------------------------------------------------
create function private.delete_certificate(p_id uuid, p_reason text default null)
returns public.certificates
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.certificates;
  v_new public.certificates;
  v_is_admin boolean;
begin
  select * into v_old from public.certificates where id = p_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  v_is_admin := (select private.is_admin());
  if not v_is_admin and not (select private.has_site_access(v_old.site_id)) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    raise exception 'already_deleted';
  end if;
  if (v_is_admin and v_old.status <> 'approved')
     or (not v_is_admin and v_old.status = 'approved') then
    raise exception 'forbidden';
  end if;

  update public.certificates
  set deleted_at = now(), deleted_by = (select auth.uid())
  where id = p_id
  returning * into v_new;

  perform private.write_audit(
    (select auth.uid()), 'delete_certificate', 'certificate', p_id,
    jsonb_build_object('status', v_old.status, 'return_note', v_old.return_note),
    jsonb_build_object('status', v_new.status, 'return_note', v_new.return_note),
    p_reason
  );
  return v_new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Public wrappers (security invoker) exposed over the Data API.
-- ---------------------------------------------------------------------------
create function public.submit_certificate(p_id uuid)
returns public.certificates
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return private.submit_certificate(p_id);
end;
$$;

create function public.return_certificate(p_id uuid, p_note text)
returns public.certificates
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return private.return_certificate(p_id, p_note);
end;
$$;

create function public.approve_for_signing(p_id uuid)
returns public.certificates
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return private.approve_for_signing(p_id);
end;
$$;

create function public.reopen_certificate(p_id uuid, p_reason text)
returns public.certificates
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return private.reopen_certificate(p_id, p_reason);
end;
$$;

create function public.delete_certificate(p_id uuid, p_reason text default null)
returns public.certificates
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return private.delete_certificate(p_id, p_reason);
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: only authenticated may execute (R14: per-function revoke; Supabase
-- also grants anon/service_role execute on new public functions by default).
-- ---------------------------------------------------------------------------
revoke execute on function private.submit_certificate(uuid) from public, anon, service_role;
revoke execute on function private.return_certificate(uuid, text) from public, anon, service_role;
revoke execute on function private.approve_for_signing(uuid) from public, anon, service_role;
revoke execute on function private.reopen_certificate(uuid, text) from public, anon, service_role;
revoke execute on function private.delete_certificate(uuid, text) from public, anon, service_role;
revoke execute on function public.submit_certificate(uuid) from public, anon, service_role;
revoke execute on function public.return_certificate(uuid, text) from public, anon, service_role;
revoke execute on function public.approve_for_signing(uuid) from public, anon, service_role;
revoke execute on function public.reopen_certificate(uuid, text) from public, anon, service_role;
revoke execute on function public.delete_certificate(uuid, text) from public, anon, service_role;

grant execute on function private.submit_certificate(uuid) to authenticated;
grant execute on function private.return_certificate(uuid, text) to authenticated;
grant execute on function private.approve_for_signing(uuid) to authenticated;
grant execute on function private.reopen_certificate(uuid, text) to authenticated;
grant execute on function private.delete_certificate(uuid, text) to authenticated;
grant execute on function public.submit_certificate(uuid) to authenticated;
grant execute on function public.return_certificate(uuid, text) to authenticated;
grant execute on function public.approve_for_signing(uuid) to authenticated;
grant execute on function public.reopen_certificate(uuid, text) to authenticated;
grant execute on function public.delete_certificate(uuid, text) to authenticated;

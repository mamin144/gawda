-- Service RPCs for the finalize-certificate Edge Function. Both functions are
-- security definer in public and executable by service_role only: the Edge
-- Function validates the caller's JWT and passes the user id as p_actor. As
-- auth.uid() is null for service_role, the actor is checked here explicitly
-- (an active site_user mapped to the certificate's site); the auth.uid()-based
-- helpers (private.has_site_access is also true for admins) are not used.

-- ---------------------------------------------------------------------------
-- finalize_with_signed_copy: awaiting_signature -> approved, locks the
-- certificate and returns its active initial attachments, whose storage
-- objects the Edge Function then deletes. An already approved certificate
-- returns the still-active initial attachments without a new audit row, so a
-- retry after a failed storage delete is idempotent.
--
-- A signed copy qualifies only for the current signing round: it is active,
-- its object exists in the certificates bucket, and it was uploaded at or
-- after the latest approve_for_signing audit row of the certificate. Signed
-- copies of earlier rounds (before a reopen) are kept but do not qualify.
-- ---------------------------------------------------------------------------
create function public.finalize_with_signed_copy(p_id uuid, p_actor uuid)
returns table (attachment_id uuid, storage_path text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_old public.certificates;
  v_new public.certificates;
  v_round_start timestamptz;
begin
  select * into v_old from public.certificates c where c.id = p_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  if p_actor is null or not exists (
    select 1
    from public.profiles p
    join public.user_sites us on us.user_id = p.id
    where p.id = p_actor
      and p.is_active
      and p.role = 'site_user'
      and us.site_id = v_old.site_id
  ) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    raise exception 'not_found';
  end if;

  if v_old.status = 'approved' then
    return query
      select a.id, a.storage_path
      from public.attachments a
      where a.certificate_id = p_id
        and a.kind = 'initial'
        and a.deleted_at is null
      order by a.uploaded_at, a.id;
    return;
  end if;

  if v_old.status <> 'awaiting_signature' then
    raise exception 'invalid_transition';
  end if;

  select l.created_at into v_round_start
  from public.audit_logs l
  where l.entity = 'certificate'
    and l.entity_id = p_id
    and l.action = 'approve_for_signing'
  order by l.created_at desc, l.id desc
  limit 1;

  if v_round_start is null or not exists (
    select 1
    from public.attachments a
    join storage.objects o
      on o.bucket_id = 'certificates' and o.name = a.storage_path
    where a.certificate_id = p_id
      and a.kind = 'signed'
      and a.deleted_at is null
      and a.uploaded_at >= v_round_start
  ) then
    raise exception 'signed_copy_missing';
  end if;

  update public.certificates c
  set status = 'approved', locked_at = now()
  where c.id = p_id
  returning * into v_new;

  perform private.write_audit(
    p_actor, 'finalize_with_signed_copy', 'certificate', p_id,
    jsonb_build_object('status', v_old.status, 'return_note', v_old.return_note),
    jsonb_build_object('status', v_new.status, 'return_note', v_new.return_note),
    null
  );

  return query
    select a.id, a.storage_path
    from public.attachments a
    where a.certificate_id = p_id
      and a.kind = 'initial'
      and a.deleted_at is null
    order by a.uploaded_at, a.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- record_initial_file_deleted: soft-deletes the metadata row of an initial
-- attachment of an approved certificate after the Edge Function removed its
-- storage object (the row is kept). A no-op when the row is already deleted.
-- Lock order matches finalize_with_signed_copy: certificate, then attachment.
-- ---------------------------------------------------------------------------
create function public.record_initial_file_deleted(p_attachment_id uuid, p_actor uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cert public.certificates;
  v_old public.attachments;
  v_new public.attachments;
begin
  select * into v_cert
  from public.certificates c
  where c.id = (select a.certificate_id from public.attachments a where a.id = p_attachment_id)
  for update;
  if not found then
    raise exception 'not_found';
  end if;
  select * into v_old from public.attachments a where a.id = p_attachment_id for update;
  if not found then
    raise exception 'not_found';
  end if;
  if p_actor is null or not exists (
    select 1
    from public.profiles p
    join public.user_sites us on us.user_id = p.id
    where p.id = p_actor
      and p.is_active
      and p.role = 'site_user'
      and us.site_id = v_cert.site_id
  ) then
    raise exception 'forbidden';
  end if;
  if v_old.deleted_at is not null then
    return;
  end if;
  if v_cert.deleted_at is not null then
    raise exception 'not_found';
  end if;
  if v_old.kind <> 'initial' or v_cert.status <> 'approved' then
    raise exception 'invalid_transition';
  end if;

  update public.attachments a
  set deleted_at = now(), deleted_by = p_actor, delete_reason = 'replaced_by_signed_copy'
  where a.id = p_attachment_id
  returning * into v_new;

  perform private.write_audit(
    p_actor, 'record_initial_file_deleted', 'attachment', p_attachment_id,
    jsonb_build_object('deleted_at', v_old.deleted_at, 'delete_reason', v_old.delete_reason),
    jsonb_build_object('deleted_at', v_new.deleted_at, 'delete_reason', v_new.delete_reason),
    null
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants: service_role only (R14: per-function revoke; Supabase grants new
-- public functions to anon/authenticated/service_role by default).
-- ---------------------------------------------------------------------------
revoke execute on function public.finalize_with_signed_copy(uuid, uuid) from public, anon, authenticated;
revoke execute on function public.record_initial_file_deleted(uuid, uuid) from public, anon, authenticated;
grant execute on function public.finalize_with_signed_copy(uuid, uuid) to service_role;
grant execute on function public.record_initial_file_deleted(uuid, uuid) to service_role;

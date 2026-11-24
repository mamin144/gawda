-- remove_attachment: only initial attachments can be removed.
-- Final review finding I2 (plan docs/superpowers/plans/2026-11-24-p3-fixes-p4-site-user.md):
-- a signed copy is the record of an approval and survives re-opening
-- (PROJECT_PLAN 5), so removing it is an invalid_transition for every role.
-- Same signature, owner, grants and check order as before; only the kind
-- check is new.

create or replace function private.remove_attachment(p_id uuid, p_reason text default null)
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
  if v_old.kind <> 'initial'
     or v_cert.deleted_at is not null or v_cert.status not in ('draft', 'returned') then
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

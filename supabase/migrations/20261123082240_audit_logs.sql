-- Append-only audit log. Rows are written only through private.write_audit
-- (called by other security definer functions); no API role can insert,
-- update, delete or truncate, and a trigger blocks update/delete/truncate
-- for every role, including postgres.

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------
create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles (id),
  action text not null,
  entity text not null,
  entity_id uuid not null,
  before jsonb,
  after jsonb,
  reason text,
  created_at timestamptz not null default now()
);

create index audit_logs_entity_idx on public.audit_logs (entity, entity_id);

alter table public.audit_logs enable row level security;

-- ---------------------------------------------------------------------------
-- Append-only guard. Raised for every role; a row-level trigger for
-- update/delete and a statement-level trigger for truncate.
-- ---------------------------------------------------------------------------
create function private.forbid_audit_mutation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception 'audit_log_append_only';
end;
$$;

revoke execute on function private.forbid_audit_mutation() from public, anon, authenticated, service_role;

create trigger forbid_audit_mutation
before update or delete on public.audit_logs
for each row execute function private.forbid_audit_mutation();

create trigger forbid_audit_truncate
before truncate on public.audit_logs
for each statement execute function private.forbid_audit_mutation();

-- ---------------------------------------------------------------------------
-- Writers (security definer, non-exposed schema, no API role may execute).
-- The explicit-actor overload holds the insert; the other one takes the
-- actor from the caller's JWT.
-- ---------------------------------------------------------------------------
create function private.write_audit(
  p_actor uuid,
  p_action text,
  p_entity text,
  p_entity_id uuid,
  p_before jsonb,
  p_after jsonb,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.audit_logs (actor_id, action, entity, entity_id, before, after, reason)
  values (p_actor, p_action, p_entity, p_entity_id, p_before, p_after, p_reason);
end;
$$;

create function private.write_audit(
  p_action text,
  p_entity text,
  p_entity_id uuid,
  p_before jsonb,
  p_after jsonb,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.write_audit(
    (select auth.uid()), p_action, p_entity, p_entity_id, p_before, p_after, p_reason
  );
end;
$$;

revoke execute on function private.write_audit(uuid, text, text, uuid, jsonb, jsonb, text)
  from public, anon, authenticated, service_role;
revoke execute on function private.write_audit(text, text, uuid, jsonb, jsonb, text)
  from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- RLS: admins read. No insert/update/delete policies.
-- ---------------------------------------------------------------------------
create policy audit_logs_select_admin
on public.audit_logs
for select
to authenticated
using ((select private.is_admin()));

-- ---------------------------------------------------------------------------
-- Grants: read only. No API role may write.
-- ---------------------------------------------------------------------------
revoke all on table public.audit_logs from public, anon, authenticated, service_role;

grant select on table public.audit_logs to authenticated, service_role;

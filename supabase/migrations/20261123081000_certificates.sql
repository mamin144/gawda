-- Certificates: one per site and half-month period, with an edit guard.

-- ---------------------------------------------------------------------------
-- Functions created by postgres in schema private are not executable by
-- PUBLIC by default (R14). Must run before any private function below.
-- ---------------------------------------------------------------------------
alter default privileges for role postgres in schema private revoke execute on functions from public;

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------
create table public.certificates (
  id uuid primary key default gen_random_uuid(),
  site_id uuid not null references public.sites (id),
  certificate_date date not null,
  period_year smallint generated always as (extract(year from certificate_date)::smallint) stored,
  period_month smallint generated always as (extract(month from certificate_date)::smallint) stored,
  period_half smallint generated always as (public.period_half(certificate_date)) stored,
  amount numeric(18,2) not null check (amount >= 0),
  notes text,
  status public.certificate_status not null default 'draft',
  return_note text,
  created_by uuid not null default auth.uid() references public.profiles (id),
  submitted_at timestamptz,
  locked_at timestamptz,
  deleted_at timestamptz,
  deleted_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- One live certificate per site and period. A soft-deleted certificate does
-- not block its period (Q13). Its leading column also covers site_id lookups.
create unique index certificates_one_per_period
on public.certificates (site_id, period_year, period_month, period_half)
where deleted_at is null;

create index certificates_status_idx on public.certificates (status);

alter table public.certificates enable row level security;

-- ---------------------------------------------------------------------------
-- Edit guard. Applies to API callers only (authenticated, anon); SECURITY
-- DEFINER RPCs run as their owner and pass.
-- ---------------------------------------------------------------------------
create function private.guard_certificate_update()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if old.status not in ('draft', 'returned') then
      raise exception 'certificate_locked';
    end if;
    if (select private.is_admin()) then
      raise exception 'admin_cannot_edit_values';
    end if;
  end if;
  return new;
end;
$$;

revoke execute on function private.guard_certificate_update() from public, anon, authenticated;

create trigger guard_certificate_update
before update on public.certificates
for each row execute function private.guard_certificate_update();

create trigger set_updated_at
before update on public.certificates
for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS policies (all to authenticated). No delete policy: deletion is a
-- soft delete through a later RPC.
-- ---------------------------------------------------------------------------
create policy certificates_select_with_access
on public.certificates
for select
to authenticated
using (private.has_site_access(site_id) and deleted_at is null);

create policy certificates_insert_with_access
on public.certificates
for insert
to authenticated
with check (private.has_site_access(site_id) and status = 'draft');

-- The admin passes RLS here and is rejected by the guard trigger with an
-- explicit admin_cannot_edit_values error instead of a silent 0-row update.
create policy certificates_update_with_access
on public.certificates
for update
to authenticated
using (private.has_site_access(site_id))
with check (private.has_site_access(site_id));

-- ---------------------------------------------------------------------------
-- Grants: only what the policies allow. Nothing for anon.
-- ---------------------------------------------------------------------------
revoke all on table public.certificates from public, anon, authenticated;

grant select on table public.certificates to authenticated;
grant insert (site_id, certificate_date, amount, notes) on table public.certificates to authenticated;
grant update (certificate_date, amount, notes) on table public.certificates to authenticated;

grant select, insert, update, delete on table public.certificates to service_role;

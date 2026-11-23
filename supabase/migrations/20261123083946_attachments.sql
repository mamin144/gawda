-- Attachments: file metadata for a certificate (the files live in Storage).
-- Clients may only insert; there is no client update or delete. Storage path
-- format: site_id/period_year/period_month/period_half/unique_name, numbers as
-- unpadded integer text (for example '<site uuid>/2026/3/1/<name>').

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------
create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  certificate_id uuid not null references public.certificates (id),
  kind public.attachment_kind not null,
  storage_path text not null unique,
  file_name text not null,
  mime text not null check (mime in ('application/pdf', 'image/jpeg', 'image/png')),
  size_bytes integer not null check (size_bytes between 1 and 2097152),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  uploaded_by uuid not null default auth.uid() references public.profiles (id),
  uploaded_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references public.profiles (id),
  delete_reason text
);

-- Dedup: one active file per content hash across all certificates (Q14 open;
-- implemented as global per the plan). A soft-deleted row does not block.
create unique index attachments_active_sha256
on public.attachments (sha256)
where deleted_at is null;

-- FK lookups and the RLS join to the parent certificate.
create index attachments_certificate_id_idx on public.attachments (certificate_id);

alter table public.attachments enable row level security;

-- ---------------------------------------------------------------------------
-- Path check. Security invoker: it reads the parent certificate under the
-- caller's RLS (the INSERT policy also requires site access). Compares text
-- segments only and returns false, never raises, for malformed input.
-- ---------------------------------------------------------------------------
create function private.attachment_path_matches(p_path text, p_certificate_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce((
    select cardinality(s.seg) = 5
           and s.seg[5] <> ''
           and not (s.seg && array['', '.', '..'])
           and s.seg[1] = c.site_id::text
           and s.seg[2] = c.period_year::text
           and s.seg[3] = c.period_month::text
           and s.seg[4] = c.period_half::text
    from public.certificates c
    cross join (select string_to_array(p_path, '/') as seg) s
    where c.id = p_certificate_id
      and c.deleted_at is null
  ), false)
$$;

-- R14: per-function revoke (PUBLIC execute is not removable by default ACLs;
-- Supabase also grants service_role on new functions).
revoke execute on function private.attachment_path_matches(text, uuid) from public, anon, service_role;
grant execute on function private.attachment_path_matches(text, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RLS policies (all to authenticated). No UPDATE/DELETE policies.
-- The parent certificate is read under the caller's RLS.
-- ---------------------------------------------------------------------------
create policy attachments_select_with_access
on public.attachments
for select
to authenticated
using (
  exists (
    select 1 from public.certificates c
    where c.id = attachments.certificate_id
      and private.has_site_access(c.site_id)
  )
);

-- initial: parent in draft/returned. signed: parent awaiting_signature and the
-- caller is not an admin. The parent must not be soft-deleted.
create policy attachments_insert_with_access
on public.attachments
for insert
to authenticated
with check (
  uploaded_by = (select auth.uid())
  and private.attachment_path_matches(storage_path, certificate_id)
  and exists (
    select 1 from public.certificates c
    where c.id = attachments.certificate_id
      and c.deleted_at is null
      and private.has_site_access(c.site_id)
      and (
        (attachments.kind = 'initial' and c.status in ('draft', 'returned'))
        or (attachments.kind = 'signed' and c.status = 'awaiting_signature'
            and not (select private.is_admin()))
      )
  )
);

-- ---------------------------------------------------------------------------
-- Grants: only what the policies allow. Nothing for anon; no update/delete.
-- ---------------------------------------------------------------------------
revoke all on table public.attachments from public, anon, authenticated, service_role;

grant select on table public.attachments to authenticated;
grant insert (certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256)
on table public.attachments to authenticated;

grant select on table public.attachments to service_role;

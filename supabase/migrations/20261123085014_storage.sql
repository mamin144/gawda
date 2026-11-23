-- Storage: private 'certificates' bucket with per-site isolation.
-- Object path format: site_id/period_year/period_month/period_half/unique_name,
-- numbers as unpadded integer text (for example '<site uuid>/2026/3/1/<name>').
-- Clients may upload and read only; there is no client update (no upsert) or
-- delete. The initial file's object is deleted only by the service role.

-- ---------------------------------------------------------------------------
-- Bucket: private, 2 MB, PDF/JPEG/PNG only.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('certificates', 'certificates', false, 2097152, array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Path parser. Returns the site id (first segment) of a well-formed object
-- path, otherwise null. Never raises: the uuid cast sits in a CASE arm that
-- runs only after a strict regex matched. The function is not inlined (it has
-- a SET clause), so its argument is never a plan-time constant and the cast
-- cannot be constant-folded ahead of the guard.
-- ---------------------------------------------------------------------------
create function private.path_site_id(p_name text)
returns uuid
language sql
immutable
security invoker
set search_path = ''
as $$
  select case
    when cardinality(s.seg) = 5
         and not (s.seg && array['', '.', '..'])
         and s.seg[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
         and s.seg[2] ~ '^[0-9]{4}$'
         and s.seg[3] ~ '^([1-9]|1[0-2])$'
         and s.seg[4] ~ '^[12]$'
    then s.seg[1]::uuid
  end
  from (select string_to_array(p_name, '/') as seg) s
$$;

-- R14: per-function revoke (PUBLIC execute is not removable by default ACLs;
-- Supabase also grants service_role on new functions).
revoke execute on function private.path_site_id(text) from public, anon, service_role;
grant execute on function private.path_site_id(text) to authenticated;

-- ---------------------------------------------------------------------------
-- storage.objects policies for the certificates bucket (to authenticated).
-- has_site_access(null) is true for an admin, so a malformed path (null site
-- id) is rejected explicitly before the access check.
-- No UPDATE or DELETE policies.
-- ---------------------------------------------------------------------------
create policy certificates_objects_select
on storage.objects
for select
to authenticated
using (
  bucket_id = 'certificates'
  and private.path_site_id(name) is not null
  and private.has_site_access(private.path_site_id(name))
);

create policy certificates_objects_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'certificates'
  and private.path_site_id(name) is not null
  and private.has_site_access(private.path_site_id(name))
);

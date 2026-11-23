begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(51);

-- Local helpers (rolled back with the test).
-- t7.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t7;
create function t7.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t7.' || name)::uuid $$;

-- t7.path(site, file): '<site uuid>/2025/3/1/<file>' (unpadded numbers).
create function t7.path(site text, file text)
returns text
language sql
stable
as $$ select t7.id(site)::text || '/2025/3/1/' || file $$;

-- t7.ins(bucket, name): the client INSERT statement for one storage object.
create function t7.ins(p_bucket text, p_name text)
returns text
language sql
stable
as $$
  select format(
    'insert into storage.objects (bucket_id, name, owner_id) values (%L, %L, %L)',
    p_bucket, p_name, nullif(current_setting('request.jwt.claims', true), '')::json ->> 'sub'
  )
$$;

-- t7.objects_deleted(name): deletes one certificates object as the current
-- role and returns the number of rows deleted (security invoker, so RLS applies).
create function t7.objects_deleted(p_name text)
returns integer
language plpgsql
as $$
declare
  n integer;
begin
  delete from storage.objects where bucket_id = 'certificates' and name = p_name;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- t7.objects_updated(name): same for an update of the metadata column.
create function t7.objects_updated(p_name text)
returns integer
language plpgsql
as $$
declare
  n integer;
begin
  update storage.objects set metadata = '{"t7": true}'::jsonb
  where bucket_id = 'certificates' and name = p_name;
  get diagnostics n = row_count;
  return n;
end;
$$;

grant usage on schema t7 to anon, authenticated;
grant execute on all functions in schema t7 to anon, authenticated;

-- Fixtures (created as the session role, which bypasses RLS).
select set_config('t7.admin', tests.create_user('t7-admin@example.test', 'admin')::text, true);
select set_config('t7.s1', tests.create_user('t7-s1@example.test', 'site_user')::text, true);
select set_config('t7.s2', tests.create_user('t7-s2@example.test', 'site_user')::text, true);
select set_config('t7.inactive_su', tests.create_user('t7-is@example.test', 'site_user', false)::text, true);
select set_config('t7.' || n, gen_random_uuid()::text, true)
from unnest(array['site1', 'site2']) as n;

insert into public.sites (id, code, name) values
  (t7.id('site1'), 't7-site-1', 'T7 Site 1'),
  (t7.id('site2'), 't7-site-2', 'T7 Site 2');
insert into public.user_sites (user_id, site_id) values
  (t7.id('s1'), t7.id('site1')),
  (t7.id('s2'), t7.id('site2')),
  (t7.id('inactive_su'), t7.id('site1'));

-- A second bucket (rolled back) to prove the policies are scoped to 'certificates'.
insert into storage.buckets (id, name, public) values ('t7-other', 't7-other', false);

-- Objects that exist before the role checks: one per site, and one at a
-- malformed path (first segment is not a uuid).
insert into storage.objects (bucket_id, name) values
  ('certificates', t7.path('site2', 'site2.pdf')),
  ('certificates', 'not-a-uuid/2025/1/1/fixture.pdf');

-- 1-7: bucket, function and policy structure.
select is(
  (select public from storage.buckets where id = 'certificates'),
  false,
  'the certificates bucket exists and is not public'
);
select is(
  (select file_size_limit from storage.buckets where id = 'certificates'),
  2097152::bigint,
  'the certificates bucket limits files to 2097152 bytes'
);
select set_eq(
  $$select unnest(allowed_mime_types) from storage.buckets where id = 'certificates'$$,
  array['application/pdf', 'image/jpeg', 'image/png'],
  'the certificates bucket allows exactly pdf, jpeg and png'
);
select ok(
  (select not prosecdef
          and provolatile = 'i'
          and proconfig = array['search_path=""']
          and prolang = (select oid from pg_language where lanname = 'sql')
          and prorettype = 'uuid'::regtype
   from pg_proc where oid = 'private.path_site_id(text)'::regprocedure),
  'path_site_id is an immutable security invoker sql function with an empty search_path'
);
select ok(
  has_function_privilege('authenticated', 'private.path_site_id(text)', 'execute')
  and not has_function_privilege('anon', 'private.path_site_id(text)', 'execute')
  and not has_function_privilege('service_role', 'private.path_site_id(text)', 'execute')
  and not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid = 'private.path_site_id(text)'::regprocedure
      and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'path_site_id is executable by authenticated only (not public, anon, service_role)'
);
select results_eq(
  $$select policyname::text collate "default", cmd::text, roles::text collate "default" from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname like 'certificates%'
    order by policyname$$,
  $$values ('certificates_objects_insert', 'INSERT', '{authenticated}'),
           ('certificates_objects_select', 'SELECT', '{authenticated}')$$,
  'storage.objects has exactly the certificates SELECT and INSERT policies, to authenticated'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'storage.objects'::regclass),
  'RLS is still enabled on storage.objects'
);

-- 8-25: path_site_id, called as site user s1.
select tests.act_as(t7.id('s1'));
select is(private.path_site_id(t7.path('site1', 'x.pdf')), t7.id('site1'), 'path_site_id: a valid path returns the site id');
select is(private.path_site_id(upper(t7.id('site1')::text) || '/2025/12/2/x.pdf'), t7.id('site1'), 'path_site_id: upper-case uuid, month 12, half 2 is valid');
select is(private.path_site_id('not-a-uuid/2025/1/1/x.pdf'), null::uuid, 'path_site_id: non-uuid first segment is null (no error)');
select is(private.path_site_id(t7.id('site1')::text || 'z/2025/1/1/x.pdf'), null::uuid, 'path_site_id: uuid with a trailing character is null');
select is(private.path_site_id(t7.id('site1')::text || '/../x'), null::uuid, 'path_site_id: ''<uuid>/../x'' is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/1/../x.pdf'), null::uuid, 'path_site_id: a ''..'' segment is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/1/1/..'), null::uuid, 'path_site_id: a ''..'' last segment is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/1/1/.'), null::uuid, 'path_site_id: a ''.'' last segment is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/1/1'), null::uuid, 'path_site_id: 4 segments is null');
select is(private.path_site_id(t7.path('site1', 'a/x.pdf')), null::uuid, 'path_site_id: 6 segments is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/1/1/'), null::uuid, 'path_site_id: empty last segment is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/03/1/x.pdf'), null::uuid, 'path_site_id: padded month ''03'' is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/13/1/x.pdf'), null::uuid, 'path_site_id: month 13 is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/0/1/x.pdf'), null::uuid, 'path_site_id: month 0 is null');
select is(private.path_site_id(t7.id('site1')::text || '/2025/1/3/x.pdf'), null::uuid, 'path_site_id: half 3 is null');
select is(private.path_site_id(t7.id('site1')::text || '/225/1/1/x.pdf'), null::uuid, 'path_site_id: a 3-digit year is null');
select is(private.path_site_id(null), null::uuid, 'path_site_id: NULL is null');
select is(private.path_site_id(''), null::uuid, 'path_site_id: empty string is null');
select tests.reset_role();

-- 26-38: site user s1 (mapped to site1).
select tests.act_as(t7.id('s1'));
select lives_ok(t7.ins('certificates', t7.path('site1', 'own.pdf')), 'site user uploads under their own site''s path');
select isnt_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site1', 'own.pdf')),
  'site user sees their own site''s object'
);
select is_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site2', 'site2.pdf')),
  'site user cannot see another site''s object'
);
select throws_ok(t7.ins('certificates', t7.path('site2', 'cross.pdf')), '42501', null, 'site user upload under another site''s path is denied');
select throws_ok(t7.ins('certificates', 'not-a-uuid/2025/1/1/x.pdf'), '42501', null, 'upload at a non-uuid path is denied without another error');
select throws_ok(t7.ins('certificates', t7.id('site1')::text || '/../x'), '42501', null, 'upload at ''<uuid>/../x'' is denied');
select throws_ok(t7.ins('certificates', t7.id('site1')::text || '/2025/03/1/x.pdf'), '42501', null, 'upload at a padded-month path is denied');
select throws_ok(t7.ins('t7-other', t7.path('site1', 'other.pdf')), '42501', null, 'upload to another bucket is not allowed by the certificates policies');
select is(t7.objects_updated(t7.path('site1', 'own.pdf')), 0, 'site user update of their own object affects 0 rows (no UPDATE policy)');
-- Direct DELETE on storage.objects is blocked by storage.protect_delete (a
-- statement-level BEFORE DELETE trigger) unless storage.allow_delete_query is 'true'.
select throws_ok(
  format('delete from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site1', 'own.pdf')),
  '42501',
  'Direct deletion from storage tables is not allowed. Use the Storage API instead.',
  'direct delete as authenticated raises 42501 (storage.protect_delete)'
);
-- With the trigger bypass on, RLS alone decides: no DELETE policy, 0 rows.
select set_config('storage.allow_delete_query', 'true', true);
select is(t7.objects_deleted(t7.path('site1', 'own.pdf')), 0, 'site user delete of their own object affects 0 rows (no DELETE policy)');
select set_config('storage.allow_delete_query', '', true);
select tests.reset_role();
select isnt_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site1', 'own.pdf')),
  'the object still exists after the delete attempts'
);
select is_empty(
  format('select 1 from storage.objects where bucket_id = %L and metadata ? %L', 'certificates', 't7'),
  'no object was changed by the update attempt'
);

-- 39-40: site user s2 (mapped to site2).
select tests.act_as(t7.id('s2'));
select isnt_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site2', 'site2.pdf')),
  'precondition: site2 user sees its own site''s object'
);
select is_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site1', 'own.pdf')),
  'site2 user cannot see a site1 object'
);
select tests.reset_role();

-- 41-45: admin. has_site_access returns true for an admin on any argument,
-- including NULL, so the policies must reject a malformed path first.
select tests.act_as(t7.id('admin'));
select isnt_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site2', 'site2.pdf')),
  'admin sees objects of any site'
);
select is_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', 'not-a-uuid/2025/1/1/fixture.pdf'),
  'admin cannot see an object at a malformed path'
);
-- Current behavior; admin upload of initial files is an open owner question.
select lives_ok(t7.ins('certificates', t7.path('site1', 'admin.pdf')), 'admin uploads under a valid site path (current behavior)');
select throws_ok(t7.ins('certificates', 'not-a-uuid/2025/1/1/x.pdf'), '42501', null, 'admin upload at a malformed path is denied');
select throws_ok(t7.ins('certificates', t7.id('site1')::text || '/../x'), '42501', null, 'admin upload at ''<uuid>/../x'' is denied');
select tests.reset_role();

-- 46-47: inactive site user (still mapped to site1).
select tests.act_as(t7.id('inactive_su'));
select throws_ok(t7.ins('certificates', t7.path('site1', 'inactive.pdf')), '42501', null, 'inactive site user upload is denied');
select is_empty(
  format('select 1 from storage.objects where bucket_id = %L and name = %L', 'certificates', t7.path('site1', 'own.pdf')),
  'inactive site user cannot see their site''s object'
);
select tests.reset_role();

-- 48-49: anon (has table grants on storage.objects but no policy).
set local role anon;
select is_empty(
  $$select 1 from storage.objects where bucket_id = 'certificates'$$,
  'anon sees no certificates objects'
);
select throws_ok(t7.ins('certificates', 'x/2025/1/1/anon.pdf'), '42501', null, 'anon upload is denied');
reset role;

-- 50-51: the policies only cover the certificates bucket and its objects.
select is(
  (select count(*) from storage.objects where bucket_id = 'certificates' and name like '%/2025/3/1/%'),
  3::bigint,
  'exactly the three valid-path objects exist (site2 fixture, s1 upload, admin upload)'
);
select is(
  (select count(*) from storage.objects where bucket_id = 't7-other'),
  0::bigint,
  'no object was written to the other bucket'
);

select * from finish();
rollback;

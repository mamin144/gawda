begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(47);

-- Local helpers (rolled back with the test).
-- t6.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t6;
create function t6.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t6.' || name)::uuid $$;

-- t6.path(prefix, file): storage path '<prefix>/<file>', where the prefix
-- (site_id/period_year/period_month/period_half) is stored in a setting.
create function t6.path(prefix text, file text)
returns text
language sql
stable
as $$ select current_setting('t6.p_' || prefix) || '/' || file $$;

-- t6.sha(n): a valid lowercase 64-hex-digit sha256 built from n.
create function t6.sha(n integer)
returns text
language sql
immutable
as $$ select lpad(to_hex(n), 64, '0') $$;

-- t6.ins(...): the client INSERT statement for one attachment.
create function t6.ins(
  p_cert uuid,
  p_kind text,
  p_path text,
  p_sha text,
  p_mime text default 'application/pdf',
  p_size integer default 1000
)
returns text
language sql
stable
as $$
  select format(
    'insert into public.attachments (certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256) values (%L, %L, %L, %L, %L, %s, %L)',
    p_cert, p_kind, p_path, 'file.pdf', p_mime, p_size, p_sha
  )
$$;

grant usage on schema t6 to anon, authenticated;
grant execute on all functions in schema t6 to anon, authenticated;

-- Fixtures (created as the session role, which bypasses RLS).
select set_config('t6.admin', tests.create_user('t6-admin@example.test', 'admin')::text, true);
select set_config('t6.s1', tests.create_user('t6-s1@example.test', 'site_user')::text, true);
select set_config('t6.s2', tests.create_user('t6-s2@example.test', 'site_user')::text, true);
select set_config('t6.inactive_su', tests.create_user('t6-is@example.test', 'site_user', false)::text, true);

select set_config('t6.' || n, gen_random_uuid()::text, true)
from unnest(array[
  'site1', 'site2', 'random',
  'c_draft', 'c_returned', 'c_review', 'c_await', 'c_deleted', 'c_site2', 'a_site2'
]) as n;

insert into public.sites (id, code, name) values
  (t6.id('site1'), 't6-site-1', 'T6 Site 1'),
  (t6.id('site2'), 't6-site-2', 'T6 Site 2');
insert into public.user_sites (user_id, site_id) values
  (t6.id('s1'), t6.id('site1')),
  (t6.id('s2'), t6.id('site2')),
  (t6.id('inactive_su'), t6.id('site1'));

insert into public.certificates
  (id, site_id, certificate_date, amount, status, created_by, deleted_at, deleted_by) values
  (t6.id('c_draft'),    t6.id('site1'), '2026-01-10', 100, 'draft',              t6.id('s1'), null,  null),
  (t6.id('c_returned'), t6.id('site1'), '2026-01-20', 110, 'returned',           t6.id('s1'), null,  null),
  (t6.id('c_review'),   t6.id('site1'), '2026-02-10', 120, 'in_review',          t6.id('s1'), null,  null),
  (t6.id('c_await'),    t6.id('site1'), '2026-02-20', 130, 'awaiting_signature', t6.id('s1'), null,  null),
  (t6.id('c_deleted'),  t6.id('site1'), '2026-03-05', 140, 'draft',              t6.id('s1'), now(), t6.id('s1')),
  (t6.id('c_site2'),    t6.id('site2'), '2026-01-10', 150, 'draft',              t6.id('s2'), null,  null);

-- Path prefixes: site_id/period_year/period_month/period_half, unpadded.
select set_config('t6.p_draft',    t6.id('site1')::text || '/2026/1/1', true);
select set_config('t6.p_returned', t6.id('site1')::text || '/2026/1/2', true);
select set_config('t6.p_review',   t6.id('site1')::text || '/2026/2/1', true);
select set_config('t6.p_await',    t6.id('site1')::text || '/2026/2/2', true);
select set_config('t6.p_deleted',  t6.id('site1')::text || '/2026/3/1', true);
select set_config('t6.p_site2',    t6.id('site2')::text || '/2026/1/1', true);

-- One existing site2 attachment (for the cross-site select checks).
insert into public.attachments (id, certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256, uploaded_by)
values (t6.id('a_site2'), t6.id('c_site2'), 'initial', t6.path('site2', 'site2.pdf'), 'site2.pdf', 'application/pdf', 500, t6.sha(900), t6.id('s2'));

-- 1-8: structure and privileges.
select ok((select relrowsecurity from pg_class where oid = 'public.attachments'::regclass), 'RLS enabled on attachments');
select ok(
  (select i.indisunique and i.indpred is not null and i.indkey::text = (
            select attnum::text from pg_attribute
            where attrelid = 'public.attachments'::regclass and attname = 'sha256')
   from pg_index i where i.indexrelid = 'public.attachments_active_sha256'::regclass),
  'attachments_active_sha256 is a unique partial index on sha256'
);
select has_index('public', 'attachments', 'attachments_certificate_id_idx', 'certificate_id'::name, 'attachments has an index on certificate_id');
select ok(
  (select not prosecdef
          and provolatile = 's'
          and proconfig = array['search_path=""']
          and prolang = (select oid from pg_language where lanname = 'sql')
          and prorettype = 'boolean'::regtype
   from pg_proc where oid = 'private.attachment_path_matches(text,uuid)'::regprocedure),
  'attachment_path_matches is a stable security invoker sql function with an empty search_path'
);
select ok(
  has_function_privilege('authenticated', 'private.attachment_path_matches(text,uuid)', 'execute')
  and not has_function_privilege('anon', 'private.attachment_path_matches(text,uuid)', 'execute')
  and not has_function_privilege('service_role', 'private.attachment_path_matches(text,uuid)', 'execute')
  and not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid = 'private.attachment_path_matches(text,uuid)'::regprocedure
      and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'attachment_path_matches is executable by authenticated only (not public, anon, service_role)'
);
select ok(
  not has_table_privilege('anon', 'public.attachments', 'select,insert,update,delete,truncate,references,trigger')
  and not has_table_privilege('authenticated', 'public.attachments', 'update,delete,truncate,references,trigger')
  and has_table_privilege('authenticated', 'public.attachments', 'select')
  and has_table_privilege('service_role', 'public.attachments', 'select')
  and not has_table_privilege('service_role', 'public.attachments', 'insert,update,delete,truncate,references,trigger'),
  'table privileges: anon none; authenticated select (+column insert); service_role select only'
);
select ok(
  has_column_privilege('authenticated', 'public.attachments', 'certificate_id', 'insert')
  and has_column_privilege('authenticated', 'public.attachments', 'kind', 'insert')
  and has_column_privilege('authenticated', 'public.attachments', 'storage_path', 'insert')
  and has_column_privilege('authenticated', 'public.attachments', 'file_name', 'insert')
  and has_column_privilege('authenticated', 'public.attachments', 'mime', 'insert')
  and has_column_privilege('authenticated', 'public.attachments', 'size_bytes', 'insert')
  and has_column_privilege('authenticated', 'public.attachments', 'sha256', 'insert')
  and not has_column_privilege('authenticated', 'public.attachments', 'id', 'insert')
  and not has_column_privilege('authenticated', 'public.attachments', 'uploaded_by', 'insert')
  and not has_column_privilege('authenticated', 'public.attachments', 'uploaded_at', 'insert')
  and not has_column_privilege('authenticated', 'public.attachments', 'deleted_at', 'insert')
  and not has_column_privilege('authenticated', 'public.attachments', 'deleted_by', 'insert')
  and not has_column_privilege('authenticated', 'public.attachments', 'delete_reason', 'insert'),
  'authenticated may insert only the seven client columns'
);
select is_empty(
  $$select policyname from pg_policies
    where schemaname = 'public' and tablename = 'attachments'
      and (cmd not in ('SELECT', 'INSERT') or roles <> array['authenticated']::name[])$$,
  'attachments has only SELECT/INSERT policies, all to authenticated'
);

-- 9-18: attachment_path_matches, called as site user s1.
select tests.act_as(t6.id('s1'));
select is(private.attachment_path_matches(t6.path('draft', 'a.pdf'), t6.id('c_draft')), true, 'path_matches: correct path is true');
select is(private.attachment_path_matches('not-a-uuid/2026/1/1/a.pdf', t6.id('c_draft')), false, 'path_matches: non-uuid first segment is false (no error)');
select is(private.attachment_path_matches(t6.id('site1')::text || '/2026/1/1', t6.id('c_draft')), false, 'path_matches: 4 segments is false');
select is(private.attachment_path_matches(t6.path('draft', 'x/a.pdf'), t6.id('c_draft')), false, 'path_matches: 6 segments is false');
select is(private.attachment_path_matches(t6.path('draft', '..'), t6.id('c_draft')), false, 'path_matches: a ''..'' segment is false');
select is(private.attachment_path_matches(t6.path('draft', ''), t6.id('c_draft')), false, 'path_matches: empty last segment is false');
select is(private.attachment_path_matches(t6.id('site1')::text || '/2026/01/1/a.pdf', t6.id('c_draft')), false, 'path_matches: padded month ''01'' is false');
select is(private.attachment_path_matches(t6.path('returned', 'a.pdf'), t6.id('c_draft')), false, 'path_matches: another period is false');
select is(private.attachment_path_matches(null, t6.id('c_draft')), false, 'path_matches: NULL path is false');
select is(private.attachment_path_matches(t6.path('draft', 'a.pdf'), t6.id('random')), false, 'path_matches: missing certificate is false');
select tests.reset_role();

-- 19: soft-deleted certificate, as the session role (no RLS), so the
-- function's own deleted_at filter is what is tested.
select is(private.attachment_path_matches(t6.path('deleted', 'a.pdf'), t6.id('c_deleted')), false, 'path_matches: soft-deleted certificate is false');

-- 20-39: site user s1 (mapped to site1).
select tests.act_as(t6.id('s1'));
select lives_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'one.pdf'), t6.sha(1)), 'site user inserts an initial attachment on a draft');
select is(
  (select array[uploaded_by::text, (uploaded_at = now())::text, (deleted_at is null)::text]
   from public.attachments where storage_path = t6.path('draft', 'one.pdf')),
  array[t6.id('s1')::text, 'true', 'true'],
  'uploaded_by defaults to the caller, uploaded_at to now(), deleted_at is null'
);
select lives_ok(t6.ins(t6.id('c_returned'), 'initial', t6.path('returned', 'two.pdf'), t6.sha(2)), 'site user inserts an initial attachment on a returned certificate');
select lives_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'img.png'), t6.sha(3), 'image/png', 2097152), 'png of exactly 2097152 bytes is accepted');
select throws_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'bad.gif'), t6.sha(4), 'image/gif'), '23514', null, 'wrong mime is rejected');
select throws_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'big.pdf'), t6.sha(5), 'application/pdf', 2097153), '23514', null, '2097153 bytes is rejected');
select throws_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'zero.pdf'), t6.sha(6), 'application/pdf', 0), '23514', null, '0 bytes is rejected');
select throws_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'sha.pdf'), upper(t6.sha(7)) || 'Z'), '23514', null, 'a bad sha256 is rejected');
select throws_ok(t6.ins(t6.id('c_returned'), 'initial', t6.path('returned', 'dup.pdf'), t6.sha(1)), '23505', null, 'the same active sha256 on another certificate is rejected');
select throws_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'one.pdf'), t6.sha(8)), '23505', null, 'a duplicate storage_path is rejected');
select throws_ok(t6.ins(t6.id('c_draft'), 'signed', t6.path('draft', 'signed.pdf'), t6.sha(9)), '42501', null, 'site user inserting signed while draft is denied');
select throws_ok(t6.ins(t6.id('c_review'), 'initial', t6.path('review', 'r.pdf'), t6.sha(10)), '42501', null, 'inserting initial while in_review is denied');
select throws_ok(t6.ins(t6.id('c_await'), 'initial', t6.path('await', 'i.pdf'), t6.sha(11)), '42501', null, 'inserting initial while awaiting_signature is denied');
select lives_ok(t6.ins(t6.id('c_await'), 'signed', t6.path('await', 'signed.pdf'), t6.sha(12)), 'site user inserts signed while awaiting_signature');
select throws_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('returned', 'p.pdf'), t6.sha(13)), '42501', null, 'a path whose period does not match the certificate is denied');
select throws_ok(t6.ins(t6.id('c_site2'), 'initial', t6.path('site2', 'x.pdf'), t6.sha(14)), '42501', null, 'cross-site insert is denied');
select throws_ok(t6.ins(t6.id('c_deleted'), 'initial', t6.path('deleted', 'd.pdf'), t6.sha(15)), '42501', null, 'inserting initial on a soft-deleted draft is denied');
select throws_ok(
  format('update public.attachments set file_name = %L where storage_path = %L', 'x.pdf', t6.path('draft', 'one.pdf')),
  '42501', null, 'update is denied'
);
select throws_ok(
  format('delete from public.attachments where storage_path = %L', t6.path('draft', 'one.pdf')),
  '42501', null, 'delete is denied'
);
select is_empty(
  format('select 1 from public.attachments where id = %L', t6.id('a_site2')),
  'site user cannot select another site''s attachment'
);
select tests.reset_role();

-- 40-41: site user s2 (mapped to site2).
select tests.act_as(t6.id('s2'));
select isnt_empty(
  format('select 1 from public.attachments where id = %L', t6.id('a_site2')),
  'precondition: site2 user sees its own site''s attachment'
);
select is_empty(
  format('select 1 from public.attachments where storage_path = %L', t6.path('draft', 'one.pdf')),
  'site2 user cannot select a site1 attachment'
);
select tests.reset_role();

-- 42-43: admin.
select tests.act_as(t6.id('admin'));
select throws_ok(t6.ins(t6.id('c_await'), 'signed', t6.path('await', 'admin.pdf'), t6.sha(16)), '42501', null, 'admin inserting signed is denied');
select isnt_empty(format('select 1 from public.attachments where id = %L', t6.id('a_site2')), 'admin sees attachments of any site');
select tests.reset_role();

-- 44: inactive site user (still mapped to site1).
select tests.act_as(t6.id('inactive_su'));
select throws_ok(t6.ins(t6.id('c_draft'), 'initial', t6.path('draft', 'inactive.pdf'), t6.sha(17)), '42501', null, 'inactive site user insert is denied');
select tests.reset_role();

-- 45: anon. anon has no usage on schema tests, so return with a plain reset role.
set local role anon;
select throws_ok('select 1 from public.attachments', '42501', null, 'anon cannot select attachments');
reset role;

-- 46-47: dedup is for active rows only. Soft-delete the sha(1) row as the
-- session role, then the same sha256 is accepted on another certificate.
update public.attachments set deleted_at = now(), deleted_by = t6.id('s1')
where storage_path = t6.path('draft', 'one.pdf');
select is(
  (select count(*) from public.attachments where sha256 = t6.sha(1) and deleted_at is not null),
  1::bigint,
  'precondition: the sha(1) attachment is soft-deleted'
);
select tests.act_as(t6.id('s1'));
select lives_ok(t6.ins(t6.id('c_returned'), 'initial', t6.path('returned', 'again.pdf'), t6.sha(1)), 'a soft-deleted attachment does not block its sha256');
select tests.reset_role();

select * from finish();
rollback;

begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(27);

-- Local helpers (rolled back with the test).
create schema t11;
create function t11.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t11.' || name)::uuid $$;

-- Audit rows for an entity and action. Call as the session role only.
create function t11.audit_count(p_action text, p_entity_id uuid)
returns bigint
language sql
stable
as $$
  select count(*) from public.audit_logs
  where action = p_action and entity_id = p_entity_id
$$;

grant usage on schema t11 to anon, authenticated, service_role;
grant execute on function t11.id(text) to anon, authenticated, service_role;

-- Fixtures (session role: bypasses RLS, audit triggers write nothing).
select set_config('t11.admin', tests.create_user('t11-admin@example.test', 'admin')::text, true);
select set_config('t11.admin2', tests.create_user('t11-admin2@example.test', 'admin')::text, true);
select set_config('t11.su', tests.create_user('t11-su@example.test', 'site_user')::text, true);
select set_config('t11.su2', tests.create_user('t11-su2@example.test', 'site_user')::text, true);
select set_config('t11.supro', tests.create_user('t11-supro@example.test', 'site_user')::text, true);
select set_config('t11.' || n, gen_random_uuid()::text, true)
from unnest(array['site1', 'site2', 'sarch', 'delsite', 'c_draft', 'c_sub', 'c_del',
                  'a_draft', 'a_sub', 'random']) as n;

insert into public.sites (id, code, name) values
  (t11.id('site1'), 't11-site-1', 'T11 Site 1'),
  (t11.id('site2'), 't11-site-2', 'T11 Site 2'),
  (t11.id('sarch'), 't11-arch', 'T11 Archive Me'),
  (t11.id('delsite'), 't11-del', 'T11 Deleted Cert Site');
insert into public.user_sites (user_id, site_id) values
  (t11.id('su'), t11.id('site1')),
  (t11.id('supro'), t11.id('site1'));
insert into public.certificates (id, site_id, certificate_date, amount, created_by, status, deleted_at) values
  (t11.id('c_draft'), t11.id('site1'), '2026-04-05', 1, t11.id('su'), 'draft', null),
  (t11.id('c_sub'), t11.id('site1'), '2026-04-20', 1, t11.id('su'), 'in_review', null),
  (t11.id('c_del'), t11.id('delsite'), '2026-04-05', 1, t11.id('su'), 'draft', now());
insert into public.attachments (id, certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256, uploaded_by) values
  (t11.id('a_draft'), t11.id('c_draft'), 'initial',
   t11.id('site1') || '/2026/4/1/a.pdf', 'a.pdf', 'application/pdf', 10, repeat('a', 64), t11.id('su')),
  (t11.id('a_sub'), t11.id('c_sub'), 'initial',
   t11.id('site1') || '/2026/4/2/b.pdf', 'b.pdf', 'application/pdf', 10, repeat('b', 64), t11.id('su'));
update auth.users set email_confirmed_at = now() where id = t11.id('su2');

-- 1-2: user_sites only links site users (P3 review).
select tests.act_as(t11.id('admin'));
select throws_ok(
  format('insert into public.user_sites (user_id, site_id) values (%L, %L)', t11.id('admin2'), t11.id('site1')),
  'P0001', 'invalid_target', 'a site cannot be linked to an admin profile'
);
select lives_ok(
  format('insert into public.user_sites (user_id, site_id) values (%L, %L)', t11.id('su2'), t11.id('site2')),
  'a site can be linked to a site user'
);

-- 3-4: a site user with linked sites cannot become admin (has_sites).
select throws_ok(
  format('update public.profiles set role = %L where id = %L', 'admin', t11.id('supro')),
  'P0001', 'has_sites', 'a site user with linked sites cannot be promoted'
);
select lives_ok(
  format($q$delete from public.user_sites where user_id = %L;
           update public.profiles set role = 'admin' where id = %L$q$, t11.id('supro'), t11.id('supro')),
  'after removing the links the promotion succeeds'
);

-- 5-8: no-op updates write no audit row (R4).
update public.sites set name = name where id = t11.id('site2');
update public.profiles set full_name = full_name where id = t11.id('su2');
select tests.reset_role();
select is(t11.audit_count('site_updated', t11.id('site2')), 0::bigint, 'a no-op site update writes no audit row');
select is(t11.audit_count('profile_updated', t11.id('su2')), 0::bigint, 'a no-op profile update writes no audit row');
select tests.act_as(t11.id('admin'));
update public.sites set name = 'T11 Site 2 renamed' where id = t11.id('site2');
update public.profiles set full_name = 'T11 SU2 renamed' where id = t11.id('su2');
select tests.reset_role();
select is(t11.audit_count('site_updated', t11.id('site2')), 1::bigint, 'a real site update writes one audit row');
select is(t11.audit_count('profile_updated', t11.id('su2')), 1::bigint, 'a real profile update writes one audit row');

-- 9-14: archived_at is derived by the server (R3).
select tests.act_as(t11.id('admin'));
select lives_ok(
  format('update public.sites set is_active = false where id = %L', t11.id('sarch')),
  'an admin archives a site through the client role'
);
select ok(
  (select archived_at is not null from public.sites where id = t11.id('sarch')),
  'archiving sets archived_at'
);
select set_config('t11.arch_at', (select archived_at::text from public.sites where id = t11.id('sarch')), true);
update public.sites set name = 'T11 Archived renamed', archived_at = '2000-01-01'
where id = t11.id('sarch');
select is(
  (select archived_at::text from public.sites where id = t11.id('sarch')),
  current_setting('t11.arch_at'),
  'editing an archived site keeps its archived_at and ignores the client value'
);
select lives_ok(
  format('update public.sites set is_active = true, archived_at = now() where id = %L', t11.id('sarch')),
  'restoring with a client archived_at is accepted'
);
select ok(
  (select archived_at is null from public.sites where id = t11.id('sarch')),
  'restoring clears archived_at (client value ignored)'
);
select lives_ok(
  format('insert into public.sites (code, name, is_active, archived_at) values (%L, %L, false, null)', 't11-new-arch', 'T11 New Archived'),
  'inserting an inactive site without archived_at is accepted'
);

-- 15: admin_list_users reports a confirmed user as not pending (P2 test gap).
select is(
  (select invite_pending from public.admin_list_users() where id = t11.id('su2')),
  false, 'a confirmed user is not invite_pending'
);

-- 16: a soft-deleted certificate still locks the site code (P2 test gap).
select throws_ok(
  format('update public.sites set code = %L where id = %L', 't11-del-2', t11.id('delsite')),
  'P0001', 'code_locked', 'a soft-deleted certificate still locks the site code'
);
select tests.reset_role();

-- 17-25: remove_attachment (R1).
select tests.act_as(t11.id('su2'));
select throws_ok(
  format('select public.remove_attachment(%L)', t11.id('a_draft')),
  'P0001', 'forbidden', 'a user of another site cannot remove the attachment'
);
select tests.reset_role();
select tests.act_as(t11.id('su'));
select throws_ok(
  format('select public.remove_attachment(%L)', t11.id('a_sub')),
  'P0001', 'invalid_transition', 'an attachment of an in_review certificate cannot be removed'
);
select lives_ok(
  format('select public.remove_attachment(%L, %L)', t11.id('a_draft'), 'wrong file'),
  'the site user removes an attachment of a draft certificate'
);
select throws_ok(
  format('select public.remove_attachment(%L)', t11.id('a_draft')),
  'P0001', 'already_deleted', 'removing twice is rejected'
);
select throws_ok(
  format('select public.remove_attachment(%L)', t11.id('random')),
  'P0001', 'not_found', 'an unknown attachment is not_found'
);
select tests.reset_role();
select ok(
  (select deleted_at is not null and deleted_by = t11.id('su') and delete_reason = 'wrong file'
   from public.attachments where id = t11.id('a_draft')),
  'remove_attachment soft-deletes with deleted_by and the reason'
);
select is(t11.audit_count('remove_attachment', t11.id('a_draft')), 1::bigint, 'remove_attachment writes one audit row');
select lives_ok(
  format($q$insert into public.attachments (certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256, uploaded_by)
           values (%L, 'initial', %L, 'a2.pdf', 'application/pdf', 10, %L, %L)$q$,
         t11.id('c_draft'), t11.id('site1') || '/2026/4/1/a2.pdf', repeat('a', 64), t11.id('su')),
  'the same file can be attached again after removal'
);
-- anon has no usage on schema tests, so return with a plain reset role.
set local role anon;
select throws_ok(
  format('select public.remove_attachment(%L)', t11.id('a_sub')),
  '42501', null, 'anon cannot execute public.remove_attachment'
);
reset role;

-- 26-27: structure and privileges of remove_attachment.
select ok(
  (select bool_and(proconfig = array['search_path=""']
                   and prosecdef = (pronamespace = 'private'::regnamespace))
          and count(*) = 2
   from pg_proc
   where oid in ('public.remove_attachment(uuid,text)'::regprocedure,
                 'private.remove_attachment(uuid,text)'::regprocedure)),
  'remove_attachment body is security definer in private, the public wrapper is invoker; empty search_path'
);
select ok(
  has_function_privilege('authenticated', 'public.remove_attachment(uuid,text)', 'execute')
  and has_function_privilege('authenticated', 'private.remove_attachment(uuid,text)', 'execute')
  and not exists (
    select 1
    from pg_proc p
    cross join (values ('anon'), ('service_role')) as r (rolname)
    where p.oid in ('public.remove_attachment(uuid,text)'::regprocedure,
                    'private.remove_attachment(uuid,text)'::regprocedure)
      and has_function_privilege(r.rolname, p.oid, 'execute'))
  and not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid in ('public.remove_attachment(uuid,text)'::regprocedure,
                    'private.remove_attachment(uuid,text)'::regprocedure)
      and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'remove_attachment (both layers) is executable by authenticated only'
);

select * from finish();
rollback;

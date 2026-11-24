begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(40);

-- Local helpers (rolled back with the test).
-- t10.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t10;
create function t10.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t10.' || name)::uuid $$;

-- Audit rows for an entity and action. Call as the session role only.
create function t10.audit_count(p_action text, p_entity_id uuid)
returns bigint
language sql
stable
as $$
  select count(*) from public.audit_logs
  where action = p_action and entity_id = p_entity_id
$$;

grant usage on schema t10 to anon, authenticated, service_role;
grant execute on function t10.id(text) to anon, authenticated, service_role;

-- Fixtures (created as the session role, which bypasses RLS; auth.uid() is
-- null, so the audit triggers write nothing for them).
select set_config('t10.admin', tests.create_user('t10-admin@example.test', 'admin')::text, true);
select set_config('t10.admin2', tests.create_user('t10-admin2@example.test', 'admin')::text, true);
select set_config('t10.su', tests.create_user('t10-su@example.test', 'site_user')::text, true);
select set_config('t10.su2', tests.create_user('t10-su2@example.test', 'site_user')::text, true);
select set_config('t10.' || n, gen_random_uuid()::text, true)
from unnest(array['site1', 'site2', 'site3', 'archived', 'certsite', 'random']) as n;

insert into public.sites (id, code, name, is_active, archived_at) values
  (t10.id('site1'), 't10-site-1', 'T10 Site 1', true, null),
  (t10.id('site2'), 't10-site-2', 'T10 Site 2', true, null),
  (t10.id('site3'), 't10-site-3', 'T10 Site 3', true, null),
  (t10.id('archived'), 't10-archived', 'T10 Archived', false, now()),
  (t10.id('certsite'), 't10-cert', 'T10 Cert Site', true, null);
insert into public.user_sites (user_id, site_id) values (t10.id('su'), t10.id('site1'));
insert into public.certificates (site_id, certificate_date, amount, created_by)
values (t10.id('certsite'), '2026-04-05', 1, t10.id('su'));

-- 1-3: structure and privileges. The admin RPCs follow the transitions
-- pattern: security definer body in private, security invoker wrapper in
-- public (no definer function in the exposed schema for authenticated).
select ok(
  (select bool_and(proconfig = array['search_path=""']
                   and prosecdef = (pronamespace = 'private'::regnamespace
                                    or oid = 'public.auth_user_exists(text)'::regprocedure))
          and count(*) = 5
   from pg_proc
   where oid in ('public.admin_list_users()'::regprocedure,
                 'public.admin_set_user_sites(uuid,uuid[])'::regprocedure,
                 'private.admin_list_users()'::regprocedure,
                 'private.admin_set_user_sites(uuid,uuid[])'::regprocedure,
                 'public.auth_user_exists(text)'::regprocedure)),
  'admin RPC bodies are security definer in private, public wrappers are invoker, auth_user_exists is definer; all with an empty search_path'
);
select ok(
  has_function_privilege('authenticated', 'public.admin_list_users()', 'execute')
  and has_function_privilege('authenticated', 'public.admin_set_user_sites(uuid,uuid[])', 'execute')
  and has_function_privilege('authenticated', 'private.admin_list_users()', 'execute')
  and has_function_privilege('authenticated', 'private.admin_set_user_sites(uuid,uuid[])', 'execute')
  and not exists (
    select 1
    from pg_proc p
    cross join (values ('anon'), ('service_role')) as r (rolname)
    where p.oid in ('public.admin_list_users()'::regprocedure,
                    'public.admin_set_user_sites(uuid,uuid[])'::regprocedure,
                    'private.admin_list_users()'::regprocedure,
                    'private.admin_set_user_sites(uuid,uuid[])'::regprocedure)
      and has_function_privilege(r.rolname, p.oid, 'execute'))
  and not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid in ('public.admin_list_users()'::regprocedure,
                    'public.admin_set_user_sites(uuid,uuid[])'::regprocedure,
                    'private.admin_list_users()'::regprocedure,
                    'private.admin_set_user_sites(uuid,uuid[])'::regprocedure,
                    'public.auth_user_exists(text)'::regprocedure)
      and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'admin_list_users and admin_set_user_sites (both layers) are executable by authenticated only'
);
select ok(
  has_function_privilege('service_role', 'public.auth_user_exists(text)', 'execute')
  and not has_function_privilege('authenticated', 'public.auth_user_exists(text)', 'execute')
  and not has_function_privilege('anon', 'public.auth_user_exists(text)', 'execute'),
  'auth_user_exists is executable by service_role only'
);

-- 4-6: profiles_guard, cannot_change_self (Q15).
select tests.act_as(t10.id('admin'));
select throws_ok(
  format('update public.profiles set is_active = false where id = %L', t10.id('admin')),
  'P0001', 'cannot_change_self', 'an admin cannot deactivate themself'
);
select throws_ok(
  format('update public.profiles set role = %L where id = %L', 'site_user', t10.id('admin')),
  'P0001', 'cannot_change_self', 'an admin cannot demote themself'
);
select lives_ok(
  format('update public.profiles set full_name = %L where id = %L', 'T10 Admin Renamed', t10.id('admin')),
  'an admin can still rename themself'
);

-- 7-11: sites_archive_consistency and code normalization (Q16).
select throws_ok(
  format('update public.sites set is_active = false, archived_at = null where id = %L', t10.id('site3')),
  'P0001', 'archive_inconsistent', 'is_active=false without archived_at is rejected'
);
select throws_ok(
  format('insert into public.sites (code, name, is_active, archived_at) values (%L, %L, true, now())', 't10-x', 'X'),
  'P0001', 'archive_inconsistent', 'archived_at with is_active=true is rejected'
);
select lives_ok(
  format('insert into public.sites (code, name) values (%L, %L)', ' s01 ', 'T10 S01'),
  'an admin creates a site with a padded lowercase code'
);
select is(
  (select code from public.sites where name = 'T10 S01'),
  'S01', 'the site code is trimmed and upper-cased'
);
select throws_ok(
  format('insert into public.sites (code, name) values (%L, %L)', 'S01', 'T10 S01 again'),
  '23505', null, 'a duplicate normalized code is rejected'
);

-- 12-13: sites_code_lock (Q20).
select throws_ok(
  format('update public.sites set code = %L where id = %L', 't10-cert-2', t10.id('certsite')),
  'P0001', 'code_locked', 'the code of a site with certificates cannot change'
);
select lives_ok(
  format('update public.sites set code = %L, name = %L where id = %L', 't10-site-2b', 'T10 Site 2 renamed', t10.id('site2')),
  'the code of a site without certificates can change'
);
select tests.reset_role();

-- 14-18: audit triggers (Q19), as the admin above.
select is(t10.audit_count('site_updated', t10.id('site2')), 1::bigint,
  'one site_updated audit row after the site update');
select is(
  (select array[actor_id::text, before ->> 'code', after ->> 'code']
   from public.audit_logs where action = 'site_updated' and entity_id = t10.id('site2')),
  array[t10.id('admin')::text, 'T10-SITE-2', 'T10-SITE-2B'],
  'the site_updated row has the admin actor and the before/after code'
);
select is(
  (select actor_id from public.audit_logs
   where action = 'site_created' and entity = 'site'
     and entity_id = (select id from public.sites where code = 'S01')),
  t10.id('admin'), 'site_created is audited with the admin actor'
);
select is(
  (select array[actor_id::text, before ->> 'full_name', after ->> 'full_name']
   from public.audit_logs where action = 'profile_updated' and entity_id = t10.id('admin')),
  array[t10.id('admin')::text, 't10-admin@example.test', 'T10 Admin Renamed'],
  'profile_updated is audited with before/after values'
);
update public.sites set name = 'T10 Site 3 by postgres' where id = t10.id('site3');
select is(t10.audit_count('site_updated', t10.id('site3')), 0::bigint,
  'no audit row is written when auth.uid() is null (service path)');

-- 19-22: admin_list_users.
select tests.act_as(t10.id('admin'));
select results_eq(
  format($q$select id, email, role, is_active, invite_pending, site_ids
            from public.admin_list_users() where id in (%L, %L) order by email$q$,
         t10.id('admin2'), t10.id('su')),
  format($q$values (%L::uuid, 't10-admin2@example.test'::text, 'admin'::public.user_role, true, true, '{}'::uuid[]),
                   (%L::uuid, 't10-su@example.test'::text, 'site_user'::public.user_role, true, true, array[%L::uuid])$q$,
         t10.id('admin2'), t10.id('su'), t10.id('site1')),
  'admin_list_users returns users with email, role, flags and site ids'
);
select is(
  (select count(*) from public.admin_list_users()),
  (select count(*) from public.profiles),
  'admin_list_users returns every profile'
);
select tests.reset_role();
select tests.act_as(t10.id('su'));
select throws_ok('select * from public.admin_list_users()', 'P0001', 'forbidden',
  'a site user cannot list users');
select tests.reset_role();
set local role anon;
select throws_ok('select * from public.admin_list_users()', '42501', null,
  'anon cannot execute admin_list_users');
reset role;

-- 23-32: admin_set_user_sites.
select tests.act_as(t10.id('admin'));
select lives_ok(
  format('select public.admin_set_user_sites(%L, array[%L, %L]::uuid[])',
         t10.id('su'), t10.id('site2'), t10.id('site3')),
  'an admin replaces the sites of a site user'
);
select tests.reset_role();
select set_eq(
  format('select site_id from public.user_sites where user_id = %L', t10.id('su')),
  format('values (%L::uuid), (%L::uuid)', t10.id('site2'), t10.id('site3')),
  'the site user now has exactly the two new sites'
);
select is(
  (select array[t10.audit_count('user_site_added', t10.id('su')),
                t10.audit_count('user_site_removed', t10.id('su'))]),
  array[2::bigint, 1::bigint],
  'two user_site_added and one user_site_removed audit rows are written'
);
select tests.act_as(t10.id('admin'));
select throws_ok(
  format('select public.admin_set_user_sites(%L, array[%L, %L]::uuid[])',
         t10.id('su'), t10.id('site1'), t10.id('archived')),
  'P0001', 'invalid_sites', 'an archived site is rejected'
);
select throws_ok(
  format('select public.admin_set_user_sites(%L, array[%L]::uuid[])', t10.id('su'), t10.id('random')),
  'P0001', 'invalid_sites', 'an unknown site id is rejected'
);
select throws_ok(
  format('select public.admin_set_user_sites(%L, array[%L]::uuid[])', t10.id('admin2'), t10.id('site1')),
  'P0001', 'invalid_target', 'an admin target is rejected (admins are never linked to sites)'
);
select throws_ok(
  format('select public.admin_set_user_sites(%L, array[%L]::uuid[])', t10.id('random'), t10.id('site1')),
  'P0001', 'invalid_target', 'an unknown target is rejected'
);
select lives_ok(
  format('select public.admin_set_user_sites(%L, array[]::uuid[])', t10.id('su')),
  'an admin can leave a site user with zero sites'
);
select tests.reset_role();
select is(
  (select count(*) from public.user_sites where user_id = t10.id('su')),
  0::bigint, 'the site user has zero sites'
);
select tests.act_as(t10.id('su2'));
select throws_ok(
  format('select public.admin_set_user_sites(%L, array[%L]::uuid[])', t10.id('su2'), t10.id('site1')),
  'P0001', 'forbidden', 'a site user cannot set sites'
);
select tests.reset_role();

-- 33-35: auth_user_exists.
select tests.act_as_service();
select ok(public.auth_user_exists('T10-SU@Example.Test'), 'auth_user_exists matches an email case-insensitively');
select ok(not public.auth_user_exists('t10-nobody@example.test'), 'auth_user_exists is false for an unknown email');
select tests.reset_role();
select tests.act_as(t10.id('admin'));
select throws_ok(
  format('select public.auth_user_exists(%L)', 't10-su@example.test'),
  '42501', null, 'authenticated cannot execute auth_user_exists'
);
select tests.reset_role();

-- 36-40: last_admin (Q15), with auth.uid() null (postgres, no JWT claims).
select lives_ok(
  format('update public.profiles set is_active = false where role = %L and is_active and id <> %L',
         'admin', t10.id('admin')),
  'other active admins can be deactivated while one remains'
);
select is(
  (select count(*) from public.profiles where role = 'admin' and is_active),
  1::bigint, 'precondition: exactly one active admin remains'
);
select throws_ok(
  format('update public.profiles set is_active = false where id = %L', t10.id('admin')),
  'P0001', 'last_admin', 'the last active admin cannot be deactivated'
);
select throws_ok(
  format('update public.profiles set role = %L where id = %L', 'site_user', t10.id('admin')),
  'P0001', 'last_admin', 'the last active admin cannot be demoted'
);
select lives_ok(
  format('update public.profiles set full_name = %L where id = %L', 'Still Admin', t10.id('admin')),
  'the last active admin can still be renamed'
);

select * from finish();
rollback;

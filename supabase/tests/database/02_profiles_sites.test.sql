begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(46);

-- Local helpers (rolled back with the test).
-- t2.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t2;
create function t2.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t2.' || name)::uuid $$;

-- Rows a role can see in a table; a permission error counts as 0 visible rows.
create function t2.visible_rows(rel regclass)
returns bigint
language plpgsql
as $$
declare
  n bigint;
begin
  execute format('select count(*) from %s', rel) into n;
  return n;
exception when insufficient_privilege then
  return 0;
end;
$$;

-- Rows changed by a statement; a permission error counts as 0 changed rows.
create function t2.rows_affected(stmt text)
returns bigint
language plpgsql
as $$
declare
  n bigint;
begin
  execute stmt;
  get diagnostics n = row_count;
  return n;
exception when insufficient_privilege then
  return 0;
end;
$$;

grant usage on schema t2 to anon, authenticated;
grant execute on all functions in schema t2 to anon, authenticated;

-- Fixtures (created as the session role, which bypasses RLS).
select set_config('t2.admin', tests.create_user('t2-admin@example.test', 'admin')::text, true);
select set_config('t2.s1', tests.create_user('t2-s1@example.test', 'site_user')::text, true);
select set_config('t2.s2', tests.create_user('t2-s2@example.test', 'site_user')::text, true);
select set_config('t2.inactive_admin', tests.create_user('t2-ia@example.test', 'admin', false)::text, true);
select set_config('t2.inactive_su', tests.create_user('t2-is@example.test', 'site_user', false)::text, true);
select set_config('t2.noprofile', tests.create_user('t2-np@example.test')::text, true);

select set_config('t2.site1', gen_random_uuid()::text, true);
select set_config('t2.site2', gen_random_uuid()::text, true);
select set_config('t2.site3', gen_random_uuid()::text, true);
insert into public.sites (id, code, name) values
  (t2.id('site1'), 't2-site-1', 'T2 Site 1'),
  (t2.id('site2'), 't2-site-2', 'T2 Site 2'),
  (t2.id('site3'), 't2-site-3', 'T2 Site 3 (unmapped)');
insert into public.user_sites (user_id, site_id) values
  (t2.id('s1'), t2.id('site1')),
  (t2.id('s2'), t2.id('site2')),
  (t2.id('inactive_su'), t2.id('site1'));

select set_config('t2.total_profiles', (select count(*) from public.profiles)::text, true);
select set_config('t2.total_sites', (select count(*) from public.sites)::text, true);
select set_config('t2.total_user_sites', (select count(*) from public.user_sites)::text, true);

-- 1-3: RLS enabled on every table.
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass), 'RLS enabled on profiles');
select ok((select relrowsecurity from pg_class where oid = 'public.sites'::regclass), 'RLS enabled on sites');
select ok((select relrowsecurity from pg_class where oid = 'public.user_sites'::regclass), 'RLS enabled on user_sites');

-- 4-9: helper function privileges.
select ok(not has_function_privilege('anon', 'private.is_admin()', 'execute'), 'anon cannot execute private.is_admin()');
select ok(not has_function_privilege('anon', 'private.is_active_user()', 'execute'), 'anon cannot execute private.is_active_user()');
select ok(not has_function_privilege('anon', 'private.has_site_access(uuid)', 'execute'), 'anon cannot execute private.has_site_access(uuid)');
select ok(has_function_privilege('authenticated', 'private.is_admin()', 'execute'), 'authenticated can execute private.is_admin()');
select ok(has_function_privilege('authenticated', 'private.has_site_access(uuid)', 'execute'), 'authenticated can execute private.has_site_access(uuid)');
select ok(
  (select bool_and(p.prosecdef) from pg_proc p
   where p.pronamespace = 'private'::regnamespace
     and p.proname in ('is_active_user', 'is_admin', 'has_site_access')),
  'authorization helpers are security definer'
);

-- 10-17: active site user s1 (mapped to site1 only).
select tests.act_as(t2.id('s1'));
select results_eq('select id from public.profiles', array[t2.id('s1')], 'site user sees only own profile');
select results_eq('select id from public.sites', array[t2.id('site1')], 'site user sees only mapped sites');
select is_empty(format('select 1 from public.sites where id = %L', t2.id('site3')), 'unmapped site is invisible to site user');
select results_eq('select site_id from public.user_sites', array[t2.id('site1')], 'site user sees only own user_sites rows');
select is(
  t2.rows_affected(format('update public.profiles set role = %L where id = %L', 'admin', t2.id('s1'))),
  0::bigint,
  'site user update of own role affects 0 rows or is denied'
);
select throws_ok(
  $$insert into public.sites (code, name) values ('t2-s1-site', 'S1 site')$$,
  '42501', null, 'site user cannot insert a site'
);
select throws_ok(
  format('insert into public.user_sites (user_id, site_id) values (%L, %L)', t2.id('s1'), t2.id('site2')),
  '42501', null, 'site user cannot map self to another site'
);
select ok(not private.is_admin(), 'private.is_admin() is false for a site user');
select tests.reset_role();

-- 18: the role update did not happen (checked as the session role).
select is(
  (select role from public.profiles where id = t2.id('s1')),
  'site_user'::public.user_role,
  'site user role is unchanged after the denied update'
);

-- 19-25: active admin.
select tests.act_as(t2.id('admin'));
select ok(private.is_admin(), 'private.is_admin() is true for an active admin');
select is(t2.visible_rows('public.profiles'), current_setting('t2.total_profiles')::bigint, 'admin sees all profiles');
select is(t2.visible_rows('public.sites'), current_setting('t2.total_sites')::bigint, 'admin sees all sites');
select is(t2.visible_rows('public.user_sites'), current_setting('t2.total_user_sites')::bigint, 'admin sees all user_sites rows');
select is(
  t2.rows_affected(format('update public.profiles set full_name = %L where id = %L', 'S2 renamed', t2.id('s2'))),
  1::bigint,
  'admin can update another profile'
);
select lives_ok(
  format('insert into public.user_sites (user_id, site_id) values (%L, %L)', t2.id('s1'), t2.id('site3')),
  'admin can map a user to a site'
);
select is(
  t2.rows_affected(format('delete from public.user_sites where user_id = %L and site_id = %L', t2.id('s1'), t2.id('site3'))),
  1::bigint,
  'admin can delete a mapping'
);
select tests.reset_role();

-- 26-30: inactive admin.
select tests.act_as(t2.id('inactive_admin'));
select ok(not private.is_admin(), 'private.is_admin() is false for an inactive admin');
select ok(not private.is_active_user(), 'private.is_active_user() is false for an inactive admin');
select is(t2.visible_rows('public.profiles'), 0::bigint, 'inactive admin sees 0 profiles');
select is(t2.visible_rows('public.sites'), 0::bigint, 'inactive admin sees 0 sites');
select is(
  t2.rows_affected(format('update public.profiles set role = %L where id = %L', 'admin', t2.id('s2'))),
  0::bigint,
  'inactive admin update affects 0 rows or is denied'
);
select tests.reset_role();

-- 31-34: inactive site user (still mapped to site1).
select tests.act_as(t2.id('inactive_su'));
select is(t2.visible_rows('public.profiles'), 0::bigint, 'inactive site user sees 0 profiles');
select is(t2.visible_rows('public.sites'), 0::bigint, 'inactive site user sees 0 sites');
select is(t2.visible_rows('public.user_sites'), 0::bigint, 'inactive site user sees 0 user_sites rows');
select ok(not private.has_site_access(t2.id('site1')), 'inactive site user has no access to a mapped site');
select tests.reset_role();

-- 35-39: auth user without a profile.
select tests.act_as(t2.id('noprofile'));
select is(t2.visible_rows('public.profiles'), 0::bigint, 'user without profile sees 0 profiles');
select is(t2.visible_rows('public.sites'), 0::bigint, 'user without profile sees 0 sites');
select is(t2.visible_rows('public.user_sites'), 0::bigint, 'user without profile sees 0 user_sites rows');
select ok(not private.is_active_user(), 'private.is_active_user() is false without a profile');
select ok(not private.has_site_access(t2.id('site1')), 'private.has_site_access() is false without a profile');
select tests.reset_role();

-- 40-42: anon gets a permission error or 0 rows. Only schema t2 (test-only)
-- is granted to anon; t2.visible_rows catches insufficient_privilege raised by
-- the table query itself, so it cannot mask a test-schema error.
set local role anon;
select is(t2.visible_rows('public.profiles'), 0::bigint, 'anon sees 0 profiles');
select is(t2.visible_rows('public.sites'), 0::bigint, 'anon sees 0 sites');
select is(t2.visible_rows('public.user_sites'), 0::bigint, 'anon sees 0 user_sites rows');
-- anon has no usage on schema tests, so return with a plain reset role
-- (no JWT claims were set for anon).
reset role;

-- 43-44: anon has no table privileges at all.
select ok(
  not has_table_privilege('anon', 'public.profiles', 'select,insert,update,delete')
  and not has_table_privilege('anon', 'public.sites', 'select,insert,update,delete')
  and not has_table_privilege('anon', 'public.user_sites', 'select,insert,update,delete'),
  'anon has no privileges on profiles, sites, user_sites'
);
select ok(
  not has_table_privilege('authenticated', 'public.profiles', 'insert')
  and not has_table_privilege('authenticated', 'public.profiles', 'delete')
  and not has_table_privilege('authenticated', 'public.sites', 'delete'),
  'authenticated cannot insert/delete profiles or delete sites'
);

-- 45-46: updated_at is maintained by the trigger.
update public.sites set updated_at = '2000-01-01' where id = t2.id('site1');
update public.sites set name = 'T2 Site 1 renamed' where id = t2.id('site1');
select is((select updated_at from public.sites where id = t2.id('site1')), now(), 'sites.updated_at is set on update');
update public.profiles set updated_at = '2000-01-01' where id = t2.id('s1');
update public.profiles set full_name = 'S1 renamed' where id = t2.id('s1');
select is((select updated_at from public.profiles where id = t2.id('s1')), now(), 'profiles.updated_at is set on update');

select * from finish();
rollback;

begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(14);

-- Local helpers (rolled back with the test).
-- t9.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t9;
create function t9.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t9.' || name)::uuid $$;

-- Audit rows written by audit_user_created for a user. Call as the session role only.
create function t9.audit_count(p_user uuid)
returns bigint
language sql
stable
as $$
  select count(*) from public.audit_logs
  where entity = 'profile' and entity_id = p_user and action = 'audit_user_created'
$$;

grant usage on schema t9 to anon, authenticated, service_role;
grant execute on function t9.id(text) to anon, authenticated, service_role;

-- Fixtures (created as the session role, which bypasses RLS).
select set_config('t9.admin', tests.create_user('t9-admin@example.test', 'admin')::text, true);
select set_config('t9.inactive_admin', tests.create_user('t9-ia@example.test', 'admin', false)::text, true);
select set_config('t9.su', tests.create_user('t9-su@example.test', 'site_user')::text, true);
select set_config('t9.new_su', tests.create_user('t9-new@example.test', 'site_user')::text, true);
select set_config('t9.noprofile', tests.create_user('t9-np@example.test')::text, true);
select set_config('t9.' || n, gen_random_uuid()::text, true)
from unnest(array['site1', 'site2', 'random']) as n;

insert into public.sites (id, code, name) values
  (t9.id('site1'), 't9-site-1', 'T9 Site 1'),
  (t9.id('site2'), 't9-site-2', 'T9 Site 2');
-- Inserted in descending id order so the test proves the payload is sorted.
insert into public.user_sites (user_id, site_id)
select t9.id('new_su'), s
from unnest(array[t9.id('site1'), t9.id('site2')]) as s
order by s desc;
update public.profiles set full_name = 'T9 New User' where id = t9.id('new_su');

-- 1-2: structure and privileges.
select ok(
  (select prosecdef
          and proconfig = array['search_path=""']
          and pronamespace = 'public'::regnamespace
          and prorettype = 'void'::regtype
   from pg_proc where oid = 'public.audit_user_created(uuid,uuid)'::regprocedure),
  'audit_user_created is a void security definer function in public with an empty search_path'
);
select ok(
  has_function_privilege('service_role', 'public.audit_user_created(uuid,uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.audit_user_created(uuid,uuid)', 'execute')
  and not has_function_privilege('anon', 'public.audit_user_created(uuid,uuid)', 'execute')
  and not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid = 'public.audit_user_created(uuid,uuid)'::regprocedure
      and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'audit_user_created is executable by service_role only (not public, anon, authenticated)'
);

-- 3-4: API roles cannot execute (an active admin's JWT included).
select tests.act_as(t9.id('admin'));
select throws_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('new_su'), t9.id('admin')),
  '42501', null, 'authenticated (even an active admin) cannot execute audit_user_created'
);
select tests.reset_role();
set local role anon;
select throws_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('new_su'), t9.id('admin')),
  '42501', null, 'anon cannot execute audit_user_created'
);
reset role;

-- 5-10: checks, as service_role (auth.uid() is null).
select tests.act_as_service();
select throws_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('random'), t9.id('admin')),
  'P0001', 'not_found', 'a user without a profile row is not_found'
);
select throws_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('noprofile'), t9.id('admin')),
  'P0001', 'not_found', 'an auth user without a profile is not_found'
);
select throws_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('new_su'), t9.id('su')),
  'P0001', 'forbidden', 'a site_user actor is forbidden'
);
select throws_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('new_su'), t9.id('inactive_admin')),
  'P0001', 'forbidden', 'an inactive admin actor is forbidden'
);
select throws_ok(
  format('select public.audit_user_created(%L, null)', t9.id('new_su')),
  'P0001', 'forbidden', 'a null actor is forbidden'
);
select throws_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('random'), t9.id('su')),
  'P0001', 'not_found', 'not_found is checked before forbidden'
);
select tests.reset_role();

-- 11: nothing was written by the rejected calls.
select is(t9.audit_count(t9.id('new_su')), 0::bigint, 'rejected calls wrote no audit row');

-- 12-14: happy path, as service_role with an active admin actor.
select tests.act_as_service();
select lives_ok(
  format('select public.audit_user_created(%L, %L)', t9.id('new_su'), t9.id('admin')),
  'an active admin actor records the new user'
);
select tests.reset_role();
select is(t9.audit_count(t9.id('new_su')), 1::bigint, 'exactly one audit row is written');
select results_eq(
  format($q$select actor_id, action, entity, entity_id, before, after, reason
            from public.audit_logs
            where entity = 'profile' and entity_id = %L$q$, t9.id('new_su')),
  format($q$select %L::uuid, 'audit_user_created'::text, 'profile'::text, %L::uuid,
                   null::jsonb,
                   jsonb_build_object(
                     'role', 'site_user',
                     'full_name', 'T9 New User',
                     'is_active', true,
                     'site_ids', (select jsonb_agg(s order by s)
                                  from unnest(array[%L::uuid, %L::uuid]) as s)),
                   null::text$q$,
         t9.id('admin'), t9.id('new_su'), t9.id('site1'), t9.id('site2')),
  'the audit row has the admin actor, action, entity, null before and reason, and the sorted site_ids'
);

select * from finish();
rollback;

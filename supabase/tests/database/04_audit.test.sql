begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(34);

-- Local helpers (rolled back with the test).
-- t4.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t4;
create function t4.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t4.' || name)::uuid $$;

grant usage on schema t4 to authenticated, service_role;
grant execute on all functions in schema t4 to authenticated, service_role;

-- Fixtures (created as the session role).
select set_config('t4.admin', tests.create_user('t4-admin@example.test', 'admin')::text, true);
select set_config('t4.s1', tests.create_user('t4-s1@example.test', 'site_user')::text, true);
select set_config('t4.site1', gen_random_uuid()::text, true);
insert into public.sites (id, code, name) values (t4.id('site1'), 't4-site-1', 'T4 Site 1');
insert into public.user_sites (user_id, site_id) values (t4.id('s1'), t4.id('site1'));
select set_config('t4.e1', gen_random_uuid()::text, true);
select set_config('t4.e2', gen_random_uuid()::text, true);

-- 1-8: structure.
select has_table('public', 'audit_logs', 'public.audit_logs exists');
select ok((select relrowsecurity from pg_class where oid = 'public.audit_logs'::regclass), 'RLS enabled on audit_logs');
select col_type_is('public', 'audit_logs', 'id', 'bigint', 'id is bigint');
select ok(
  (select attidentity = 'a' from pg_attribute
   where attrelid = 'public.audit_logs'::regclass and attname = 'id'),
  'id is generated always as identity'
);
select col_is_pk('public', 'audit_logs', 'id', 'id is the primary key');
select fk_ok('public', 'audit_logs', 'actor_id', 'public', 'profiles', 'id', 'actor_id references profiles');
select has_index('public', 'audit_logs', 'audit_logs_entity_idx', array['entity', 'entity_id']::name[], 'audit_logs has an index on (entity, entity_id)');
select ok(
  (select bool_and(tgenabled <> 'D') and count(*) = 2
   from pg_trigger
   where tgrelid = 'public.audit_logs'::regclass and not tgisinternal
     and tgfoid = 'private.forbid_audit_mutation()'::regprocedure),
  'two enabled triggers on audit_logs use private.forbid_audit_mutation()'
);

-- 9-13: privileges.
select ok(
  (select bool_and(prosecdef) and count(*) = 2 from pg_proc
   where oid in ('private.write_audit(text,text,uuid,jsonb,jsonb,text)'::regprocedure,
                 'private.write_audit(uuid,text,text,uuid,jsonb,jsonb,text)'::regprocedure)),
  'both write_audit overloads are security definer'
);
select is_empty(
  $$select p.oid::regprocedure::text || ' executable by ' || r.rolname
    from pg_proc p
    cross join (values ('public'), ('anon'), ('authenticated'), ('service_role')) as r (rolname)
    where p.oid in ('private.write_audit(text,text,uuid,jsonb,jsonb,text)'::regprocedure,
                    'private.write_audit(uuid,text,text,uuid,jsonb,jsonb,text)'::regprocedure,
                    'private.forbid_audit_mutation()'::regprocedure)
      and (case when r.rolname = 'public'
                then exists (select 1 from aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
                             where a.grantee = 0 and a.privilege_type = 'EXECUTE')
                else has_function_privilege(r.rolname, p.oid, 'execute') end)$$,
  'write_audit overloads and forbid_audit_mutation are not executable by public, anon, authenticated, service_role'
);
select ok(
  not has_table_privilege('anon', 'public.audit_logs', 'select,insert,update,delete,truncate,references,trigger'),
  'anon has no privileges on audit_logs'
);
select ok(
  has_table_privilege('authenticated', 'public.audit_logs', 'select')
  and not has_table_privilege('authenticated', 'public.audit_logs', 'insert,update,delete,truncate,references,trigger'),
  'authenticated has select only on audit_logs'
);
select ok(
  has_table_privilege('service_role', 'public.audit_logs', 'select')
  and not has_table_privilege('service_role', 'public.audit_logs', 'insert,update,delete,truncate,references,trigger'),
  'service_role has select only on audit_logs'
);

-- 14-17: write_audit as the session role (as definer RPCs will call it).
select lives_ok(
  format(
    'select private.write_audit(%L::uuid, %L, %L, %L::uuid, %L::jsonb, %L::jsonb, %L)',
    t4.id('s1'), 't4_update', 't4_entity', t4.id('e1'), '{"amount": 1}', '{"amount": 2}', 'service reason'
  ),
  'write_audit (explicit actor) inserts as the session role'
);
select is(
  (select array[actor_id::text, action, entity, entity_id::text, before::text, after::text, reason]
   from public.audit_logs where entity = 't4_entity' and entity_id = t4.id('e1')),
  array[t4.id('s1')::text, 't4_update', 't4_entity', t4.id('e1')::text, '{"amount": 1}', '{"amount": 2}', 'service reason'],
  'write_audit (explicit actor) stores the given actor and values'
);
select set_config('request.jwt.claims', json_build_object('sub', t4.id('admin'), 'role', 'authenticated')::text, true);
select lives_ok(
  format(
    'select private.write_audit(%L, %L, %L::uuid, null, %L::jsonb, null)',
    't4_create', 't4_entity', t4.id('e2'), '{"amount": 3}'
  ),
  'write_audit (auth.uid() actor) inserts as the session role'
);
select set_config('request.jwt.claims', '', true);
select is(
  (select array[actor_id::text, action, before::text, after::text, reason, (created_at = now())::text]
   from public.audit_logs where entity = 't4_entity' and entity_id = t4.id('e2')),
  array[t4.id('admin')::text, 't4_create', null, '{"amount": 3}', null, 'true'],
  'write_audit (auth.uid() actor) derives actor_id from the JWT sub'
);

-- 18-20: append-only for the session role (postgres), exact trigger message.
select throws_ok(
  'update public.audit_logs set reason = ''x'' where entity = ''t4_entity''',
  'P0001', 'audit_log_append_only', 'postgres cannot update audit_logs'
);
select throws_ok(
  'delete from public.audit_logs where entity = ''t4_entity''',
  'P0001', 'audit_log_append_only', 'postgres cannot delete from audit_logs'
);
select throws_ok(
  'truncate public.audit_logs',
  'P0001', 'audit_log_append_only', 'postgres cannot truncate audit_logs'
);

-- 21-22: rows still present; site user sees none of them.
select is(
  (select count(*) from public.audit_logs where entity = 't4_entity'),
  2::bigint,
  'precondition: both audit rows exist after the denied mutations'
);
select tests.act_as(t4.id('s1'));
-- Plain query (no helper that swallows insufficient_privilege).
select is((select count(*) from public.audit_logs), 0::bigint, 'site user sees 0 audit rows');
select tests.reset_role();

-- 23-28: admin sees rows; authenticated cannot insert, mutate or call write_audit.
select tests.act_as(t4.id('admin'));
select is(
  (select count(*) from public.audit_logs where entity = 't4_entity'),
  2::bigint,
  'admin sees the inserted audit rows'
);
select throws_ok(
  format('insert into public.audit_logs (actor_id, action, entity, entity_id) values (%L, %L, %L, %L)',
         t4.id('admin'), 'x', 't4_entity', t4.id('e1')),
  '42501', null, 'authenticated cannot insert into audit_logs directly'
);
select throws_ok(
  'update public.audit_logs set reason = ''x'' where entity = ''t4_entity''',
  '42501', null, 'authenticated cannot update audit_logs'
);
select throws_ok(
  'delete from public.audit_logs where entity = ''t4_entity''',
  '42501', null, 'authenticated cannot delete from audit_logs'
);
select throws_ok(
  'truncate public.audit_logs',
  '42501', null, 'authenticated cannot truncate audit_logs'
);
select throws_ok(
  format('select private.write_audit(%L, %L, %L::uuid, null, null, null)', 'x', 't4_entity', t4.id('e1')),
  '42501', null, 'authenticated cannot execute write_audit'
);
select tests.reset_role();

-- 29-33: service_role cannot mutate or call write_audit.
select tests.act_as_service();
select throws_ok(
  'update public.audit_logs set reason = ''x'' where entity = ''t4_entity''',
  '42501', null, 'service_role cannot update audit_logs'
);
select throws_ok(
  'delete from public.audit_logs where entity = ''t4_entity''',
  '42501', null, 'service_role cannot delete from audit_logs'
);
select throws_ok(
  'truncate public.audit_logs',
  '42501', null, 'service_role cannot truncate audit_logs'
);
select throws_ok(
  format('insert into public.audit_logs (actor_id, action, entity, entity_id) values (%L, %L, %L, %L)',
         t4.id('admin'), 'x', 't4_entity', t4.id('e1')),
  '42501', null, 'service_role cannot insert into audit_logs directly'
);
select throws_ok(
  format('select private.write_audit(%L::uuid, %L, %L, %L::uuid, null, null, null)',
         t4.id('admin'), 'x', 't4_entity', t4.id('e1')),
  '42501', null, 'service_role cannot execute write_audit'
);
select tests.reset_role();

-- 34: nothing changed after all denied attempts.
select is(
  (select count(*) from public.audit_logs where entity = 't4_entity'),
  2::bigint,
  'audit rows unchanged after all denied attempts'
);

select * from finish();
rollback;

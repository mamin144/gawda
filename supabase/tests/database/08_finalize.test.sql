begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(45);

-- Local helpers (rolled back with the test).
-- t8.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t8;
create function t8.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t8.' || name)::uuid $$;

-- t8.path(site, period, file): storage path '<site id>/<year/month/half>/<file>'.
create function t8.path(site text, period text, file text)
returns text
language sql
stable
as $$ select t8.id(site)::text || '/' || period || '/' || file $$;

-- t8.sha(n): a valid lowercase 64-hex-digit sha256 built from n.
create function t8.sha(n integer)
returns text
language sql
immutable
as $$ select lpad(to_hex(n), 64, '0') $$;

-- Audit rows for an entity id. Call as the session role only.
create function t8.audit_count(p_entity_id uuid)
returns bigint
language sql
stable
as $$ select count(*) from public.audit_logs where entity_id = p_entity_id $$;

grant usage on schema t8 to anon, authenticated, service_role;
grant execute on function t8.id(text), t8.path(text, text, text) to anon, authenticated, service_role;

-- Fixtures (created as the session role, which bypasses RLS and the guard).
select set_config('t8.admin', tests.create_user('t8-admin@example.test', 'admin')::text, true);
select set_config('t8.s1', tests.create_user('t8-s1@example.test', 'site_user')::text, true);
select set_config('t8.s2', tests.create_user('t8-s2@example.test', 'site_user')::text, true);
select set_config('t8.inactive_su', tests.create_user('t8-is@example.test', 'site_user', false)::text, true);
select set_config('t8.noprofile', tests.create_user('t8-np@example.test')::text, true);

select set_config('t8.' || n, gen_random_uuid()::text, true)
from unnest(array[
  'site1', 'site2', 'random',
  'c_main', 'c_nosigned', 'c_noobj', 'c_delsigned', 'c_noaudit', 'c_review',
  'c_deleted', 'c_site2', 'c_draft',
  'i_main', 's_main_v1', 's_main_v2', 'i_draft'
]) as n;

insert into public.sites (id, code, name) values
  (t8.id('site1'), 't8-site-1', 'T8 Site 1'),
  (t8.id('site2'), 't8-site-2', 'T8 Site 2');
insert into public.user_sites (user_id, site_id) values
  (t8.id('s1'), t8.id('site1')),
  (t8.id('s2'), t8.id('site2')),
  (t8.id('inactive_su'), t8.id('site1'));

insert into public.certificates
  (id, site_id, certificate_date, amount, status, created_by, deleted_at, deleted_by) values
  (t8.id('c_main'),      t8.id('site1'), '2026-01-05', 100, 'awaiting_signature', t8.id('s1'), null,  null),
  (t8.id('c_nosigned'),  t8.id('site1'), '2026-01-20', 110, 'awaiting_signature', t8.id('s1'), null,  null),
  (t8.id('c_noobj'),     t8.id('site1'), '2026-02-05', 120, 'awaiting_signature', t8.id('s1'), null,  null),
  (t8.id('c_delsigned'), t8.id('site1'), '2026-02-20', 130, 'awaiting_signature', t8.id('s1'), null,  null),
  (t8.id('c_noaudit'),   t8.id('site1'), '2026-03-05', 140, 'awaiting_signature', t8.id('s1'), null,  null),
  (t8.id('c_review'),    t8.id('site1'), '2026-03-20', 150, 'in_review',          t8.id('s1'), null,  null),
  (t8.id('c_deleted'),   t8.id('site1'), '2026-04-05', 160, 'awaiting_signature', t8.id('s1'), now(), t8.id('s1')),
  (t8.id('c_draft'),     t8.id('site1'), '2026-04-20', 170, 'draft',              t8.id('s1'), null,  null),
  (t8.id('c_site2'),     t8.id('site2'), '2026-01-05', 180, 'awaiting_signature', t8.id('s2'), null,  null);

-- Timestamps. Inside one transaction now() is constant, so the history of the
-- first signing round is backdated explicitly: its approve_for_signing audit
-- row is at now() - 2 hours and its signed copy at now() - 1 hour. The second
-- round (reopen -> submit -> approve_for_signing, tests 39-41) runs the real
-- RPCs, so its approve_for_signing audit row is at now(), later than the old
-- signed copy and not later than a copy uploaded now().
insert into public.audit_logs (actor_id, action, entity, entity_id, before, after, created_at)
select t8.id('admin'), 'approve_for_signing', 'certificate', t8.id(c),
       '{"status": "in_review", "return_note": null}'::jsonb,
       '{"status": "awaiting_signature", "return_note": null}'::jsonb,
       now() - interval '2 hours'
from unnest(array['c_main', 'c_nosigned', 'c_noobj', 'c_delsigned', 'c_deleted', 'c_site2']) as c;
-- c_noaudit has no approve_for_signing audit row at all.

insert into public.attachments
  (id, certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256, uploaded_by, uploaded_at, deleted_at, deleted_by) values
  (t8.id('i_main'),    t8.id('c_main'),      'initial', t8.path('site1', '2026/1/1', 'initial.pdf'),  'initial.pdf', 'application/pdf', 1000, t8.sha(1), t8.id('s1'), now() - interval '3 hours', null, null),
  (t8.id('s_main_v1'), t8.id('c_main'),      'signed',  t8.path('site1', '2026/1/1', 'signed1.pdf'),  'signed1.pdf', 'application/pdf', 1000, t8.sha(2), t8.id('s1'), now() - interval '1 hour',  null, null),
  (gen_random_uuid(),  t8.id('c_noobj'),     'signed',  t8.path('site1', '2026/2/1', 'signed.pdf'),   'signed.pdf',  'application/pdf', 1000, t8.sha(3), t8.id('s1'), now() - interval '1 hour',  null, null),
  (gen_random_uuid(),  t8.id('c_delsigned'), 'signed',  t8.path('site1', '2026/2/2', 'signed.pdf'),   'signed.pdf',  'application/pdf', 1000, t8.sha(4), t8.id('s1'), now() - interval '1 hour',  now(), t8.id('s1')),
  (gen_random_uuid(),  t8.id('c_noaudit'),   'signed',  t8.path('site1', '2026/3/1', 'signed.pdf'),   'signed.pdf',  'application/pdf', 1000, t8.sha(5), t8.id('s1'), now() - interval '1 hour',  null, null),
  (gen_random_uuid(),  t8.id('c_deleted'),   'signed',  t8.path('site1', '2026/4/1', 'signed.pdf'),   'signed.pdf',  'application/pdf', 1000, t8.sha(6), t8.id('s1'), now() - interval '1 hour',  null, null),
  (gen_random_uuid(),  t8.id('c_site2'),     'signed',  t8.path('site2', '2026/1/1', 'signed.pdf'),   'signed.pdf',  'application/pdf', 1000, t8.sha(7), t8.id('s2'), now() - interval '1 hour',  null, null),
  (t8.id('i_draft'),   t8.id('c_draft'),     'initial', t8.path('site1', '2026/4/2', 'initial.pdf'),  'initial.pdf', 'application/pdf', 1000, t8.sha(8), t8.id('s1'), now() - interval '1 hour',  null, null);

-- Storage objects for every signed copy except c_noobj's.
insert into storage.objects (bucket_id, name) values
  ('certificates', t8.path('site1', '2026/1/1', 'initial.pdf')),
  ('certificates', t8.path('site1', '2026/1/1', 'signed1.pdf')),
  ('certificates', t8.path('site1', '2026/2/2', 'signed.pdf')),
  ('certificates', t8.path('site1', '2026/3/1', 'signed.pdf')),
  ('certificates', t8.path('site1', '2026/4/1', 'signed.pdf')),
  ('certificates', t8.path('site2', '2026/1/1', 'signed.pdf'));

-- 1-4: structure and privileges.
select ok(
  (select prosecdef
          and proconfig = array['search_path=""']
          and pronamespace = 'public'::regnamespace
          and proretset
   from pg_proc where oid = 'public.finalize_with_signed_copy(uuid,uuid)'::regprocedure),
  'finalize_with_signed_copy is a set-returning security definer function in public with an empty search_path'
);
select ok(
  (select prosecdef
          and proconfig = array['search_path=""']
          and pronamespace = 'public'::regnamespace
          and prorettype = 'void'::regtype
   from pg_proc where oid = 'public.record_initial_file_deleted(uuid,uuid)'::regprocedure),
  'record_initial_file_deleted is a void security definer function in public with an empty search_path'
);
select ok(
  has_function_privilege('service_role', 'public.finalize_with_signed_copy(uuid,uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.finalize_with_signed_copy(uuid,uuid)', 'execute')
  and not has_function_privilege('anon', 'public.finalize_with_signed_copy(uuid,uuid)', 'execute')
  and not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid = 'public.finalize_with_signed_copy(uuid,uuid)'::regprocedure
      and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'finalize_with_signed_copy is executable by service_role only (not public, anon, authenticated)'
);
select ok(
  has_function_privilege('service_role', 'public.record_initial_file_deleted(uuid,uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.record_initial_file_deleted(uuid,uuid)', 'execute')
  and not has_function_privilege('anon', 'public.record_initial_file_deleted(uuid,uuid)', 'execute')
  and not exists (
    select 1 from pg_proc p, aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
    where p.oid = 'public.record_initial_file_deleted(uuid,uuid)'::regprocedure
      and a.grantee = 0 and a.privilege_type = 'EXECUTE'),
  'record_initial_file_deleted is executable by service_role only (not public, anon, authenticated)'
);

-- 5-8: API roles cannot execute.
select tests.act_as(t8.id('s1'));
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('s1')),
  '42501', null, 'authenticated cannot execute finalize_with_signed_copy'
);
select throws_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('i_main'), t8.id('s1')),
  '42501', null, 'authenticated cannot execute record_initial_file_deleted'
);
select tests.reset_role();
set local role anon;
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('s1')),
  '42501', null, 'anon cannot execute finalize_with_signed_copy'
);
select throws_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('i_main'), t8.id('s1')),
  '42501', null, 'anon cannot execute record_initial_file_deleted'
);
reset role;

-- 9-21: finalize_with_signed_copy checks, as service_role.
select tests.act_as_service();
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('random'), t8.id('s1')),
  'P0001', 'not_found', 'finalize: a missing certificate is not_found'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('admin')),
  'P0001', 'forbidden', 'finalize: an admin as p_actor is forbidden'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, null)', t8.id('c_main')),
  'P0001', 'forbidden', 'finalize: a null p_actor is forbidden'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('inactive_su')),
  'P0001', 'forbidden', 'finalize: an inactive site user is forbidden'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('noprofile')),
  'P0001', 'forbidden', 'finalize: a user without a profile is forbidden'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_site2'), t8.id('s1')),
  'P0001', 'forbidden', 'finalize: a site user of another site is forbidden'
);
select lives_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_site2'), t8.id('s2')),
  'finalize: site2''s own user finalizes its certificate'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_deleted'), t8.id('s1')),
  'P0001', 'not_found', 'finalize: a soft-deleted certificate is not_found'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_review'), t8.id('s1')),
  'P0001', 'invalid_transition', 'finalize: in_review is invalid_transition'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_nosigned'), t8.id('s1')),
  'P0001', 'signed_copy_missing', 'finalize: no signed attachment is signed_copy_missing'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_noobj'), t8.id('s1')),
  'P0001', 'signed_copy_missing', 'finalize: a signed row without a storage object is signed_copy_missing'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_delsigned'), t8.id('s1')),
  'P0001', 'signed_copy_missing', 'finalize: a soft-deleted signed row is signed_copy_missing'
);
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_noaudit'), t8.id('s1')),
  'P0001', 'signed_copy_missing', 'finalize: without an approve_for_signing audit row no signed copy qualifies'
);

-- 22-26: happy path and idempotent retry.
select results_eq(
  format('select attachment_id, storage_path from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('s1')),
  format('values (%L::uuid, %L::text)', t8.id('i_main'), t8.path('site1', '2026/1/1', 'initial.pdf')),
  'finalize: returns the active initial attachment'
);
select tests.reset_role();
select is(
  (select array[status::text, (locked_at = now())::text] from public.certificates where id = t8.id('c_main')),
  array['approved', 'true'],
  'finalize: the certificate is approved with locked_at = now()'
);
select is(
  (select array[actor_id::text, entity, before::text, after::text, coalesce(reason, '<null>')]
   from public.audit_logs
   where entity_id = t8.id('c_main') and action = 'finalize_with_signed_copy'),
  array[t8.id('s1')::text, 'certificate',
        '{"status": "awaiting_signature", "return_note": null}',
        '{"status": "approved", "return_note": null}', '<null>'],
  'finalize: one audit row with actor p_actor, status before/after, no reason'
);
select set_config('t8.audit_before_retry', t8.audit_count(t8.id('c_main'))::text, true);
select tests.act_as_service();
select results_eq(
  format('select attachment_id, storage_path from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('s1')),
  format('values (%L::uuid, %L::text)', t8.id('i_main'), t8.path('site1', '2026/1/1', 'initial.pdf')),
  'finalize retry: an approved certificate returns the same initial path'
);
select tests.reset_role();
select is(
  t8.audit_count(t8.id('c_main')),
  current_setting('t8.audit_before_retry')::bigint,
  'finalize retry: no new audit row'
);

-- 27: the approved certificate is locked for its site user.
select tests.act_as(t8.id('s1'));
select throws_ok(
  format('update public.certificates set amount = 1 where id = %L', t8.id('c_main')),
  'P0001', 'certificate_locked', 'after approved, a site user''s update raises certificate_locked'
);
select tests.reset_role();

-- 28-38: record_initial_file_deleted.
select tests.act_as_service();
select throws_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('random'), t8.id('s1')),
  'P0001', 'not_found', 'record: a missing attachment is not_found'
);
select throws_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('i_main'), t8.id('admin')),
  'P0001', 'forbidden', 'record: an admin as p_actor is forbidden'
);
select throws_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('i_main'), t8.id('s2')),
  'P0001', 'forbidden', 'record: a site user of another site is forbidden'
);
select throws_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('s_main_v1'), t8.id('s1')),
  'P0001', 'invalid_transition', 'record: a signed attachment is invalid_transition'
);
select throws_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('i_draft'), t8.id('s1')),
  'P0001', 'invalid_transition', 'record: an initial attachment of a draft is invalid_transition'
);
select lives_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('i_main'), t8.id('s1')),
  'record: the site user records the initial file deletion'
);
select tests.reset_role();
select is(
  (select array[(deleted_at = now())::text, deleted_by::text, delete_reason]
   from public.attachments where id = t8.id('i_main')),
  array['true', t8.id('s1')::text, 'replaced_by_signed_copy'],
  'record: the row is kept with deleted_at, deleted_by and delete_reason set'
);
select is(
  (select array[actor_id::text, entity, before::text,
                ((after ->> 'deleted_at')::timestamptz = now()
                 and after ->> 'delete_reason' = 'replaced_by_signed_copy'
                 and (select count(*) from jsonb_object_keys(after)) = 2)::text]
   from public.audit_logs
   where entity_id = t8.id('i_main') and action = 'record_initial_file_deleted'),
  array[t8.id('s1')::text, 'attachment', '{"deleted_at": null, "delete_reason": null}', 'true'],
  'record: one audit row on the attachment with deleted_at/delete_reason before and after'
);
select set_config('t8.audit_before_noop', t8.audit_count(t8.id('i_main'))::text, true);
select tests.act_as_service();
select lives_ok(
  format('select public.record_initial_file_deleted(%L, %L)', t8.id('i_main'), t8.id('s1')),
  'record: a second call on a deleted row is a no-op'
);
select tests.reset_role();
select is(
  t8.audit_count(t8.id('i_main')),
  current_setting('t8.audit_before_noop')::bigint,
  'record no-op: no new audit row'
);
select tests.act_as_service();
select is_empty(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('s1')),
  'finalize retry after the deletion is recorded returns no initial attachment'
);
select tests.reset_role();

-- 39-45: second signing round. Previous signed copies are kept.
select tests.act_as(t8.id('admin'));
select lives_ok(format('select public.reopen_certificate(%L, %L)', t8.id('c_main'), 'correction'), 'round 2: admin reopens');
select tests.act_as(t8.id('s1'));
select lives_ok(format('select public.submit_certificate(%L)', t8.id('c_main')), 'round 2: site user submits');
select tests.act_as(t8.id('admin'));
select lives_ok(format('select public.approve_for_signing(%L)', t8.id('c_main')), 'round 2: admin approves for signing');
select tests.act_as_service();
select throws_ok(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('s1')),
  'P0001', 'signed_copy_missing', 'round 2: the previous round''s signed copy does not qualify'
);
select tests.reset_role();

insert into public.attachments
  (id, certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256, uploaded_by)
values
  (t8.id('s_main_v2'), t8.id('c_main'), 'signed', t8.path('site1', '2026/1/1', 'signed2.pdf'), 'signed2.pdf', 'application/pdf', 1000, t8.sha(9), t8.id('s1'));
insert into storage.objects (bucket_id, name) values ('certificates', t8.path('site1', '2026/1/1', 'signed2.pdf'));

select tests.act_as_service();
select is_empty(
  format('select * from public.finalize_with_signed_copy(%L, %L)', t8.id('c_main'), t8.id('s1')),
  'round 2: with a new signed copy finalize succeeds (no active initial left)'
);
select tests.reset_role();
select is(
  (select array[status::text, (locked_at is not null)::text] from public.certificates where id = t8.id('c_main')),
  array['approved', 'true'],
  'round 2: the certificate is approved and locked again'
);
select is(
  (select count(*) from public.attachments
   where certificate_id = t8.id('c_main') and kind = 'signed' and deleted_at is null
     and id in (t8.id('s_main_v1'), t8.id('s_main_v2'))),
  2::bigint,
  'round 2: both the previous and the new signed copies remain active'
);

select * from finish();
rollback;

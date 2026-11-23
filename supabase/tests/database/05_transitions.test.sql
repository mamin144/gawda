begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(58);

-- Local helpers (rolled back with the test).
-- t5.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t5;
create function t5.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t5.' || name)::uuid $$;

-- Rows changed by a statement (other errors propagate).
create function t5.rows_affected(stmt text)
returns bigint
language plpgsql
as $$
declare
  n bigint;
begin
  execute stmt;
  get diagnostics n = row_count;
  return n;
end;
$$;

-- Audit rows for an entity id. Call as the session role only.
create function t5.audit_count(p_entity_id uuid)
returns bigint
language sql
stable
as $$ select count(*) from public.audit_logs where entity_id = p_entity_id $$;

grant usage on schema t5 to anon, authenticated;
grant execute on function t5.id(text), t5.rows_affected(text) to anon, authenticated;

-- Fixtures (created as the session role, which bypasses RLS and the guard).
select set_config('t5.admin', tests.create_user('t5-admin@example.test', 'admin')::text, true);
select set_config('t5.s1', tests.create_user('t5-s1@example.test', 'site_user')::text, true);
select set_config('t5.s2', tests.create_user('t5-s2@example.test', 'site_user')::text, true);
select set_config('t5.inactive_su', tests.create_user('t5-is@example.test', 'site_user', false)::text, true);
select set_config('t5.noprofile', tests.create_user('t5-np@example.test')::text, true);

select set_config('t5.' || n, gen_random_uuid()::text, true)
from unnest(array[
  'site1', 'site2', 'random',
  'c_draft', 'c_returned', 'c_review', 'c_review2', 'c_approved', 'c_draft2', 'c_deleted',
  'd_draft', 'd_review', 'd_returned', 'd_await', 'c_approved2', 'c_await2', 'c_site2'
]) as n;

insert into public.sites (id, code, name) values
  (t5.id('site1'), 't5-site-1', 'T5 Site 1'),
  (t5.id('site2'), 't5-site-2', 'T5 Site 2');
insert into public.user_sites (user_id, site_id) values
  (t5.id('s1'), t5.id('site1')),
  (t5.id('s2'), t5.id('site2')),
  (t5.id('inactive_su'), t5.id('site1'));

insert into public.certificates
  (id, site_id, certificate_date, amount, status, return_note, locked_at, created_by, deleted_at, deleted_by) values
  (t5.id('c_draft'),     t5.id('site1'), '2026-01-05', 100, 'draft',              null,       null,  t5.id('s1'), null,  null),
  (t5.id('c_returned'),  t5.id('site1'), '2026-01-20', 110, 'returned',           'old note', null,  t5.id('s1'), null,  null),
  (t5.id('c_review'),    t5.id('site1'), '2026-02-05', 120, 'in_review',          null,       null,  t5.id('s1'), null,  null),
  (t5.id('c_review2'),   t5.id('site1'), '2026-02-20', 130, 'in_review',          null,       null,  t5.id('s1'), null,  null),
  (t5.id('c_approved'),  t5.id('site1'), '2026-03-05', 140, 'approved',           null,       now(), t5.id('s1'), null,  null),
  (t5.id('c_draft2'),    t5.id('site1'), '2026-03-20', 150, 'draft',              null,       null,  t5.id('s1'), null,  null),
  (t5.id('c_deleted'),   t5.id('site1'), '2026-04-05', 160, 'draft',              null,       null,  t5.id('s1'), now(), t5.id('s1')),
  (t5.id('d_draft'),     t5.id('site1'), '2026-05-05', 170, 'draft',              null,       null,  t5.id('s1'), null,  null),
  (t5.id('d_review'),    t5.id('site1'), '2026-05-20', 180, 'in_review',          null,       null,  t5.id('s1'), null,  null),
  (t5.id('d_returned'),  t5.id('site1'), '2026-06-05', 190, 'returned',           'note',     null,  t5.id('s1'), null,  null),
  (t5.id('d_await'),     t5.id('site1'), '2026-06-20', 200, 'awaiting_signature', null,       null,  t5.id('s1'), null,  null),
  (t5.id('c_approved2'), t5.id('site1'), '2026-07-05', 210, 'approved',           null,       now(), t5.id('s1'), null,  null),
  (t5.id('c_await2'),    t5.id('site1'), '2026-07-20', 220, 'awaiting_signature', null,       null,  t5.id('s1'), null,  null),
  (t5.id('c_site2'),     t5.id('site2'), '2026-01-05', 230, 'draft',              null,       null,  t5.id('s2'), null,  null);

-- 1-5: structure and privileges.
select ok(
  (select count(*) = 5
          and bool_and(prosecdef)
          and bool_and(proconfig = array['search_path=""'])
          and bool_and(prorettype = 'public.certificates'::regtype)
   from pg_proc
   where oid in ('private.submit_certificate(uuid)'::regprocedure,
                 'private.return_certificate(uuid,text)'::regprocedure,
                 'private.approve_for_signing(uuid)'::regprocedure,
                 'private.reopen_certificate(uuid,text)'::regprocedure,
                 'private.delete_certificate(uuid,text)'::regprocedure)),
  'five private transition functions: security definer, empty search_path, return certificates'
);
select ok(
  (select count(*) = 5
          and not bool_or(prosecdef)
          and bool_and(proconfig = array['search_path=""'])
          and bool_and(prorettype = 'public.certificates'::regtype)
   from pg_proc
   where oid in ('public.submit_certificate(uuid)'::regprocedure,
                 'public.return_certificate(uuid,text)'::regprocedure,
                 'public.approve_for_signing(uuid)'::regprocedure,
                 'public.reopen_certificate(uuid,text)'::regprocedure,
                 'public.delete_certificate(uuid,text)'::regprocedure)),
  'five public wrappers: security invoker, empty search_path, return certificates'
);
-- Offenders are listed by signature and role in the failure diagnostics.
select is_empty(
  $$select p.oid::regprocedure::text || ' executable by ' || r.rolname
    from pg_proc p
    cross join (values ('public'), ('anon'), ('service_role')) as r (rolname)
    where p.pronamespace in ('public'::regnamespace, 'private'::regnamespace)
      and p.proname in ('submit_certificate', 'return_certificate', 'approve_for_signing',
                        'reopen_certificate', 'delete_certificate')
      and (case when r.rolname = 'public'
                then exists (select 1 from aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
                             where a.grantee = 0 and a.privilege_type = 'EXECUTE')
                else has_function_privilege(r.rolname, p.oid, 'execute') end)$$,
  'transition functions are not executable by public, anon, service_role'
);
select ok(
  (select count(*) = 10 and bool_and(has_function_privilege('authenticated', p.oid, 'execute'))
   from pg_proc p
   where p.pronamespace in ('public'::regnamespace, 'private'::regnamespace)
     and p.proname in ('submit_certificate', 'return_certificate', 'approve_for_signing',
                       'reopen_certificate', 'delete_certificate')),
  'authenticated can execute the ten transition functions'
);
-- anon has no usage on schema tests, so return with a plain reset role.
set local role anon;
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('c_draft')),
  '42501', null, 'anon cannot execute public.submit_certificate'
);
reset role;

-- 6-15: site user s1 (mapped to site1).
select tests.act_as(t5.id('s1'));
select lives_ok(format('select public.submit_certificate(%L)', t5.id('c_draft')), 'site user submits a draft');
select lives_ok(format('select public.submit_certificate(%L)', t5.id('c_returned')), 'site user submits a returned certificate');
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('c_review')),
  'P0001', 'invalid_transition', 'submit from in_review raises invalid_transition'
);
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('c_site2')),
  'P0001', 'forbidden', 'site user of site1 submitting a site2 certificate raises forbidden'
);
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('random')),
  'P0001', 'not_found', 'submit of an unknown id raises not_found'
);
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('c_deleted')),
  'P0001', 'not_found', 'submit of a soft-deleted certificate raises not_found'
);
select throws_ok(
  format('select public.delete_certificate(%L)', t5.id('c_deleted')),
  'P0001', 'already_deleted', 'delete of a soft-deleted certificate raises already_deleted'
);
select throws_ok(
  format('select public.return_certificate(%L, %L)', t5.id('c_review'), 'note'),
  'P0001', 'forbidden', 'site user calling return raises forbidden'
);
select throws_ok(
  format('select public.approve_for_signing(%L)', t5.id('c_review')),
  'P0001', 'forbidden', 'site user calling approve raises forbidden'
);
select throws_ok(
  format('select public.reopen_certificate(%L, %L)', t5.id('c_approved'), 'reason'),
  'P0001', 'forbidden', 'site user calling reopen raises forbidden'
);
select tests.reset_role();

-- 16-19: effects of the site user calls, checked as the session role.
select is(
  (select array[status::text, (submitted_at = now())::text] from public.certificates where id = t5.id('c_draft')),
  array['in_review', 'true'],
  'submit sets in_review and submitted_at'
);
select is(
  (select status::text from public.certificates where id = t5.id('c_returned')),
  'in_review',
  'submit from returned sets in_review'
);
select is(
  (select array[actor_id::text, action, entity, before::text, after::text, reason]
   from public.audit_logs where entity_id = t5.id('c_draft')),
  array[t5.id('s1')::text, 'submit_certificate', 'certificate',
        '{"status": "draft", "return_note": null}', '{"status": "in_review", "return_note": null}', null],
  'submit writes the audit row'
);
select is(
  array[t5.audit_count(t5.id('c_draft')), t5.audit_count(t5.id('c_returned')),
        t5.audit_count(t5.id('c_review')), t5.audit_count(t5.id('c_site2')),
        t5.audit_count(t5.id('c_approved')), t5.audit_count(t5.id('c_deleted'))],
  array[1, 1, 0, 0, 0, 0]::bigint[],
  'one audit row per successful submit, none for the rejected calls'
);

-- 20: precondition for test 9: site2's own user can submit c_site2.
select tests.act_as(t5.id('s2'));
select lives_ok(format('select public.submit_certificate(%L)', t5.id('c_site2')), 'site2 user submits the site2 draft');
select tests.reset_role();

-- 21-29: admin.
select tests.act_as(t5.id('admin'));
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('c_draft2')),
  'P0001', 'forbidden', 'admin calling submit raises forbidden'
);
select throws_ok(
  format('select public.approve_for_signing(%L)', t5.id('c_draft2')),
  'P0001', 'invalid_transition', 'approve from draft raises invalid_transition'
);
select throws_ok(
  format('select public.reopen_certificate(%L, %L)', t5.id('c_review'), 'reason'),
  'P0001', 'invalid_transition', 'reopen from in_review raises invalid_transition'
);
select throws_ok(
  format('select public.return_certificate(%L, %L)', t5.id('c_review'), '   '),
  'P0001', 'return_note_required', 'return with a blank note raises return_note_required'
);
select throws_ok(
  format('select public.return_certificate(%L, null)', t5.id('c_review')),
  'P0001', 'return_note_required', 'return with a null note raises return_note_required'
);
select lives_ok(
  format('select public.return_certificate(%L, %L)', t5.id('c_review'), 'fix the totals'),
  'admin returns an in_review certificate'
);
select is(
  (select (public.approve_for_signing(t5.id('c_review2'))).status::text),
  'awaiting_signature',
  'admin approves for signing; the wrapper returns the updated row'
);
select throws_ok(
  format('select public.reopen_certificate(%L, %L)', t5.id('c_approved'), '  '),
  'P0001', 'reopen_reason_required', 'reopen with a blank reason raises reopen_reason_required'
);
select lives_ok(
  format('select public.reopen_certificate(%L, %L)', t5.id('c_approved'), 'wrong amount'),
  'admin reopens an approved certificate'
);
select tests.reset_role();

-- 30-35: effects of the admin calls.
select is(
  (select array[status::text, return_note] from public.certificates where id = t5.id('c_review')),
  array['returned', 'fix the totals'],
  'return sets returned and the return note'
);
select is(
  (select array[status::text, (locked_at is null)::text, return_note] from public.certificates where id = t5.id('c_approved')),
  array['returned', 'true', null],
  'reopen sets returned, clears locked_at and does not set return_note'
);
select is(
  (select array[actor_id::text, action, before::text, after::text, reason]
   from public.audit_logs where entity_id = t5.id('c_review')),
  array[t5.id('admin')::text, 'return_certificate',
        '{"status": "in_review", "return_note": null}', '{"status": "returned", "return_note": "fix the totals"}', null],
  'return writes the audit row'
);
select is(
  (select array[actor_id::text, action, before::text, after::text, reason]
   from public.audit_logs where entity_id = t5.id('c_review2')),
  array[t5.id('admin')::text, 'approve_for_signing',
        '{"status": "in_review", "return_note": null}', '{"status": "awaiting_signature", "return_note": null}', null],
  'approve writes the audit row'
);
select is(
  (select array[actor_id::text, action, before::text, after::text, reason]
   from public.audit_logs where entity_id = t5.id('c_approved')),
  array[t5.id('admin')::text, 'reopen_certificate',
        '{"status": "approved", "return_note": null}', '{"status": "returned", "return_note": null}', 'wrong amount'],
  'reopen writes the audit row with the reason'
);
select is(
  array[t5.audit_count(t5.id('c_review')), t5.audit_count(t5.id('c_review2')),
        t5.audit_count(t5.id('c_approved')), t5.audit_count(t5.id('c_draft2'))],
  array[1, 1, 1, 0]::bigint[],
  'one audit row per successful admin call, none for the rejected calls'
);

-- 36-37: inactive site user and user without profile.
select tests.act_as(t5.id('inactive_su'));
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('c_draft2')),
  'P0001', 'forbidden', 'inactive site user calling submit raises forbidden'
);
select tests.reset_role();
select tests.act_as(t5.id('noprofile'));
select throws_ok(
  format('select public.submit_certificate(%L)', t5.id('c_draft2')),
  'P0001', 'forbidden', 'user without profile calling submit raises forbidden'
);
select tests.reset_role();

-- 38-39: s1 edits the reopened certificate, then submits c_draft2 (proves
-- the forbidden calls above were not caused by the certificate's state).
select tests.act_as(t5.id('s1'));
select is(
  t5.rows_affected(format('update public.certificates set amount = 999 where id = %L', t5.id('c_approved'))),
  1::bigint,
  'after reopen the site user can edit amount'
);
select lives_ok(format('select public.submit_certificate(%L)', t5.id('c_draft2')), 'site user submits c_draft2');
select tests.reset_role();

-- 40-41.
select is((select amount from public.certificates where id = t5.id('c_approved')), 999.00::numeric, 'reopened amount edit is stored');
select is(
  (select array[c.status::text, t5.audit_count(c.id)::text] from public.certificates c where c.id = t5.id('c_draft2')),
  array['in_review', '1'],
  'c_draft2 is in_review with exactly one audit row'
);

-- 42-50: soft delete by the site user.
select tests.act_as(t5.id('s1'));
select set_eq(
  format('select id from public.certificates where id in (%L, %L, %L, %L)',
         t5.id('d_draft'), t5.id('d_review'), t5.id('d_returned'), t5.id('d_await')),
  array[t5.id('d_draft'), t5.id('d_review'), t5.id('d_returned'), t5.id('d_await')],
  'precondition: the site user sees the four certificates before the delete'
);
select throws_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1)', t5.id('site1'), '2026-05-10'),
  '23505', null, 'precondition: the live d_draft blocks its period'
);
select lives_ok(format('select public.delete_certificate(%L, %L)', t5.id('d_draft'), 'duplicate entry'), 'site user deletes a draft');
select lives_ok(format('select public.delete_certificate(%L)', t5.id('d_review')), 'site user deletes an in_review certificate');
select lives_ok(format('select public.delete_certificate(%L)', t5.id('d_returned')), 'site user deletes a returned certificate');
select lives_ok(format('select public.delete_certificate(%L)', t5.id('d_await')), 'site user deletes an awaiting_signature certificate');
select is_empty(
  format('select id from public.certificates where id in (%L, %L, %L, %L)',
         t5.id('d_draft'), t5.id('d_review'), t5.id('d_returned'), t5.id('d_await')),
  'deleted certificates are invisible to the site user'
);
select lives_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1)', t5.id('site1'), '2026-05-10'),
  'after the soft delete the site can create a certificate for the same period'
);
select throws_ok(
  format('select public.delete_certificate(%L)', t5.id('c_approved2')),
  'P0001', 'forbidden', 'site user deleting an approved certificate raises forbidden'
);
select tests.reset_role();

-- 51: site user of another site.
select tests.act_as(t5.id('s2'));
select throws_ok(
  format('select public.delete_certificate(%L)', t5.id('c_await2')),
  'P0001', 'forbidden', 'site2 user deleting a site1 certificate raises forbidden'
);
select tests.reset_role();

-- 52-53: admin.
select tests.act_as(t5.id('admin'));
select throws_ok(
  format('select public.delete_certificate(%L, %L)', t5.id('c_await2'), 'x'),
  'P0001', 'forbidden', 'admin deleting a non-approved certificate raises forbidden'
);
select lives_ok(
  format('select public.delete_certificate(%L, %L)', t5.id('c_approved2'), 'duplicate of another'),
  'admin deletes an approved certificate'
);
select tests.reset_role();

-- 54-58: effects, checked as the session role.
select is(
  (select array_agg(status::text order by certificate_date) from public.certificates
   where id in (t5.id('d_draft'), t5.id('d_review'), t5.id('d_returned'), t5.id('d_await'))
     and deleted_at = now() and deleted_by = t5.id('s1')),
  array['draft', 'in_review', 'returned', 'awaiting_signature'],
  'the four rows still exist, soft-deleted by the site user, status unchanged'
);
select is(
  array[t5.audit_count(t5.id('d_draft')), t5.audit_count(t5.id('d_review')),
        t5.audit_count(t5.id('d_returned')), t5.audit_count(t5.id('d_await'))],
  array[1, 1, 1, 1]::bigint[],
  'one audit row per site user delete'
);
select is(
  (select array[actor_id::text, action, entity, before::text, after::text, reason]
   from public.audit_logs where entity_id = t5.id('d_draft')),
  array[t5.id('s1')::text, 'delete_certificate', 'certificate',
        '{"status": "draft", "return_note": null}', '{"status": "draft", "return_note": null}', 'duplicate entry'],
  'delete writes the audit row with the reason'
);
select is(
  (select array[c.status::text, (c.deleted_at = now())::text, c.deleted_by::text, a.actor_id::text, a.action, a.reason]
   from public.certificates c join public.audit_logs a on a.entity_id = c.id
   where c.id = t5.id('c_approved2')),
  array['approved', 'true', t5.id('admin')::text, t5.id('admin')::text, 'delete_certificate', 'duplicate of another'],
  'admin delete of an approved certificate is stored and audited once'
);
select is(
  (select array[(c.deleted_at is null)::text, t5.audit_count(c.id)::text] from public.certificates c where c.id = t5.id('c_await2')),
  array['true', '0'],
  'the rejected deletes left c_await2 live with no audit row'
);

select * from finish();
rollback;

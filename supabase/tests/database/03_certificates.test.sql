begin;
\set tests_in_transaction true
\ir _helpers.sql

select plan(52);

-- Local helpers (rolled back with the test).
-- t3.id(name): fixture id stored in a transaction-local setting, readable by any role.
create schema t3;
create function t3.id(name text)
returns uuid
language sql
stable
as $$ select current_setting('t3.' || name)::uuid $$;

-- Rows a role can see in a table; a permission error counts as 0 visible rows.
create function t3.visible_rows(rel regclass)
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

-- Rows changed by a statement (other errors propagate).
create function t3.rows_affected(stmt text)
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

grant usage on schema t3 to anon, authenticated;
grant execute on all functions in schema t3 to anon, authenticated;

-- Fixtures (created as the session role, which bypasses RLS and the guard).
select set_config('t3.admin', tests.create_user('t3-admin@example.test', 'admin')::text, true);
select set_config('t3.s1', tests.create_user('t3-s1@example.test', 'site_user')::text, true);
select set_config('t3.s2', tests.create_user('t3-s2@example.test', 'site_user')::text, true);
select set_config('t3.inactive_su', tests.create_user('t3-is@example.test', 'site_user', false)::text, true);
select set_config('t3.noprofile', tests.create_user('t3-np@example.test')::text, true);

select set_config('t3.site1', gen_random_uuid()::text, true);
select set_config('t3.site2', gen_random_uuid()::text, true);
insert into public.sites (id, code, name) values
  (t3.id('site1'), 't3-site-1', 'T3 Site 1'),
  (t3.id('site2'), 't3-site-2', 'T3 Site 2');
insert into public.user_sites (user_id, site_id) values
  (t3.id('s1'), t3.id('site1')),
  (t3.id('s2'), t3.id('site2')),
  (t3.id('inactive_su'), t3.id('site1'));

select set_config('t3.c_draft', gen_random_uuid()::text, true);
select set_config('t3.c_returned', gen_random_uuid()::text, true);
select set_config('t3.c_review', gen_random_uuid()::text, true);
select set_config('t3.c_await', gen_random_uuid()::text, true);
select set_config('t3.c_approved', gen_random_uuid()::text, true);
select set_config('t3.c_deleted', gen_random_uuid()::text, true);
select set_config('t3.c_site2', gen_random_uuid()::text, true);
insert into public.certificates (id, site_id, certificate_date, amount, status, created_by, updated_at, deleted_at, deleted_by) values
  (t3.id('c_draft'),    t3.id('site1'), '2026-01-10', 100.00, 'draft',              t3.id('s1'), '2000-01-01', null,  null),
  (t3.id('c_returned'), t3.id('site1'), '2026-01-20', 200.00, 'returned',           t3.id('s1'), now(),        null,  null),
  (t3.id('c_review'),   t3.id('site1'), '2026-02-10', 300.00, 'in_review',          t3.id('s1'), now(),        null,  null),
  (t3.id('c_await'),    t3.id('site1'), '2026-02-20', 400.00, 'awaiting_signature', t3.id('s1'), now(),        null,  null),
  (t3.id('c_approved'), t3.id('site1'), '2026-03-10', 500.00, 'approved',           t3.id('s1'), now(),        null,  null),
  (t3.id('c_deleted'),  t3.id('site1'), '2026-05-05', 600.00, 'draft',              t3.id('s1'), now(),        now(), t3.id('admin')),
  (t3.id('c_site2'),    t3.id('site2'), '2026-01-10', 700.00, 'draft',              t3.id('s2'), now(),        null,  null);

-- 1-9: structure and privileges.
select ok((select relrowsecurity from pg_class where oid = 'public.certificates'::regclass), 'RLS enabled on certificates');
select col_type_is('public', 'certificates', 'amount', 'numeric(18,2)', 'amount is numeric(18,2)');
select ok(
  (select i.indisunique and i.indpred is not null
   from pg_index i where i.indexrelid = 'public.certificates_one_per_period'::regclass),
  'certificates_one_per_period is a unique partial index'
);
select has_index('public', 'certificates', 'certificates_status_idx', 'status'::name, 'certificates has an index on status');
-- Catch-all guard for schema private. The known functions must exist (so the
-- guard below cannot pass on an empty or missing schema; 'private'::regnamespace
-- errors if the schema is gone).
select set_eq(
  $$select p.oid::regprocedure::text from pg_proc p
    where p.pronamespace = 'private'::regnamespace
      and p.oid::regprocedure::text in (
        'private.is_active_user()', 'private.is_admin()',
        'private.has_site_access(uuid)', 'private.guard_certificate_update()')$$,
  array['private.is_active_user()', 'private.is_admin()',
        'private.has_site_access(uuid)', 'private.guard_certificate_update()'],
  'schema private holds the expected helper and trigger functions'
);
-- Offenders are listed by signature and role in the failure diagnostics.
select is_empty(
  $$select p.oid::regprocedure::text || ' executable by ' || r.rolname
    from pg_proc p
    cross join (values ('anon'), ('authenticated')) as r (rolname)
    where p.pronamespace = 'private'::regnamespace
      and has_function_privilege(r.rolname, p.oid, 'execute')
      and not (
        r.rolname = 'authenticated'
        and p.oid::regprocedure::text in (
          'private.is_active_user()', 'private.is_admin()', 'private.has_site_access(uuid)',
        'private.submit_certificate(uuid)', 'private.return_certificate(uuid,text)',
        'private.approve_for_signing(uuid)', 'private.reopen_certificate(uuid,text)',
        'private.delete_certificate(uuid,text)', 'private.attachment_path_matches(text,uuid)',
        'private.path_site_id(text)', 'private.admin_list_users()',
        'private.admin_set_user_sites(uuid,uuid[])', 'private.remove_attachment(uuid,text)')
      )$$,
  'private functions are not executable by anon; only the RLS helpers, transition functions, remove_attachment, path checks and admin RPC bodies by authenticated'
);
select ok(
  not has_function_privilege('anon', 'private.guard_certificate_update()', 'execute')
  and not has_function_privilege('authenticated', 'private.guard_certificate_update()', 'execute'),
  'anon and authenticated cannot execute private.guard_certificate_update()'
);
select ok(
  not has_table_privilege('anon', 'public.certificates', 'select,insert,update,delete,truncate,references,trigger'),
  'anon has no privileges on certificates'
);
select ok(
  not has_table_privilege('authenticated', 'public.certificates', 'delete,truncate,references,trigger'),
  'authenticated has no delete/truncate/references/trigger on certificates'
);

-- 10-11: generated period columns.
select is(
  (select array[period_year, period_month, period_half] from public.certificates where id = t3.id('c_await')),
  array[2026, 2, 2]::smallint[],
  'period columns are derived from certificate_date (2026-02-20 -> 2026/2/2)'
);
select throws_ok(
  format(
    'insert into public.certificates (site_id, certificate_date, amount, created_by, period_half) values (%L, %L, 1, %L, 1)',
    t3.id('site1'), '2026-08-05', t3.id('s1')
  ),
  '428C9', null, 'inserting period_half explicitly fails (generated column)'
);

-- 12-32: active site user s1 (mapped to site1 only).
select tests.act_as(t3.id('s1'));
select set_eq(
  'select id from public.certificates',
  array[t3.id('c_draft'), t3.id('c_returned'), t3.id('c_review'), t3.id('c_await'), t3.id('c_approved')],
  'site user sees only non-deleted certificates of mapped sites'
);
select is_empty(format('select 1 from public.certificates where id = %L', t3.id('c_site2')), 'site user cannot select another site''s certificate');
select lives_ok(
  format('insert into public.certificates (site_id, certificate_date, amount, notes) values (%L, %L, 10.50, %L)', t3.id('site1'), '2026-04-05', 'n'),
  'site user can insert a certificate for a mapped site'
);
select is(
  (select array[created_by::text, status::text] from public.certificates where site_id = t3.id('site1') and certificate_date = '2026-04-05'),
  array[t3.id('s1')::text, 'draft'],
  'created_by defaults to the caller and status to draft'
);
select throws_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1)', t3.id('site1'), '2026-04-12'),
  '23505', null, 'duplicate period for the same site is rejected'
);
select lives_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1), (%L, %L, 2)',
         t3.id('site1'), '2026-06-15', t3.id('site1'), '2026-06-16'),
  'day 15 and day 16 of the same month are different periods'
);
select lives_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1)', t3.id('site1'), '2026-05-10'),
  'a soft-deleted certificate does not block its period'
);
select throws_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1)', t3.id('site2'), '2026-09-05'),
  '42501', null, 'site user cannot insert a certificate for another site'
);
select throws_ok(
  format('insert into public.certificates (site_id, certificate_date, amount, status) values (%L, %L, 1, %L)', t3.id('site1'), '2026-09-05', 'approved'),
  '42501', null, 'site user cannot insert with an explicit status'
);
select throws_ok(
  format('insert into public.certificates (site_id, certificate_date, amount, created_by) values (%L, %L, 1, %L)', t3.id('site1'), '2026-09-05', t3.id('s2')),
  '42501', null, 'site user cannot set created_by'
);
select throws_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, -1)', t3.id('site1'), '2026-09-05'),
  '23514', null, 'negative amount is rejected'
);
select is(
  t3.rows_affected(format('update public.certificates set amount = 1 where id = %L', t3.id('c_site2'))),
  0::bigint,
  'site user update of another site''s certificate affects 0 rows'
);
select is(
  t3.rows_affected(format('update public.certificates set amount = 150.25, notes = %L where id = %L', 'edited', t3.id('c_draft'))),
  1::bigint,
  'site user can edit a draft'
);
select is(
  t3.rows_affected(format('update public.certificates set amount = 250 where id = %L', t3.id('c_returned'))),
  1::bigint,
  'site user can edit a returned certificate'
);
select throws_ok(
  format('update public.certificates set certificate_date = %L where id = %L', '2026-01-25', t3.id('c_draft')),
  '23505', null, 'moving a draft into a taken period is rejected'
);
select throws_ok(
  format('update public.certificates set status = %L where id = %L', 'approved', t3.id('c_draft')),
  '42501', null, 'site user cannot update status directly'
);
select throws_ok(
  format('update public.certificates set site_id = %L where id = %L', t3.id('site2'), t3.id('c_draft')),
  '42501', null, 'site user cannot update site_id'
);
select throws_ok(
  format('update public.certificates set amount = 1 where id = %L', t3.id('c_review')),
  'P0001', 'certificate_locked', 'editing an in_review certificate raises certificate_locked'
);
select throws_ok(
  format('update public.certificates set amount = 1 where id = %L', t3.id('c_await')),
  'P0001', 'certificate_locked', 'editing an awaiting_signature certificate raises certificate_locked'
);
select throws_ok(
  format('update public.certificates set amount = 1 where id = %L', t3.id('c_approved')),
  'P0001', 'certificate_locked', 'editing an approved certificate raises certificate_locked'
);
select throws_ok(
  format('delete from public.certificates where id = %L', t3.id('c_draft')),
  '42501', null, 'site user cannot delete a certificate'
);
select tests.reset_role();

-- 33-35: effects checked as the session role.
select is((select amount from public.certificates where id = t3.id('c_site2')), 700.00::numeric, 'other site''s certificate is unchanged');
select is(
  (select array[amount::text, notes, (updated_at = now())::text] from public.certificates where id = t3.id('c_draft')),
  array['150.25', 'edited', 'true'],
  'draft edit is stored and updated_at is refreshed'
);
select is(
  (select array[status::text, site_id::text] from public.certificates where id = t3.id('c_draft')),
  array['draft', t3.id('site1')::text],
  'draft status and site_id are unchanged after the denied updates'
);

-- 36-39: active admin.
select tests.act_as(t3.id('admin'));
select isnt_empty(format('select 1 from public.certificates where id = %L', t3.id('c_site2')), 'admin sees certificates of any site');
select throws_ok(
  format('update public.certificates set amount = 1 where id = %L', t3.id('c_draft')),
  'P0001', 'admin_cannot_edit_values', 'admin editing a draft amount raises admin_cannot_edit_values'
);
select lives_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 5)', t3.id('site2'), '2026-07-05'),
  'admin can insert a certificate'
);
select is_empty(format('select 1 from public.certificates where id = %L', t3.id('c_deleted')), 'admin does not see soft-deleted certificates');
select tests.reset_role();

-- 40: same period, different site.
select tests.act_as(t3.id('s2'));
select lives_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1)', t3.id('site2'), '2026-04-05'),
  'the same period for a different site is allowed'
);
select tests.reset_role();

-- 41-42: inactive site user (still mapped to site1).
select tests.act_as(t3.id('inactive_su'));
select is(t3.visible_rows('public.certificates'), 0::bigint, 'inactive site user sees 0 certificates');
select is(
  t3.rows_affected(format('update public.certificates set amount = 1 where id = %L', t3.id('c_returned'))),
  0::bigint,
  'inactive site user update affects 0 rows'
);
select tests.reset_role();

-- 43-46: auth user without a profile. Precondition: a live site1 certificate
-- exists, so the 0-row results below cannot pass vacuously.
select is(
  (select count(*) from public.certificates where id = t3.id('c_returned') and deleted_at is null),
  1::bigint,
  'precondition: a live site1 certificate exists'
);
select tests.act_as(t3.id('noprofile'));
-- Plain queries (no helper that swallows insufficient_privilege).
select is((select count(*) from public.certificates), 0::bigint, 'user without profile sees 0 certificates');
select throws_ok(
  format('insert into public.certificates (site_id, certificate_date, amount) values (%L, %L, 1)', t3.id('site1'), '2026-10-05'),
  '42501', null, 'user without profile cannot insert a certificate'
);
select is(
  t3.rows_affected(format('update public.certificates set amount = 1 where id = %L', t3.id('c_returned'))),
  0::bigint,
  'user without profile update affects 0 rows'
);
select tests.reset_role();

-- 47: anon. anon has no usage on schema tests, so return with a plain reset role.
set local role anon;
select is(t3.visible_rows('public.certificates'), 0::bigint, 'anon sees 0 certificates');
reset role;

-- 48-50: the guard applies to authenticated/anon only; the session role
-- (as SECURITY DEFINER RPCs will) can still update a locked certificate.
select lives_ok(
  format('update public.certificates set amount = 501 where id = %L', t3.id('c_approved')),
  'session role can update an approved certificate (guard skipped)'
);
select is((select amount from public.certificates where id = t3.id('c_returned')), 250.00::numeric, 'returned edit is stored');
select is(
  (select count(*) from public.certificates where site_id = t3.id('site1') and certificate_date in ('2026-06-15', '2026-06-16')),
  2::bigint,
  'both day-15 and day-16 certificates exist'
);

-- 51-52: column grants for authenticated.
select ok(
  has_column_privilege('authenticated', 'public.certificates', 'certificate_date', 'update')
  and has_column_privilege('authenticated', 'public.certificates', 'amount', 'update')
  and has_column_privilege('authenticated', 'public.certificates', 'notes', 'update')
  and not has_column_privilege('authenticated', 'public.certificates', 'status', 'update')
  and not has_column_privilege('authenticated', 'public.certificates', 'site_id', 'update')
  and not has_column_privilege('authenticated', 'public.certificates', 'deleted_at', 'update')
  and not has_column_privilege('authenticated', 'public.certificates', 'locked_at', 'update'),
  'authenticated may update only certificate_date, amount, notes'
);
select ok(
  has_column_privilege('authenticated', 'public.certificates', 'site_id', 'insert')
  and not has_column_privilege('authenticated', 'public.certificates', 'status', 'insert')
  and not has_column_privilege('authenticated', 'public.certificates', 'created_by', 'insert')
  and not has_column_privilege('authenticated', 'public.certificates', 'deleted_at', 'insert'),
  'authenticated may insert only site_id, certificate_date, amount, notes'
);

select * from finish();
rollback;

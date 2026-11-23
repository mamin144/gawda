-- Read-only verification of supabase/seed.sql on the linked DEV database.
-- Run it before seeding (expected: FAIL, the fake data is missing) and after
-- seeding (expected: PASS).
--
-- Usage:
--   psql "$(tr -d '\r\n' < supabase/.temp/pooler-url)" -w -X \
--     -v ON_ERROR_STOP=1 -f supabase/tests/seed_verify.sql
--
-- It never writes. It raises an exception (non-zero exit with ON_ERROR_STOP)
-- when the fake seed is missing, incomplete or unsafe.

\set ON_ERROR_STOP on

do $$
declare
  v_fake_emails constant text[] := array[
    'admin@example.test',
    'site1@example.test',
    'site2@example.test'
  ];
  v_known_passwords constant text[] := array[
    'password', 'Password1', 'admin', 'admin123', 'changeme', '123456', 'test'
  ];
  v_ids uuid[];
  v_admin uuid;
  v_site1 uuid;
  v_site2 uuid;
  v_site_one uuid;
  v_site_two uuid;
  v_count integer;
  v_bad integer;
  r record;
begin
  -- 1. Three fake auth users, email-confirmed, with bcrypt hashes.
  select array_agg(u.id order by u.email), count(*)
    into v_ids, v_count
  from auth.users u
  where u.email = any (v_fake_emails);

  if v_count <> 3 then
    raise exception 'seed check: expected 3 fake auth users, found %', v_count;
  end if;

  select count(*) into v_bad
  from auth.users u
  where u.email = any (v_fake_emails)
    and (
      u.encrypted_password is null
      or u.email_confirmed_at is null
      or u.encrypted_password !~ '^\$2[aby]\$'
    );
  if v_bad > 0 then
    raise exception 'seed check: % fake user(s) missing a confirmed bcrypt password', v_bad;
  end if;

  -- 2. No known default credential is usable (insecure-defaults rule).
  select count(*) into v_bad
  from auth.users u
  cross join unnest(v_known_passwords) as p(candidate)
  where u.email = any (v_fake_emails)
    and extensions.crypt(p.candidate, u.encrypted_password) = u.encrypted_password;
  if v_bad > 0 then
    raise exception 'seed check: % fake user(s) have a known default password', v_bad;
  end if;

  -- 3. One email identity per fake user, so magic-link sign-in works.
  select count(*) into v_bad
  from auth.users u
  join auth.identities i
    on i.user_id = u.id
   and i.provider = 'email'
  where u.email = any (v_fake_emails);
  if v_bad <> 3 then
    raise exception 'seed check: expected 3 email identities, found %', v_bad;
  end if;

  -- 4. Profiles: one admin, two active site users.
  select id into v_admin from public.profiles where id = (
    select id from auth.users where email = 'admin@example.test'
  );
  select id into v_site1 from public.profiles where id = (
    select id from auth.users where email = 'site1@example.test'
  );
  select id into v_site2 from public.profiles where id = (
    select id from auth.users where email = 'site2@example.test'
  );
  if v_admin is null or v_site1 is null or v_site2 is null then
    raise exception 'seed check: profiles missing for the fake users';
  end if;

  select count(*) into v_bad
  from public.profiles
  where id in (v_admin, v_site1, v_site2)
    and is_active
    and (
      (id = v_admin and role = 'admin')
      or (id in (v_site1, v_site2) and role = 'site_user')
    );
  if v_bad <> 3 then
    raise exception 'seed check: expected 3 active profiles with the right roles, found %', v_bad;
  end if;

  -- 5. Two fake sites with the documented codes.
  select id into v_site_one from public.sites where code = 'S-001';
  select id into v_site_two from public.sites where code = 'S-002';
  if v_site_one is null or v_site_two is null then
    raise exception 'seed check: fake sites S-001 and/or S-002 are missing';
  end if;

  select count(*) into v_bad
  from public.sites
  where id in (v_site_one, v_site_two)
    and name ilike '%fake%';
  if v_bad <> 2 then
    raise exception 'seed check: fake site names must be marked fake, found %', v_bad;
  end if;

  -- 6. Site assignment: site1 -> S-001, site2 -> S-002, admin unassigned.
  select count(*) into v_bad
  from public.user_sites
  where (user_id, site_id) in ((v_site1, v_site_one), (v_site2, v_site_two));
  if v_bad <> 2 then
    raise exception 'seed check: expected 2 site assignments, found %', v_bad;
  end if;

  select count(*) into v_bad
  from public.user_sites
  where user_id = v_admin;
  if v_bad <> 0 then
    raise exception 'seed check: the fake admin must not be assigned to a site, found %', v_bad;
  end if;

  -- 7. One certificate in each status for S-001, each in its own period.
  for r in
    select expected.status as status,
           expected.certificate_date as certificate_date,
           count(c.id) as n
    from (values
      ('draft'::public.certificate_status, '2026-01-05'::date),
      ('in_review'::public.certificate_status, '2026-01-20'::date),
      ('returned'::public.certificate_status, '2026-02-03'::date),
      ('awaiting_signature'::public.certificate_status, '2026-02-17'::date),
      ('approved'::public.certificate_status, '2026-03-04'::date)
    ) as expected(status, certificate_date)
    left join public.certificates c
      on c.site_id = v_site_one
     and c.status = expected.status
     and c.certificate_date = expected.certificate_date
     and c.deleted_at is null
    group by expected.status, expected.certificate_date
  loop
    if r.n <> 1 then
      raise exception 'seed check: expected exactly one % certificate dated %, found %',
        r.status, r.certificate_date, r.n;
    end if;
  end loop;

  select count(*) into v_bad
  from public.certificates
  where site_id = v_site_one
    and deleted_at is null;
  if v_bad <> 5 then
    raise exception 'seed check: expected 5 live certificates for S-001, found %', v_bad;
  end if;

  select count(*) into v_bad
  from public.certificates
  where site_id = v_site_one
    and deleted_at is null
    and created_by = v_site1;
  if v_bad <> 5 then
    raise exception 'seed check: expected the fake site-1 user to own all 5 certificates, found %', v_bad;
  end if;

  -- 8. S-002 must stay empty (the second site exists for isolation checks).
  select count(*) into v_bad
  from public.certificates
  where site_id = v_site_two;
  if v_bad <> 0 then
    raise exception 'seed check: S-002 must have no certificates, found %', v_bad;
  end if;

  -- 9. Seed adds no attachments.
  select count(*) into v_bad from public.attachments;
  if v_bad <> 0 then
    raise exception 'seed check: seed must not create attachments, found %', v_bad;
  end if;

  raise notice 'seed check: all assertions passed';
end;
$$;

-- Evidence summary for the phase report.
select 'auth.users (fake)' as item, count(*) as n
from auth.users where email like '%@example.test'
union all
select 'profiles (fake)', count(*)
from public.profiles p
join auth.users u on u.id = p.id
where u.email like '%@example.test'
union all
select 'sites (fake)', count(*) from public.sites where code in ('S-001', 'S-002')
union all
select 'user_sites (fake)', count(*)
from public.user_sites us
join auth.users u on u.id = us.user_id
where u.email like '%@example.test'
union all
select 'certificates (S-001)', count(*)
from public.certificates c
join public.sites s on s.id = c.site_id
where s.code = 'S-001' and c.deleted_at is null
union all
select 'attachments', count(*) from public.attachments
order by item;

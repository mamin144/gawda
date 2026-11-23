-- Development seed: fake data only, never real financial records.
--
-- Applied by `supabase db push --include-seed` (see [db.seed] in config.toml).
-- It is idempotent: every insert uses fixed UUIDs and `on conflict do nothing`,
-- so running it twice changes nothing. Verified read-only by
-- supabase/tests/seed_verify.sql.
--
-- Contents:
--   * 3 fake auth users (admin, site1, site2) with random bcrypt passwords and
--     one email identity each, so magic-link sign-in works in development.
--   * 2 fake sites: S-001 (owned by site1) and S-002 (owned by site2, kept
--     empty for cross-site isolation checks).
--   * 5 certificates on S-001, one per status, each in its own half-month
--     period, so every UI state and transition path can be exercised.
--   * No attachments and no audit rows: those are produced by the app/RPCs.
--
-- The passwords are random and unrecoverable on purpose (insecure-defaults):
-- no known default credential exists. To sign in, reset the password through
-- the local auth flow instead of reusing a shared secret.

begin;

-- ---------------------------------------------------------------------------
-- Fake auth users
-- ---------------------------------------------------------------------------
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '5eed0000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'admin@example.test',
    extensions.crypt(gen_random_uuid()::text, extensions.gen_salt('bf', 10)),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Fake Admin"}'::jsonb,
    now(),
    now(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '5eed0000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'site1@example.test',
    extensions.crypt(gen_random_uuid()::text, extensions.gen_salt('bf', 10)),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Fake Site One User"}'::jsonb,
    now(),
    now(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '5eed0000-0000-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'site2@example.test',
    extensions.crypt(gen_random_uuid()::text, extensions.gen_salt('bf', 10)),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Fake Site Two User"}'::jsonb,
    now(),
    now(),
    '',
    '',
    '',
    ''
  )
on conflict (id) do nothing;

-- One email identity per fake user (required by the auth flow).
insert into auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
values
  (
    '5eed0000-0000-4000-8000-000000000001',
    '5eed0000-0000-4000-8000-000000000001',
    '{"sub":"5eed0000-0000-4000-8000-000000000001","email":"admin@example.test","email_verified":true,"phone_verified":false}'::jsonb,
    'email',
    now(),
    now(),
    now()
  ),
  (
    '5eed0000-0000-4000-8000-000000000002',
    '5eed0000-0000-4000-8000-000000000002',
    '{"sub":"5eed0000-0000-4000-8000-000000000002","email":"site1@example.test","email_verified":true,"phone_verified":false}'::jsonb,
    'email',
    now(),
    now(),
    now()
  ),
  (
    '5eed0000-0000-4000-8000-000000000003',
    '5eed0000-0000-4000-8000-000000000003',
    '{"sub":"5eed0000-0000-4000-8000-000000000003","email":"site2@example.test","email_verified":true,"phone_verified":false}'::jsonb,
    'email',
    now(),
    now(),
    now()
  )
on conflict (provider_id, provider) do nothing;

-- ---------------------------------------------------------------------------
-- Profiles
-- ---------------------------------------------------------------------------
insert into public.profiles (id, full_name, role, is_active)
values
  ('5eed0000-0000-4000-8000-000000000001', 'Fake Admin', 'admin', true),
  ('5eed0000-0000-4000-8000-000000000002', 'Fake Site One User', 'site_user', true),
  ('5eed0000-0000-4000-8000-000000000003', 'Fake Site Two User', 'site_user', true)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Sites
-- ---------------------------------------------------------------------------
insert into public.sites (id, code, name, is_active)
values
  ('5eed0000-0000-4000-8000-000000000011', 'S-001', 'Fake Site One (seed)', true),
  ('5eed0000-0000-4000-8000-000000000012', 'S-002', 'Fake Site Two (seed)', true)
on conflict (id) do nothing;

-- site1 -> S-001, site2 -> S-002, admin unassigned (admins see every site).
insert into public.user_sites (user_id, site_id)
values
  ('5eed0000-0000-4000-8000-000000000002', '5eed0000-0000-4000-8000-000000000011'),
  ('5eed0000-0000-4000-8000-000000000003', '5eed0000-0000-4000-8000-000000000012')
on conflict (user_id, site_id) do nothing;

-- ---------------------------------------------------------------------------
-- Certificates on S-001: one per status, one per half-month period.
-- submitted_at / locked_at mirror what the RPCs would have set.
-- ---------------------------------------------------------------------------
insert into public.certificates (
  id,
  site_id,
  certificate_date,
  amount,
  notes,
  status,
  return_note,
  created_by,
  submitted_at,
  locked_at
)
values
  (
    '5eed0000-0000-4000-8000-000000000021',
    '5eed0000-0000-4000-8000-000000000011',
    '2026-01-05',
    1250000.00,
    'Fake draft certificate (seed)',
    'draft',
    null,
    '5eed0000-0000-4000-8000-000000000002',
    null,
    null
  ),
  (
    '5eed0000-0000-4000-8000-000000000022',
    '5eed0000-0000-4000-8000-000000000011',
    '2026-01-20',
    1310500.50,
    'Fake certificate under review (seed)',
    'in_review',
    null,
    '5eed0000-0000-4000-8000-000000000002',
    '2026-01-21 09:15:00+00',
    null
  ),
  (
    '5eed0000-0000-4000-8000-000000000023',
    '5eed0000-0000-4000-8000-000000000011',
    '2026-02-03',
    1180000.00,
    'Fake returned certificate (seed)',
    'returned',
    'Fake return note (seed): the total does not match the attachments.',
    '5eed0000-0000-4000-8000-000000000002',
    '2026-02-04 10:00:00+00',
    null
  ),
  (
    '5eed0000-0000-4000-8000-000000000024',
    '5eed0000-0000-4000-8000-000000000011',
    '2026-02-17',
    1422750.75,
    'Fake certificate awaiting signature (seed)',
    'awaiting_signature',
    null,
    '5eed0000-0000-4000-8000-000000000002',
    '2026-02-18 08:30:00+00',
    null
  ),
  (
    '5eed0000-0000-4000-8000-000000000025',
    '5eed0000-0000-4000-8000-000000000011',
    '2026-03-04',
    1600000.00,
    'Fake approved certificate (seed)',
    'approved',
    null,
    '5eed0000-0000-4000-8000-000000000002',
    '2026-03-05 07:45:00+00',
    '2026-03-06 12:00:00+00'
  )
on conflict do nothing;

commit;

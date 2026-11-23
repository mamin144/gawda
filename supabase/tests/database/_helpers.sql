-- Shared pgTAP helpers. Include from a test file right after `begin;`:
--   \set tests_in_transaction true
--   \ir _helpers.sql
-- Everything below is created inside the test transaction and disappears
-- with its `rollback;`. The guard stops this file from creating objects
-- outside a test transaction (for example if a runner executes it alone).
\if :{?tests_in_transaction}
\else
\echo '_helpers.sql is an include file; it does nothing when run on its own.'
\quit
\endif

create schema if not exists tests;

-- Creates an auth user and returns its id. Task 2 adds the profile insert.
create or replace function tests.create_user(email text)
returns uuid
language plpgsql
as $$
declare
  new_id uuid := gen_random_uuid();
begin
  insert into auth.users (id, instance_id, aud, role, email)
  values (
    new_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    email
  );
  return new_id;
end;
$$;

-- Acts as a signed-in user for the rest of the transaction.
create or replace function tests.act_as(uid uuid)
returns void
language plpgsql
as $$
begin
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text,
    true
  );
end;
$$;

-- Acts as the service_role for the rest of the transaction.
create or replace function tests.act_as_service()
returns void
language plpgsql
as $$
begin
  set local role service_role;
end;
$$;

-- Returns to the session role (the role that runs the tests) and clears
-- the JWT claims set by act_as.
create or replace function tests.reset_role()
returns void
language plpgsql
as $$
begin
  reset role;
  perform set_config('request.jwt.claims', '', true);
end;
$$;

-- The helpers must stay callable after switching role.
grant usage on schema tests to authenticated, service_role;
grant execute on all functions in schema tests to authenticated, service_role;

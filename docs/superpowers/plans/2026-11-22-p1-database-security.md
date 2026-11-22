# P1 Database and Security Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Supabase schema, RLS, status-transition RPCs, append-only audit log, private storage, and two Edge Functions. Each piece is proven by pgTAP tests, and the Supabase advisors report no critical findings.

**Architecture:** Imperative SQL migrations in `supabase/migrations/`, each created with `supabase migration new`.
- Authorization helpers are `SECURITY DEFINER` functions in a non-exposed `private` schema, with `search_path = ''`.
- Client-callable RPCs in `public` are `SECURITY INVOKER` wrappers that delegate to `private`.
- Status, lock and period columns cannot be written by clients. Column grants and a guard trigger enforce this.
- Service-role work (creating users, deleting the initial file) happens only inside Edge Functions.

**Tech Stack:** Supabase CLI 3.2.0, PostgreSQL 17 (Supabase), pgTAP (`supabase test db`), Supabase Storage, Edge Functions (Deno, `npm:@supabase/supabase-js@2` pinned).

**Spec:**
- `docs/PROJECT_PLAN.md` sections 2, 3, 4, 5, 7, 8;
- `docs/OPENCODE_PROMPT.md` section 3 "P1 Database and security";
- `AGENTS.md`.

## Test Environment (owner decision, 22 November 2026)

Tests and migrations run **remotely on the DEV project** (`kbjsonvnbbhvczttvzhv`); there is no local Docker stack.
- One-time: the owner runs `supabase link --project-ref kbjsonvnbbhvczttvzhv` and types the DB password in the terminal (never in chat, never stored in the repo).
- Apply: `supabase db push --dry-run`, then `supabase db push` (asks for approval every time).
- Test: `supabase test db --remote`. Every pgTAP file runs in one transaction ending in `rollback`, so test users, sites and objects never persist on DEV.
- Advisors: `supabase db advisors --remote --type all` and MCP `get_advisors`.
- Migrations are forward-only: a pushed migration is never edited. A mistake is fixed by a new migration. `supabase db reset` stays denied.
- Before each push, the task's migration is reviewed against its tests (RED first: tests run against DEV before the push and must fail for the expected reason).
- Risk to check in Task 0: if `supabase test db --remote` still needs Docker for `pg_prove` on CLI 3.2.0, STOP and report; the fallback is running each test file with `psql` against the linked DB, with the owner's approval.

## Global Constraints

- RLS enabled on every table; every table has tests. Never use `user_metadata` for authorization.
- `amount numeric(18,2)`. No `double`/`float`/`real` for money. No derived financial totals (G1). No extra certificate fields (G2).
- Period rule:
  - day 1-15 → half 1; day 16 to month end → half 2;
  - the period comes from `certificate_date`, not the upload date;
  - unique `(site_id, period_year, period_month, period_half)`.
- Statuses: `draft`, `in_review`, `returned`, `awaiting_signature`, `approved`. Roles: `admin`, `site_user`. Attachment kinds: `initial`, `signed`.
- Status changes only through RPCs. Each transition writes one `audit_logs` row.
- The admin never edits entered values. The admin cannot upload the signed copy.
- Soft delete for financial records. The only hard delete is the initial file's storage object; its metadata row stays.
- Storage:
  - private bucket;
  - path `site_id/year/month/half/unique_name`;
  - PDF/JPG/PNG only (`application/pdf`, `image/jpeg`, `image/png`);
  - max 2 MB (2097152 bytes);
  - SHA-256 dedup.
- `audit_logs` is append-only: no UPDATE or DELETE for anyone.
- `service_role` is used only in Edge Functions. `seed.sql` holds fake data only.
- Never run `supabase db reset` (deny rule) or destructive remote commands. `supabase link` and `supabase db push` are run or approved by the owner.
- Code, identifiers and comments in English. User-facing error messages are stable error codes (e.g. `P0001` + `message = 'certificate_locked'`) that P2 maps to Arabic l10n. No Arabic strings in SQL.

## Review Focus

1. **Malformed storage path** (non-UUID first segment, missing segments, `..`): the policy must return false (deny), never raise a cast error. Owner: Task 7.
2. **Inactive user or user with no `profiles` row** but a valid JWT: denied everywhere. Owner: Task 2 (helpers) and Task 3 (certificates).
3. **Changing `certificate_date` of a draft into a period the site already has**: unique violation. Changing `site_id` of an existing certificate: denied. Owner: Task 3.
4. **Double or retried `finalize-certificate` call**: the second call does not fail half-way and does not write a second transition audit row. Owner: Task 8.
5. **Same file re-uploaded** (same sha256) to the same or another certificate while the first is active: rejected. Owner: Task 6.

---

## File Structure

```
supabase/
  config.toml                         (supabase init)
  seed.sql                            fake data only
  migrations/
    <ts>_enums_and_period.sql         enums + public.period_half(date)
    <ts>_profiles_sites.sql           private schema, helpers, profiles, sites, user_sites, RLS
    <ts>_certificates.sql             certificates, column grants, guard trigger, RLS
    <ts>_audit_logs.sql               audit_logs, append-only trigger, RLS
    <ts>_transitions.sql              private + public transition RPCs
    <ts>_attachments.sql              attachments, checks, dedup index, RLS
    <ts>_storage.sql                  bucket + storage.objects policies
    <ts>_finalize.sql                 service-only finalize + record-deleted RPCs
  tests/database/
    _helpers.sql                      test users/sites, act_as(uuid), act_as_service()
    00_smoke.test.sql ... 08_finalize.test.sql
  functions/
    _shared/auth.ts                   caller resolution (JWT -> profile)
    admin-create-user/index.ts, handler.ts, handler_test.ts
    finalize-certificate/index.ts, handler.ts, handler_test.ts
```

---

### Task 0: Scaffold and test harness

**Files:** Create `supabase/config.toml` (via `supabase init`), `supabase/tests/database/_helpers.sql`, `supabase/tests/database/00_smoke.test.sql`.

**Interfaces — Produces** (in `_helpers.sql`, created inside each test transaction):
- `tests.create_user(email text, role user_role default null, active bool default true) returns uuid`: inserts into `auth.users` and, if role is given, into `profiles`.
- `tests.act_as(uid uuid)`: `set local role authenticated` plus `request.jwt.claims` with `sub` and `role`.
- `tests.act_as_service()`: `set local role service_role`.
- `tests.reset_role()`: `reset role`.

Task 0 adds only `create_user` without the profile step. The profile insert is added in Task 2.

- [ ] Step 1: Fetch `https://supabase.com/changelog.md`. Note any `breaking-change` entries for RLS, Storage, Data API grants, pgTAP or Edge Functions in `docs/SKILLS_LOG.md`.
- [ ] Step 2: Run `supabase init` (non-interactive). Keep `config.toml` defaults. Set `[storage] file_size_limit = "2MiB"`.
- [ ] Step 3: Write `00_smoke.test.sql`: `\ir _helpers.sql`, then `select plan(2); select has_extension('pgtap'); select has_schema('tests'); select * from finish(); rollback;`. If `\ir` is unsupported by the runner, inline the helper block in each file; record this in the plan.
- [ ] Step 4: Migration `supabase migration new enable_pgtap` with `create extension if not exists pgtap with schema extensions`. `supabase db push`, then `supabase test db --remote`. Expected: `00_smoke ... ok`, `Result: PASS`.
- [ ] Step 5: Commit `chore(p1): init supabase project and pgTAP harness`.

### Task 1: Enums and period function

**Files:** migration `enums_and_period` and test `01_period.test.sql`.

**Interfaces — Produces:**
- `create type public.user_role as enum ('admin','site_user')`
- `create type public.certificate_status as enum ('draft','in_review','returned','awaiting_signature','approved')`
- `create type public.attachment_kind as enum ('initial','signed')`
- `public.period_half(d date) returns smallint`: `immutable`, `strict`, `parallel safe`, `security invoker`, `set search_path = ''`.

- [ ] Step 1: Write the failing tests:
  - `period_half` returns 1 for `2025-01-01`, `2025-01-15`, `2024-02-15`.
  - It returns 2 for:
    - `2025-01-16`, `2025-01-31` (31-day month);
    - `2025-04-30` (30-day month);
    - `2025-02-28` (28-day month);
    - `2024-02-29` (29-day month);
    - `2025-02-16`.
  - `period_half(null)` is null.
  - `has_type` for the three enums with `enum_has_labels` exact label order.
- [ ] Step 2: `supabase test db --remote`. Expected: FAIL (function missing).
- [ ] Step 3: `supabase migration new enums_and_period` and implement: `case when extract(day from d) <= 15 then 1 else 2 end`.
- [ ] Step 4: `supabase db push` then `supabase test db --remote`. Expected: PASS.
- [ ] Step 5: Commit `feat(p1): add enums and period derivation function`.

### Task 2: Profiles, sites, user_sites, authorization helpers

**Files:** migration `profiles_sites` and test `02_profiles_sites.test.sql`.

**Interfaces — Produces:**
- Schema `private`: revoke all from public; `grant usage` to `authenticated`, `service_role`.
- Tables:
  - `public.profiles(id uuid pk references auth.users on delete restrict, full_name text not null, role user_role not null, is_active bool not null default true, created_at, updated_at timestamptz not null default now())`
  - `public.sites(id uuid pk default gen_random_uuid(), code text not null unique, name text not null, is_active bool not null default true, archived_at timestamptz, created_at, updated_at)`
  - `public.user_sites(user_id uuid references profiles, site_id uuid references sites, created_at, primary key (user_id, site_id))`, plus an index on `site_id`
- Helpers (`security definer`, `stable`, `set search_path = ''`, use `(select auth.uid())`; `revoke execute from public`; `grant execute to authenticated`):
  - `private.is_active_user() returns bool`: a profile exists and `is_active`.
  - `private.is_admin() returns bool`: active and `role = 'admin'`.
  - `private.has_site_access(p_site uuid) returns bool`: active admin, or an active `site_user` with a `user_sites` row.
- Trigger `private.set_updated_at()` on every table that has `updated_at`.
- RLS (all policies `to authenticated`):
  - `profiles`: SELECT own row or admin. UPDATE admin only (USING + WITH CHECK). No INSERT/DELETE policy; Edge Function inserts.
  - `sites`: SELECT if `has_site_access(id)`. INSERT/UPDATE admin. No DELETE (archive instead).
  - `user_sites`: SELECT own rows or admin. INSERT/DELETE admin (a mapping is not a financial record).
- Grants: explicit `grant select, insert, update` per table to `authenticated` matching the policies. No grants to `anon`.

Tests (write first, watch them fail):
- A site user sees only their own profile.
- An admin sees all profiles.
- A site user's `update profiles set role='admin'` affects 0 rows / is denied.
- A site user sees only mapped sites.
- An unmapped site is invisible.
- Inactive users (both roles) see 0 sites and 0 profiles, and `private.is_admin()` is false for an inactive admin.
- An auth user without a profile sees nothing.
- `anon` selects from each table and gets a permission error or 0 rows.
- `has_function_privilege('anon', 'private.is_admin()', 'execute')` is false.
- `rls enabled` on every table.

- [ ] Steps:
  1. Tests.
  2. Run; FAIL.
  3. Migration.
  4. `supabase db push` + `supabase test db --remote`; PASS.
  5. Commit `feat(p1): profiles, sites, user_sites with RLS helpers`.

### Task 3: Certificates

**Files:** migration `certificates` and test `03_certificates.test.sql`.

**Interfaces — Produces:**
- Table `public.certificates`:
  - `id uuid pk default gen_random_uuid()`
  - `site_id uuid not null references sites`
  - `certificate_date date not null`
  - `period_year smallint generated always as (extract(year from certificate_date)::smallint) stored`
  - `period_month smallint generated always as (extract(month from certificate_date)::smallint) stored`
  - `period_half smallint generated always as (public.period_half(certificate_date)) stored`
  - `amount numeric(18,2) not null check (amount >= 0)`
  - `notes text`
  - `status certificate_status not null default 'draft'`
  - `return_note text`
  - `created_by uuid not null default auth.uid() references profiles`
  - `submitted_at timestamptz`, `locked_at timestamptz`
  - `deleted_at timestamptz`, `deleted_by uuid references profiles`
  - `created_at`, `updated_at`
  - uniqueness: `create unique index certificates_one_per_period on certificates (site_id, period_year, period_month, period_half) where deleted_at is null` (a soft-deleted certificate does not block its period; Q13)
- Column grants for `authenticated`:
  - `grant select` on all columns;
  - `grant insert (site_id, certificate_date, amount, notes)`;
  - `grant update (certificate_date, amount, notes)`;
  - no DELETE.
- Guard trigger `private.guard_certificate_update()` (BEFORE UPDATE). When `current_user` is `authenticated` or `anon`:
  - raise `certificate_locked` if `old.status` is not in (`draft`, `returned`);
  - raise `admin_cannot_edit_values` if the caller is an admin.

  RPCs run as the definer, so they pass.
- RLS (`to authenticated`):
  - SELECT: `has_site_access(site_id)` and `deleted_at is null`.
  - INSERT WITH CHECK: `has_site_access(site_id)` and `status = 'draft'`. Admin insert is allowed per plan section 3 "إدخال شهادة ✅".
  - UPDATE: USING and WITH CHECK both `has_site_access(site_id)`. The admin is rejected by the guard trigger rather than by RLS, so the caller gets an explicit `admin_cannot_edit_values` error instead of a silent 0-row update.
- Indexes: `site_id` is covered by the unique constraint's leading column. Add an index on `status`.

Tests:
- A duplicate period for the same site raises `23505`.
- The same period for different sites is OK.
- Day 15 and day 16 of the same month are different periods.
- Updating a draft's date into a taken period raises `23505`.
- The site user of site A cannot select, insert or update site B certificates.
- Direct `update certificates set status='approved'` raises `42501`.
- `update ... set site_id` raises `42501`.
- Editing `amount` in `in_review`, `awaiting_signature` or `approved` raises `certificate_locked`.
- An admin updating `amount` on a draft raises `admin_cannot_edit_values`.
- `delete` raises `42501`.
- Inserting with `period_half` explicitly raises an error (generated column).
- The `amount` column type is `numeric(18,2)` (`col_type_is`).
- An inactive site user sees 0 rows.

- [ ] Steps: as in Task 2. Commit `feat(p1): certificates with period uniqueness and edit guard`.

### Task 4: Audit log (append-only)

**Files:** migration `audit_logs` and test `04_audit.test.sql`.

**Interfaces — Produces:**
- `public.audit_logs(id bigint generated always as identity pk, actor_id uuid references profiles, action text not null, entity text not null, entity_id uuid not null, before jsonb, after jsonb, reason text, created_at timestamptz not null default now())`, plus an index on `(entity, entity_id)`.
- `private.write_audit(p_action text, p_entity text, p_entity_id uuid, p_before jsonb, p_after jsonb, p_reason text) returns void`: security definer; actor is `(select auth.uid())`, or an explicit `p_actor` overload for service calls. Grants: `revoke execute from public`; no grant to `authenticated`, so it is called only by other definer functions.
- Trigger `private.forbid_audit_mutation()` BEFORE UPDATE OR DELETE plus BEFORE TRUNCATE (statement level): raises `audit_log_append_only` for every role, including `postgres`.
- RLS: SELECT admin only. No INSERT/UPDATE/DELETE policies. `grant select` to `authenticated` only.

Tests:
- A site user selects 0 rows.
- The admin sees inserted rows.
- `update`/`delete`/`truncate` raise errors as `authenticated`, as `service_role` and as `postgres`.
- `authenticated` cannot `insert` directly.

- [ ] Steps: as in Task 2. Commit `feat(p1): append-only audit log`.

### Task 5: Status-transition RPCs

**Files:** migration `transitions` and test `05_transitions.test.sql`.

**Interfaces — Produces.** Each is a `private.*` security definer function plus a `public.*` security invoker wrapper with the same signature. Each returns `public.certificates`, locks the row `for update`, checks role, site access and the current status, and writes one audit row (`action` = function name, before/after = `{status, return_note}`).

| Function | Caller | From → To | Extra |
|---|---|---|---|
| `submit_certificate(p_id uuid)` | site_user with site access | `draft`/`returned` → `in_review` | sets `submitted_at = now()` |
| `return_certificate(p_id uuid, p_note text)` | admin | `in_review` → `returned` | `p_note` non-blank, else `return_note_required`; sets `return_note` |
| `approve_for_signing(p_id uuid)` | admin | `in_review` → `awaiting_signature` | |
| `reopen_certificate(p_id uuid, p_reason text)` | admin | `approved` → `returned` | `p_reason` non-blank, else `reopen_reason_required`; clears `locked_at`; reason goes to the audit row |
| `delete_certificate(p_id uuid, p_reason text default null)` | site_user with site access, status not `approved`; admin, status `approved` (Q13) | soft delete: sets `deleted_at`, `deleted_by` (status unchanged) | `already_deleted` if `deleted_at` is set; reason goes to the audit row; attachments and files are kept |

Errors: `forbidden` (wrong role or no site access), `invalid_transition` (wrong from-status), `not_found`.

Grants:
- `public.*` wrappers: `revoke execute from public, anon`; `grant execute to authenticated`.
- `private.*`: `grant execute to authenticated`. Not reachable over the API because `private` is not exposed.

Tests:
- Each happy path ends in the right status with exactly 1 new audit row.
- A site user calling return/approve/reopen gets `forbidden`.
- An admin calling submit gets `forbidden`.
- A site user of site B calling submit on site A's certificate gets `forbidden`.
- Submit from `in_review` gets `invalid_transition`.
- Return with a blank note gets `return_note_required`.
- Reopen with a blank reason gets `reopen_reason_required`.
- After reopen, the site user can edit `amount`.
- `anon` cannot execute the wrappers.
- A site user deletes a certificate in `draft`, `in_review`, `returned` and `awaiting_signature`: the row becomes invisible to them, the row still exists (checked as `postgres`), and there is 1 audit row.
- A site user deleting an `approved` certificate gets `forbidden`. An admin deleting an `approved` certificate succeeds.
- After a soft delete, the site can create a new certificate for the same period only if the unique key ignores deleted rows (see Task 3 change below).

- [ ] Steps: as in Task 2. Commit `feat(p1): status transition RPCs with audit`.

### Task 6: Attachments

**Files:** migration `attachments` and test `06_attachments.test.sql`.

**Interfaces — Produces:**
- `public.attachments`:
  - `id uuid pk default gen_random_uuid()`
  - `certificate_id uuid not null references certificates`
  - `kind attachment_kind not null`
  - `storage_path text not null unique`
  - `file_name text not null`
  - `mime text not null check (mime in ('application/pdf','image/jpeg','image/png'))`
  - `size_bytes integer not null check (size_bytes between 1 and 2097152)`
  - `sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$')`
  - `uploaded_by uuid not null default auth.uid() references profiles`
  - `uploaded_at timestamptz not null default now()`
  - `deleted_at timestamptz`, `deleted_by uuid references profiles`, `delete_reason text`
- Dedup: `create unique index on attachments (sha256) where deleted_at is null`.
- `private.attachment_path_matches(p_path text, p_certificate_id uuid) returns bool`: the path's first four segments equal the certificate's `site_id/period_year/period_month/period_half`.
- RLS (`to authenticated`):
  - SELECT: `has_site_access` of the parent certificate.
  - INSERT WITH CHECK, all of:
    - site access;
    - path matches;
    - `uploaded_by = auth.uid()`;
    - either `kind = 'initial'` with parent status in (`draft`, `returned`), or `kind = 'signed'` with parent status `awaiting_signature` and the caller not an admin.
  - No UPDATE/DELETE policies or grants.

  `grant select, insert (certificate_id, kind, storage_path, file_name, mime, size_bytes, sha256)` to `authenticated`.

Tests:
- Wrong mime raises `23514`.
- 2097153 bytes raises `23514`.
- A bad sha raises `23514`.
- Duplicate active sha raises `23505`.
- An admin inserting `signed` is denied.
- A site user inserting `signed` while in `draft` is denied.
- Inserting `initial` while in `in_review` is denied.
- Cross-site insert/select is denied.
- A path whose period doesn't match the certificate is denied.
- `update`/`delete` raise `42501`.

- [ ] Steps: as in Task 2. Commit `feat(p1): attachments table with upload rules`.

### Task 7: Storage bucket and policies

**Files:** migration `storage` and test `07_storage.test.sql`.

**Interfaces — Produces:**
- `insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('certificates','certificates', false, 2097152, array['application/pdf','image/jpeg','image/png']) on conflict (id) do nothing`.
- `private.path_site_id(p_name text) returns uuid`: returns the first segment as a uuid, or null if it doesn't parse. Never raises. Requires exactly 5 segments, no `..`, year 4 digits, month 1-12, half 1-2.
- `storage.objects` policies (`to authenticated`, `bucket_id = 'certificates'`):
  - SELECT: `private.has_site_access(private.path_site_id(name))`.
  - INSERT WITH CHECK: same.
  - No UPDATE or DELETE policies. No upsert; the initial file is deleted only by the service role.

Tests:
- A site user can insert and select an object under their own site's path.
- Another site's path is denied.
- `'not-a-uuid/2025/1/1/x.pdf'` is denied without error.
- `'<uuid>/../x'` is denied.
- Delete as `authenticated` affects 0 rows.
- The bucket is not public.

- [ ] Steps: as in Task 2. Commit `feat(p1): private certificates bucket with site isolation`.

### Task 8: Finalize RPCs and `finalize-certificate` Edge Function

**Files:**
- migration `finalize` and test `08_finalize.test.sql`;
- `supabase/functions/_shared/auth.ts`;
- `supabase/functions/finalize-certificate/{index.ts,handler.ts,handler_test.ts}`.

**Interfaces — Produces (SQL).** Both functions are security definer in `public`, granted to `service_role` only (`revoke` from `public`, `anon`, `authenticated`):

- `finalize_with_signed_copy(p_id uuid, p_actor uuid) returns table(attachment_id uuid, storage_path text)`. It checks:
  - `p_actor` is an active `site_user` with site access;
  - the status is `awaiting_signature`;
  - an active `signed` attachment exists;
  - its object exists in `storage.objects` (`bucket_id = 'certificates' and name = storage_path`).

  Then it sets `status = 'approved'` and `locked_at = now()`, writes an audit row (actor `p_actor`), and returns the active `initial` attachments.

  If the status is already `approved`, it returns the still-active initial attachments without a new audit row. This makes retries idempotent.
- `record_initial_file_deleted(p_attachment_id uuid, p_actor uuid) returns void`: sets `deleted_at`, `deleted_by`, `delete_reason = 'replaced_by_signed_copy'` on an `initial` row of an `approved` certificate and writes an audit row. It is a no-op if the row is already deleted.

**Interfaces — Produces (TS).**
- `handleFinalize(req: Request, deps: { userClient(jwt): SupabaseClient; serviceClient: SupabaseClient }): Promise<Response>`.
- Body: `{ certificate_id: string }`.
- Responses:
  - 200 `{ status: 'approved', deleted_initial: number }`;
  - 401 when there is no or an invalid JWT;
  - 403 for `forbidden`;
  - 409 for `invalid_transition` / `signed_copy_missing`;
  - 500 with `{ error: 'initial_delete_failed' }` when storage removal fails. The certificate stays approved and a retry cleans up.
- Flow:
  1. `getUser(jwt)`.
  2. `rpc finalize_with_signed_copy`.
  3. For each returned row, `storage.from('certificates').remove([path])`.
  4. Then `rpc record_initial_file_deleted`.

pgTAP tests:
- `authenticated` cannot execute either function.
- Finalize without a signed attachment raises `signed_copy_missing`.
- Finalize with a signed row but no storage object raises `signed_copy_missing`.
- The happy path gives `approved` with `locked_at` set, and returns the initial path.
- A second call returns the same path and the audit count is unchanged.
- An admin as `p_actor` gets `forbidden`.
- `record_initial_file_deleted` keeps the row with `deleted_at` set.
- After `approved`, a site user's update raises `certificate_locked`.
- Previous signed rows remain after `reopen` + second finalize.

Deno tests (`handler_test.ts`, fake clients):
- 401 without a JWT.
- 403 maps from an RPC `forbidden`.
- A storage failure gives 500 and does not call `record_initial_file_deleted`.
- The happy path calls remove, then record, in order.

Steps:
- [ ] SQL test first, run (FAIL), migration, run (PASS).
- [ ] Deno test first, run `deno test supabase/functions/finalize-certificate` (FAIL), handler, run (PASS).
- [ ] Commit `feat(p1): finalize-certificate edge function and service RPCs`.

### Task 9: `admin-create-user` Edge Function

**Files:** `supabase/functions/admin-create-user/{index.ts,handler.ts,handler_test.ts}`.

**Interfaces:**
- Consumes `_shared/auth.ts`.
- Produces `handleCreateUser(req, deps)`.
- Body: `{ email: string, full_name: string, role: 'admin'|'site_user', site_ids?: string[] }`.
- Flow:
  1. Resolve the caller. It must be an active admin, checked by reading `profiles` with the caller's user-scoped client so RLS applies. Otherwise 403.
  2. Validate the body: 400 on bad email, empty name, unknown role, or non-uuid site ids.
  3. `serviceClient.auth.admin.inviteUserByEmail(email, { redirectTo })` (Q11: email invite). `redirectTo` comes from the `INVITE_REDIRECT_URL` function secret; if it is missing the function returns 500 `config_missing` (no fallback URL). DEV needs Auth SMTP or the built-in mailer (rate-limited, fine for DEV); the owner sets this in the dashboard.
  4. Insert `profiles` and `user_sites` with the service client.
  5. On failure after the user is created, delete that auth user (compensation) and return 500.
  6. Return 201 `{ id }`.

  The function writes an audit row through a service-only SQL function `public.audit_user_created(p_user uuid, p_actor uuid)`, added in this task's migration.
- Deno tests:
  - 401, 403 for a site_user, 403 for an inactive admin;
  - 400 cases;
  - 201 happy path;
  - compensation on a profile insert failure.

Steps: Deno test first (FAIL), handler, PASS, commit `feat(p1): admin-create-user edge function`.

### Task 10: Seed data (fake only)

**Files:** `supabase/seed.sql`.

- Fake auth users (`admin@example.test`, `site1@example.test`, `site2@example.test`). Passwords are generated with `crypt(gen_random_uuid()::text, gen_salt('bf'))`, so no known password exists. Local sign-in is done by the owner through Studio "send magic link" or by resetting the password.
- Fake sites `S-001`/`S-002`.
- One certificate in each status for site 1.
- No real names, no Excel data.

Apply with `supabase db push --include-seed` (owner approval), check the rows with MCP `execute_sql` (read-only), then `supabase test db --remote`: PASS. Seed must be idempotent (`on conflict do nothing`). Commit `chore(p1): fake seed data`.

### Task 11: Advisors, DEV push, evidence

- [ ] `supabase db advisors --remote --type all --level info`. Fix every security finding (new migration) and re-run until there are 0 security issues.
- [ ] MCP `get_advisors` (security and performance) on DEV. Fix and re-run until there are no ERROR/critical items. Record the remaining WARN items with a justification.
- [ ] MCP `list_tables` shows six tables with `rls_enabled: true`.
- [ ] Deploy functions: `supabase functions deploy admin-create-user` and `supabase functions deploy finalize-certificate` (`--use-api` if Docker is unavailable). Requires owner approval.
- [ ] Full verification: `supabase test db --remote` and `deno test supabase/functions`, with the output summary recorded.
- [ ] Update `docs/PROGRESS.md` and `docs/SKILLS_LOG.md` (SKILLS APPLIED). Write the P1 report. Commit `docs(p1): phase report and evidence`.

---

## New open questions raised by this plan

- **Q11 (answered 22 Nov 2026):** new users get an email invite.
- **Q12 (answered 22 Nov 2026):** keep the assumption (the site user submits); the owner will check it when testing.
- **Q13 (answered 22 Nov 2026):** the site user can delete a certificate until it is approved; once approved, only the admin can delete it. Soft delete via `delete_certificate` (Task 5).
- **Q14. Dedup scope.** This plan blocks the same SHA-256 across all active attachments system-wide. Confirm, or limit dedup to one certificate.

Field choices to confirm (not financial and not certificate fields):
- `profiles.full_name`;
- `sites.is_active` + `archived_at` for "status, archive".

## Environment blockers

- **Docker:** not installed; resolved by testing on DEV (see Test Environment).
- **Deno is not installed.** It is needed for Edge Function unit tests (`deno test`).

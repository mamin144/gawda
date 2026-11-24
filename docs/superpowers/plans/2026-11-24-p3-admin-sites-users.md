# P3 Admin: Sites and Users Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the Admin a web side-navigation shell with screens to list, create, edit and archive sites, and to list, invite, edit, deactivate and assign sites to users.

**Architecture:** Server rules live in PostgreSQL (RLS policies already exist from P1; this phase adds guard triggers, audit triggers and one admin read RPC) and in the `admin-create-user` Edge Function. The Flutter app adds two feature folders (`features/sites`, `features/users`) following the P2 layering: Service (raw Supabase) → Repository (`Result<T>`) → Cubit → Page. The admin area becomes a `ShellRoute` under `/admin` with a responsive side navigation.

**Tech Stack:** Flutter 3.47.6, flutter_bloc 9.1.1, go_router 18.1.4, supabase_flutter 2.18.3, fpdart, mocktail/bloc_test; Supabase Postgres + pgTAP; Deno Edge Function.

**Spec:** `docs/PROJECT_PLAN.md` §3 (roles), §7 (entities), §8 (security), §11 (Admin UX), §12 (P3). Business answers: `docs/OPEN_QUESTIONS.md` Q15–Q19 (added by this plan; **tasks marked ⛔ wait for the answer**).

## Global Constraints

- Role and authorization come from `profiles` only, never `user_metadata` (PROJECT_PLAN §3, §8).
- Site isolation is enforced by RLS, not by the UI (§3).
- No hard delete of sites or profiles; archive / deactivate only (§3 "Soft Delete فقط").
- User creation only through the `admin-create-user` Edge Function; the app never holds the `service_role` key (§8).
- Every new table / function: RLS or explicit grants, `search_path = ''`, pgTAP tests (§8, AGENTS.md).
- UI strings Arabic, only through `app/lib/l10n/app_ar.arb`; RTL first; touch targets ≥ 48dp; contrast ≥ 4.5:1 (§11).
- Status colors: green active, grey archived/inactive (§11) using the existing `AppStatusColors` extension.
- Repositories return `Result<T>` (`Either<AppFailure,T>`); no raw exception crosses layers.
- Schema changes only via `supabase migration new` files applied with the CLI; Supabase MCP stays read-only.

## Review Focus

1. Admin deactivates or demotes **their own** account / the last active admin → must be refused by the DB (locks everyone out otherwise). Test in Task 2.
2. Invite with a site id that does not exist or is archived → 400 **before** any email is sent. Test in Task 1.
3. Re-invite an email that already has a profile (pending invite) → 409 `user_exists`, no second email. Test in Task 1.
4. Duplicate site code (case/whitespace variants, e.g. `" s01 "` vs `"S01"`) → friendly "code already used" error, not a raw 23505. Tests in Task 2 (DB) and Task 3 (mapping).
5. Editing a user's sites when a network failure happens mid-way → the server state is consistent (single RPC transaction, not N client calls). Test in Task 2.

---

## Open business questions (block marked tasks)

Added to `docs/OPEN_QUESTIONS.md`; proposed answer in brackets, **not applied until the owner confirms**:

- **Q15** May an admin deactivate or demote themselves? May the last active admin be deactivated/demoted? [Proposed: no to both, enforced by DB trigger.]
- **Q16** Site "archive": one action that sets `is_active=false` and `archived_at=now()` (and restore clears both), or two separate controls? [Proposed: one archive/restore action; `is_active` and `archived_at` always move together.]
- **Q17** Can an admin user also be linked to sites? (today the Edge Function answers 400) [Proposed: no — admins see all sites.]
- **Q18** May a site user exist with zero sites (e.g. invited before assignment)? [Proposed: yes; they see an empty home until assigned.]
- **Q19** Must site/user management actions (create/edit/archive site, role/active/name change, site assignment) be written to `audit_logs`? [Proposed: yes, via triggers.]
- **Q20** Is a site code editable after creation? [Proposed: yes while the site has no certificates; locked afterwards.]

---

### Task 1: Harden `admin-create-user` (Task 9 review Minors 2–4)

**Files:**
- Modify: `supabase/functions/admin-create-user/handler.ts`
- Test: `supabase/functions/admin-create-user/handler_test.ts`

**Interfaces:**
- Produces: HTTP contract consumed by Task 4 — `POST {email, full_name, role, site_ids?}` → `201 {id}` | `400 {error:"invalid_request"}` | `400 {error:"invalid_sites"}` | `401` | `403 {error:"forbidden"}` | `409 {error:"user_exists"}` | `500 {error:"config_missing"|"create_failed"|"internal_error"}`.

- [ ] **Step 1: Failing tests** in `handler_test.ts` using the existing fake deps:
  - `rejects unknown site id before invite`: service `from('sites').select('id').in('id', ids).eq('is_active', true)` returns fewer rows than requested → status 400, body `{error:"invalid_sites"}`, `inviteUserByEmail` call count 0.
  - `rejects archived site id before invite`: same, the archived id is filtered by `is_active=true` → 400 `invalid_sites`, no invite.
  - `returns 409 without inviting when a profile already exists for the email`: service RPC/lookup finds an existing auth user with that email → 409 `user_exists`, invite count 0.
- [ ] **Step 2:** Run `deno test --allow-env supabase/functions/admin-create-user/` (with the finalize `--config` for `_shared`). Expected: the 3 new tests FAIL.
- [ ] **Step 3: Implement** in `handleCreateUser`, after `parseInput` and before the invite:
  - the site check above (skipped when `siteIds` is empty);
  - the existing-email check via `service.rpc('auth_user_exists', {p_email})` (defined in Task 2), mapping `true` → 409.
- [ ] **Step 4:** Re-run deno tests → all pass (44 + 3).
- [ ] **Step 5: Commit** `fix(fn): validate sites and existing email before sending invite`.

### Task 2: DB — guards, audit triggers, admin RPCs ⛔ Q15, Q16, Q19, Q20

**Files:**
- Create: `supabase/migrations/<ts>_admin_management.sql` (via `supabase migration new admin_management`)
- Create: `supabase/tests/database/10_admin_management.test.sql`

**Interfaces:**
- Produces (all `security definer`, `set search_path = ''`, in `public`, `revoke ... from public, anon`, explicit grants):
  - `public.admin_list_users() returns table(id uuid, email text, full_name text, role user_role, is_active boolean, invite_pending boolean, site_ids uuid[])`. Grant to `authenticated`; body raises `forbidden` unless `private.is_admin()`. `invite_pending = auth.users.email_confirmed_at is null`.
  - `public.admin_set_user_sites(p_user uuid, p_site_ids uuid[]) returns void`. Grant to `authenticated`; admin only; target must be `site_user` (Q17) and every id an active site; replaces the set in one transaction.
  - `public.auth_user_exists(p_email text) returns boolean`. Grant to `service_role` only.
  - Trigger `profiles_guard` (before update): raises `cannot_change_self` when `new.id = auth.uid()` and `role`/`is_active` change; raises `last_admin` when the change would leave zero active admins. (Q15)
  - Trigger `sites_archive_consistency` (before insert/update): `archived_at is not null ⇔ is_active = false`, else raises `archive_inconsistent`. (Q16)
  - Trigger `sites_code_lock` (before update of `code`): raises `code_locked` if certificates exist. (Q20)
  - Normalize `sites.code`: `upper(trim(code))` in the before-insert/update trigger; unique index already enforces duplicates.
  - Audit triggers (after insert/update on `sites`, after update on `profiles`, after insert/delete on `user_sites`) call `private.write_audit(...)` with before/after JSON; actions `site_created`, `site_updated`, `profile_updated`, `user_site_added`, `user_site_removed`. (Q19)

- [ ] **Step 1: Failing pgTAP** in `10_admin_management.test.sql` (reuse `_helpers.sql` for admin/site-user/anon sessions), assertions:
  - `throws_ok` admin updates own `is_active=false` → `cannot_change_self`; own role → `cannot_change_self`.
  - `throws_ok` demoting the only other active admin when the caller is the last one left (set up 2 admins, deactivate one, try the other via a 3rd? — use: admin A deactivates admin B when A is inactive is impossible, so test with the RPC-free direct update as postgres role switching `auth.uid()` to admin A and B being the last other) → `last_admin`.
  - `throws_ok` site update with `is_active=false, archived_at=null` → `archive_inconsistent`.
  - `is(code, 'S01')` after insert of `' s01 '`; `throws_ok` insert `'S01'` again → `23505`.
  - `throws_ok` code change on a site with a certificate → `code_locked`.
  - `admin_list_users()` as admin returns the seed users with emails; as site user → `forbidden`; as anon → `42501`.
  - `admin_set_user_sites` as admin replaces sites (count check); with an archived site → `invalid_sites`; for an admin target → `invalid_target`; as site user → `forbidden`.
  - `auth_user_exists` executable by service_role, `42501` for authenticated.
  - audit: after a site update, `audit_logs` has one `site_updated` row with the actor.
- [ ] **Step 2:** `bash supabase/tests/run_remote.sh` → only file 10 fails.
- [ ] **Step 3:** Write the migration; run `supabase db push` to DEV (non-destructive, additive only).
- [ ] **Step 4:** `bash supabase/tests/run_remote.sh` → all 11 files PASS; MCP `get_advisors` (security + performance) → no new ERROR/WARN.
- [ ] **Step 5: Commit** `feat(db): admin management guards, audit triggers and RPCs`.

### Task 3: App — sites data layer

**Files:**
- Create: `app/lib/features/sites/domain/entities/site.dart`, `domain/repositories/sites_repository.dart`, `data/models/site_row.dart`, `data/services/sites_service.dart`, `data/repositories/sites_repository_impl.dart`
- Modify: `app/lib/core/error/app_failure.dart`, `app/lib/core/error/failure_mapper.dart`
- Test: `app/test/features/sites/data/sites_repository_impl_test.dart`, `app/test/core/error/failure_mapper_test.dart`

**Interfaces:**
- Produces:
  - `class Site { String id; String code; String name; bool isActive; DateTime? archivedAt; }` (freezed, value equality).
  - `abstract interface class SitesRepository { Future<Result<List<Site>>> list(); Future<Result<Site>> create({required String code, required String name}); Future<Result<Site>> update(String id, {required String code, required String name}); Future<Result<Site>> setArchived(String id, {required bool archived}); }`
  - New failures: `DuplicateFailure` (Postgres `23505`), `ForbiddenFailure` (`42501`, P0001 `forbidden`, HTTP 403), `BusinessRuleFailure(String code)` for P0001 messages `cannot_change_self | last_admin | code_locked | invalid_sites | invalid_target | archive_inconsistent | user_exists`.
- [ ] **Step 1: Failing tests:** mapper maps `PostgrestException(code:'23505')` → `DuplicateFailure`, `(code:'P0001', message:'last_admin')` → `BusinessRuleFailure('last_admin')`, `(code:'42501')` → `ForbiddenFailure`; repository with a mocktail `SitesService`: `list()` maps rows ordered by code; `setArchived(archived:true)` sends `{is_active:false, archived_at: <now ISO>}`; service throwing `23505` → `Left(DuplicateFailure())`.
- [ ] **Step 2:** `flutter test test/features/sites test/core/error` → FAIL (types missing).
- [ ] **Step 3: Implement**; `SupabaseSitesService` uses `.from('sites').select('id, code, name, is_active, archived_at').order('code')`, `insert(...).select().single()`, `update(...).eq('id', id).select().single()`. Run `dart run build_runner build -d`.
- [ ] **Step 4:** Tests pass; `flutter analyze` clean.
- [ ] **Step 5: Commit** `feat(app): sites data layer`.

### Task 4: App — users data layer ⛔ Q17, Q18

**Files:**
- Create: `app/lib/features/users/domain/entities/managed_user.dart`, `domain/repositories/users_repository.dart`, `data/models/managed_user_row.dart`, `data/services/users_service.dart`, `data/repositories/users_repository_impl.dart`
- Test: `app/test/features/users/data/users_repository_impl_test.dart`

**Interfaces:**
- Consumes: Task 1 HTTP contract; Task 2 `admin_list_users`, `admin_set_user_sites`; Task 3 failures.
- Produces:
  - `class ManagedUser { String id; String email; String fullName; UserRole role; bool isActive; bool invitePending; List<String> siteIds; }` (reuse `UserRole` from `features/auth/domain/entities/app_user.dart`).
  - `abstract interface class UsersRepository { Future<Result<List<ManagedUser>>> list(); Future<Result<String>> invite({required String email, required String fullName, required UserRole role, required List<String> siteIds}); Future<Result<void>> update(String id, {required String fullName, required UserRole role, required bool isActive}); Future<Result<void>> setSites(String id, List<String> siteIds); }`
  - `invite` calls `client.functions.invoke('admin-create-user', body: {...})`; maps `FunctionException` status/`error`: 409 → `BusinessRuleFailure('user_exists')`, 400 `invalid_sites` → `BusinessRuleFailure('invalid_sites')`, 400 other → `ServerFailure(code:'invalid_request')`, 403 → `ForbiddenFailure`, 500 `config_missing` → `ServerFailure(code:'config_missing')`. Check the exact `FunctionException` fields with Context7 before writing.
- [ ] **Step 1: Failing tests** (mocktail service): list maps `site_ids` array and `invite_pending`; invite 409 → `BusinessRuleFailure('user_exists')`; invite 400 `invalid_sites` → `BusinessRuleFailure('invalid_sites')`; `setSites` calls `rpc('admin_set_user_sites', params:{p_user, p_site_ids})`; `update` sends only `full_name, role, is_active`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Pass + analyze clean.
- [ ] **Step 5: Commit** `feat(app): users data layer`.

### Task 5: Admin shell and routing

**Files:**
- Create: `app/lib/features/admin/presentation/admin_shell.dart`
- Modify: `app/lib/core/router/app_router.dart`, `app/lib/app.dart` (provide repositories), `app/lib/l10n/app_ar.arb`, `app/lib/features/home/presentation/pages/admin_home_page.dart` (becomes the shell's overview body, no own AppBar)
- Test: `app/test/core/router/app_router_test.dart`, `app/test/features/admin/admin_shell_test.dart`

**Interfaces:**
- Produces: routes `/admin` (overview), `/admin/sites`, `/admin/users` inside a `ShellRoute` whose builder is `AdminShell(child:)`. `RepositoryProvider<SitesRepository>` and `RepositoryProvider<UsersRepository>` above `MaterialApp.router`.
- `resolveRedirect` rule changes: any location starting with `/admin` is admin-only (site user → `/site`); `/site` prefix is site-user-only.
- `AdminShell`: `LayoutBuilder`; `maxWidth >= 840` → `Row(NavigationRail(extended: maxWidth >= 1200), VerticalDivider, Expanded(child))`; else `Scaffold(drawer: NavigationDrawer)`. Destinations: overview / sites / users; logout action in the app bar. Selected index from `GoRouterState.of(context).matchedLocation`.
- [ ] **Step 1: Failing tests:** `resolveRedirect` site user at `/admin/sites` → `/site`; admin at `/admin/users` → null; widget: at 1280×800 a `NavigationRail` with 3 destinations is shown; at 400×800 no rail, a drawer button opens 3 entries; tapping "المواقع" navigates to `/admin/sites`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement + arb keys `navOverview`, `navSites`, `navUsers`. **Step 4:** Pass.
- [ ] **Step 5: Commit** `feat(app): admin shell with responsive side navigation`.

### Task 6: Sites screen ⛔ Q16, Q20

**Files:**
- Create: `app/lib/features/sites/presentation/bloc/sites_cubit.dart`, `presentation/pages/sites_page.dart`, `presentation/widgets/site_form_dialog.dart`
- Modify: `app/lib/l10n/app_ar.arb`
- Test: `app/test/features/sites/presentation/sites_cubit_test.dart`, `sites_page_test.dart`, `site_form_dialog_test.dart`

**Interfaces:**
- Consumes: `SitesRepository` (Task 3).
- Produces: `sealed class SitesState` → `SitesLoading`, `SitesLoaded({List<Site> sites, SitesFilter filter, String query, AppFailure? actionError})`, `SitesError(AppFailure)`; `enum SitesFilter { active, archived, all }`; cubit methods `load()`, `setFilter(SitesFilter)`, `setQuery(String)`, `create(code,name)`, `update(id,code,name)`, `setArchived(id, archived)` → each returns `Future<bool>` (true on success, reloads list).
- Page: search field + segmented filter (default `active`), list rows code · name · status chip (green active / grey archived), add FAB (≥48dp), row menu edit / archive / restore with a confirm dialog for archive. Form dialog: code (required, ≤ 20 chars, trimmed), name (required, ≤ 120 chars); `DuplicateFailure` shows `siteCodeDuplicate` under the code field; `BusinessRuleFailure('code_locked')` shows `siteCodeLocked`.
- [ ] **Step 1: Failing tests:** bloc_test `load` emits Loading → Loaded; `setFilter(archived)` shows only archived; widget: empty code shows `fieldRequired`; duplicate shows `siteCodeDuplicate`; archive asks confirmation then calls `setArchived(id, archived:true)`; archived row shows grey chip text `siteArchived`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement + arb keys. **Step 4:** Pass + analyze.
- [ ] **Step 5: Commit** `feat(app): sites management screen`.

### Task 7: Users screen ⛔ Q15, Q17, Q18

**Files:**
- Create: `app/lib/features/users/presentation/bloc/users_cubit.dart`, `presentation/pages/users_page.dart`, `presentation/widgets/invite_user_dialog.dart`, `presentation/widgets/edit_user_dialog.dart`, `presentation/widgets/site_multi_select.dart`
- Modify: `app/lib/l10n/app_ar.arb`
- Test: `app/test/features/users/presentation/users_cubit_test.dart`, `users_page_test.dart`, `invite_user_dialog_test.dart`, `edit_user_dialog_test.dart`

**Interfaces:**
- Consumes: `UsersRepository` (Task 4), `SitesRepository.list()` (Task 3, active sites only for selection), `SessionCubit` (current admin id).
- Produces: `UsersState` mirroring `SitesState` with `List<ManagedUser>` and `List<Site> activeSites`; methods `load()`, `invite(...)`, `update(...)`, `setSites(id, ids)` returning `Future<bool>`.
- Rows: name · email · role · status chip (active green / inactive grey / "دعوة معلّقة" yellow when `invitePending`) · site count.
- Invite dialog: email (trimmed, basic format), full name, role radio; site multi-select **hidden and cleared when role = admin** (Q17). Error mapping: `user_exists` → `userExists`; `invalid_sites` → `inviteInvalidSites`; `config_missing` → `inviteNotConfigured`.
- Edit dialog: name, role, active switch, sites. For the signed-in admin's own row the role and active controls are disabled (Q15, server still enforces); `last_admin` → `lastAdminError`.
- [ ] **Step 1: Failing tests:** selecting role admin hides the site selector; invalid email shows `emailInvalid`; 409 shows `userExists`; own row has the active switch disabled; saving calls `update` then `setSites` only when sites changed.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Pass + analyze.
- [ ] **Step 5: Commit** `feat(app): users management screen`.

### Task 8: Phase verification and docs

**Files:** Modify `docs/PROGRESS.md`, `docs/SKILLS_LOG.md`, `docs/OPEN_QUESTIONS.md` (close answered Q15–Q20).

- [ ] **Step 1:** Run and record real output: `flutter analyze`; `flutter test`; deno tests (both functions); `bash supabase/tests/run_remote.sh`; `flutter build web --release`; `flutter build apk --debug`; MCP `get_advisors` security + performance; `node verify_p0.mjs`.
- [ ] **Step 2:** Deploy the function: `supabase functions deploy admin-create-user` (verify_jwt stays true); confirm ACTIVE.
- [ ] **Step 3:** Whole-branch review (fresh reviewer, model opus) against this plan; fix Critical/Important.
- [ ] **Step 4:** Update PROGRESS/SKILLS_LOG (SKILLS LOADED / SKILLS APPLIED); commit `docs(p3): phase report`.

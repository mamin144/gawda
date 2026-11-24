# Progress Log - Site Financial Quality Tracking System

## P0: Environment Bootstrap
- Status: Performed; awaiting owner approval (not self-approved).
- Skills: 23 installed skills are present under `.agents/skills/`, each with a `SKILL.md`; the unavailable `flutter-bloc` skill is an owner-approved exception, not an installed skill.
- `insecure-defaults`: upstream `trailofbits/skills` ships it as a plugin (`plugins/insecure-defaults`), not as a skill; `npx skills add ... --skill insecure-defaults` returns `[SKILLS_NO_MATCHING_SKILLS]`. Vendored from the upstream repo and wrapped with a `SKILL.md` (see `docs/SKILLS_LOG.md`).
- `flutter-bloc`: no BLoC skill exists in `flutter/agent-plugins` (25 skills listed, none BLoC/Cubit). The owner approved use of the `flutter_bloc` package with `flutter-apply-architecture-best-practices` as a documented exception on 22 November 2026; this is no longer an open question.
- MCP servers: Supabase (remote, read-only, DEV project), Dart (local), and Context7 (remote) were all reported `connected` by `opencode mcp list` on 22 November 2026. An unrelated stale global `shadcn` entry failed because its old path no longer exists; it was not modified from this project.
- OpenCode config: migrated to the native V2 shape after verifying the installed Desktop CLI is `2.1.4`; server entries now live under `mcp.servers`, and V2 `permissions` preserve the planned safety denials.
- Plugins: `opencode-dcp` version `3.2.1` is installed. `opencode-notifier` remains optional and is not installed. Envsitter Guard is not installed; V2 read permissions deny `.env*`, `.xlsx`, and `.xlsm` files instead.
- Git repo: initialized on branch `master`, no remotes configured. Live history at the time of this pass: `8ce6580` (migrate OpenCode config to v2), `58a9528` (record approved BLoC exception), `d7a3f1b` (re-verify bootstrap), `f671181`, `d292479`, `2cba9d6`; working tree clean before the documentation commit.
- .gitignore: `.env*`, `*.xlsx`, `*.xlsm`, `app/env/`, build outputs.
- docs/ layout: `PROJECT_PLAN.md`, `OPENCODE_PROMPT.md`, `OPEN_QUESTIONS.md`, `PROGRESS.md`, `SKILLS_LOG.md`. `AGENTS.md` is at the repository root.
- Supabase URL/key: stored in `app/env/dev.json` (gitignored), see P2. No publishable key is committed; `git log --all -S "sb_publishable"` returns nothing.
- Python: installed to `D:\Tools\Python313` with `winget install -e --id Python.Python.3.13 --location "D:\Tools\Python313"` (Python 3.13.17). CPython's Windows installer ships only `python.exe` and `py.exe`, never `python3.exe`, so `python3` still resolved to the Microsoft Store App Execution Alias stub. The owner approved a real `python3.exe` created as a **hard link**, not a copy:
  `New-Item -ItemType HardLink -Path "D:\Tools\Python313\python3.exe" -Target "D:\Tools\Python313\python.exe"` -> `LinkType: HardLink`, `Length: 105696`, and `fsutil hardlink list` reports exactly 2 links. Verified in a shell whose `PATH` was rebuilt from the registry (equivalent to a fresh terminal):
  `where python` -> `D:\Tools\Python313\python.exe` (first), `where python3` -> `D:\Tools\Python313\python3.exe` (first), `python --version` -> `Python 3.13.17`, `python3 --version` -> `Python 3.13.17`. Both exit code 0. The Microsoft Store stubs remain in `PATH` but are shadowed.
- P0 evidence pass on 22 November 2026: `opencode mcp list` -> context7, dart, supabase all `connected`; `opencode plugin list` -> `opencode-dcp 3.2.1`; `supabase --version` -> `3.2.0`; `node verify_p0.mjs` -> `Missing required: 0` (23/23 skills), all 8 required files OK, no stray files, `Tracked files that must NOT be tracked: none`, secret scan clean (`sb_secret_` none, JWT none, publishable key none), and `python3 Python 3.13.17` now appears in the tool-version section with no ERROR.
- `verify_p0.mjs` was fixed on 22 November 2026 (owner-authorized verifier-only change) to validate the OpenCode V2 configuration instead of the retired V1 keys. It now requires a non-empty `"plugins"` array and a `"permissions"` array, and it additionally **enforces** that every forbidden action is still denied (it does not merely look for the block). `opencode.json` was not modified. The two stale lines `plugin entries: none` and `permission block: NO` are gone. Final result: `plugins (V2 array): OK "@tarquinen/opencode-dcp@latest"`, `permissions (V2 array): OK 11 rules`, `deny shell actions: all 4 OK`, `deny secret/file reads: all 4 OK`, and the full run contains no `MISSING`, `ERROR`, `WARNING`, `plugin entries: none`, or `permission block: NO`.
- Flutter toolchain verified with `flutter doctor -v` on 22 November 2026 (exit 0, fresh terminal):
  - `[√] Flutter` — 3.47.6 stable at `C:\flutter`, Dart 3.13.5, DevTools 2.60.0; feature flags include `enable-web` and `enable-android`.
  - `[√] Android toolchain` — SDK 37.0.0 at `C:\Users\PC-01\AppData\Local\Android\sdk`, platform `android-37.0`, build-tools `37.0.0`, emulator 37.2.12.0, Java `C:\jdk-17\jdk-17.0.20.1+1\bin\java` (OpenJDK 17.0.20.1+1-LTS), "All Android licenses accepted."
  - `[√] Chrome` — `C:\Program Files\Google\Chrome\Application\chrome.exe`, web target available.
  - `[X] Visual Studio` — not installed; affects **Windows desktop only**.
  - `[√] Connected device` — Windows (desktop), Chrome (web), Edge (web).
  - `[√] Network resources` — all available.
  - **Blocker assessment: no blocker for Android builds and no blocker for Web builds.** The single `[X]` is Windows desktop, which is not a target of this project (Android + Web per `docs/OPEN_QUESTIONS.md` item 9), so it was reported and deliberately not "fixed".

- Independent review on 22 November 2026 (Claude Code session, owner-requested). Re-ran `node verify_p0.mjs` (exit 0, `Missing required: 0`), `opencode mcp list` (context7, dart, supabase `connected`), `opencode plugin list` (`opencode-dcp 3.2.1`). Gaps found and fixed:
  - `supabase/.temp/cli-latest` (Supabase CLI local state) was tracked in Git; untracked and `supabase/.temp/` + `supabase/.branches/` ignored.
  - `.gitignore` had `/app/env/`, which would also have ignored the placeholder `app/env/dev.example.json` that P2 must commit; now `/app/env/*` with `!/app/env/*.example.json`.
  - `/build/` and `/.dart_tool/` were anchored to the repo root and did not cover `app/build` or `app/.dart_tool`; now unanchored.
  - Removed `/functions/**` and `/storage/**/.private/` (they matched nothing and looked like they might hide `supabase/functions`, which must be committed).
  - `docs/SKILLS_LOG.md`: logged the `flutter-responsive-layout` -> `flutter-build-responsive-layout` mapping (no `flutter-responsive-layout` upstream), updated the stale `flutter-bloc` row, logged the optional `static-analysis` status and the superpowers skills-vs-plugin note.
  - Still open for the owner: the Supabase MCP "harmless read call" proof (for example list tables) has not been pasted yet; `opencode mcp list` only shows it is authenticated and connected. `supabase login` / `supabase link` not done yet (owner types the DB password in the terminal). Section 1.6 items: superpowers plugin not installed (skills are), `opencode-notifier` not installed (optional), Envsitter Guard not installed (replaced by read-deny permissions).

- Executor switch on 22 November 2026 (owner decision): **Claude Code now executes the whole project; OpenCode is retired.**
  - Skills: the 23 skills in `.agents/skills/` (source, `skills-lock.json`) are copied to `.claude/skills/`, where Claude Code discovers them. `node verify_p0.mjs` checks the two trees are identical (`yes (222 files)`).
  - MCP: project-scoped `.mcp.json` with `supabase` (DEV `project_ref`, `read_only=true`, features `docs,database,debugging,development`), `dart` (`dart mcp-server`) and `context7`. No user-scope Supabase entry. Approved for the project through `enabledMcpjsonServers` in `.claude/settings.json`.
  - Permissions: `.claude/settings.json` denies `rm -rf`, `git push --force`/`-f`, `supabase db reset`, `supabase projects delete`, and reads of `.env`, `.env.*`, `*.xlsx`, `*.xlsm`, `app/env/dev.json`, `app/env/prod.json`; `supabase db push` and `supabase link` always ask. `.claude/settings.local.json` is gitignored.
  - `CLAUDE.md` imports `AGENTS.md`; `AGENTS.md` now says skills load with the `Skill` tool; `docs/OPENCODE_PROMPT.md` carries a status note that its OpenCode-only setup steps are historical (phase plan and "Skills per phase" table still apply).
  - `opencode.json` removed (it remains in Git history). The OpenCode plugin items of section 1.6 (`opencode-dcp`, `opencode-notifier`, Envsitter Guard) no longer apply.
  - `verify_p0.mjs` now checks `.mcp.json`, the `.claude/settings.json` deny rules, `CLAUDE.md`, and the skill copy instead of `opencode.json`. Run result: exit 0, `Missing required: 0`, all Supabase MCP checks `yes`/`none`, `deny shell actions: all 4 OK`, `deny secret/file reads: all 5 OK`, secret scan clean, no `MISSING`/`ERROR`/`WARNING`.
  - Still open for the owner: authenticate the Supabase MCP in Claude Code (OAuth in the browser) and then the harmless read proof (list tables); `supabase login` / `supabase link`.

- Supabase MCP read proof on 22 November 2026 (Claude Code session):
  - Auth: the project `supabase` server in `.mcp.json` authenticates with `Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}` (personal access token in the owner's Windows user environment, never committed). The first attempt failed with HTTP 401 `JWT could not be decoded` because the Claude app had been started before the variable was set; after a full app restart the server connected.
  - Scope check: the server exposes only read tools (`list_tables`, `execute_sql`, `list_migrations`, `list_extensions`, `get_advisors`, `query_logs`, `get_project_url`, `get_publishable_keys`, `generate_typescript_types`, `search_docs`); no `apply_migration`, `create_project`, `deploy_edge_function` or branching tools, consistent with `read_only=true` and the `project_ref` scoping.
  - `list_tables` with `schemas: ["public"]`, `verbose: false` on the DEV project (`kbjsonvnbbhvczttvzhv`) returned `{"tables":[]}`: the `public` schema is empty, as expected before P1 (no migrations applied yet).
  - Still open for the owner: `supabase login` / `supabase link`.

## P1: Database and Security (implemented and verified on DEV; awaiting owner approval)
- P0 approved by the owner on 22 November 2026 ("Approve P0, start P1").
- Plan: `docs/superpowers/plans/2026-11-22-p1-database-security.md`. Requirements: supabase CLI, pgTAP tests, RLS policies, seed data, Edge Functions.
- Skills (per docs/OPENCODE_PROMPT.md): supabase, supabase-postgres-best-practices, writing-plans, test-driven-development, insecure-defaults, sharp-edges, verification-before-completion. Per-task SKILLS LOADED / SKILLS APPLIED entries are in `docs/SKILLS_LOG.md` (Tasks 0-11).
- Testing environment: Docker is not installed, so pgTAP runs through `supabase/tests/run_remote.sh` (psql against the linked DEV project via `supabase/.temp/pooler-url` + the owner's `pgpass`; no password in the repo, no Docker).

- Schema (10 migrations, applied to DEV; `supabase migration list --remote` shows every local migration on the remote): `public.user_role` / `public.certificate_status` / `public.attachment_kind` enums and `public.period_half(date)`; `profiles`, `sites`, `user_sites` with the `private.is_active_user()` / `private.is_admin()` / `private.has_site_access(uuid)` helpers; `certificates` with generated period columns, `numeric(18,2)` amounts and the partial unique index `certificates_one_per_period`; append-only `audit_logs`; `attachments` with active-only SHA-256 dedup and upload constraints; the private `certificates` storage bucket with site-scoped policies; the five status-transition RPCs; the `finalize-certificate` service RPCs; `public.audit_user_created`. All six tables have RLS enabled (MCP `list_tables`: 6/6 `rls_enabled: true`), every policy is `to authenticated` with a site-ownership predicate, and nothing is granted to `anon`.
- Seed (`supabase/seed.sql`, fake data only, applied with `supabase db push --include-seed --remote --yes`): 3 fake auth users (`admin@example.test`, `site1@example.test`, `site2@example.test`) with random unrecoverable bcrypt passwords plus one email identity each, 2 fake sites `S-001`/`S-002`, site1→S-001, site2→S-002, admin unassigned, and 5 certificates on S-001 — one per status, each in its own half-month period. No attachments, no audit rows, no real Excel data. Idempotent: re-running the file directly through `psql` leaves an md5 over users/identities/certificates unchanged.
- Database tests: `bash supabase/tests/run_remote.sh` → `Files=10, Result: PASS`, 367 assertions, 0 failures (00_smoke 2, 01_period 18, 02_profiles_sites 46, 03_certificates 52, 04_audit 34, 05_transitions 58, 06_attachments 47, 07_storage 51, 08_finalize 45, 09_admin_create_user 14).
- Seed verifier (`supabase/tests/seed_verify.sql`, read-only): RED before seeding (`expected 3 fake auth users, found 0`), GREEN after (`seed check: all assertions passed`), evidence table `3 users / 3 profiles / 2 sites / 2 assignments / 5 certificates / 0 attachments`. It also rejects any known default password and any non-bcrypt hash.
- RLS probe with the seeded identities (`set local role authenticated` + JWT claims, rolled back): site1 sees 5 certificates / 1 site / 1 profile; site2 sees 0 / 1 / 1; admin sees 5 / 2 / 3. The seed therefore demonstrates cross-site isolation, not just row counts.
- Edge Functions (deployed with `--use-api`, Docker not installed): `admin-create-user` and `finalize-certificate`, both `status: ACTIVE`, `verify_jwt: true`, version 1. `supabase functions list` is no longer empty.
- Deno tests (run per function directory so the per-function `deno.json` import map applies): `finalize-certificate` 17 passed, `admin-create-user` 25 passed, `_shared` 2 passed — 44 total, 0 failed.
- Advisors (`supabase db advisors --remote --type all --level info` and MCP `get_advisors`, identical): **0 security ERROR/CRITICAL**. One security WARN remains — `auth_leaked_password_protection` (project-level HaveIBeenPwned check disabled; owner action in the dashboard). Seven INFO performance items remain and are accepted: 5 unindexed FKs (`certificates.created_by/deleted_by`, `attachments.uploaded_by/deleted_by`, `audit_logs.actor_id`) that are never used as filter predicates, and 2 unused indexes (`certificates_status_idx`, `attachments_certificate_id_idx`) that serve planned screens.
- Flutter verification for P1: `app/` is still empty (P2 has not started), so there is no Flutter target to `analyze`, `test` or build in this phase; nothing was skipped silently. `node verify_p0.mjs` still exits 0 (23/23 skills, `.agents/skills` == `.claude/skills`, deny rules intact, no tracked secret, `sb_secret_`/JWT/publishable-key scans clean).
- Owner actions still open before P1 can be approved: set the `INVITE_REDIRECT_URL` function secret (without it `admin-create-user` answers `500 config_missing` by design — there is no fallback URL), enable leaked-password protection, and decide whether DEV needs Auth SMTP for real invites. Product question still open: **Q14** (SHA-256 dedup scope, currently system-wide across active attachments).
- P1 commits: `chore(p1): init supabase project and pgTAP harness`, `feat(p1): add enums and period derivation function`, `feat(p1): profiles, sites and authorization helpers`, `feat(p1): certificates with period uniqueness and edit guard`, `feat(p1): append-only audit log`, `feat(p1): status transition RPCs with audit`, `feat(p1): attachments table with upload rules`, `feat(p1): private certificates bucket with site isolation`, `test(p1): fix collation in storage policy assertion`, `feat(p1): finalize-certificate edge function and service RPCs`, `feat(p1): admin-create-user edge function`, `chore(p1): fake seed data`, `docs(p1): phase report and evidence`.

## P2: App Foundation (implemented; awaiting owner approval)
- Status: Implemented on branch `p2-app-foundation` and verified locally; awaiting owner approval (not self-approved). See the P2 phase report below.
- Requirements: Flutter project creation, Auth setup, go_router, state management, localization. (DELIVERED in P2 Tasks 1-8.)
- State-management decision: use `flutter_bloc` as approved by the owner; the project does not depend on a separate unavailable `flutter-bloc` skill.

### P2 notes (recorded during P0; do not act on them before P2)
- Supabase DEV project URL: `https://kbjsonvnbbhvczttvzhv.supabase.co` (project_ref `kbjsonvnbbhvczttvzhv`).
- URL and publishable key: stored in `app/env/dev.json` (gitignored). Commit only `app/env/dev.example.json` with placeholders. Run with `--dart-define-from-file=env/dev.json`. No key is ever committed.
- Before writing the init code, check the current `Supabase.initialize(...)` parameter names of `supabase_flutter` with the Context7 MCP (the dashboard quickstart uses `url` + `publishableKey`; older versions used `anonKey`).
- Do NOT use the Supabase quickstart `todos` sample code or table. The schema comes only from `supabase/migrations/`.
- Never use secret / `service_role` keys in the app.
- `docs/DESIGN_SYSTEM.md` (from `ui-ux-pro-max`) must exist before any UI code.

## P2 phase report (23 November 2026)

PHASE: P2 App foundation
SKILLS LOADED: `using-superpowers`, `brainstorming`, `audit-context-building`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `writing-plans`, `executing-plans`, `flutter-apply-architecture-best-practices`, `flutter-setup-declarative-routing`, `flutter-implement-json-serialization`, `dart-run-static-analysis`, `dart-use-pattern-matching`, `ui-ux-pro-max`, `flutter-build-responsive-layout`, `supabase` (`flutter-bloc` remains the owner-approved documented exception).
BUILT: Flutter project (Android+Web) in `app/`; strict analysis; env config; bundled IBM Plex Sans Arabic; sealed `AppFailure` + mapper; M3 theme extensions + Arabic RTL l10n; shared state widgets; auth data/domain (freezed models, services, repository); session + login cubits; Arabic login page; role-guarded go_router; role home placeholders; app wiring; web + Android builds.
COMMANDS RUN:
- `flutter analyze` -> No issues found! (after every task)
- `flutter test` -> 84 passed, 0 failed
- `flutter build web --dart-define-from-file=env/dev.json` -> exit 0 (`√ Built build/web`)
- `flutter build apk --debug --dart-define-from-file=env/dev.json` -> exit 0 (`√ Built .../app-debug.apk`)
- APK installed (`Success`) and launched on `emulator-5554` (Android 17 / API 37); screenshot saved to `C:\Users\PC-01\AppData\Local\Temp\opencode\p2_login_android.png`.
- Browser tool: served `build/web` on localhost:8123; confirmed Arabic RTL login renders (`/#/login` -> `/login` after usePathUrlStrategy).
- `node verify_p0.mjs` -> exit 0 (publishable scan now `none`).
TESTS: 84 passing (app_config 8, failure_mapper 16, theme 10, l10n 2, state_views 5, profile_row 5, auth_repository 12, session_cubit 7, login_cubit 5, login_page 4, redirect 14, app_router 3, app 3). Note: counts are approximate per file; `flutter test` reports 84 total.
SKILLS APPLIED: see `docs/SKILLS_LOG.md` P2 Tasks 0-8 (per-task).
DEVIATIONS FROM PLAN: (1) `AppConfig.fromEnvironment` is a validating factory, not a const constructor (validation cannot run in const context) — recorded in SKILLS_LOG. (2) `toDomain()` moved from the freezed class body to an extension because freezed's generated class `implements` the interface and would not inherit the concrete method. (3) `AuthRepositoryImpl` constructor is positional (not named) to satisfy `prefer_initializing_formals`. (4) Gradle/Kotlin incremental caching disabled in `app/android/gradle.properties` to work around a daemon/cache registration race on this machine. (5) `usePathUrlStrategy()` added to main.dart (routing skill requirement) though Task 8's interface block did not list it.
NEW OPEN QUESTIONS: none product-side. Owner actions: ~~provide DEV login credentials~~ DONE (owner set DEV passwords for the three seed users — verified via Supabase Auth REST API; the value is not recorded here). Review 2026-11-24: the password chosen is weak and was previously written into this file — owner must rotate all three DEV seed passwords to strong unique values (see OPEN_QUESTIONS owner actions); remaining: set `INVITE_REDIRECT_URL`, enable leaked-password protection (advisor WARN), decide on DEV SMTP, decide on merging `p1-database-security` + `p2-app-foundation` into `master`.

## P3 Admin sites and users: COMPLETE (24 November 2026)
- Branch `p3-admin-sites-users` (not pushed; no remote configured). Plan: `docs/superpowers/plans/2026-11-24-p3-admin-sites-users.md`. Q15-Q20 approved by owner (recorded in `docs/OPEN_QUESTIONS.md`).
- Commits on this branch: `f4bb476` (owner approval) → `6045f47` (plan) → `9bbfefb` (DB guards/audit/RPCs) → `d46e565` (Edge Function hardening) → `cd99f82` (sites data layer) → `95f3d89` (users data layer) → `68a7db0` (admin shell) → `389eaa4` (sites screen) → `57f0987` (users screen) → final docs commit.
- Delivered: admin shell with responsive side nav; sites management screen (list/search/filter, add/edit dialog, archive/restore); users management screen (list/search, invite dialog with email/full-name/role/site multi-select, edit dialog with self-lock and last-admin guard, promotion clears sites first); Edge Function `admin-create-user` redeployed (version 2, ACTIVE, verify_jwt true); DB guards + audit triggers + RPCs.
- Flutter tests: 215 passing, 0 failing (`flutter analyze`: No issues found!).
- Verification (Task 8):
  - `flutter analyze` -> No issues found!
  - `flutter test` -> 215 passed, 0 failed
  - deno tests: admin-create-user 31 passed, finalize-certificate 17 passed, _shared 2 passed (44 total, 0 failed)
  - `bash supabase/tests/run_remote.sh` -> Files=11, Result: PASS (10_admin_management added, 40 assertions)
  - `flutter build web --release` -> exit 0 (`√ Built build/web`)
  - `flutter build apk --debug` -> exit 0 (`√ Built build/app/outputs/flutter-apk/app-debug.apk`)
  - MCP `get_advisors`: security 1 WARN (auth_leaked_password_protection, owner action); performance 5 INFO unindexed FKs + 2 INFO unused indexes (accepted, unchanged from P1)
  - `node verify_p0.mjs` -> exit 0, Missing required: 0
- Parked-minor fixes applied in this phase: dropped `user_exists` from `businessRuleCodes` (mapped per repository); `updateProfile` now uses `.select('id').single()` so zero-row updates surface as PGRST116 ServerFailure.
- Deploy: `admin-create-user` version 2, ACTIVE, verify_jwt true (deployed with `--yes`).
- Owner actions still open: set `INVITE_REDIRECT_URL`; enable leaked-password protection; decide DEV SMTP; rotate the three DEV seed passwords; decide on merging `p1-database-security` + `p2-app-foundation` + `p3-admin-sites-users` into `master`.

## P4 Site user certificate flow + P3 fix wave: COMPLETE (24 November 2026)
- Branch `p4-site-user-flow` (not pushed). Plan: `docs/superpowers/plans/2026-11-24-p3-fixes-p4-site-user.md` (executed inline, final whole-branch review on Opus).
- Commits: `bed2e10`, `5b5b108`, `c68a32a`, `4272f41`, `133f1a8` (initial P4 by OpenCode) → `2013edd` (repair plan) → `5eabecd` (DB: P3 review guards + `remove_attachment` RPC) → `6e80db9` (401 → session failure, server-side `archived_at`) → `d79989d` (certificate data layer via RPCs, local dates, valid storage paths) → `4b52316` (draft auto-save, safe create-or-update) → `f7d1863` (entry page: storage path, mime, auto-save, localized status, confirmations) → final-review fixes `fe8d5c7` (signed copies never removable, migration `20261124150000_remove_attachment_initial_only`; finalize retry reuses this round's signed copy), `b7a5fa6` (submit queued behind saves, auto-save cancelled; records over all sites, kept current), `2af6806` (records open in the entry tab, pull-to-refresh, new-certificate action) → docs commit.
- Delivered: site-user shell (bottom nav: dashboard / entry / records); certificate entry with site picker, amount validation, debounced auto-save, upload (mime allow-list, size limit, SHA-256 duplicate check, progress), signed-copy upload + finalize (a retry reuses this round's signed copy), confirm-before-delete; records list over all assigned sites (tap to open, pull to refresh, new-certificate action); Arabic status/period labels; read-only view after submission; soft-remove of attachments on draft/returned certificates (Q21, pending owner confirmation); signed copies can never be removed. New open questions: Q22 (initial file required before submit?), Q23 (block entry on archived sites?).
- Verification:
  - `flutter analyze` -> No issues found!
  - `flutter test` -> 275 passed, 0 failed
  - `bash supabase/tests/run_remote.sh` -> Files=12, Result: PASS (11_p3_fixes_p4 added, 29 assertions)
  - deno tests: admin-create-user 31, finalize-certificate 17, _shared 2 (50 total, 0 failed). Correction: the P3 total above should read 50, not 44.
  - `flutter build web --release` -> `√ Built build\web`
  - APK build not re-run in this phase.

## P5-P7: Pending
- Status: Not started.

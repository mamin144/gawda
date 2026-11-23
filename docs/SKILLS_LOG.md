# Skills Log - Site Financial Quality Tracking System

## P0: Environment Bootstrap - Verified Skills

| Skill Name | Source Repo | Install Path | Verified | One Quoted Rule |
|---|---|---|---|---|
| using-superpowers | Obra/superpowers | .agents/skills/using-superpowers | yes | "Invoke relevant or requested skills BEFORE any response or action — including clarifying questions, exploring the codebase, or checking files." |
| brainstorming | Obra/superpowers | .agents/skills/brainstorming | yes | "Use BEFORE any creative work - creating features, building components, adding functionality, modifying behavior, or planning anything new" |
| writing-plans | Obra/superpowers | .agents/skills/writing-plans | yes | "Every plan MUST start with this header: `# [Feature Name] Implementation Plan`, followed by Goal, Architecture, Tech Stack, and Spec sections" |
| executing-plans | Obra/superpowers | .agents/skills/executing-plans | yes | "Use when executing an implementation plan in the current session as the implementer yourself" |
| test-driven-development | Obra/superpowers | .agents/skills/test-driven-development | yes | "Use when implementing any feature or bugfix, before writing implementation code" |
| systematic-debugging | Obra/superpowers | .agents/skills/systematic-debugging | yes | "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes" |
| verification-before-completion | Obra/superpowers | .agents/skills/verification-before-completion | yes | "Use when about to claim work is complete, fixed, or passing, before committing or creating PRs" |
| flutter-apply-architecture-best-practices | flutter/agent-plugins | .agents/skills/flutter-apply-architecture-best-practices | yes | "Architects a Flutter application using the recommended layered approach (UI, Logic, Data)" |
| flutter-build-responsive-layout | flutter/agent-plugins | .agents/skills/flutter-build-responsive-layout | yes | "Use `LayoutBuilder`, `MediaQuery`, or `Expanded/Flexible` to create a layout that adapts to different screen sizes" |
| flutter-add-widget-test | flutter/agent-plugins | .agents/skills/flutter-add-widget-test | yes | "Implement a component-level test using `WidgetTester` to verify UI rendering and user interactions" |
| flutter-setup-declarative-routing | flutter/agent-plugins | .agents/skills/flutter-setup-declarative-routing | yes | "Configure `MaterialApp.router` using a package like `go_router` for advanced URL-based navigation" |
| flutter-implement-json-serialization | flutter/agent-plugins | .agents/skills/flutter-implement-json-serialization | yes | "Create model classes with `fromJson` and `toJson` methods using `dart:convert`" |
| dart-run-static-analysis | dart-lang/skills | .agents/skills/dart-run-static-analysis | yes | "Execute `dart analyze` to identify warnings and errors, and use `dart fix --apply` to automatically resolve mechanical lint issues" |
| dart-use-pattern-matching | dart-lang/skills | .agents/skills/dart-use-pattern-matching | yes | "Applies Dart 3 pattern matching, switch expressions, and destructuring idiomatically to validate data schemas" |
| supabase | supabase/agent-skills | .agents/skills/supabase | yes | "Use when doing ANY task involving Supabase. Triggers: Supabase products (Database, Auth, Edge Functions, Realtime, Storage)" |
| supabase-postgres-best-practices | supabase/agent-skills | .agents/skills/supabase-postgres-best-practices | yes | "Enable RLS on every table in any exposed schema. This is critical in Supabase because tables in exposed schemas can be reachable through the Data API" |
| ui-ux-pro-max | nextlevelbuilder/ui-ux-pro-max-skill | .agents/skills/ui-ux-pro-max | yes | "UI/UX design intelligence for web, mobile, and desktop. Use when designing, building, reviewing, or fixing interfaces" |
| subagent-driven-development | Obra/superpowers | .agents/skills/subagent-driven-development | yes | "Use when executing implementation plans with independent tasks in the current session" |
| dart-add-unit-test | dart-lang/skills | .agents/skills/dart-add-unit-test | yes | "Write and organize unit tests for functions, methods, and classes using `package:test`" |
| dart-fix-runtime-errors | dart-lang/skills | .agents/skills/dart-fix-runtime-errors | yes | "Uses get_runtime_errors and lsp to fetch an active stack trace, locate the failing line, apply a fix, and verify resolution" |
| sharp-edges | trailofbits/skills | .agents/skills/sharp-edges | yes | "Identifies error-prone APIs, dangerous configurations, and footgun designs that enable security mistakes. Use when reviewing API designs, configuration schemas, cryptographic library ergonomics" |
| insecure-defaults | trailofbits/skills (plugin `plugins/insecure-defaults`, vendored) | .agents/skills/insecure-defaults | yes | "Detect insecure default configuration in a codebase - fallback secrets, seeded default credentials, fail-open switches, weak crypto, permissive access, and debug leakage" |
| audit-context-building | trailofbits/skills | .agents/skills/audit-context-building | yes | "Enables ultra-granular, line-by-line code analysis to build deep architectural context before vulnerability or bug finding" |

## Mapped / Renamed Skills (not exact match)

| Expected Name | Actual Skill | Reason | Mapping Note |
|---|---|---|---|
| declarative-routing | flutter-setup-declarative-routing | Close match; `flutter-setup-declarative-routing` configures go_router which is the planned routing solution | Exact name difference, functionality matches |
| json-serialization | flutter-implement-json-serialization | Close match; `flutter-implement-json-serialization` maps JSON keys to classes manually with `dart:convert` (`fromJson`/`toJson`) | Exact name difference; note it does NOT cover `freezed`/`json_serializable` codegen |
| flutter-responsive-layout | flutter-build-responsive-layout | `flutter-responsive-layout` does not exist upstream. `npx skills add flutter/agent-plugins --list` (re-run 22 Nov 2026) shows only two layout skills: `flutter-build-responsive-layout` (adaptive layouts with `LayoutBuilder`/`MediaQuery`) and `flutter-fix-layout-issues` (overflow/unbounded-constraint fixes) | Single skill kept; there is no duplicate. Earlier reports listing both names were wrong |

## Skills With No Available Install (documented gap, not a mapping)

| Expected Name | Status | Evidence |
|---|---|---|
| flutter-bloc | NOT INSTALLED - no BLoC skill exists upstream | `npx skills add flutter/agent-plugins --list` returns 25 skills, none BLoC/Cubit related. `flutter-apply-architecture-best-practices` (the closest candidate) contains 0 matches for `bloc` or `cubit`. No substitute is claimed. Owner approved the `flutter_bloc` package without a skill as a documented exception on 22 Nov 2026 (closed in `docs/OPEN_QUESTIONS.md`); in P2 check `flutter_bloc` APIs with Context7. |
| static-analysis (optional) | NOT INSTALLED | Optional per `docs/OPENCODE_PROMPT.md` 1.4 ("use only if Semgrep is installable for free"). Only needed in P7; decide there. |

## Superpowers delivery note

The prompt (1.4 / 1.6) says superpowers is delivered as an OpenCode plugin. It is installed here as the 8 project skills under `.agents/skills/` (source `obra/superpowers`, recorded in `skills-lock.json`); `opencode plugin list` shows only `opencode-dcp`, so the superpowers *plugin* is not installed. The skills load with the `skill` tool, which is what the phases require.

## Skills Log Summary

- **Total skills installed**: 23 (23 required, 0 extras)
- **All required P0 skills verified**: Yes (23/23 loadable via the `skill` tool; `flutter-bloc` has no upstream skill and is logged as an explicit gap above)
- **MCP servers**: Configured and connected (supabase read-only, dart local, context7 remote)
- **Git repo**: Initialized with first commit
- **docs/ layout**: Required files in place (`PROJECT_PLAN.md`, `OPENCODE_PROMPT.md`, `OPEN_QUESTIONS.md`, `PROGRESS.md`, `SKILLS_LOG.md`); `AGENTS.md` lives at the repo root (required by `verify_p0.mjs`)
- **.gitignore**: Correctly ignores `.env*`, `/app/env/`, `*.xlsx`, `*.xlsm`, build outputs

## Key Security Rules Logged

- Never use `user_metadata` for authorization (from supabase skill)
- Enable RLS on every table (from supabase-postgres-best-practices)
- Invoke skills before any response/action (from using-superpowers)
- Verify before claiming completion (from verification-before-completion)

## P0 Verification Evidence (22 November 2026)

### Toolchain gate
`python` and `python3` are both required by the approved UI/UX tooling. After installing Python 3.13.17 to `D:\Tools\Python313`, `python --version` worked but `python3` did not, because CPython's Windows installer ships only `python.exe` and `py.exe`. The owner approved a hard link (not a copy):

```powershell
New-Item -ItemType HardLink -Path "D:\Tools\Python313\python3.exe" -Target "D:\Tools\Python313\python.exe"
```

Result: `LinkType: HardLink`, `Length: 105696`, and `fsutil hardlink list` shows exactly 2 links (`python3.exe`, `python.exe`) to the same file data.

Verified with `PATH` rebuilt from the registry (equivalent to a fresh terminal):

| Command | Output | Exit |
|---|---|---|
| `where python` | `D:\Tools\Python313\python.exe` then `...\WindowsApps\python.exe` | 0 |
| `where python3` | `D:\Tools\Python313\python3.exe` then `...\WindowsApps\python3.exe` | 0 |
| `python --version` | `Python 3.13.17` | 0 |
| `python3 --version` | `Python 3.13.17` | 0 |

Both resolve first to `D:\Tools\Python313\` and report `Python 3.13.17`. The Microsoft Store App Execution Alias stubs are shadowed.

### Evidence pass
| Check | Result |
|---|---|
| `opencode mcp list` | context7 `connected`, dart `connected`, supabase `connected` (an unrelated stale global `shadcn` entry fails on a missing path and is out of scope) |
| `opencode plugin list` | `opencode-dcp 3.2.1` from `@tarquinen/opencode-dcp@latest` |
| `supabase --version` | `3.2.0` |
| `node verify_p0.mjs` | `Missing required: 0` (23/23 skills); 8/8 required files; no stray files; no forbidden tracked files; secret scan clean; `plugins (V2 array): OK`; `permissions (V2 array): OK 11 rules`; `deny shell actions: all 4 OK`; `deny secret/file reads: all 4 OK` |
| `git status --short` | clean |
| `git log --oneline -3` | `8ce6580`, `58a9528`, `d7a3f1b` |

### Checker updated for OpenCode V2 (verifier-only fix, owner-authorized)

`verify_p0.mjs` previously printed `plugin entries: none` and `permission block: NO` because its old lines 83-84 searched for the retired V1 keys `"plugin"` and `"permission"`. The live config correctly uses the V2 keys `"plugins"` and `"permissions"` (Desktop CLI `2.1.4`).

The verifier was fixed to validate V2 and to **strengthen** the security assertion rather than relax it:

- `plugins (V2 array)` — requires a non-empty `"plugins"` array and prints its contents.
- `permissions (V2 array)` — requires a non-empty `"permissions"` array and prints the rule count.
- `deny shell actions` — asserts each of `rm -rf *`, `git push --force*`, `supabase db reset*`, `supabase projects delete*` still carries `"effect": "deny"`.
- `deny secret/file reads` — asserts each of `*.env`, `*.env.*`, `*.xlsx`, `*.xlsm` still carries `"effect": "deny"`.

Final run (fresh terminal, Python on PATH) printed `plugins (V2 array): OK "@tarquinen/opencode-dcp@latest"`, `permissions (V2 array): OK 11 rules`, `deny shell actions: all 4 OK`, `deny secret/file reads: all 4 OK`, with no `MISSING`, `ERROR`, `WARNING`, `plugin entries: none`, or `permission block: NO`. `opencode.json` was not modified.

## P0 Remediation — 22 November 2026

### Skills Loaded

`using-superpowers`, `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `flutter-apply-architecture-best-practices`, `flutter-setup-declarative-routing`, `flutter-implement-json-serialization`, `flutter-build-responsive-layout`, `flutter-add-widget-test`, `dart-run-static-analysis`, `dart-use-pattern-matching`, `dart-add-unit-test`, `dart-fix-runtime-errors`, `supabase`, `supabase-postgres-best-practices`, `ui-ux-pro-max`, `insecure-defaults`, `sharp-edges`, `audit-context-building`.

### Skills Applied

- `writing-plans`: recorded the narrowly scoped P0 remediation plan before modifying project records.
- `systematic-debugging`: traced the Supabase CLI verification failure to its blocked local telemetry write rather than treating it as a project failure.
- `verification-before-completion`: verified the installed Supabase package (`3.2.0`), available skill directories, Git state, and C: free space from live command output; did not claim P0 complete.
- `supabase`, `supabase-postgres-best-practices`, `insecure-defaults`, and `sharp-edges`: retained the private, read-only project-scoped MCP posture and did not introduce credentials, permissive access, or schema changes.
- `ui-ux-pro-max`: retained `python3` as a prerequisite for P2 rather than bypassing its required helper.
- `flutter-apply-architecture-best-practices`: recorded the owner-approved `flutter_bloc` package decision without falsely claiming a nonexistent BLoC skill is installed.
- `sharp-edges`: migrated the OpenCode configuration to V2 so secure restrictions use active `permissions` rules instead of obsolete V1 fields that could be silently ignored.
- All remaining loaded skills: no product or database code exists yet, so their implementation-specific rules were not applied in P0.

## P0 Final Verification — flutter doctor (22 November 2026)

Run from a fresh terminal (PATH rebuilt from the registry, so `D:\Tools\Python313` is active): `flutter doctor -v`, exit code 0.

| Check | Result | Detail |
|---|---|---|
| Flutter | OK | 3.47.6 stable at `C:\flutter`, Dart 3.13.5, DevTools 2.60.0 |
| Windows Version | OK | Windows 11 / 26H2 |
| Android toolchain | OK | SDK 37.0.0, platform `android-37.0`, build-tools `37.0.0`, emulator 37.2.12.0, JDK 17.0.20.1+1-LTS, all licenses accepted |
| Chrome (web) | OK | `C:\Program Files\Google\Chrome\Application\chrome.exe` |
| Visual Studio | FAIL | Not installed — Windows desktop only |
| Connected device | OK | Windows (desktop), Chrome (web), Edge (web) |
| Network resources | OK | All available |

**Blocker verdict:** no blocker for Android builds; no blocker for Web builds. The only failing category is Visual Studio, which is required exclusively for Windows desktop apps and is not a project target (Android + Web). It was reported and intentionally not remediated, per the owner's "do not fix it yet" instruction.

### Final P0 evidence in the same pass

- `node verify_p0.mjs` exit 0, 1552 lines, `Missing required: 0`, all 23 required skills `OK`, all 8 required files `OK`, `Stray files in wrong place: none`, `Tracked files that must NOT be tracked: none`, secret scan clean (`sb_secret_` none, JWT none, publishable key none).
- Supabase MCP checks: `url present: yes`, `read_only=true: yes`, `project_ref present: yes`, `forbidden groups: none`, `plugins (V2 array): OK "@tarquinen/opencode-dcp@latest"`, `permissions (V2 array): OK 11 rules`, `deny shell actions: all 4 OK`, `deny secret/file reads: all 4 OK`.
- `git status --short` -> clean. `git log --oneline -4` -> `1a35f76`, `b8705ec`, `8ce6580`, `58a9528`.
- No `MISSING`, `ERROR`, `WARNING`, `plugin entries: none`, or `permission block: NO` line exists in the output.

## Executor switch to Claude Code (22 November 2026)

OpenCode is retired; Claude Code executes the project. Skills stay sourced in `.agents/skills/` (`skills-lock.json`) and are copied to `.claude/skills/` so the Claude Code `Skill` tool discovers them. `node verify_p0.mjs` reports all 23 required skills `OK` and `.claude/skills identical to .agents/skills: yes (222 files)`. After installing or updating a skill in `.agents/skills/`, re-copy it to `.claude/skills/` and re-run the verifier.

## P1 Database and Security: SKILLS LOADED (22 November 2026)

Loaded with the Claude Code `Skill` tool at the start of P1: `supabase`, `supabase-postgres-best-practices`, `writing-plans`, `test-driven-development`, `insecure-defaults`, `sharp-edges`, `verification-before-completion` (all 7 required by `docs/OPENCODE_PROMPT.md`).

Applied so far, in the plan only (no code yet):
- `writing-plans`: required header, Global Constraints, Review Focus (5 items, each with a test in its owning task), Interfaces per task, self-review.
- `supabase`: SECURITY DEFINER helpers in non-exposed `private` schema with `search_path = ''`; `TO authenticated` + ownership predicates; `(select auth.uid())`; explicit grants; `migration new` for filenames; advisors before completion; changelog check as Task 0 step 1.
- `supabase-postgres-best-practices`: indexes on FK/filter columns, `numeric(18,2)`, generated period columns.
- `test-driven-development`: every task starts with a failing pgTAP/Deno test.
- `sharp-edges` / `insecure-defaults`: storage path parser never raises (deny on malformed), no known seed passwords, service-only RPCs, idempotent finalize.

### P1 Task 0: Supabase changelog check (22 November 2026)

`supabase` skill rule "check the changelog first": fetched `https://supabase.com/changelog.md`. Breaking-change entries relevant to RLS, Storage, Data API grants, pgTAP or Edge Functions:
- 2026-04-28 Data APIs: new `public` tables are not exposed to the Data API by default (enforced on all projects since 2026-10-30). Every P1 table needs explicit `grant`s to `authenticated` (and RLS).
- 2026-07-22 Database: the version clause of `create extension` is ignored. Do not pin extension versions (`pgtap` is created without one).
- 2026-11-04 CLI v3: local by default, asks before hosted changes, so remote commands need `--remote` and an explicit confirmation.
- 2025-03-18 Auth/Storage: no DDL on the `auth`, `storage`, `realtime` schemas. Test helpers only insert rows into `auth.users`; own objects live in `public`, `private`, `tests`.
- 2026-10-12 TLS (CBC ciphers removed for Auth, Data APIs, Storage, Edge Functions): no action for this project.
- pgTAP, RLS-specific, Edge Functions-specific: none found.

Applied in Task 0: `test-driven-development` (smoke test written before the `enable_pgtap` migration; RED was not observed at the pgTAP level: the one `supabase test db --remote` attempt stopped at the CLI v3 agent consent gate before any test ran, and that command needs Docker anyway), `supabase` (`migration new` for the filename; verification uses `bash supabase/tests/run_remote.sh`, the R10 psql fallback because there is no Docker), `insecure-defaults` / `sharp-edges` (helpers file refuses to create objects unless included inside a test transaction).

Commit 2b3406f (controller, ruling R10): `supabase/tests/run_remote.sh` runs each `supabase/tests/database/*.test.sql` with the local psql 17 client against the linked pooler URL (no password in the URL; the password comes from the owner's pgpass, never from the repo or the command line). A file passes only when its TAP plan count equals its `ok` count with no `not ok` and no psql error. Fix round 1 hardened it: files whose first SQL statement is not `begin;` are refused and counted as FAIL (every remote run rolls back), and error detection is anchored to psql error lines (`^(psql:[^ ]* )?(ERROR|FATAL):`) so a test description containing "ERROR:" cannot cause a false FAIL.

### P1 Task 2: profiles, sites, user_sites, authorization helpers (23 November 2026)

SKILLS LOADED: `supabase-postgres-best-practices`, `supabase`, `test-driven-development`.
SKILLS APPLIED:
- `supabase`: security definer helpers live in the non-exposed `private` schema with `set search_path = ''` and an explicit `(select auth.uid())` check; `revoke execute from public, anon`; every policy is `to authenticated`; UPDATE policies have USING and WITH CHECK; no `user_metadata`; explicit grants to `authenticated` (new public tables are not auto-exposed) and nothing for `anon`; `migration new` for the filename.
- `supabase-postgres-best-practices`: `(select ...)` wrapping of `auth.uid()` and of the argument-free helpers in policies; index on `user_sites.site_id` (the PK covers `user_id`); least-privilege column-level UPDATE grants.
- `test-driven-development`: `02_profiles_sites.test.sql` written and run RED (fails on `relation "public.profiles" does not exist`) before the migration was applied.

### P1 Task 3: certificates (23 November 2026)

SKILLS LOADED: `supabase-postgres-best-practices`, `supabase`, `test-driven-development`, `verification-before-completion`.
SKILLS APPLIED:
- `supabase`: guard trigger function in the non-exposed `private` schema, `security invoker`, `set search_path = ''`, execute revoked from `public, anon, authenticated`; `alter default privileges for role postgres in schema private revoke execute on functions from public` before any new private function (R14); every policy is `to authenticated`; the UPDATE policy has USING and WITH CHECK; `revoke all ... from public, anon, authenticated` (the DEV default ACL hands `anon`/`authenticated` TRUNCATE/REFERENCES/TRIGGER/MAINTAIN on new public tables) then explicit grants; nothing for `anon`; `migration new` for the filename.
- `supabase-postgres-best-practices`: `numeric(18,2)` with a `check (amount >= 0)`; stored generated period columns; partial unique index (`where deleted_at is null`) whose leading `site_id` column covers the FK; index on `status`; `(select private.is_admin())` wrapping in the trigger; least-privilege column-level INSERT/UPDATE grants (status, site_id, created_by and soft-delete columns are not client-writable).
- `test-driven-development`: `03_certificates.test.sql` (48 tests) written and run RED against DEV (fails on `relation "public.certificates" does not exist`) before the migration was written; GREEN is run by the controller after `supabase db push` (R1, R11).
- `verification-before-completion`: no GREEN claim made; only the RED run and read-only checks were executed by the implementer.
- Fix round 1 (R14 revised): the per-schema default-ACL revoke does nothing (Postgres per-schema defaults can only add to the global defaults). The test now uses a catch-all guard instead: every function in `private` is checked for anon/authenticated execute, and only the three RLS helpers may be executed by authenticated (`supabase` rule: revoke `EXECUTE` from roles that should not call private functions). The guard also checks that the expected functions exist, so it cannot pass vacuously (`test-driven-development`: name the break). Suite: 4 files PASS (2/18/46/48).

### P1 Task 4: append-only audit log (23 November 2026)

SKILLS LOADED: `supabase-postgres-best-practices`, `supabase`, `test-driven-development`, `verification-before-completion`.
SKILLS APPLIED:
- `supabase`: `private.write_audit` (both overloads) is security definer in the non-exposed `private` schema with `set search_path = ''`, and execute is revoked from `public, anon, authenticated, service_role` per function (the per-schema default-ACL revoke is a no-op, so every function gets its own revoke); the 6-arg overload takes the actor from `(select auth.uid())`; the trigger function is `security invoker` with its own revoke; the SELECT policy is `to authenticated` with `(select private.is_admin())`; no INSERT/UPDATE/DELETE policies; `revoke all ... from public, anon, authenticated, service_role` then `grant select` to `authenticated, service_role` only; `migration new` for the filename.
- `supabase-postgres-best-practices`: `bigint generated always as identity` primary key; composite index on `(entity, entity_id)` matching the lookup pattern; `jsonb` for before/after snapshots; least privilege (no API role holds INSERT/UPDATE/DELETE/TRUNCATE); append-only enforced by a row-level BEFORE UPDATE OR DELETE trigger plus a statement-level BEFORE TRUNCATE trigger, so it holds for the table owner too.
- `test-driven-development`: `04_audit.test.sql` (34 tests) written and run RED against DEV (fails on `relation "public.audit_logs" does not exist`) before the migration was written; the site-user 0-row check is a plain `count(*)` with a precondition that rows exist, so it cannot pass vacuously.
- `verification-before-completion`: no GREEN claim made; GREEN (after `supabase db push`) is the controller's (R1, R11).

### P1 Task 5: status-transition RPCs (23 November 2026)

SKILLS LOADED: `supabase-postgres-best-practices`, `supabase`, `test-driven-development`.
SKILLS APPLIED:
- `supabase`: the five transition functions are security definer in the non-exposed `private` schema with `set search_path = ''`, fully qualified names and an explicit caller check (`(select private.is_admin())` / `(select private.has_site_access(site_id))`, both built on `auth.uid()`) because definer functions bypass RLS and the edit guard; the Data API surface is a `security invoker` wrapper in `public` with the same signature; execute is revoked per function from `public, anon, service_role` (the per-schema default-ACL revoke is a no-op and Supabase grants new `public` functions to anon/service_role) and granted to `authenticated` only; audit rows go through `private.write_audit` with `(select auth.uid())` as actor; `migration new` for the filename.
- `supabase-postgres-best-practices`: each function locks its row with `select ... for update` before checking status, so concurrent transitions serialize on the row and cannot both pass the from-status check; the lock is held only for one short statement sequence (lock-short-transactions); least privilege (no anon/service_role execute, private functions unreachable over the API); soft delete keeps the row and relies on the existing partial unique index (`where deleted_at is null`) so the period is freed.
- `test-driven-development`: `05_transitions.test.sql` (58 tests) written and run RED against DEV (fails on `function "private.submit_certificate(uuid)" does not exist`) before the migration was written; every negative test has a positive counterpart proving the fixture is real (site2's own user submits `c_site2`; s1 submits `c_draft2` after the admin/inactive/profile-less calls were rejected; a live `d_draft` blocks its period before the delete). `03_certificates.test.sql` test 6 allowlist extended with exactly the five private transition functions (plan unchanged). GREEN is run by the controller after `supabase db push`.

### P1 Task 6: attachments (23 November 2026)

SKILLS LOADED: `supabase-postgres-best-practices`, `supabase`, `test-driven-development`.
SKILLS APPLIED:
- `supabase`: `private.attachment_path_matches` lives in the non-exposed `private` schema as `security invoker` (no definer needed: it reads the parent certificate under the caller's RLS) with `set search_path = ''` and fully qualified names; execute revoked per function from `public, anon, service_role` (R14) and granted to `authenticated` only; both policies are `to authenticated`; the INSERT policy checks `uploaded_by = (select auth.uid())`; no UPDATE/DELETE policies; `revoke all ... from public, anon, authenticated, service_role` then explicit grants (table-level SELECT and column-level INSERT for `authenticated`, SELECT for `service_role`); nothing for `anon`; `migration new` for the filename.
- `supabase-postgres-best-practices`: partial unique index `attachments_active_sha256 (sha256) where deleted_at is null` for active-only dedup; index on the `certificate_id` FK (used by the RLS join); CHECK constraints for mime, size (1..2097152) and the sha256 format; `(select auth.uid())` / `(select private.is_admin())` wrapping in the policy; least-privilege column-level INSERT grant (uploaded_by, uploaded_at and the soft-delete columns are not client-writable).
- `test-driven-development`: `06_attachments.test.sql` (47 tests) written and run RED against DEV (fails on `relation "public.attachments" does not exist`) before the migration was written; every denial has a positive counterpart (s1 inserts `signed` on `c_await` before the admin is denied; s2 sees its own attachment before s1 is shown not to; 2097152 bytes accepted next to 2097153 rejected; the soft-deleted sha is accepted only after a precondition shows it is soft-deleted). `03_certificates.test.sql` test 6 allowlist extended with `private.attachment_path_matches(text,uuid)` (plan unchanged). GREEN is run by the controller after `supabase db push`.

### P1 Task 7: private certificates storage bucket (23 November 2026)

SKILLS LOADED: `supabase`, `supabase-postgres-best-practices`, `test-driven-development`.
SKILLS APPLIED:
- `supabase`: the bucket is private (`public = false`) with the 2097152-byte limit and the three mime types set on the bucket itself; both storage policies are `to authenticated` with a site-ownership predicate (not authentication alone, the BOLA/IDOR rule); no UPDATE policy, so upsert is impossible ("storage upsert requires INSERT + SELECT + UPDATE"), and no DELETE policy; `private.path_site_id` lives in the non-exposed `private` schema as `security invoker` with `set search_path = ''`; execute revoked per function from `public, anon, service_role` and granted to `authenticated` only; storage grants, RLS settings and other buckets untouched (no DDL on the storage schema beyond the policies); `migration new` for the filename.
- `supabase-postgres-best-practices`: RLS policies call a pure, `immutable` parser with no table access, and the site check is the existing `has_site_access` helper; malformed input is denied (null) instead of raising, with the uuid cast guarded by a strict regex inside CASE; the policies test `path_site_id(name) is not null` first because `has_site_access(null)` is true for admins (fail closed).
- `test-driven-development`: `07_storage.test.sql` (51 tests) written and run RED against DEV (fails on `objects_bucketId_fkey`: the `certificates` bucket does not exist) before the migration was written; every denial has a positive counterpart (s1 uploads and reads its own path before cross-site, malformed and other-bucket uploads are denied; s2 sees its own object before it is shown not to see s1's; the admin sees any site's object before the malformed-path object is shown hidden). The delete test pins what DEV does: `storage.protect_delete` (statement-level BEFORE DELETE trigger) raises 42501, and with `storage.allow_delete_query` set RLS alone deletes 0 rows; the session role then confirms the object still exists. `03_certificates.test.sql` test 6 allowlist extended with `private.path_site_id(text)` (plan unchanged). GREEN is run by the controller after `supabase db push`.

### P1 Task 8: finalize-certificate Edge Function and service RPCs (23 November 2026)

SKILLS LOADED: `supabase`, `supabase-postgres-best-practices`, `test-driven-development`, `sharp-edges`, `insecure-defaults`.
SKILLS APPLIED:
- `supabase`: `finalize_with_signed_copy` and `record_initial_file_deleted` are security definer with `set search_path = ''` and fully qualified names; they live in `public` because the Edge Function reaches them over the Data API. Execute is revoked per function from `public, anon, authenticated` (aclexplode test for PUBLIC) and granted to `service_role` only. `auth.uid()` is null for the service client, so the actor is an explicit `p_actor` checked against `profiles`/`user_sites` (an active `site_user` mapped to the site; `has_site_access` is not reused because it is true for admins). The `service_role`/secret key is used only inside the Edge Function. The function reads `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEYS` and `SUPABASE_SECRET_KEYS` (docs page "Environment variables"), with no fallback to the legacy keys. The caller's JWT is validated with `auth.getUser(jwt)`, never with `user_metadata`. supabase-js is pinned to an exact version (`2.119.0`, over 7 days old) in a per-function `deno.json`, and `deno.lock` is committed (npm-security guide). `migration new` gave the filename.
- `supabase-postgres-best-practices`: the certificate is locked with `select ... for update` before any check. `record_initial_file_deleted` takes the same lock order (certificate, then attachment), so a concurrent finalize and record cannot deadlock. The signed-copy check is one `exists` join on `storage.objects (bucket_id, name)`. Soft delete only: the attachment row is kept and only the storage object is hard-deleted.
- `test-driven-development`: `08_finalize.test.sql` (45 tests) was run RED against DEV (fails on `function "public.finalize_with_signed_copy(uuid,uuid)" does not exist`) before the migration; GREEN is the controller's after `supabase db push`. `handler_test.ts` was run RED (`Cannot find module .../handler.ts` and `.../_shared/auth.ts`) before the handler, then GREEN (17 passed). Fake clients record a call log, so the remove-then-record order and "no record after a failed remove" are asserted on real calls. Every denial has a positive counterpart: s2 finalizes its own `c_site2`; round 2 fails with only the old copy and passes with a new one.
- `sharp-edges`: fail closed on every empty/null edge. A missing `p_actor` → forbidden; a missing `approve_for_signing` audit row → `signed_copy_missing` (not "any signed copy qualifies"); an empty or whitespace bearer → 401; a non-uuid id → 400 before any RPC. RPC errors map through an allowlist of the four stable codes; anything else becomes a generic 500 `internal_error` with no database message.
- `insecure-defaults`: no secret has a fallback value. A missing or unparseable key env var gives 500 `server_misconfigured` instead of running with a default. Keys and the JWT are never logged. No CORS headers and no wildcard origin (mobile-only caller).

### P1 Task 9: admin-create-user Edge Function (23 November 2026)

SKILLS LOADED: `supabase`, `supabase-postgres-best-practices`, `test-driven-development`, `insecure-defaults`, `sharp-edges`.
SKILLS APPLIED:
- `supabase`: `public.audit_user_created` is security definer with `set search_path = ''` and fully qualified names; execute revoked from `public, anon, authenticated` (aclexplode test for PUBLIC) and granted to `service_role` only. `auth.uid()` is null for the service client, so the actor is an explicit `p_actor` checked against `profiles` (active admin). The caller is authorized only from its `profiles` row, read with the caller's user-scoped client so RLS applies (an inactive user cannot see its own row → 403); `user_metadata` is never read, and the invite passes only `redirectTo` (no `data`), so role/site data never land in user_metadata. supabase-js API confirmed against the pinned 2.119.0 typings and `search_docs`: `auth.admin.inviteUserByEmail(email, { redirectTo })`, `auth.admin.deleteUser(id)`, `AuthError.code` (`email_exists` / `user_already_exists` → 409). The secret key stays inside the Edge Function; supabase-js pinned to the same exact version with a committed `deno.lock`. `migration new` gave the filename.
- `supabase-postgres-best-practices`: least privilege on the new RPC; the audit payload's `site_ids` is one ordered `jsonb_agg` over the `user_sites` primary key (no extra index needed); the compensation deletes in FK order (user_sites → profiles → auth user) because `profiles.id` is `on delete restrict`.
- `test-driven-development`: `09_admin_create_user.test.sql` (14 tests) run RED against DEV (`function "public.audit_user_created(uuid,uuid)" does not exist`) before the migration; GREEN is the controller's after `supabase db push`. `handler_test.ts` and `_shared/env_test.ts` run RED (`Cannot find module .../handler.ts` / `.../env.ts`), then GREEN (27 and 19 passed). Fakes keep a call log so the compensation order (user_sites, profile, then deleteUser) and "no write before validation" are asserted on real calls; every denial has a 201 counterpart.
- `sharp-edges`: fail closed on empty/null edges: an empty `INVITE_REDIRECT_URL` is treated as missing (500 `config_missing`, checked before the invite, no fallback); `site_ids: null` or non-array → 400; duplicate ids compared after lowercasing; admin with site ids → 400; null `p_actor` → forbidden. Compensation removes the profile only if this call inserted it, so a re-invite of an existing user cannot delete that user's profile.
- `insecure-defaults`: no secret or URL has a default value (missing keys → 500 `server_misconfigured`, missing redirect → 500 `config_missing`). Errors from Auth/PostgREST never reach the response (generic `internal_error` / `create_failed`). Compensation failures log only the user id and step name, never the email, keys or JWT. No CORS headers.

### P1 Task 10: fake seed data (23 November 2026)

SKILLS LOADED: `supabase`, `supabase-postgres-best-practices`, `test-driven-development`, `insecure-defaults`, `sharp-edges`.
SKILLS APPLIED:
- `supabase`: the seed lives in `supabase/seed.sql` and is applied only through `supabase db push --include-seed --remote --yes` (wired by `[db.seed] sql_paths` in `config.toml`), never as ad-hoc SQL against the project; the fake accounts are written into `auth.users` **and** `auth.identities` (one `provider = 'email'` identity each) so the real sign-in path works instead of a table that merely looks populated; no `service_role` key appears anywhere in the repository, and no destructive statement was run. `--dry-run --include-seed` was used first and reported exactly `"seeds":["supabase/seed.sql"]` with no pending migrations.
- `supabase-postgres-best-practices`: fixed UUIDs (`5eed0000-...`) make the seed deterministic, so it can be verified and re-run safely; every insert ends in `on conflict ... do nothing`; the generated period columns (`period_year`, `period_month`, `period_half`) are never written — the database derives them — and the amounts are `numeric(18,2)` literals, never floats; the five certificates sit in five different half-month periods so the partial unique index `certificates_one_per_period` is exercised without being violated.
- `test-driven-development`: `supabase/tests/seed_verify.sql` (read-only) was written and executed **before** the seed: RED, `ERROR: seed check: expected 3 fake auth users, found 0`. After `db push --include-seed` the same file was re-run: GREEN, `NOTICE: seed check: all assertions passed` plus the evidence table (3 users / 3 profiles / 2 sites / 2 assignments / 5 certificates / 0 attachments). The full pgTAP suite was then re-run to prove the seed breaks nothing: `Files=10, Result: PASS` (367 assertions).
- `insecure-defaults`: no fake account has a usable shared password — each hash is `extensions.crypt(gen_random_uuid()::text, extensions.gen_salt('bf', 10))`, so nothing is recoverable, and the verifier actively tries seven common passwords against every stored hash and fails the check if any matches; the data is unmistakably fake (`@example.test`, names ending in `(seed)`, notes starting with "Fake"), so it cannot be confused with real financial records.
- `sharp-edges`: `db push` skips the seed when the database is already up to date (`"seeds":[]`), so the CLI run alone does not prove idempotency; the file was therefore executed twice directly with `psql` and an md5 over users, identities and certificates was compared before and after — identical, exit 0. The status-dependent columns (`submitted_at`, `locked_at`, `return_note`) mirror exactly what the transition RPCs set, so a seeded `returned` row is not a state the RPCs could never produce.

### P1 Task 11: advisors, deployment and evidence (23 November 2026)

SKILLS LOADED: `supabase`, `supabase-postgres-best-practices`, `verification-before-completion`, `insecure-defaults`.
SKILLS APPLIED:
- `verification-before-completion`: every statement in the phase report is backed by a command run in this session and its real output — `supabase functions list` (both `ACTIVE`, `verify_jwt: true`), `supabase db advisors --remote --type all --level info` and MCP `get_advisors` (same 8 findings), MCP `list_tables` (6 tables, `rls_enabled: true`, seed row counts), `Files=10, Result: PASS`, `17/25/2 passed | 0 failed`, the seed verifier NOTICE, and the RLS probe (site1 5/1/1, site2 0/1/1, admin 5/2/3). No phase was declared approved: approval is the owner's.
- `supabase`: deployed with `--use-api` because Docker is unavailable, naming both functions explicitly instead of "deploy all" and without `--prune`, so nothing can be deleted; `verify_jwt` was left at the platform default (`true`) because both functions are called by signed-in users; the platform-provided `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEYS` / `SUPABASE_SECRET_KEYS` are present (listed only as digests), so no legacy key fallback is needed.
- `supabase-postgres-best-practices`: advisors re-read after seeding; 0 security ERROR/CRITICAL. The 5 unindexed-FK and 2 unused-index items stay INFO and are accepted: those foreign keys (`created_by`, `deleted_by`, `uploaded_by`, `actor_id`) are never used as filter predicates, and the two indexes serve planned screens rather than the current empty tables. No index was added for a hypothetical query.
- `insecure-defaults`: two gaps were found and are reported to the owner instead of being papered over — the project-level `auth_leaked_password_protection` WARN (enable HaveIBeenPwned checking in the dashboard) and the missing `INVITE_REDIRECT_URL` function secret, which makes `admin-create-user` answer `500 config_missing` by design rather than falling back to a default URL. The RLS probe also confirms the seed grants no cross-site visibility (site2 sees 0 of site1's 5 certificates).
## P2: App Foundation (23 November 2026)

Phase skills loaded at start (per docs/OPENCODE_PROMPT.md "Skills per phase" + mandatory set): `using-superpowers`, `brainstorming`, `audit-context-building`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `writing-plans`, `executing-plans`, `flutter-apply-architecture-best-practices`, `flutter-setup-declarative-routing` (table name `flutter-declarative-routing`), `flutter-implement-json-serialization` (table name `flutter-json-serialization`), `dart-run-static-analysis`, `dart-use-pattern-matching`, `ui-ux-pro-max`, `flutter-build-responsive-layout` (table name `flutter-responsive-layout`), `supabase`. `flutter-bloc` remains the owner-approved documented exception (no such skill exists upstream); `flutter_bloc` is used with the architecture skill's layering.

### P2 Task 0: design system document

SKILLS LOADED: `ui-ux-pro-max`, `brainstorming`, `writing-plans`.
SKILLS APPLIED:
- `ui-ux-pro-max`: ran `--design-system` twice; both outputs (Enterprise Gateway/OLED, then Glassmorphism/Fira Code) were rejected as off-topic per the Query Contract and NOT persisted; the doc labels the style direction as fallback and adopts only verified targeted matches: `minimalism-and-swiss-style` with `rtl_level: full` (`--domain style --rtl=full`), the "Arabic Elegant" pairing (`--domain typography`), IBM Plex Sans Arabic (`--domain google-fonts`), the light Banking/Traditional Finance palette (`--domain color`), form error rules (`--domain ux`), and `Theme.of(context)`/darkTheme/no-hardcoded-colors (`--stack flutter`).
- `brainstorming`: understanding summary + decision log (D1-D7) written into `docs/DESIGN_SYSTEM.md`; business-fixed rules (status colors, 48dp targets, Western digits default) taken from PROJECT_PLAN.md, not invented.
- `writing-plans`: phase plan saved to `docs/superpowers/plans/2026-11-23-p2-app-foundation.md` with Global Constraints, Review Focus (5 failure modes pinned to tasks), interfaces and self-review.

### P2 Task 1: scaffold, strict analysis, env config, arabic font

SKILLS LOADED: `flutter-setup-declarative-routing`, `dart-run-static-analysis`, `supabase`, `test-driven-development`, `verification-before-completion`.
SKILLS APPLIED:
- `flutter-setup-declarative-routing`: scaffold step exactly as the skill prescribes (`flutter create`, platforms android+web only); `go_router` added now, router configured in Task 7.
- `dart-run-static-analysis`: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`, enables `strict-casts`/`strict-inference`/`strict-raw-types`, excludes `**/*.g.dart`, `**/*.freezed.dart`, `lib/l10n/gen/**`; formatter `page_width: 100`, `trailing_commas: preserve`. `flutter analyze` run after the task: No issues found.
- `supabase`: publishable key fetched with read-only MCP `get_publishable_keys`; `Supabase.initialize` parameter names verified against the 2.18.3 API docs (`url` + `publishableKey`; `anonKey` deprecated). `AppConfig.parse` rejects `sb_secret_` keys and service_role JWTs so a secret can never reach the client; only `app/env/dev.example.json` is committed (`git check-ignore` proves `dev.json` ignored, example not ignored).
- `test-driven-development`: `app_config_test.dart` (8 tests) written first and run RED (`'ConfigException' isn't a type`), then minimal implementation, GREEN 8/8.
- `flutter-build-responsive-layout`: removed the generated `"orientation": "portrait-primary"` lock from `web/manifest.json` (skill: never lock orientation).
- Deviation (minor, recorded): `AppConfig.fromEnvironment` is a validating factory reading `const String.fromEnvironment`, not a const constructor (validation cannot run in const context).

### P2 Task 2: sealed AppFailure and exception mapper

SKILLS LOADED: `dart-use-pattern-matching`, `test-driven-development`, `supabase`.
SKILLS APPLIED:
- `dart-use-pattern-matching`: mapper is a switch expression with object patterns (`AuthException(code: 'invalid_credentials')`, `AuthException(:final code, :final message)`); the sealed hierarchy is matched exhaustively without a default arm in a compile-time test; unknown AuthException codes are preserved in `ServerFailure`, never silently dropped.
- `test-driven-development`: 8 mapper tests run RED (missing files) before implementation; GREEN 16/16 total.
- `supabase`: exception constructors verified from the resolved pub-cache sources (`AuthException(message, {statusCode, code})`, `PostgrestException({required message, code, details, hint})`) instead of guessed.
- Platform correctness: `dart:io` `SocketException` detection lives in a conditional-import helper (`network_error_stub.dart` / `network_error_io.dart`) so the same code compiles for Web and Android.

### P2 Task 3: material 3 theme extensions and arabic rtl localization

SKILLS LOADED: `ui-ux-pro-max`, `dart-run-static-analysis`, `test-driven-development`, `systematic-debugging`.
SKILLS APPLIED:
- `ui-ux-pro-max`: every token in `AppTheme`/`AppSpacing`/`AppRadii`/`AppStatusColors` comes from DESIGN_SYSTEM.md (verified palette hex, 4/8/12/16/24/32/48 spacing, 8/12/16 radii, status pairs); 48dp minimum button size enforced in all three button themes; Arabic body height 1.5, letter-spacing 0, no text below 12; light AND dark themes provided (`--stack flutter` rule).
- `test-driven-development`: theme + l10n tests written first, run RED (both files fail to load), then implementation; GREEN 26/26.
- `systematic-debugging`: two failures diagnosed from real output before fixing — `gen-l10n` refused without `flutter: generate: true` (added flag), and `ThemeData.fontFamily` is not a getter (test corrected to assert `textTheme.bodyLarge!.fontFamily`); unused-import warning removed; final `flutter analyze` No issues found.
- All user-facing strings live in `lib/l10n/app_ar.arb`; RTL proven by widget test (`Directionality.of == rtl` under `Locale('ar')`).

### P2 Task 4: shared loading, empty and error widgets

SKILLS LOADED: `ui-ux-pro-max`, `flutter-build-responsive-layout`, `test-driven-development`.
SKILLS APPLIED:
- `test-driven-development`: 5 widget tests written first, run RED (missing widget files), then minimal implementation; GREEN 31/31 total.
- `ui-ux-pro-max`: error retry is a real >=48dp button (tested), loading announces via `Semantics(liveRegion: true)`, empty/error states are first-class widgets; icon sizes use the `AppSpacing.xxxl` token instead of a literal 48.
- Test-only helper `test/helpers/localized_app.dart` keeps localization/theme setup out of production code (writing-good-tests rule).

### P2 Task 5: auth data and domain layers

SKILLS LOADED: `flutter-apply-architecture-best-practices`, `flutter-implement-json-serialization`, `dart-use-pattern-matching`, `supabase`, `test-driven-development`, `systematic-debugging`.
SKILLS APPLIED:
- `flutter-apply-architecture-best-practices`: strict layering — `AuthService`/`ProfileService` (stateless API wrappers) -> `AuthRepositoryImpl` (single source of truth, returns domain `AppUser`) -> cubits; no Supabase type crosses into `domain/`.
- `flutter-implement-json-serialization` + `dart-use-pattern-matching`: `ProfileRow.fromJson` generated by json_serializable with exact column names (`full_name`, `is_active`); role mapping is a switch expression that fast-fails (`FormatException`) on unknown roles instead of silently defaulting; missing required keys throw (tested).
- `supabase`: profile read is `select('id, full_name, role, is_active').eq('id', userId).single()` under RLS; role never comes from `user_metadata`; a missing/inaccessible profile row on restore signs the user out (fail closed), while a network error keeps the persisted session (tested both).
- `test-driven-development`: 5 model tests + 12 repository tests run RED before implementation; GREEN 48/48 total. mocktail mocks only the two service seams; repository logic is real.
- `systematic-debugging`: freezed compile error (`_ProfileRow` missing `toDomain`) diagnosed from the real error text — freezed's generated class `implements` the interface, so the mapping moved to an extension; `prefer_initializing_formals` fixed with positional constructor params.

### P2 Task 6: session and login blocs with arabic login page

SKILLS LOADED: `flutter-apply-architecture-best-practices`, `dart-use-pattern-matching`, `ui-ux-pro-max`, `test-driven-development`, `systematic-debugging`.
SKILLS APPLIED:
- `flutter-apply-architecture-best-practices`: views are lean — `LoginPage` only renders `LoginState` and forwards events; all logic in cubits; `SessionCubit` owns session restore + event subscription and cancels it in `close()`.
- `dart-use-pattern-matching`: sealed `SessionState` matched exhaustively in `restore()`; failure-to-Arabic mapping in the page is an exhaustive switch over the sealed `AppFailure` (no default arm).
- `ui-ux-pro-max`: visible floating labels (never placeholder-only), inline Arabic error under each invalid field, failure banner uses `errorContainer/onErrorContainer` tokens, submit disabled + spinner while pending (tested), form constrained to the new `AppSpacing.formMaxWidth` (640) token.
- `test-driven-development`: 7 session + 5 login-cubit + 4 page widget tests written first and run RED; GREEN 64/64 total.
- `systematic-debugging`: 27 analyzer errors traced to ONE missing `flutter_bloc` import; three test-expectation mismatches fixed against real bloc semantics (equal states are deduplicated; trim+submitting is a single emit) after reading the actual Expected/Actual diff — production code was not bent to fit wrong tests.

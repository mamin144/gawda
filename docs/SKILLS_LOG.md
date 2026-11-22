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

Applied in Task 0: `test-driven-development` (smoke test written before the `enable_pgtap` migration and run first as RED), `supabase` (`migration new` for the filename, `test db --remote`), `insecure-defaults` / `sharp-edges` (helpers file refuses to create objects unless included inside a test transaction).

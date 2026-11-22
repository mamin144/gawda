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

## P1: Database and Security (pending)
- Status: Not started - awaiting owner approval of P0.
- Requirements: supabase CLI, pgTAP tests, RLS policies, seed data, Edge Functions.
- Dependencies: supabase, supabase-postgres-best-practices, insecure-defaults, sharp-edges, audit-context-building.

## P2: App Foundation (pending)
- Status: Not started.
- Requirements: Flutter project creation, Auth setup, go_router, state management, localization.
- State-management decision: use `flutter_bloc` as approved by the owner; the project does not depend on a separate unavailable `flutter-bloc` skill.

### P2 notes (recorded during P0; do not act on them before P2)
- Supabase DEV project URL: `https://kbjsonvnbbhvczttvzhv.supabase.co` (project_ref `kbjsonvnbbhvczttvzhv`).
- URL and publishable key: stored in `app/env/dev.json` (gitignored). Commit only `app/env/dev.example.json` with placeholders. Run with `--dart-define-from-file=env/dev.json`. No key is ever committed.
- Before writing the init code, check the current `Supabase.initialize(...)` parameter names of `supabase_flutter` with the Context7 MCP (the dashboard quickstart uses `url` + `publishableKey`; older versions used `anonKey`).
- Do NOT use the Supabase quickstart `todos` sample code or table. The schema comes only from `supabase/migrations/`.
- Never use secret / `service_role` keys in the app.
- `docs/DESIGN_SYSTEM.md` (from `ui-ux-pro-max`) must exist before any UI code.

## P3-P7: Pending
- Status: Not started.

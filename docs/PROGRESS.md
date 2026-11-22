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

## P1: Database and Security (pending)
- Status: Not started - awaiting owner approval of P0.
- Requirements: supabase CLI, pgTAP tests, RLS policies, seed data, Edge Functions.
- Dependencies: supabase, supabase-postgres-best-practices, insecure-defaults, sharp-edges, audit-context-building.

## P2: App Foundation (pending)
- Status: Not started.
- Requirements: Flutter project creation, Auth setup, go_router, state management, localization.
- State-management decision: use `flutter_bloc` as approved by the owner; the project does not depend on a separate unavailable `flutter-bloc` skill.

## P3-P7: Pending
- Status: Not started.

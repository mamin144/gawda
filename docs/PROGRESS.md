# Progress Log - Site Financial Quality Tracking System

## P0: Environment Bootstrap
- Status: Performed; awaiting owner approval (not self-approved).
- Skills: 23 installed skills are present under `.agents/skills/`, each with a `SKILL.md`; the unavailable `flutter-bloc` skill is an owner-approved exception, not an installed skill.
- `insecure-defaults`: upstream `trailofbits/skills` ships it as a plugin (`plugins/insecure-defaults`), not as a skill; `npx skills add ... --skill insecure-defaults` returns `[SKILLS_NO_MATCHING_SKILLS]`. Vendored from the upstream repo and wrapped with a `SKILL.md` (see `docs/SKILLS_LOG.md`).
- `flutter-bloc`: no BLoC skill exists in `flutter/agent-plugins` (25 skills listed, none BLoC/Cubit). The owner approved use of the `flutter_bloc` package with `flutter-apply-architecture-best-practices` as a documented exception on 22 November 2026; this is no longer an open question.
- MCP servers: Supabase (remote, read-only, DEV project), Dart (local), and Context7 (remote) were all reported `connected` by `opencode mcp list` on 22 November 2026. An unrelated stale global `shadcn` entry failed because its old path no longer exists; it was not modified from this project.
- OpenCode config: migrated to the native V2 shape after verifying the installed Desktop CLI is `2.1.4`; server entries now live under `mcp.servers`, and V2 `permissions` preserve the planned safety denials.
- Plugins: `opencode-dcp` version `3.2.1` is installed. `opencode-notifier` remains optional and is not installed. Envsitter Guard is not installed; V2 read permissions deny `.env*`, `.xlsx`, and `.xlsm` files instead.
- Git repo: initialized, 3 commits.
- .gitignore: `.env*`, `*.xlsx`, `*.xlsm`, `app/env/`, build outputs.
- docs/ layout: `PROJECT_PLAN.md`, `OPENCODE_PROMPT.md`, `OPEN_QUESTIONS.md`, `PROGRESS.md`, `SKILLS_LOG.md`. `AGENTS.md` is at the repository root.
- Supabase URL/key: stored in `app/env/dev.json` (gitignored), see P2. No publishable key is committed; `git log --all -S "sb_publishable"` returns nothing.
- Environment gaps: Python is not installed (`py` and `python3` are unavailable); this must be installed before P2 because the approved UI/UX tooling requires `python3`. Drive C: has about 545 MB free, so free space must be checked before installing it.

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

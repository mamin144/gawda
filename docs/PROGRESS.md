# Progress Log - Site Financial Quality Tracking System

## P0: Environment Bootstrap
- Status: Performed; awaiting owner approval (not self-approved).
- Skills: 23/23 required skills present under `.agents/skills/`, each with a `SKILL.md`; `node verify_p0.mjs` reports `Missing required: 0`.
- `insecure-defaults`: upstream `trailofbits/skills` ships it as a plugin (`plugins/insecure-defaults`), not as a skill; `npx skills add ... --skill insecure-defaults` returns `[SKILLS_NO_MATCHING_SKILLS]`. Vendored from the upstream repo and wrapped with a `SKILL.md` (see `docs/SKILLS_LOG.md`).
- `flutter-bloc`: no BLoC skill exists in `flutter/agent-plugins` (25 skills listed, none BLoC/Cubit). `flutter-apply-architecture-best-practices` contains 0 occurrences of `bloc`/`cubit`. No substitution is claimed; this is an open item for P2.
- MCP servers: supabase (remote, read-only, DEV project), dart (local), context7 (remote). Supabase MCP proven with `list_tables` -> `{"tables": []}`.
- Git repo: initialized, 3 commits.
- .gitignore: `.env*`, `*.xlsx`, `*.xlsm`, `app/env/`, build outputs.
- docs/ layout: `PROJECT_PLAN.md`, `OPENCODE_PROMPT.md`, `OPEN_QUESTIONS.md`, `PROGRESS.md`, `SKILLS_LOG.md`. `AGENTS.md` is at the repository root.
- Supabase URL/key: stored in `app/env/dev.json` (gitignored), see P2. No publishable key is committed; `git log --all -S "sb_publishable"` returns nothing.
- Environment gaps: Python is not installed (only the Microsoft Store alias stub); drive C: has under 1 GB free, which blocks `npm install -g` and a Python install.

## P1: Database and Security (pending)
- Status: Not started - awaiting owner approval of P0.
- Requirements: supabase CLI, pgTAP tests, RLS policies, seed data, Edge Functions.
- Dependencies: supabase, supabase-postgres-best-practices, insecure-defaults, sharp-edges, audit-context-building.

## P2: App Foundation (pending)
- Status: Not started.
- Requirements: Flutter project creation, Auth setup, go_router, state management, localization.
- Open question: the plan names BLoC, but no BLoC skill exists upstream. Owner must decide: install a third-party BLoC skill, or approve a documented deviation.

## P3-P7: Pending
- Status: Not started.

# AGENTS.md: Site Financial Quality Tracking System

This file is loaded in every session. Follow it exactly.

## Source of truth
- Read `docs/PROJECT_PLAN.md` before any task. It is the only source of product and business decisions.
- Open questions live in `docs/OPEN_QUESTIONS.md`. If a task depends on an unanswered question, STOP and ask the owner. Never guess a business rule, a financial formula, a field, or a status transition.

## Skills are MANDATORY (strict)
1. Before starting any phase or task, load every skill listed for that phase in `docs/OPENCODE_PROMPT.md` (section "Skills per phase") using the native `skill` tool.
2. If a required skill is not installed, find it, install it (see the install protocol in the prompt), verify it loads, and only then continue.
3. If a required skill cannot be installed or loaded, STOP and report. Do NOT continue without it and do NOT replace it with your own knowledge.
4. Start every phase report with a "SKILLS LOADED" list and end it with a "SKILLS APPLIED" list that says concretely which rules of each skill changed the code. Append the same to `docs/SKILLS_LOG.md`.
5. Skills override your general habits. If a skill and your instinct disagree, follow the skill.

## Working method
- Work in small tasks (one concern at a time). Commit after each task with a clear message.
- Use the superpowers skills: `writing-plans` to plan a phase, `executing-plans` or `subagent-driven-development` to execute it, `test-driven-development` for logic, `systematic-debugging` for any bug, `verification-before-completion` before claiming anything is done.
- Never claim success without running the verification commands and showing their real output summary: `flutter analyze`, `flutter test`, `supabase test db`, and the build for the targets that exist.
- Use the Context7 MCP and the Dart MCP to check current APIs of `supabase_flutter`, `go_router`, `flutter_bloc` and other packages instead of guessing signatures.

## Safety rules
- Never commit or print secrets. `.env`, keys, tokens, the Excel source file and any password stay out of Git. The Flutter app only ever uses the project URL and the `anon` key. The `service_role` key never appears in app code.
- Never run destructive commands against a remote database or storage (`supabase db reset --linked`, dropping tables, deleting buckets). Never run `git push --force`, `rm -rf` outside the project, or any command that touches the user's home directory.
- The Supabase MCP is scoped to the DEV project and read-only. Schema changes go through migration files in `supabase/migrations/` applied with the Supabase CLI. Never create or delete Supabase projects.
- Never use `user_metadata` for authorization. Every table has RLS enabled with tests.
- Do not store financial values in `double`. Totals are computed in PostgreSQL.

## Language and UI
- Code, identifiers, comments, commits: English. App UI and user-facing messages: Arabic (RTL first), through localization files, never hardcoded strings.

## Reporting
After each phase give: SKILLS LOADED, what was built, commands run and results, tests added, deviations from the plan (should be none), and new open questions.

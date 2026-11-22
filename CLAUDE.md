# CLAUDE.md

Claude Code is the executor for this project (OpenCode was retired on 22 November 2026).
All project rules live in `AGENTS.md`, imported below. Follow it exactly.

@AGENTS.md

## Claude Code specifics
- Skills: project skills are discovered from `.claude/skills/<name>/SKILL.md` and loaded with the `Skill` tool.
  `.agents/skills/` is the source of truth (tracked in `skills-lock.json`); `.claude/skills/` is a copy that
  must stay identical (`node verify_p0.mjs` checks this). After adding or updating a skill in `.agents/skills/`,
  re-copy it to `.claude/skills/`.
- Skills per phase: use the table in `docs/OPENCODE_PROMPT.md` (section "Skills per phase"). The OpenCode-specific
  setup steps in that file (opencode.json, OpenCode plugins, `opencode mcp ...`) are historical and no longer apply.
- MCP servers: defined in `.mcp.json` (project scope only): `supabase` (DEV project, `read_only=true`),
  `dart` (`dart mcp-server`), `context7`. Never add a global Supabase MCP entry, never drop `read_only=true`
  or the `project_ref` scoping, never enable the `account`, `branching`, `feedback` or `notebooks` feature groups.
- Safety: `.claude/settings.json` holds the deny rules (destructive commands, `.env*`, Excel files, `app/env/*.json`).
  Do not weaken them.

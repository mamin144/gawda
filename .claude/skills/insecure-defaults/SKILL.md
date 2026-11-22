---
name: insecure-defaults
description: Detect insecure default configuration in a codebase — fallback secrets, seeded default credentials, fail-open switches, weak crypto, permissive access, and debug leakage. Use when auditing config, auth defaults, secrets handling, or hardening a service before release.
---

# Insecure Defaults Detection

This skill is a vendored copy of the upstream Trail of Bits plugin
`insecure-defaults` v2.0.3 (`plugins/insecure-defaults` in
`trailofbits/skills`). Upstream ships it as a Claude Code plugin
(commands + workflow + references), not as a `SKILL.md` skill, so this
manifest wraps the same upstream corpus. The authoritative rules are in
`references/*.md`; do not invent categories beyond them.

Audits a codebase for insecure default configuration, tracing each candidate
before reporting it. Whatever path you are given is the target, however
test-like it looks: a run scoped to `tests/` audits the tests. Exclusions
(fixtures, docs, vendored code) apply only outside the scope named.

## Corpus check first (no fallback)

List `references/`. It must contain the `*.md` corpus files. If it errors or
lists none, **stop and say so**. Do not search elsewhere, do not guess, and do
not run the audit anyway.

## What it finds

| Category            | Example                                | Corpus                                                        |
| ------------------- | -------------------------------------- | ------------------------------------------------------------- |
| Fallback secrets    | `SECRET = env.get('KEY') or 'dev'`     | [fallback-secrets.md](references/fallback-secrets.md)         |
| Default credentials | seeded `admin` / `admin123`            | [default-credentials.md](references/default-credentials.md)   |
| Fail-open switches  | `getenv('REQUIRE_AUTH', 'false')`      | [fail-open-security.md](references/fail-open-security.md)     |
| Weak crypto         | `hashlib.md5(password)`                | [weak-crypto.md](references/weak-crypto.md)                   |
| Permissive access   | `ACL='public-read'`, `0o666`, CORS `*` | [permissive-access.md](references/permissive-access.md)       |
| Debug leakage       | `traceback.format_exc()` in a response | [debug-features.md](references/debug-features.md)             |

Each category is three files that must agree: `workflows/audit.js` (the
`{ id, title }` row), `references/<id>.json` (title + seed patterns), and
`references/<id>.md` (**Report when** / **Skip when**, plus worked
vulnerable/secure pairs). `tests/seed-coverage.js` checks that the three
correspond.

## How candidates are judged

Candidates come in two shapes, judged differently:

- **Configurable**: a lookup with a fallback. Only a bug if the app runs with
  it. `env.get('K', 'x')` does; `env['K']` crashes instead, so it is fine.
- **Unconditional**: no configuration anywhere, insecure as written. About
  half of all findings. A missing env var is _not_ grounds to refute one.

## Procedure

1. Classify scope, profile the stack and deploy manifests.
2. Sweep each category against its own `references/<id>.md` + `.json` only.
3. Verify: trace every candidate to the security decision it actually reaches
   before reporting it. Refute candidates that the runtime cannot reach.
4. Report by outcome:
   - findings confirmed → report them with file/line, category, and the trace.
   - no candidates matched → say so, and state that this is not proof of absence.
   - audit did not complete → say the run failed; it is not a clean result.

For this project (Flutter + Supabase) pay particular attention to: the
`anon` vs `service_role` key boundary, RLS enabled on every table, CORS and
storage bucket policies, seeded users, and any secret with a development
fallback.

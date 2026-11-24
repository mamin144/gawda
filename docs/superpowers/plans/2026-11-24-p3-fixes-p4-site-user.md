# P3 Fix Wave + P4 Site-User Flow Repair Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (chosen: inline) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the parked P3 review findings (P1/P2/Minors) and turn the P4 site-user flow that OpenCode committed (`5b5b108..133f1a8`) into working, tested code: today every attachment upload, every draft insert and every delete fails at runtime.

**Architecture:** Server rules stay in PostgreSQL. One new migration adds the P3 guards, the no-op audit skip, the server-side `archived_at`, and a `remove_attachment` RPC (private SECURITY DEFINER + public invoker wrapper, the P1 transition pattern). The app keeps the P2 layering (Service → Repository `Result<T>` → Cubit → Page); pure helpers for period/path/date/mime move out of the page so they can be unit-tested.

**Tech Stack:** Flutter 3.47.6, flutter_bloc 9, supabase_flutter 2.18, fpdart, mocktail/bloc_test, uuid 4; Supabase Postgres + pgTAP via `supabase/tests/run_remote.sh`.

**Spec:** `docs/PROJECT_PLAN.md` §3, §7, §8, §11 (site-user UX), §12 (P4 row). Answers: `docs/OPEN_QUESTIONS.md` Q13 (site user soft-deletes until approved), Q16 (archive is one action), Q17 (admins are never linked to sites). New: **Q21** (remove attachment from a draft/returned certificate, proposed yes) — implemented under the owner's full-autonomy grant and flagged for confirmation.

## Defects being fixed (found in review of 4272f41)

| # | Where | Defect | Effect |
|---|---|---|---|
| D1 | `certificate_entry_page.dart` | storage path uses `day` and the original file name | `attachment_path_matches` + storage `path_site_id` reject every upload |
| D2 | `certificates_repository_impl.dart` createDraft | sends `status` column (no insert grant on it) | every draft insert → 42501 |
| D3 | repository date | `toUtc().toIso8601String()` | in UTC+2 a date picked at local midnight shifts one day back → wrong period |
| D4 | service `softDeleteCertificate` | direct `deleted_at` update (no grant) | delete always fails; must use `delete_certificate` RPC |
| D5 | service `softDeleteAttachment` | hard `.delete()` (no grant, violates soft delete) | must use a soft-delete RPC |
| D6 | service `fetchAttachments` | does not filter `deleted_at is null` | removed files still listed / block re-upload |
| D7 | entry page | PNG uploaded with mime `image/jpeg`; gallery images always `image/jpeg` | wrong metadata; bucket MIME check |
| D8 | entry page | "Save draft" always inserts a new certificate | second save → 23505 duplicate period |
| D9 | entry page | `_site` stays null until the user touches the dropdown | save silently does nothing |
| D10 | entry page | raw `cert.status.name`; nested `Scaffold` inside the shell | English text in UI; double app bar |
| D11 | entry page | no auto-save (§11), image compression = quality only | §11 gap; big camera photos exceed 2 MB |

## Global Constraints

- Storage/attachment path: `site_id/period_year/period_month/period_half/<name>`, integers unpadded; `period_half` = 1 for days 1–15, 2 for day 16..end; period derives from `certificate_date` (§7). Name = `<uuid v4>.<ext>`; the original name goes only to `file_name`.
- Files: PDF/JPG/PNG only, ≤ 2 MB (2097152 bytes), images compressed before upload (§7 line 78). MIME by extension: pdf→`application/pdf`, jpg/jpeg→`image/jpeg`, png→`image/png`.
- `certificate_date` is sent as the local calendar date `YYYY-MM-DD` (no UTC conversion).
- Client insert columns on certificates: `site_id, certificate_date, amount, notes` only; update: `certificate_date, amount, notes` only.
- Soft delete only; status changes and deletes go through RPCs (`delete_certificate`, new `remove_attachment`). No client `deleted_at` writes, no hard deletes.
- Amounts stay strings end-to-end (never `double`).
- Every new function: `search_path = ''`, per-function revoke from `public, anon, service_role`, grant to `authenticated`, pgTAP tests.
- UI strings Arabic via `app_ar.arb` only.

## Review Focus

1. A date picked late in the day / at local midnight on the 15th vs 16th and on the last day of a month → correct `period_half` in the storage path and the `certificate_date` string (Task 3 tests).
2. `remove_attachment` on a certificate of another site, on a submitted/approved certificate, on an already removed row, and by an admin → refused (Task 1 tests).
3. Upload succeeds in Storage but the row insert fails (duplicate sha) → user gets the duplicate message; orphan object is tolerated (no client delete policy; Ruling R2).
4. Auto-save racing a manual save / submit → no second insert (Task 4 tests).
5. `profiles_guard` `has_sites` and the `user_sites` insert guard do not break `admin_set_user_sites` for a valid site_user (Task 1 tests).

## Rulings taken while planning

- **R1:** `remove_attachment(p_id uuid, p_reason text default null)` — allowed for the site user with access while the certificate is `draft` or `returned` and not deleted; admin follows the same status rule (consistent with Q13 spirit). Soft delete (`deleted_at/deleted_by/delete_reason`), storage object kept. Cost if wrong: one more migration.
- **R2:** No client storage delete policy exists (by P1 design), so an orphan object after a failed row insert cannot be removed by the client. Keep upload-then-insert, pre-check the duplicate hash against the loaded attachments, and leave orphans to the service-role cleanup. Cost if wrong: a few orphan objects in DEV.
- **R3:** Server derives `archived_at` (`now()` when `is_active` becomes false, null when true; client value ignored). `archive_inconsistent` can no longer fire; existing tests 7–8 in `10_admin_management` are rewritten to assert the derivation.
- **R4:** No-op audit skip compares rows without `updated_at` (the `set_updated_at` trigger always changes it).

---

### Task 1: DB migration — P3 guards, audit no-op skip, server archived_at, remove_attachment

**Files:**
- Create: `supabase/migrations/<ts>_p3_fixes_p4_rpcs.sql` (via `supabase migration new p3_fixes_p4_rpcs`)
- Create: `supabase/tests/database/11_p3_fixes_p4.test.sql`
- Modify: `supabase/tests/database/10_admin_management.test.sql` (tests 7–8 per R3)

**Interfaces:** Produces `public.remove_attachment(uuid, text) returns public.attachments`, raise codes `has_sites`, `invalid_target` (user_sites), `not_found`, `forbidden`, `already_deleted`, `invalid_transition`.

- [ ] Step 1: write `11_p3_fixes_p4.test.sql` (fails: functions/guards missing):
  - user_sites insert for an admin profile → `invalid_target`; for a site_user → lives.
  - promoting a site_user with sites to admin → `has_sites`; after removing links → lives.
  - no-op `update sites set name = name` as admin → audit count unchanged; real change → +1. Same for profiles.
  - `update sites set is_active=false` with no archived_at → archived_at not null; restore → null; client-supplied archived_at on restore ignored.
  - valid archive by admin through the client role lives (P2 missing test); `admin_list_users` returns `invite_pending=false` for a confirmed user (P2); soft-deleted certificate still locks the site code (P2).
  - `remove_attachment`: owner site user on draft → deleted_at set, deleted_by = uid, reason stored, audit row `remove_attachment`; same sha can be inserted again afterwards; other-site user → `forbidden`; submitted cert → `invalid_transition`; second call → `already_deleted`; unknown id → `not_found`; anon → 42501.
- [ ] Step 2: run `bash supabase/tests/run_remote.sh supabase/tests/database/11_p3_fixes_p4.test.sql` — Expected: FAIL (migration not pushed).
- [ ] Step 3: write the migration; `supabase db push` (DEV, linked).
- [ ] Step 4: update 10 tests 7–8; run full `bash supabase/tests/run_remote.sh` — Expected: `Result: PASS`, Files=12.
- [ ] Step 5: commit `feat(db): P3 review guards and remove_attachment RPC`.

### Task 2: App — P3 Minors (failure mapping, archive payload)

**Files:** `app/lib/core/error/failure_mapper.dart`, `app/lib/core/error/failure_message.dart`, `app/lib/l10n/app_ar.arb`, `app/lib/features/sites/data/repositories/sites_repository_impl.dart`, tests in `app/test/core/error/` and `app/test/features/sites/data/`.

- [ ] Failing tests: `FunctionException(status: 401)` and `PostgrestException(code: 'PGRST301')` → `NoSessionFailure`; `P0001 has_sites` / `already_deleted` / `invalid_transition` / `not_found` → `BusinessRuleFailure`; `setArchived` sends only `{'is_active': …}`.
- [ ] Implement; add Arabic messages for the new codes; `flutter test` green; commit `fix(app): map 401 to session failure, server-side archived_at`.

### Task 3: App — certificate data layer fixes (D2–D6) + pure helpers (D1, D7)

**Files:**
- Create: `app/lib/features/certificates/domain/certificate_files.dart` — `int periodHalfOf(DateTime d)`, `String formatDbDate(DateTime d)`, `String? mimeForFileName(String name)`, `String buildStoragePath({required String siteId, required DateTime certificateDate, required String fileName, required String Function() newId})`, `const maxAttachmentBytes = 2097152`.
- Modify: service (add `deleteCertificate` → rpc `delete_certificate`, `removeAttachment` → rpc `remove_attachment`, `fetchAttachments` filters `deleted_at is null`, remove `softDelete*`), repository interface + impl (no `status` in insert, `formatDbDate`, `delete`, `removeAttachment`).
- Tests: `app/test/features/certificates/domain/certificate_files_test.dart`, `app/test/features/certificates/data/certificates_repository_test.dart` (mocktail service).

Test cases (write first): day 15 → half 1, day 16 → half 2, Feb 29 2028 → 2, Dec 31 → 2, `DateTime(2026,3,1,0,0)` → `'2026-03-01'`; path `'<site>/2026/3/2/<id>.png'` for `photo.PNG` on 2026-03-16; mime for `a.pdf`, `b.JPG`, `c.jpeg`, `d.png`, `e.gif`(null); createDraft payload has no `status` and date `'2026-03-01'`; delete calls rpc with id; removeAttachment calls rpc; failures map to lefts.

Commit `fix(app): certificate data layer uses RPCs, local dates and valid storage paths`.

### Task 4: App — cubit: save (create-or-update), auto-save, delete, remove attachment (D8, D11)

**Files:** `certificate_cubit.dart`; test `app/test/features/certificates/presentation/certificate_cubit_test.dart`.

- `saveDraft({siteId, date, amount, notes})`: creates when no current certificate, updates when one exists in `draft|returned`; serialized with an in-flight future so concurrent calls never double-insert.
- `scheduleAutoSave(...)`: debounce (default 2 s, injectable `Duration`) → `saveDraft` only when amount is non-empty and a site is selected.
- `deleteCertificate(id)` / `removeAttachment(id)` → reload.
- bloc_test cases: first save creates, second save updates; two concurrent saves → one `createDraft`; auto-save fires once after debounce for several edits; auto-save skipped with empty amount; delete clears certificate; remove reloads attachments; failure surfaces `actionError`.

Commit `feat(app): draft auto-save and safe create-or-update in certificate cubit`.

### Task 5: App — entry page repair (D1, D7, D9, D10, D11) + widget tests

**Files:** `certificate_entry_page.dart`, `app_ar.arb` (status labels), new `certificate_status_label.dart`; tests `app/test/features/certificates/presentation/certificate_entry_page_test.dart`, `site_dashboard_page_test.dart`, `site_records_page_test.dart`.

- Page uses helpers for path/mime/size; images `maxWidth: 1600, maxHeight: 1600, imageQuality: 80`; one Scaffold only when standalone; site defaults to the first site; text fields trigger `scheduleAutoSave`; localized status label; remove-attachment button for draft/returned.
- Widget tests: status label Arabic; first site preselected and save enabled; editing amount triggers auto-save (fake repo); dashboard and records render certificates/empty state.

Commit `fix(app): P4 entry page storage path, mime, auto-save and localized status`.

### Task 6: Verification and docs

- `flutter analyze`, `flutter test`, `bash supabase/tests/run_remote.sh`, `flutter build web`.
- Final whole-branch review (opus). Update `docs/PROGRESS.md`, `docs/SKILLS_LOG.md`, `docs/OPEN_QUESTIONS.md` (Q21). Commit `docs: P3 fixes and P4 repair report`.

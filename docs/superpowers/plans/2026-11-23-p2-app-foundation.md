# P2 App Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter app foundation in `app/` (Android + Web): Supabase auth (login/logout/session), role-based routing with guards, Arabic RTL Material 3 theme from `docs/DESIGN_SYSTEM.md`, typed `AppFailure`, shared state widgets.

**Architecture:** Feature-first Clean Architecture (`data / domain / presentation` per feature) with `flutter_bloc` (owner-approved exception replacing the skill's ChangeNotifier MVVM; layering rules of `flutter-apply-architecture-best-practices` still apply). Services wrap Supabase; repositories return `Either<AppFailure, T>` (fpdart); a `SessionCubit` drives `go_router` redirects; role comes only from `profiles` (RLS-protected), never `user_metadata`.

**Tech Stack:** Flutter 3.47.6 / Dart 3.13.5, supabase_flutter 2.18.3, flutter_bloc 9.1.1, bloc_test 10.0.0, go_router 18.1.4, fpdart 1.2.0, freezed 4.0.3 + json_serializable 6.15.2 + build_runner 2.17.1, intl 0.20.3, flutter_lints 6.0.0, mocktail 1.0.5. Verified on pub.dev 2026-11-23. `Supabase.initialize(url:, publishableKey:)` verified against 2.18.3 API docs (`anonKey` is deprecated — do not use).

**Spec:** `docs/PROJECT_PLAN.md` §6, §8, §11, §12 (P2 row); `docs/OPENCODE_PROMPT.md` §3 P2; `docs/DESIGN_SYSTEM.md`; `docs/PROGRESS.md` "P2 notes".

## Global Constraints

- Code/identifiers/comments/commits English; every user-facing string Arabic via `lib/l10n/app_ar.arb` — never hardcoded.
- No financial value in `double`; P2 has no money math at all.
- App uses only project URL + publishable key from `--dart-define-from-file=env/dev.json`; `app/env/dev.json` gitignored, only `app/env/dev.example.json` committed. `service_role`/`sb_secret_` never in app code; config validation rejects secret-looking keys.
- Role authorization data comes from `public.profiles` only (`id, full_name, role, is_active` — exact columns from migration `20261123075750_profiles_sites.sql`). Never `user_metadata`.
- No hardcoded colors/spacing/radius/font sizes in widgets: `Theme.of(context)` + extensions `AppSpacing`, `AppRadii`, `AppStatusColors` per `docs/DESIGN_SYSTEM.md`.
- Bundled font IBM Plex Sans Arabic (400/500/600/700 static TTF, OFL license file committed).
- Strict analyzer: `strict-casts`, `strict-inference`, `strict-raw-types` true; exclude `**/*.g.dart`, `**/*.freezed.dart`. `flutter analyze` must be clean including infos.
- TDD for all logic: failing test first, watch it fail, minimal code, watch it pass, full suite green. Generated code (`*.g.dart`, `*.freezed.dart`, l10n) exempt per TDD skill's generated-code exception.
- No Supabase quickstart `todos` sample anywhere. Schema comes only from `supabase/migrations/`.
- Touch targets ≥ 48dp, contrast ≥ 4.5:1, RTL automatic via Arabic locale; Western digits (Q10 default).
- P2 builds placeholder role homes only. Sites/users CRUD (P3), certificates (P4), review (P5), dashboards (P6) are out of scope — YAGNI.
- Work on branch `p2-app-foundation` cut from `p1-database-security` HEAD (`92e7688`). No merge to master without owner approval. No destructive remote commands.
- Seed users have unrecoverable passwords by design; live login verification needs owner-provided DEV credentials (owner action, recorded in report — do not modify the seed).

## Review Focus

1. **Deactivated account signs in** → must be signed out immediately and shown the Arabic "account inactive" message, never routed to a home (Task 5/6 tests).
2. **Session restored on cold start with deleted/missing profile row** → must land on login with an error, not crash or hang on splash (Task 6/7 tests).
3. **Site user manually navigates to `/admin` (URL bar on web)** → redirect to `/site`; admin to `/site` → `/admin` (Task 7 tests).
4. **Missing/empty/secret env values** → app fails fast with Arabic config error screen; a `sb_secret_`-prefixed key must be rejected (Task 1 tests).
5. **Network down / server error during login** → inline Arabic failure message, form re-enabled, no raw exception text shown (Task 2/6 tests).

---

### Task 0: Design system document (DONE)

**Files:** Create: `docs/DESIGN_SYSTEM.md` (written 2026-11-23 with `ui-ux-pro-max`; provenance + decision log inside).

- [x] Run verified searches; reject off-topic `--design-system` outputs (recorded in doc §1).
- [x] Write `docs/DESIGN_SYSTEM.md`.
- [ ] Commit together with this plan: `docs(p2): design system and phase plan`.

### Task 1: Scaffold, dependencies, strict analysis, env config, font assets

**Files:**
- Create: `app/` via `flutter create --org com.gawda --project-name gawda_app --platforms android,web app`
- Modify: `app/pubspec.yaml`, `app/analysis_options.yaml`, `app/.gitignore` (verify env ignore), `app/web/index.html` + `app/web/manifest.json` (Arabic title/lang/dir)
- Create: `app/env/dev.example.json`, `app/env/dev.json` (gitignored; publishable key via MCP `get_publishable_keys`), `app/lib/core/config/app_config.dart`, `app/assets/fonts/` (4 TTFs + `OFL.txt`)
- Test: `app/test/core/config/app_config_test.dart`

**Interfaces (Produces):**
- `class AppConfig { const AppConfig({required this.supabaseUrl, required this.supabasePublishableKey}); final String supabaseUrl; final String supabasePublishableKey; }`
- `AppConfig.fromEnvironment()` — const constructor reading `String.fromEnvironment('SUPABASE_URL')` / `('SUPABASE_PUBLISHABLE_KEY')`, delegating to validated factory.
- `factory AppConfig.parse({required String url, required String key})` — throws `ConfigException(String reason)` when: url empty, not parseable, scheme != https, empty host; key empty; key starts with `sb_secret_`; key is a JWT whose decoded payload contains `"role":"service_role"` (simple base64 payload check, no crypto dep).
- `class ConfigException implements Exception { final String reason; }`

- [ ] Step 1: Branch `p2-app-foundation` from current HEAD; commit Task 0 docs + plan.
- [ ] Step 2: `flutter create` as above; delete counter demo from `lib/main.dart` (replaced in Task 8); remove default `widget_test.dart` (replaced by real tests).
- [ ] Step 3: `flutter pub add supabase_flutter flutter_bloc go_router fpdart freezed_annotation json_annotation intl flutter_localizations --sdk=flutter` (split SDK deps correctly); `flutter pub add --dev build_runner freezed json_serializable mocktail bloc_test flutter_lints`. Pin resolved versions in `pubspec.yaml` with `^` at the verified versions; commit `pubspec.lock`.
- [ ] Step 4: `analysis_options.yaml`: include `package:flutter_lints/flutter.yaml`; `analyzer: language: strict-casts/strict-inference/strict-raw-types: true`, `exclude: ["**/*.g.dart", "**/*.freezed.dart", "lib/l10n/gen/**"]`.
- [ ] Step 5: Write failing `app_config_test.dart`: valid https URL + `sb_publishable_x` parses; empty url throws; `http://` throws; empty key throws; `sb_secret_x` throws; service_role JWT throws. Run `flutter test test/core/config/app_config_test.dart` → expect FAIL (file/class missing).
- [ ] Step 6: Implement `app_config.dart` minimally. Re-run → PASS.
- [ ] Step 7: Write `app/env/dev.example.json` `{"SUPABASE_URL": "https://YOUR-PROJECT.supabase.co", "SUPABASE_PUBLISHABLE_KEY": "YOUR_PUBLISHABLE_KEY_HERE"}`; write real `app/env/dev.json` (URL `https://kbjsonvnbbhvczttvzhv.supabase.co`, publishable key from MCP `get_publishable_keys`); verify `git check-ignore app/env/dev.json` matches and example is NOT ignored.
- [ ] Step 8: Download IBM Plex Sans Arabic Regular/Medium/SemiBold/Bold TTFs + OFL.txt from `https://github.com/google/fonts/tree/main/ofl/ibmplexsansarabic` (raw URLs) into `app/assets/fonts/`; register family `IBMPlexSansArabic` with weight mapping in pubspec; verify each file > 50 KB (not an HTML error page).
- [ ] Step 9: `flutter analyze` → 0 issues; `flutter test` → all pass. Commit `feat(p2): scaffold, strict analysis, env config, arabic font`.

### Task 2: Typed failure model + exception mapping

**Files:**
- Create: `app/lib/core/error/app_failure.dart`, `app/lib/core/error/failure_mapper.dart`, `app/lib/core/error/result.dart`
- Test: `app/test/core/error/failure_mapper_test.dart`

**Interfaces (Produces):**
- `sealed class AppFailure { const AppFailure(); }` with `final class` subtypes: `InvalidCredentialsFailure()`, `NetworkFailure()`, `AccountInactiveFailure()`, `NoSessionFailure()`, `ServerFailure({String? code, String? message})`, `UnexpectedFailure({required Object cause})`.
- `typedef Result<T> = Either<AppFailure, T>;` (fpdart)
- `AppFailure mapExceptionToFailure(Object error)`: `AuthException` with code `invalid_credentials` → InvalidCredentials; other `AuthException` → ServerFailure(code, message); `PostgrestException` → ServerFailure(code, message); `SocketException` / `ClientException` (package:http) / `TimeoutException` → Network; anything else → Unexpected(cause).

- [ ] Step 1: Failing tests: one per mapping row above (construct real `AuthException('...', code: 'invalid_credentials')`, `PostgrestException(message: ..., code: '42501')`, `SocketException`, `TimeoutException`, generic `Exception`). Run → FAIL.
- [ ] Step 2: Implement sealed classes + mapper (switch expression with type patterns per `dart-use-pattern-matching`; no `default` swallowing new AuthException codes silently — they map to ServerFailure with code preserved). Re-run → PASS; full suite green.
- [ ] Step 3: Commit `feat(p2): sealed AppFailure and exception mapper`.

### Task 3: Theme extensions + localization + RTL

**Files:**
- Create: `app/lib/core/theme/app_spacing.dart`, `app_radii.dart`, `app_status_colors.dart`, `app_theme.dart`; `app/l10n.yaml`; `app/lib/l10n/app_ar.arb`
- Test: `app/test/core/theme/app_theme_test.dart`, `app/test/l10n/l10n_test.dart`

**Interfaces (Produces):**
- `class AppSpacing extends ThemeExtension<AppSpacing>` — `xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48` (final doubles), `const AppSpacing.standard()`, `copyWith`/`lerp`.
- `class AppRadii extends ThemeExtension<AppRadii>` — `sm 8, md 12, lg 16`.
- `class AppStatusColors extends ThemeExtension<AppStatusColors>` — pairs `(Color container, Color onContainer)` for `approved`, `needsReview`, `lateOrReturned`, `archived`; `AppStatusColors.light()` / `.dark()` with exact hex from DESIGN_SYSTEM §4.
- `abstract final class AppTheme { static ThemeData light(); static ThemeData dark(); }` — `useMaterial3: true`, seed `Color(0xFF1E3A8A)` with §4 overrides, `fontFamily: 'IBMPlexSansArabic'`, all three extensions registered, `inputDecorationTheme` border radius `AppRadii.sm`, minimum interactive size 48 (`materialTapTargetSize: MaterialTapTargetSize.padded` + button `minimumSize: Size(48, 48)`).
- l10n: `l10n.yaml` (`arb-dir: lib/l10n`, `template-arb-file: app_ar.arb`, `output-localization-file: app_localizations.dart`, `output-dir: lib/l10n/gen`, `nullable-getter: false`, `synthetic-package: false` — verify flag against current Flutter; if removed, omit). P2 keys: `appTitle`, `loginTitle`, `emailLabel`, `passwordLabel`, `loginButton`, `logoutButton`, `fieldRequired`, `invalidEmail`, `errorInvalidCredentials`, `errorNetwork`, `errorServer`, `errorUnexpected`, `errorAccountInactive`, `errorConfig`, `loading`, `emptyDefault`, `retry`, `adminHomeTitle`, `siteHomeTitle`, `welcomeUser` (placeholder with `{name}`).

- [ ] Step 1: Failing widget tests: `AppTheme.light()` registers all 3 extensions with exact token values (e.g. `spacing.lg == 16`, `statusColors.approved.$1 == Color(0xFFDCFCE7)`); dark differs; `colorScheme.primary == Color(0xFF0F172A)`; fontFamily set. l10n test: pump `MaterialApp(locale: ar, localizationsDelegates: AppLocalizations.localizationsDelegates, ...)` → `Directionality.of` is `TextDirection.rtl` and `AppLocalizations.of(context).loginButton` is non-empty Arabic. Run → FAIL.
- [ ] Step 2: Implement extensions + theme + ARB; `flutter gen-l10n`. Re-run → PASS.
- [ ] Step 3: `flutter analyze` clean; commit `feat(p2): material 3 theme extensions and arabic rtl localization`.

### Task 4: Shared state widgets

**Files:**
- Create: `app/lib/core/widgets/loading_view.dart`, `empty_view.dart`, `error_view.dart`
- Test: `app/test/core/widgets/state_views_test.dart`

**Interfaces (Produces):**
- `LoadingView({String? message})` — centered `CircularProgressIndicator` + optional text, `Semantics(liveRegion: true)`.
- `EmptyView({required String message, IconData icon = Icons.inbox_outlined})`.
- `ErrorView({required String message, VoidCallback? onRetry})` — message + retry `FilledButton.tonal` (label from `AppLocalizations.of(context).retry`) shown only when `onRetry != null`; retry button ≥ 48dp high.
- All strings passed by callers already localized except `retry` (widget-owned key); tokens only from theme.

- [ ] Step 1: Failing widget tests (pump inside localized RTL MaterialApp with `AppTheme.light()`): loading shows progress indicator; empty shows given message; error shows message and tapping retry invokes callback once; error without callback renders no button. Run → FAIL.
- [ ] Step 2: Implement. Re-run → PASS; full suite green; analyze clean.
- [ ] Step 3: Commit `feat(p2): shared loading, empty and error widgets`.

### Task 5: Auth data + domain layer

**Files:**
- Create: `app/lib/features/auth/domain/entities/app_user.dart` (freezed), `app/lib/features/auth/domain/repositories/auth_repository.dart`, `app/lib/features/auth/data/models/profile_row.dart` (freezed + json), `app/lib/features/auth/data/services/auth_service.dart` (abstract + `SupabaseAuthService`), `app/lib/features/auth/data/services/profile_service.dart` (abstract + `SupabaseProfileService`), `app/lib/features/auth/data/repositories/auth_repository_impl.dart`
- Test: `app/test/features/auth/profile_row_test.dart`, `app/test/features/auth/auth_repository_test.dart`

**Interfaces (Produces):**
- `enum UserRole { admin, siteUser }` ; `enum AuthEvent { signedIn, signedOut }`
- `@freezed class AppUser { factory AppUser({required String id, required String fullName, required UserRole role, required bool isActive}); }`
- `@freezed class ProfileRow { factory ProfileRow({required String id, @JsonKey(name: 'full_name') required String fullName, required String role, @JsonKey(name: 'is_active') required bool isActive}); factory ProfileRow.fromJson(Map<String, dynamic> json); }` + `AppUser toDomain()` — role via switch expression `'admin' => admin, 'site_user' => siteUser, _ => throw FormatException('unknown role: $role')` (fast-fail per pattern-matching skill; optional keys read directly, not map patterns).
- `abstract interface class AuthService { Stream<AuthEvent> get events; bool get hasSession; Future<void> signInWithPassword({required String email, required String password}); Future<void> signOut(); }` — `SupabaseAuthService(GoTrueClient auth)` maps `onAuthStateChange`: session != null on signedIn/initialSession/tokenRefreshed → `AuthEvent.signedIn`; signedOut/userDeleted or null session → `signedOut`. Throws raw exceptions (repo maps).
- `abstract interface class ProfileService { Future<Map<String, dynamic>> fetchProfile(String userId); }` — impl: `client.from('profiles').select('id, full_name, role, is_active').eq('id', userId).single()`.
- `abstract interface class AuthRepository { Stream<AuthEvent> get events; bool get hasSession; Future<Result<AppUser>> signIn({required String email, required String password}); Future<Result<AppUser>> restoreSession(); Future<Result<void>> signOut(); }`
- `AuthRepositoryImpl(AuthService auth, ProfileService profiles)`: signIn → `auth.signInWithPassword` then fetch+parse profile of `auth` current uid (add `String? get currentUserId` to AuthService); if `!isActive` → `await auth.signOut()` then `Left(AccountInactiveFailure())`; success `Right(user)`. restoreSession → `!hasSession` → `Left(NoSessionFailure())`; else fetch profile (missing row → PostgrestException → signOut + `Left(ServerFailure)`); inactive same as signIn. All throws caught → `Left(mapExceptionToFailure(e))`. signOut → Right(null) / Left(mapped).

- [ ] Step 1: Failing `profile_row_test.dart`: parses exact seed-shaped row (`role: 'site_user'` → siteUser); unknown role throws FormatException; missing `is_active` key throws. Run → FAIL. Implement model + `build_runner build`; PASS.
- [ ] Step 2: Failing `auth_repository_test.dart` (mocktail mocks of AuthService/ProfileService): signIn success returns Right(AppUser); invalid credentials AuthException → Left(InvalidCredentialsFailure); inactive profile → signOut called + Left(AccountInactiveFailure); SocketException → Left(NetworkFailure); restoreSession without session → Left(NoSessionFailure); restoreSession with missing profile row (PostgrestException) → signOut + Left(ServerFailure); signOut failure → Left. Run → FAIL.
- [ ] Step 3: Implement services + repo. Re-run → PASS; full suite green; analyze clean.
- [ ] Step 4: Commit `feat(p2): auth data and domain layers with typed results`.

### Task 6: Session + login presentation (BLoC)

**Files:**
- Create: `app/lib/features/auth/presentation/bloc/session_cubit.dart`, `login_cubit.dart`, `app/lib/features/auth/presentation/pages/login_page.dart`
- Test: `app/test/features/auth/session_cubit_test.dart`, `login_cubit_test.dart`, `login_page_test.dart`

**Interfaces (Produces):**
- `sealed class SessionState`: `SessionUnknown()`, `SessionUnauthenticated()`, `SessionInactive()`, `SessionAuthenticated(AppUser user)`.
- `SessionCubit(AuthRepository repo) extends Cubit<SessionState>`: starts `SessionUnknown`, calls `restoreSession()` (Right → Authenticated; NoSession → Unauthenticated; AccountInactive → Inactive; other Left → Unauthenticated), subscribes `repo.events` (signedIn → restoreSession again; signedOut → Unauthenticated). `Future<void> signOut()` delegates repo. `close()` cancels subscription.
- `enum LoginStatus { initial, submitting, success, failure }` ; `enum LoginFieldError { required, invalidEmail }`
- `@freezed class LoginState { factory LoginState({@Default(LoginStatus.initial) LoginStatus status, @Default('') String email, @Default('') String password, LoginFieldError? emailError, LoginFieldError? passwordError, AppFailure? failure}); }`
- `LoginCubit(AuthRepository repo) extends Cubit<LoginState>`: `emailChanged(String)`, `passwordChanged(String)` clear that field's error; `Future<void> submitted()` — trim email; validation: empty email → required, no `@` or empty local/domain → invalidEmail, empty password → required (no length rule invented); invalid → emit errors, no repo call; valid → submitting → `repo.signIn` → success or failure(failure). No navigation in cubit.
- `LoginPage(LoginCubit cubit)` — `BlocProvider` supplied by caller; labels above fields, `TextInputType.emailAddress`, obscure password, autofillHints, validate-on-blank-submit via cubit errors mapped to l10n (`fieldRequired`, `invalidEmail`), failure banner mapped: InvalidCredentials → `errorInvalidCredentials`, Network → `errorNetwork`, Server → `errorServer`, Unexpected → `errorUnexpected` (exhaustive switch; AccountInactive/NoSession → `errorUnexpected` fallback label is wrong — map AccountInactive → `errorAccountInactive`, NoSession → `errorServer`). Submit button disabled + spinner while submitting. All spacing/color from theme extensions.

- [ ] Step 1: Failing `session_cubit_test.dart` (bloc_test + mock repo, `StreamController<AuthEvent>`): bootstrap paths (4), signedOut event → Unauthenticated, signedIn event refetches profile, inactive on restore → SessionInactive. Run → FAIL. Implement → PASS.
- [ ] Step 2: Failing `login_cubit_test.dart`: empty submit sets both required errors and never calls repo; bad email sets invalidEmail; valid submit success emits [submitting, success]; repo Left(NetworkFailure) emits [submitting, failure] with failure preserved; changing email clears its error. Run → FAIL. Implement → PASS.
- [ ] Step 3: Failing `login_page_test.dart` (real LoginCubit + mock repo, localized RTL app): renders Arabic labels; tapping login with empty fields shows Arabic required errors; submitting state disables button; InvalidCredentials failure shows `errorInvalidCredentials` text; directionality RTL. Run → FAIL. Implement page → PASS.
- [ ] Step 4: Full suite + analyze clean. Commit `feat(p2): session and login blocs with arabic login page`.

### Task 7: Router with role guards + role homes

**Files:**
- Create: `app/lib/core/router/app_router.dart`, `app/lib/features/home/presentation/pages/admin_home_page.dart`, `site_home_page.dart`
- Test: `app/test/core/router/redirect_test.dart`, `app/test/core/router/app_router_test.dart`

**Interfaces (Produces):**
- `String? resolveRedirect({required SessionState session, required String location})` — pure function: Unknown → `/splash` unless already there; Unauthenticated/Inactive → `/login` unless already there; Authenticated: `/splash`|`/login` → role home (`/admin` or `/site`); `/admin` with siteUser → `/site`; `/site` with admin → `/admin`; else null.
- `GoRouter buildRouter(SessionCubit cubit)` — `initialLocation: '/splash'`, `refreshListenable:` a `ValueNotifier`-free adapter: `GoRouterRefreshStream(cubit.stream)` (private class extending `ChangeNotifier`, listens in ctor, cancels in dispose). Routes: `/splash` → `LoadingView`, `/login` → `LoginPage` (cubit created with repo from `RepositoryProvider<AuthRepository>`), `/admin` → `AdminHomePage`, `/site` → `SiteHomePage`. `redirect: (context, state) => resolveRedirect(session: cubit.state, location: state.matchedLocation)`.
- `AdminHomePage` / `SiteHomePage({required AppUser user})` — placeholder Scaffold: localized title (`adminHomeTitle`/`siteHomeTitle`), `welcomeUser(user.fullName)`, logout button calling `context.read<SessionCubit>().signOut()`. No nav shell yet (P3+).

- [ ] Step 1: Failing `redirect_test.dart`: table-driven — all Review Focus #3 rows plus unknown/unauthenticated/inactive/authenticated-on-login cases (≥ 10 cases). Run → FAIL. Implement pure function → PASS.
- [ ] Step 2: Failing `app_router_test.dart` (widget test with real SessionCubit + mock repo): cold start no session lands on login (find LoginPage); emit authenticated admin via repo mock + stream → AdminHomePage visible; site user session then `router.go('/admin')` → SiteHomePage still/again shown. Run → FAIL. Implement router + homes → PASS.
- [ ] Step 3: Full suite + analyze. Commit `feat(p2): role-guarded go_router and role home placeholders`.

### Task 8: App wiring, platform runs, verification, phase report

**Files:**
- Create: `app/lib/app.dart`, replace `app/lib/main.dart`
- Modify: `app/web/index.html` (`lang="ar" dir="rtl"`, Arabic title), `app/web/manifest.json`, `docs/PROGRESS.md`, `docs/SKILLS_LOG.md`, `docs/OPEN_QUESTIONS.md` (owner actions), tick plan checkboxes
- Test: `app/test/app_test.dart`

**Interfaces (Consumes/Produces):**
- `App({required AuthRepository repo})` — creates `SessionCubit`, `MaterialApp.router(theme: AppTheme.light(), darkTheme: AppTheme.dark(), locale: Locale('ar'), supportedLocales: [Locale('ar')], localizationsDelegates: AppLocalizations.localizationsDelegates, routerConfig: buildRouter(cubit))`.
- `main()`: `WidgetsFlutterBinding.ensureInitialized()`; try `AppConfig.fromEnvironment()` catch `ConfigException` → `runApp` minimal Arabic config-error MaterialApp (uses `errorConfig`); `await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabasePublishableKey)`; construct `SupabaseAuthService(client.auth)`, `SupabaseProfileService(client)`, `AuthRepositoryImpl`; `runApp(App(repo: repo))`. No service key anywhere.

- [ ] Step 1: Failing `app_test.dart`: pump `App(repo: mockRepo)` with no session → login visible, RTL, Arabic title; with restored admin session → admin home. Run → FAIL. Implement app.dart + main.dart → PASS.
- [ ] Step 2: `flutter analyze` → 0 issues; `flutter test` → full suite pass (record counts).
- [ ] Step 3: `flutter build web --dart-define-from-file=env/dev.json` → exit 0. Serve `build/web` and open with browser tool: login renders RTL Arabic, empty-submit shows Arabic errors, wrong credentials show Arabic error (real DEV call). Screenshot evidence.
- [ ] Step 4: Android: `flutter emulators` — launch existing AVD or create one from installed SDK 37 system image; `flutter build apk --debug --dart-define-from-file=env/dev.json` → exit 0; install + launch on emulator, screenshot login. If no system image/AVD possible, report exactly what blocked (no silent skip).
- [ ] Step 5: Live login/logout with a real DEV account requires owner credentials (seed passwords unrecoverable by design). Ask owner; until provided, mark live-auth check as pending owner action — do not alter seed.
- [ ] Step 6: `node verify_p0.mjs` still exit 0; `git status` clean after commits; secret scan: `git grep -n "sb_secret_\|service_role" -- app` → no hits (docs/tests excluded).
- [ ] Step 7: Update PROGRESS.md P2 section, SKILLS_LOG.md (per-task LOADED/APPLIED), tick checkboxes, write phase report (SKILLS LOADED / BUILT / COMMANDS RUN / TESTS / SKILLS APPLIED / DEVIATIONS / NEW OPEN QUESTIONS). Commit `feat(p2): app wiring and platform verification` + `docs(p2): phase report and evidence`. Report to owner; **do not claim "P2 complete"** — owner approves.

## Self-review (done at writing time)

- Spec coverage: P2 sentence in OPENCODE_PROMPT §3 mapped — project(T1), Clean Arch+BLoC(T5-6), go_router guards(T7), supabase_flutter(T5,8), typed AppFailure(T2), l10n Arabic RTL(T3), M3 theme extensions(T3), bundled font(T1), env dart-define(T1), login/logout/session(T5-6), role home routing(T7), shared widgets(T4), analyze/test/Android/Web(T8). freezed+json per plan §6 (T5). No money code (constraint honored).
- Type consistency: `AuthEvent`, `Result<T>`, `SessionState` subtypes, `resolveRedirect` signature used identically in T6/T7/T8; `AuthService.currentUserId` added in T5 Interfaces and used by repo.
- Review Focus rows 1–5 pinned to T5/T6 (inactive), T6/T7 (restore missing profile), T7 (guards), T1 (env), T2/T6 (network/server login).
- Proportion: signatures + test assertions only; no bodies except exact-value mappings.

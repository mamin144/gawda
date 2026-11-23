# Design System — Site Financial Quality Tracking (Gawda)

> Source of truth for all UI code in `app/`. Generated with the `ui-ux-pro-max` skill on 23 November 2026.
> Business-fixed rules come from `docs/PROJECT_PLAN.md` (§3, §11) and override any design recommendation.
> No widget may hardcode a color, spacing, radius or font size. Everything comes from `Theme.of(context)`
> and the theme extensions defined below.

## 1. Provenance (what was verified vs fallback)

| Search | Result | Status |
|---|---|---|
| `--design-system "financial document tracking internal operations dashboard arabic"` | Enterprise Gateway / Dark Mode OLED / Fira Code | **Rejected — off-topic** (marketing landing pattern, no Arabic glyphs). Not persisted. |
| Retry `--design-system "internal admin dashboard mobile data entry clean light"` | Real-Time Operations Landing / Glassmorphism / Fira Code | **Rejected — off-topic** again. Per skill rule, style direction below is a labeled fallback to the built-in priority table + verified targeted matches. |
| `--domain style --rtl=full "dashboard minimal clean"` | `minimalism-and-swiss-style`, **rtl_level: full** | **Verified match — adopted.** |
| `--domain typography "arabic readable modern"` | Pairing "Arabic Elegant": Noto Naskh Arabic + Noto Sans Arabic | **Verified match** — confirms Arabic sans family direction. |
| `--domain google-fonts "arabic sans"` | IBM Plex Sans Arabic (7 weights, arabic+latin subsets), Noto Sans Arabic, Almarai | **Verified match — IBM Plex Sans Arabic adopted** (see Decision D3). |
| `--domain color "banking traditional finance"` | Light palette: navy `#0F172A` / blue `#1E3A8A` / gold `#A16207` on `#F8FAFC` | **Verified match — adopted as base palette.** |
| `--domain ux "form validation error inline"` | Focusable error summary, validate on blur, inline error per field | **Verified — binding for all forms.** |
| `--stack flutter "theme rtl localization"` | `Theme.of(context)` only, provide `darkTheme`, no hardcoded colors | **Verified — binding.** |

## 2. Understanding summary (locked by PROJECT_PLAN.md)

- Internal operational app, two roles: Admin (web-first dashboard) and site user (Android-first, very simple).
- Arabic first, full RTL. Western digits (0–9) — documented default, open question Q10.
- Light mode is the default; a dark theme must exist (Flutter stack rule) but is secondary.
- Status colors are business-fixed (§11): green = approved, amber = needs review, red = late/returned, gray = archived.
- Accessibility (§11): contrast ≥ 4.5:1, touch targets ≥ 48dp, font scaling supported.
- Non-goals for P2: no marketing patterns, no glassmorphism, no emoji icons, no decorative motion.

## 3. Decision log

| # | Decision | Alternatives | Why |
|---|---|---|---|
| D1 | Style: Minimalism & Swiss, light default | Glassmorphism, OLED dark (both returned by `--design-system`) | Only RTL-`full` verified style; matches enterprise/data-entry product; rejected outputs had no Arabic support. |
| D2 | Palette: Banking/Traditional Finance light row | Personal Finance Tracker (dark) | Light, conservative, trust navy; field users work outdoors on phones. |
| D3 | Font: **IBM Plex Sans Arabic**, static TTF weights 400/500/600/700, bundled in `app/assets/fonts/` with OFL license | Noto Sans Arabic (variable-only upstream → needs `FontVariation` mapping), Almarai (4 weights) | Verified Arabic+Latin sans; static TTFs map directly to Flutter `FontWeight`; one family for headings and body (data density, YAGNI). |
| D4 | Numerals: Western (0–9) | Arabic-Indic (٠–٩) | Documented default in `docs/OPEN_QUESTIONS.md` Q10; changeable later via one formatter. |
| D5 | Status semantics encoded as `AppStatusColors` theme extension with container/on-container pairs | Raw hex in widgets | §11 colors are business rules; pairs guarantee 4.5:1 in both modes. |
| D6 | Spacing scale 4/8/12/16/24/32/48 via `AppSpacing` extension; radius 8/12/16 via `AppRadii` | Hardcoded paddings | Plan forbids hardcoded spacing; density dial 7 (standard). |
| D7 | M3 `ColorScheme.fromSeed(seedColor: #1E3A8A)` with explicit token overrides below | Hand-built ColorScheme | M3 required by plan; overrides keep verified palette exact. |

## 4. Color tokens

### Light (default)

| Token | Hex | Use |
|---|---|---|
| primary | `#0F172A` | App bars, primary buttons, emphasis |
| onPrimary | `#FFFFFF` | Text/icons on primary |
| secondary | `#1E3A8A` | Seed color, links, selected states |
| onSecondary | `#FFFFFF` | |
| tertiary (accent) | `#A16207` | Highlights, "awaiting signature" emphasis |
| onTertiary | `#FFFFFF` | |
| background / surface | `#F8FAFC` | Scaffold background |
| onSurface | `#020617` | Body text |
| surfaceContainer (card) | `#FFFFFF` | Cards, dialogs |
| muted | `#E8ECF1` | Disabled fills, dividers background |
| mutedForeground | `#475569` | Secondary text (≥ 4.5:1 on background) |
| outline (border) | `#E2E8F0` | Input borders, dividers |
| error (destructive) | `#DC2626` | Errors, destructive actions |
| onError | `#FFFFFF` | |

### Dark (secondary)

| Token | Hex |
|---|---|
| primary | `#93C5FD` |
| onPrimary | `#0F172A` |
| secondary | `#BFDBFE` |
| background / surface | `#0F172A` |
| onSurface | `#F8FAFC` |
| surfaceContainer | `#1E293B` |
| muted | `#27324A` |
| mutedForeground | `#94A3B8` |
| outline | `#334155` |
| error | `#F87171` |
| onError | `#0F172A` |

### Status pairs (business-fixed, both modes)

| Status | Light container / on | Dark container / on |
|---|---|---|
| approved (green) | `#DCFCE7` / `#166534` | `#052E16` / `#4ADE80` |
| needsReview (amber) | `#FEF3C7` / `#92400E` | `#451A03` / `#FBBF24` |
| lateOrReturned (red) | `#FEE2E2` / `#991B1B` | `#450A0A` / `#FCA5A5` |
| archived (gray) | `#E2E8F0` / `#334155` | `#1E293B` / `#94A3B8` |

All pairs meet ≥ 4.5:1. Status is never conveyed by color alone: every status chip also carries its Arabic label.

## 5. Typography

- Family: `IBMPlexSansArabic` (bundled). Weights: 400 regular, 500 medium, 600 semiBold, 700 bold.
- M3 text theme mapped: headlineSmall 24/600, titleLarge 20/600, titleMedium 16/600, bodyLarge 16/400, bodyMedium 14/400, labelLarge 14/600 (buttons), labelSmall 12/500 (captions, never below 12).
- Line height ≥ 1.5 for Arabic body text. No letter-spacing on Arabic script.
- Digits: Western, tabular where amounts align (later phases).

## 6. Spacing, radius, targets

- `AppSpacing`: xs 4, sm 8, md 12, lg 16, xl 24, xxl 32, xxxl 48.
- `AppRadii`: sm 8, md 12, lg 16. Cards md, buttons sm, dialogs lg.
- Touch targets ≥ 48×48dp (plan §11 overrides the skill's 44px minimum).
- Content max width on large screens: forms 640, lists 960 (responsive skill: `LayoutBuilder`, never orientation/device checks).
- Breakpoint: compact < 600, expanded ≥ 600 (navigation rail/side nav appears only in later phases).

## 7. Interaction rules (from verified UX matches)

- Forms: visible labels above fields (never placeholder-only), validate on blur + on submit, inline Arabic error under each invalid field, focusable error summary at top on failed submit.
- Every async action shows a loading state; buttons disable while pending (no double submit).
- Empty and error states are first-class shared widgets with an Arabic message and a retry action where retry makes sense.
- Motion: 150–250ms transitions only; respect reduced motion; no decorative animation in P2.
- Icons: Material icons only, never emoji. Icon-only buttons must have tooltips/labels.

## 8. Flutter mapping (binding for implementation)

- `AppTheme.light()` / `AppTheme.dark()` build `ThemeData(useMaterial3: true, colorScheme: ...)` from §4, `fontFamily: 'IBMPlexSansArabic'`, and register extensions `AppSpacing`, `AppRadii`, `AppStatusColors`.
- Widgets read tokens via `Theme.of(context).extension<AppSpacing>()!` etc. A lint-level review rule: no `Color(0x...)`, no literal `EdgeInsets.all(n)` in feature widgets.
- `MaterialApp.router(theme: light, darkTheme: dark, locale: Locale('ar'), supportedLocales: [Locale('ar')])` with `flutter_localizations` delegates; RTL is automatic from the Arabic locale.
- All user-facing strings live in `lib/l10n/app_ar.arb`; no hardcoded UI strings.

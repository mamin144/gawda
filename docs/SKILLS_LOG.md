# Skills Log - Site Financial Quality Tracking System

## Installed Skills (P0 verification)

| Skill Name | Source | Path | Verified |
|---|---|---|---|
| using-superpowers | Obra/superpowers | .agents/skills/using-superpowers | yes |
| brainstorming | Obra/superpowers | .agents/skills/brainstorming | yes |
| writing-plans | Obra/superpowers | .agents/skills/writing-plans | yes |
| executing-plans | Obra/superpowers | .agents/skills/executing-plans | yes |
| test-driven-development | Obra/superpowers | .agents/skills/test-driven-development | yes |
| systematic-debugging | Obra/superpowers | .agents/skills/systematic-debugging | yes |
| verification-before-completion | Obra/superpowers | .agents/skills/verification-before-completion | yes |
| flutter-apply-architecture-best-practices | flutter/agent-plugins | .agents/skills/flutter-apply-architecture-best-practices | yes |
| flutter-build-responsive-layout | flutter/agent-plugins | .agents/skills/flutter-build-responsive-layout | yes |
| flutter-add-widget-test | flutter/agent-plugins | .agents/skills/flutter-add-widget-test | yes |
| flutter-setup-declarative-routing | flutter/agent-plugins | .agents/skills/flutter-setup-declarative-routing | yes |
| flutter-implement-json-serialization | flutter/agent-plugins | .agents/skills/flutter-implement-json-serialization | yes |
| dart-run-static-analysis | dart-lang/skills | .agents/skills/dart-run-static-analysis | yes |
| dart-use-pattern-matching | dart-lang/skills | .agents/skills/dart-use-pattern-matching | yes |
| supabase | supabase/agent-skills | .agents/skills/supabase | yes |
| supabase-postgres-best-practices | supabase/agent-skills | .agents/skills/supabase-postgres-best-practices | yes |
| ui-ux-pro-max | nextlevelbuilder/ui-ux-pro-max-skill | .agents/skills/ui-ux-pro-max | yes |

## Key Rules Applied from Skills

### using-superpowers
- **Rule:** Invoke relevant or requested skills BEFORE any response or action — including clarifying questions, exploring the codebase, or checking files. Skills must be invoked before any task execution.

### writing-plans
- **Rule:** Every plan MUST start with a header: `# [Feature Name] Implementation Plan`, followed by Goal, Architecture, Tech Stack, and Spec sections. Each task must produce self-contained changes with checkable results.

### flutter-apply-architecture-best-practices
- **Rule:** Architect a Flutter application using the recommended layered approach (UI, Logic, Data). Use when structuring a new project or refactoring for scalability.

### supabase
- **Rule:** Never use `user_metadata` claims in JWT-based authorization decisions. Store authorization data in `raw_app_meta_data` / `app_metadata` instead. `user_metadata` is user-editable and unsafe for RLS policies.

### supabase-postgres-best-practices
- **Rule:** Enable RLS on every table in any exposed schema. This is critical in Supabase because tables in exposed schemas can be reachable through the Data API when the `anon`/`authenticated` roles have access.

### ui-ux-pro-max
- **Rule:** UI/UX design intelligence for web, mobile, and desktop. Use when designing, building, reviewing, or fixing interfaces, including pages, components, design systems, accessibility, interaction, responsive layout, typography, color, charts, and stack-specific UI implementation.

### dart-use-pattern-matching
- **Rule:** Applies Dart 3 pattern matching, switch expressions, and destructuring idiomatically to validate data schemas, handle algebraic data types, and decompose control flow. Use when refactoring complex if-else chains, parsing polymorphic JSON or API responses, destructuring Lists, URI/path segments, String.split() tokens, Records, or Maps.

### dart-run-static-analysis
- **Rule:** Execute `dart analyze` to identify warnings and errors, and use `dart fix --apply` to automatically resolve mechanical lint issues. Use during development to ensure code quality and before committing changes.

### test-driven-development
- **Rule:** Use when implementing any feature or bugfix, before writing implementation code. Write the test first, then implement the minimal code to make it pass.

### systematic-debugging
- **Rule:** Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes. Follow a structured debugging protocol.

### brainstorming
- **Rule:** Use BEFORE any creative work - creating features, building components, adding functionality, modifying behavior, or planning anything new, in software or out of it (a talk, a business, a renovation).

### flutter-build-responsive-layout
- **Rule:** Use `LayoutBuilder`, `MediaQuery`, or `Expanded/Flexible` to create a layout that adapts to different screen sizes. Use when the UI needs to look good on both mobile and tablet/desktop form factors.

### flutter-add-widget-test
- **Rule:** Implement a component-level test using `WidgetTester` to verify UI rendering and user interactions (tapping, scrolling, entering text). Use when validating that a specific widget displays correct data and responds to events as expected.

### flutter-setup-declarative-routing
- **Rule:** Configure `MaterialApp.router` using a package like `go_router` for advanced URL-based navigation. Use when developing web applications or mobile apps that require specific deep linking and browser history support.

### flutter-implement-json-serialization
- **Rule:** Create model classes with `fromJson` and `toJson` methods using `dart:convert`. Use when manually mapping JSON keys to class properties for simple data structures.

### executing-plans
- **Rule:** Use when executing an implementation plan in the current session as the implementer yourself — your human partner chose inline execution, or no subagent tool is available.

### verification-before-completion
- **Rule:** Use when about to claim work is complete, fixed, or passing, before committing or creating PRs. Requires running verification commands and confirming output before making any success claims; evidence before assertions always.

---

**P0 Exit Status:** All 22 skills installed and verified. Ready to proceed to P1 after user approval.
# Agent Instructions — ShiftWise Flutter

Read `docs/PROJECT_PLAN.md` first, every session — it's short and tells you which other doc(s) to load for the task at hand. Do not read the full `docs/` tree unless explicitly asked to audit the whole plan; most tasks need one or two docs, not all of them.

## Working rules

- Implement one phase at a time (`docs/phases.md`). Don't start Phase 3 work while Phase 2 is incomplete.
- State assumptions explicitly before proceeding on anything ambiguous.
- Ask before: architecture changes, provider changes, security/privacy-relevant changes, monetization changes.
- Add tests with every change — see `docs/testing.md` for what's required per layer.
- Report back: files touched, migrations, tests added, failures encountered, risks identified.

## Hard rules (violating these is a blocker, not a style note)

- Never write currency math with raw `double`. `domain/money/` and `domain/pay/` use the `decimal` package exclusively.
- Never let the Flutter app write entitlements, quota, billing state, or parse-job authoritative transitions directly to Firestore — Cloud Functions only.
- Never let AI-imported data become a "confirmed" shift without explicit user confirmation.
- Never add inline hex colors or magic spacing values in feature code — reference `lib/app/theme/tokens.dart` (source doc: `docs/design/tokens.md`). This includes never hardcoding a light-mode hex where the dark-mode token should be used instead — always reference the semantic token, never a literal value, so theme switching stays automatic.
- Never ship a Firestore/Storage rule change without an emulator test in the same commit.
- Never add a new local persistence layer (Isar/Hive/etc.) without confirming Firestore's offline cache genuinely can't cover the case — default assumption is it can.
- Never imply take-home pay, tax accuracy, or confirmed legal violations in any UI copy — see `docs/scope.md` for exact allowed phrasing.

## Definition of done

Criteria in the relevant doc pass, success/failure/abuse/retry paths are tested (not just the happy path), `flutter analyze` and `dart format --check` pass, no sensitive data in test fixtures, offline/accessibility behavior is handled, relevant `docs/` file is updated if the change affects architecture, commit is focused on one concern.

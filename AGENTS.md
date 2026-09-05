# Agent Instructions — ShiftWise (React Native / Expo)

Read `docs/PROJECT_PLAN.md` first, every session — it's short and tells you which other doc(s) to load for the task at hand. Do not read the full `docs/` tree unless explicitly asked to audit the whole plan; most tasks need one or two docs, not all of them.

## Working rules

- Implement one phase at a time (`docs/phases.md`). Don't start Phase 3 work while Phase 2 is incomplete.
- State assumptions explicitly before proceeding on anything ambiguous.
- Ask before: architecture changes, provider changes, security/privacy-relevant changes, monetization changes.
- Add tests with every change — see `docs/testing.md` for what's required per layer.
- Report back: files touched, migrations, tests added, failures encountered, risks identified.

## Hard rules (violating these is a blocker, not a style note)

- Never write currency math with raw JS `number`. `src/domain/money/` and `src/domain/pay/` use `decimal.js` exclusively.
- Never let the React Native app write entitlements, quota, billing state, or parse-job authoritative transitions directly to Firestore — Cloud Functions only.
- Never let AI-imported data become a "confirmed" shift without explicit user confirmation.
- Never add inline hex colors or magic spacing values in feature code — reference the Uniwind/Tailwind theme tokens (source doc: `docs/design/tokens.md`). This includes never hardcoding a light-mode hex where the dark-mode token should be used instead — always reference the semantic token, never a literal value, so theme switching stays automatic.
- Never ship a Firestore/Storage rule change without an emulator test in the same commit (`@firebase/rules-unit-testing`).
- Never add a new local persistence layer (MMKV/AsyncStorage-as-database/etc.) without confirming Firestore's offline cache genuinely can't cover the case — default assumption is it can. Note the stack decision in `docs/decisions/0001-migrate-flutter-to-react-native-expo.md`: this requires React Native Firebase (native SDK), not the Firebase JS SDK, because the JS SDK has no Firestore offline persistence on React Native.
- Never imply take-home pay, tax accuracy, or confirmed legal violations in any UI copy — see `docs/scope.md` for exact allowed phrasing.

## Definition of done

Criteria in the relevant doc pass, success/failure/abuse/retry paths are tested (not just the happy path), `tsc --noEmit`, ESLint, and Prettier `--check` pass, no sensitive data in test fixtures, offline/accessibility behavior is handled, relevant `docs/` file is updated if the change affects architecture, commit is focused on one concern.

# Testing & CI

| Layer | Coverage | Tooling |
|---|---|---|
| Domain | Time, money, breaks, rounding, rate versions, schedule concerns | `flutter_test`, pure Dart — no Firebase/widget deps |
| Properties | Nonnegative duration/pay, deterministic recomputation, valid interval invariants | `flutter_test` |
| Widgets | Forms, calendar, uncertainty states, paywall, error states | `flutter_test` + `mocktail` |
| Golden | Theme pins + design-system components (tokens showcase, themed framework widgets, App* library, screens) | `golden_toolkit` |
| Security | Auth, cross-user access, privileged writes, malformed writes — via direct SDK calls, not UI | Firebase Emulator Suite |
| Cloud Functions | Quota logic, state transitions, retry/idempotency, billing reconciliation | Firebase Emulator Suite + Node test runner |
| Integration | Auth flow, shift CRUD, scan review flow, offline recovery, billing, account deletion | `integration_test` package + emulators |
| Accessibility | Screen reader (TalkBack/VoiceOver) and keyboard/switch-control manual review | Manual + platform accessibility scanners |
| Platform matrix | Representative iOS and Android device/OS versions | Physical devices or cloud device farm |

## CI gate (every PR)

`flutter analyze`, `dart format --check`, unit/widget/golden tests, Firebase emulator rules tests, critical integration tests, dependency/secret scanning, release build succeeds for both platforms.

## Non-negotiable test requirements

- Any Firestore/Storage rule change ships with an emulator test in the same commit — see `docs/threat-model.md`.
- Any pay-engine change ships with the full boundary-condition test suite passing — see `docs/architecture/pay-engine.md` for the required case list.
- Any AI-import state-machine change ships with an idempotency test proving retries don't duplicate shifts/quota/drafts — see `docs/architecture/ai-import.md`.

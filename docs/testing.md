# Testing & CI

| Layer | Coverage | Tooling |
|---|---|---|
| Domain | Time, money, breaks, rounding, rate versions, schedule concerns | Jest, pure TypeScript — no Firebase/RN deps |
| Properties | Nonnegative duration/pay, deterministic recomputation, valid interval invariants | Jest |
| Components | Forms, calendar, uncertainty states, paywall, error states | Jest + React Native Testing Library |
| Visual | Theme pins + design-system components (tokens showcase, themed component library, screens) | Storybook snapshots or `react-native-view-shot`-based snapshot tests, both light and dark |
| Security | Auth, cross-user access, privileged writes, malformed writes — via direct SDK calls, not UI | Firebase Emulator Suite + `@firebase/rules-unit-testing` |
| Cloud Functions | Quota logic, state transitions, retry/idempotency, billing reconciliation | Firebase Emulator Suite + Node test runner |
| Integration/E2E | Auth flow, shift CRUD, scan review flow, offline recovery, billing, account deletion | Maestro flows against a dev/EAS build + emulators |
| Accessibility | Screen reader (TalkBack/VoiceOver) and keyboard/switch-control manual review | Manual + platform accessibility scanners |
| Platform matrix | Representative iOS and Android device/OS versions | Physical devices or cloud device farm (EAS Build artifacts) |

## CI gate (every PR)

`tsc --noEmit`, ESLint, Prettier `--check`, unit/component/visual tests, Firebase emulator rules tests, critical Maestro flows, dependency/secret scanning, EAS Build succeeds for both platforms.

## Non-negotiable test requirements

- Any Firestore/Storage rule change ships with an emulator test (`@firebase/rules-unit-testing`) in the same commit — see `docs/threat-model.md`.
- Any pay-engine change ships with the full boundary-condition test suite passing — see `docs/architecture/pay-engine.md` for the required case list.
- Any AI-import state-machine change ships with an idempotency test proving retries don't duplicate shifts/quota/drafts — see `docs/architecture/ai-import.md`.

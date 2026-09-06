# Decision 0001 — Migrate from Flutter to React Native (Expo)

**Status:** approved (owner, 2026-09-05). **Supersedes:** the Flutter decision record in `docs/architecture/stack.md` (2026 pre-migration version, preserved in git history).

## Decision

Rewrite ShiftWise as a React Native app on Expo, styled with Uniwind (Tailwind CSS for React Native). The existing Flutter app (`lib/`, `test/`, `android/`, `ios/`) is deleted once the rewrite reaches parity; the Firebase backend (Firestore/Storage rules, Cloud Functions) is reused with minimal changes since it was always framework-agnostic.

## Rationale

Owner-stated drivers: one TypeScript stack shared with the existing Cloud Functions codebase (`functions/`, already TypeScript), Expo's cloud build/OTA-update workflow removing the local Android-SDK dependency this repo just hit, and a larger available hiring/contributor pool than Flutter/Dart.

## What is reused as-is or near-as-is

- Firestore/Storage security rules (`firebase/firestore.rules`, `firebase/storage.rules`) — client-agnostic, no changes required by the migration itself.
- Cloud Functions (`functions/src/**`) — `writeShift`, `createParseJob`, already TypeScript.
- The hostile-rules-test methodology — ports to `@firebase/rules-unit-testing` (the JS/TS equivalent of the Dart emulator tests already in `rules-tests/`).
- Every product/architecture rule not specific to Flutter: AI-import confirmation gate, money-never-a-float, server-authoritative writes, design tokens, pay-engine spec, scope/tier boundaries, threat model.

## What is rebuilt

- All of `lib/` and `test/` (187 Dart tests, goldens, auth/schedule/scan/money code) — no code ports 1:1 across languages; this is a genuine rewrite, not a transpile.
- The design system rebuild in progress (PR #7, stages A–C) restarts on the new stack; PR #7 is superseded, not merged. Token *values* carry over (same hex/spacing/type-scale decisions), the implementation does not.
- Native project files (`android/`, `ios/`) — replaced by Expo's managed project structure.

## Key technical decision folded into this migration: Firebase SDK choice

Two Firebase integration paths exist for Expo/React Native:

| | Firebase JS SDK | React Native Firebase (native) |
|---|---|---|
| Works in Expo Go | Yes | No — requires a custom dev client |
| Firestore offline persistence | **Not supported on React Native** (no IndexedDB; falls back to memory cache, silently, per upstream Firebase issue tracker) | Supported (wraps native iOS/Android SDKs) |
| Analytics/Crashlytics/Dynamic Links | Limited | Full native support |

`docs/architecture/sync-and-auth.md` and `docs/architecture/offline-conflict-resolution.md` both depend on Firestore's offline cache handling read-while-offline — a **hard requirement**, not a nice-to-have, for a shift worker checking a cached schedule with no signal. The JS SDK cannot deliver this on mobile. **Decision: use React Native Firebase (native SDK)**, which requires an Expo custom development build (`expo-dev-client` + EAS Build config plugins) instead of plain Expo Go from day one. This is a normal, documented Expo workflow, not a bare-workflow eject — noted here because it changes the Phase 1 scaffold from "just run in Expo Go" to "build a dev client first."

## Consequences / follow-up decisions still needed

- Phase 3's "no way to call an AI provider without a server" blocker (raised pre-migration) is unaffected by this decision — still needs an owner ruling, tracked separately.
- App Check on React Native Firebase uses the native App Check SDKs (Play Integrity / DeviceCheck), not the web reCAPTCHA path — `docs/threat-model.md` updated accordingly.
- Design-system rebuild restarts with Uniwind; `AppNavBar`/`AppButton`/etc. spec carries over conceptually (see PR B's widget inventory, pre-migration), implementation does not.

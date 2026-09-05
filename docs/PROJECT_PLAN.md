# ShiftWise (React Native / Expo) — Project Index

**This is the only file Claude Code should read in full at the start of every session.** Everything else is loaded on demand, per task. Do not read the whole `docs/` tree unless explicitly asked to audit the full plan.

## What this is

ShiftWise: cross-platform (iOS/Android, React Native + Expo) app answering three questions for hourly workers — next shift, scheduled hours, estimated gross pay. AI-assisted schedule import via photo, always human-confirmed before becoming authoritative.

**Migrating from Flutter as of `docs/decisions/0001-migrate-flutter-to-react-native-expo.md` (2026-09-05) — read that record before touching stack/architecture docs.** The Flutter app is being rewritten, not ported; do not assume Dart file paths below are current until each doc's own migration-progress note says so.

## How to navigate this repo's docs

| If your task involves... | Read... |
|---|---|
| Any UI/widget work, colors, type, layout | `docs/design/tokens.md` + `docs/design/screens.md` |
| Firestore schema, security rules, data model | `docs/architecture/data-model.md` |
| AI photo-import pipeline, job states | `docs/architecture/ai-import.md` |
| Pay calculation, money, time/timezone logic | `docs/architecture/pay-engine.md` |
| Billing, entitlements, subscriptions | `docs/architecture/billing.md` |
| Auth, offline sync | `docs/architecture/sync-and-auth.md` |
| Offline conflict resolution (multi-device edits, edit-vs-AI-draft overlap) | `docs/architecture/offline-conflict-resolution.md` |
| Stack choices, repo structure, package list | `docs/architecture/stack.md` |
| Security controls, threat model | `docs/threat-model.md` |
| What's in/out of scope, tier boundaries | `docs/scope.md` |
| Testing requirements, CI gates | `docs/testing.md` |
| Release checklist | `docs/release-gates.md` |
| Agent behavior rules for this repo | `AGENTS.md` (repo root, always loaded) |

## Non-negotiable rules (apply regardless of task)

These are restated here because they're the ones most likely to get silently violated if an agent is only loading one doc at a time:

1. AI never writes directly to confirmed shifts. Every import requires human confirmation. → `docs/architecture/ai-import.md`
2. Currency is never a raw `double`. → `docs/architecture/pay-engine.md`
3. The client (React Native app) never writes entitlements, quota, or billing state. Server-authoritative only, enforced by Firestore rules + Cloud Functions. → `docs/architecture/billing.md`, `docs/threat-model.md`
4. Every status shown in UI carries a non-color signal, not color alone. → `docs/design/tokens.md`
5. Firestore/Storage rule changes require an emulator test in the same commit. → `docs/testing.md`

## Current phase

See `docs/phases.md` for the phase breakdown and exit criteria. Work one phase at a time; do not jump ahead.

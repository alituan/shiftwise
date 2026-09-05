# Stack & Repository Structure

## Decision record

Flutter replaces the original Next.js web plan entirely — one codebase, iOS/Android primary, Flutter web secondary if ever needed. Firebase backend unchanged (framework-agnostic). Rationale: one developer, five concurrent projects — two frontends against one backend means every business rule (pay rounding, entitlement checks, AI-import state) gets written and maintained twice, which is how drift bugs happen.

## Package choices

| Layer | Choice | Why |
|---|---|---|
| State management | Riverpod (`flutter_riverpod` + `riverpod_generator`) | Testable, compile-safe DI; better solo-dev default than Bloc's boilerplate |
| Backend | Firebase: Auth, Firestore, Storage, Functions (2nd gen), FCM | Unchanged from original web plan |
| Local persistence | Firestore offline cache by default. Only add `Isar`/`Hive` if the cache genuinely can't cover a case (e.g. complex unsynced-edit queue) | Extra local DB = extra sync-bug surface. Default answer to "do we need this" is no |
| Money | `decimal` package. Never raw `double` for currency | Dart's `double` is binary float, same footgun as JS |
| Forms | Plain Material `Form`/`TextFormField`/`FormField` — see deviation record | Validation still mirrors Cloud Functions schema rules; stays on the token-driven `ThemeData` (2026-09-04 deviation below) |
| Push | `firebase_messaging` (server-triggered) + `flutter_local_notifications` (scheduled, offline-safe) | Use local for "shift starts in 30 min" (deterministic); FCM for server events like "import finished" |
| Images | `image_picker` + `image_cropper` + `image` (re-encode/strip EXIF) | Mirrors browser crop/re-encode pipeline from AI-import spec |
| Routing | `go_router` | Declarative, consistent route guards across platforms |
| Testing | `flutter_test`, `mocktail`, Firebase emulator integration tests, `golden_toolkit` | Golden tests protect the design system from silent drift over a long build |
| CI/CD | GitHub Actions (`flutter test`, `flutter analyze`, per-platform build) + Codemagic/Fastlane for store deploy | |
| Monitoring | Firebase Crashlytics + Sentry Flutter SDK | Same redaction requirements as original plan — see `docs/threat-model.md` |

## Deviation record

- **2026-09-04 — `flutter_form_builder` → plain Material fields (Phase 1).** v11 builds on the `material_ui` component fork, whose `InputDecoration` is a different class from `flutter/material`'s — forms built on it cannot consume the token-driven `ThemeData` every other surface maps through, so it was removed before any form shipped. Direct packages added instead: `uuid` (client-side shift ids), `intl` (en-US wall-clock formatting until locale Settings exist), `meta` (`@immutable` on domain models).
- **2026-09-05 — Material 3 off at the theme layer (owner decision, stage A of three).** `useMaterial3: false`, a directly constructed token-pinned `ColorScheme` (no `fromSeed` — seed-derived containers were the main leak), and explicit component-theme pins for every framework surface (AppBar, buttons, input, card, bottom sheet, nav bar, dialog, snackbar, FAB, progress, divider, icon, chip, switch, checkbox, radio, tooltip, tab bar, drawer, pickers), `VisualDensity.compact` global. Stage B replaces production widgets with a custom library; stage C adopts it in screens. Reference aesthetic: Linear / Vercel / Arc — dense, dark-first, high contrast.

## Repository structure

```
/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── router.dart
│   │   ├── theme/{tokens.dart,theme.dart}
│   │   └── app.dart
│   ├── features/
│   │   ├── auth/
│   │   ├── schedule/
│   │   ├── scan/
│   │   ├── pay/
│   │   ├── jobs/
│   │   ├── settings/
│   │   └── billing/
│   │       └── {data,domain,presentation}/
│   ├── domain/                    # framework-free — no Flutter/Firebase imports
│   │   ├── money/
│   │   ├── time/
│   │   ├── pay/
│   │   └── concerns/
│   ├── shared/
│   │   ├── widgets/                # design-system components
│   │   └── firebase/
│   └── l10n/
├── functions/                      # Cloud Functions, Node/TS — unchanged from web plan
│   └── src/{callable,http,workers,billing,privacy,observability}/
├── firebase/{firestore.rules,firestore.indexes.json,storage.rules}
├── test/
│   ├── domain/
│   ├── features/
│   ├── golden/
│   └── integration/
├── docs/                           # this doc tree
├── assets/{icons,fonts}/
├── AGENTS.md
└── docs/PROJECT_PLAN.md
```

**Discipline rule:** `lib/domain/` stays pure Dart — no widget imports, no Firebase imports. This is what makes the pay engine unit-testable without spinning up emulators for every run.

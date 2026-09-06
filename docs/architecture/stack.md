# Stack & Repository Structure

## Decision record

**2026-09-06 — dark-first design-system rebuild + Uniwind re-verification.** Owner explicitly asked to confirm `uniwind` (installed in Phase 1) was a real, correctly-resolved package before building further on it, with an instruction to fall back to NativeWind 4 otherwise. Verified: `cat node_modules/uniwind/package.json` returns a genuine package record (`"name": "uniwind"`, `"version": "1.12.0"`, homepage `uniwind.dev`, repo `github.com/uni-stack/uniwind`, real `dependencies`/`peerDependencies`) — matches the public npm registry, not a phantom/stub module. No swap to NativeWind was needed; Uniwind continues. Design system tokens rebuilt dark-first (`#0A0A0B` background, electric-blue `#3B6EF8` primary, glass/blur surfaces) per owner spec — see `docs/design/tokens.md`. New libraries added for this: `react-native-reanimated` + `react-native-worklets` (all animations, `withSpring`/`withTiming` only, never the legacy `Animated` API), `react-native-gesture-handler` (also required by `@gorhom/bottom-sheet`), `expo-blur`, `react-native-svg` (radial glow effect — `expo-linear-gradient` is linear-only and can't do this), `lucide-react-native` (icons, the only icon library), `@gorhom/bottom-sheet`, `@expo-google-fonts/inter` (Inter Regular 400 + Bold 700 only).

**2026-09-05 — migrated from Flutter to React Native + Expo.** Full rationale, what's reused vs rebuilt, and the Firebase-SDK consequence: `docs/decisions/0001-migrate-flutter-to-react-native-expo.md`. Firebase backend unchanged (framework-agnostic) — Firestore, Storage, Cloud Functions, security rules all carry over.

Earlier decision record, still true of the backend half: one developer, five concurrent projects — two frontends against one backend means every business rule (pay rounding, entitlement checks, AI-import state) gets written and maintained twice, which is how drift bugs happen. The migration's own driver: one TypeScript stack shared with `functions/` (already TypeScript), Expo's cloud build/OTA workflow, larger contributor pool than Flutter/Dart.

## Package choices

| Layer | Choice | Why |
|---|---|---|
| Framework | Expo (managed, custom dev client — see Firebase row) + TypeScript | Cloud builds (EAS), OTA updates, one codebase for iOS/Android, no local Android/Xcode SDK dependency for day-to-day dev |
| Routing | `expo-router` | Expo's current default (file-based, decoupled from React Navigation as of SDK 56); deep linking and typed routes out of the box |
| State management | Zustand + TanStack Query (Firestore listeners bridged via a small subscription hook) | Testable, minimal boilerplate; TanStack Query's cache semantics fit read-mostly Firestore data well |
| Styling | **Uniwind** (Tailwind CSS for React Native, from the Unistyles authors) | Owner-directed choice; classNames compile to native styles at build time (no runtime cost), dark mode and custom theme tokens built in — see `docs/design/tokens.md` for the token-to-Tailwind-theme mapping |
| Backend | Firebase: Auth, Firestore, Storage, Functions (2nd gen), FCM — unchanged | Framework-agnostic, reused as-is |
| Firebase SDK | **React Native Firebase** (native), not the Firebase JS SDK | The JS SDK has no Firestore offline persistence on RN (no IndexedDB) — see decision 0001. Requires an Expo custom dev client (`expo-dev-client` + config plugins), not plain Expo Go |
| Local persistence | Firestore offline cache (native, via React Native Firebase) by default. Only add MMKV/SQLite if the cache genuinely can't cover a case | Same discipline as the Flutter era: extra local DB = extra sync-bug surface |
| Money | `decimal.js`. Never raw JS `number` for currency | Same IEEE-754 float footgun as Dart's `double` |
| Forms | React Hook Form + Zod schemas | Validation schema mirrors Cloud Functions' server-side schema checks; Zod schemas are shareable between client validation and (if ever needed) a Functions-side schema |
| Push | `@react-native-firebase/messaging` (server-triggered) + `expo-notifications` (scheduled, offline-safe local reminders) | Same split as before: local for deterministic "shift starts in 30 min," FCM for server-triggered events like "import finished" |
| Images | `expo-image-picker` + `expo-image-manipulator` (crop/re-encode/strip EXIF) | `expo-image-picker`'s built-in crop UI plus `expo-image-manipulator` for the re-encode-to-strip-EXIF step mirrors the old `image_cropper` + `image` pipeline |
| Testing | Jest + React Native Testing Library (unit/component), Maestro (E2E flows), `@firebase/rules-unit-testing` (security rules) | Current (2026) React Native testing consensus: Jest+RNTL for fast component-level confidence, Maestro for declarative real-flow E2E instead of Detox's heavier setup |
| CI/CD | GitHub Actions (`tsc`, ESLint, Jest, rules tests) + EAS Build/Submit for store deploy | EAS replaces Codemagic/Fastlane from the Flutter plan — native to Expo |
| Monitoring | Firebase Crashlytics (via React Native Firebase) + Sentry React Native SDK | Same redaction requirements as before — see `docs/threat-model.md` |

## Repository structure

```
/
├── app/                            # expo-router routes (file-based)
│   ├── (tabs)/{schedule,scan,pay,settings}.tsx
│   ├── _layout.tsx
│   └── ...
├── src/
│   ├── features/
│   │   ├── auth/
│   │   ├── schedule/
│   │   ├── scan/
│   │   ├── pay/
│   │   ├── jobs/
│   │   ├── settings/
│   │   └── billing/
│   │       └── {data,domain,presentation}/
│   ├── domain/                     # framework-free — no React Native/Firebase imports
│   │   ├── money/
│   │   ├── time/
│   │   ├── pay/
│   │   └── concerns/
│   ├── shared/
│   │   ├── components/             # design-system components (Uniwind-styled)
│   │   └── firebase/
│   ├── theme/{tokens.ts,tailwind-theme.ts}
│   └── i18n/
├── functions/                      # Cloud Functions, Node/TS — unchanged
│   └── src/{callable,http,workers,billing,privacy,observability}/
├── firebase/{firestore.rules,firestore.indexes.json,storage.rules}
├── __tests__/
│   ├── domain/
│   ├── features/
│   └── components/
├── e2e/                             # Maestro flows
├── docs/                            # this doc tree
├── assets/{icons,fonts}/
├── AGENTS.md
└── docs/PROJECT_PLAN.md
```

**Discipline rule:** `src/domain/` stays framework-free — no React Native imports, no Firebase imports. This is what makes the pay engine unit-testable without spinning up emulators or a RN runtime for every run.

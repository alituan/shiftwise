# ShiftWise

Cross-platform (iOS/Android) Flutter app for hourly workers: next shift,
scheduled hours, estimated gross pay. AI-assisted schedule import is always
human-confirmed before it becomes authoritative.

Read `docs/PROJECT_PLAN.md` first — it routes every task to the right doc.
Agent working rules live in `AGENTS.md`; the phase breakdown in
`docs/phases.md`.

## Development

The toolchain is pinned in `mise.toml`:

    mise install
    flutter pub get
    flutter analyze
    dart format --output=none --set-exit-if-changed .
    flutter test

Web is a preview/verification target only — iOS and Android are the shipping
platforms:

    flutter run -d web-server --web-port 3000 --web-hostname 0.0.0.0

## Firebase auth (dev)

The app initializes Firebase with demo options (`lib/firebase_options.dart`),
so guest mode works with no Firebase project at all. Real sign-up/sign-in
needs the Auth emulator (or a real project, once created):

    firebase emulators:start --only auth

Then run the app or tests against it:

    flutter run -d web-server --web-port 3000 --dart-define=USE_FIREBASE_EMULATOR=true
    firebase emulators:exec --only auth -- "flutter test test/integration"

`integration_test/auth_test.dart` runs the real Firebase Auth SDK against
the emulator — it needs a device or web target (see the test file header),
not the plain `flutter test` VM. The `demo-shiftwise` project id comes from
`.firebaserc`; nothing in it is secret. When a real Firebase project exists,
regenerate `lib/firebase_options.dart` with `flutterfire configure`.

### Firestore and Storage security rules

Rules live in `firebase/` and are the app's entire security boundary —
every change ships with hostile emulator tests in the same commit
(`docs/testing.md`). Run them:

    firebase emulators:exec --only firestore,storage -- "npm --prefix rules-tests test"

The suite attacks the rules through direct SDK calls (cross-user access,
unauthenticated access, server-owned collections), never through the app
UI. Shift documents are client read-only: every shift write goes through
the `writeShift` Cloud Function.

### The writeShift guard (Cloud Functions)

All shift writes (create, edit, delete) go through one transactional
callable in `functions/` — the guard that makes stale writes either
auto-merge (disjoint fields) or return `CONFLICT` with the current server
document instead of silently overwriting. Its suite runs against the
Firestore emulator:

    firebase emulators:exec --only firestore -- "npm --prefix functions test"

### Scan (AI import, client side)

`/scan` photographs or picks a schedule, crops to the user's row (native
cropper UIs; works in the web preview too), strips EXIF by re-encoding,
validates client-side, and requires explicit consent naming the AI
processor before anything is prepared. The processor name is a single
placeholder constant in `lib/features/scan/scan_config.dart` — replace it
when the AI provider is chosen. Nothing uploads yet; the backend pipeline
is the next phase step.

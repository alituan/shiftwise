# ShiftWise

Cross-platform (iOS/Android) React Native + Expo app for hourly workers:
next shift, scheduled hours, estimated gross pay. AI-assisted schedule
import is always human-confirmed before it becomes authoritative.

**Migrating from Flutter** — see
`docs/decisions/0001-migrate-flutter-to-react-native-expo.md`. This README
describes the target stack; the Flutter app (`lib/`, `test/`, `android/`,
`ios/`) is still present in the tree until the migration phases replace it.

Read `docs/PROJECT_PLAN.md` first — it routes every task to the right doc.
Agent working rules live in `AGENTS.md`; the phase breakdown in
`docs/phases.md`.

## Development (target stack, once the Expo scaffold lands)

    npm install
    npx tsc --noEmit
    npx eslint .
    npx prettier --check .
    npx jest

Web (Expo web) is a preview/verification target only — iOS and Android are
the shipping platforms.

## Firebase (dev)

The app uses React Native Firebase (native SDK, not the Firebase JS SDK —
see the decision record for why), which requires an Expo custom
development build rather than plain Expo Go. Guest mode works with no
Firebase project at all; real sign-up/sign-in needs the Auth emulator (or
a real project, once created):

    firebase emulators:start --only auth,firestore,storage

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

`/scan` photographs or picks a schedule, crops to the user's row, strips
EXIF by re-encoding, validates client-side, and requires explicit consent
naming the AI processor before anything is prepared. Nothing uploads yet;
the backend pipeline is a later phase step.

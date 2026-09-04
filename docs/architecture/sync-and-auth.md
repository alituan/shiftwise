# Auth, Offline & Sync

## Auth (MVP)

- First-party email sign-up/sign-in via Firebase Auth.
- Email verification where risk policy requires it.
- Password reset flow.
- Optional local guest use for manual-only scheduling (no cloud sync, no AI, no billing until account created).
- Cloud sync, AI import, billing, export, and cross-device history all require an authenticated account.
- Google sign-in only after onboarding evidence supports adding it — not a default MVP requirement.

## Authority model

- Firebase ID tokens authenticate Firestore, Storage, and Cloud Functions calls.
- Firestore/Storage rules are authoritative for any direct SDK call from the app — **this is the only security boundary**, there is no server-rendered layer behind it like a traditional web app might have.
- App Check protects supported Firebase resources from abuse.
- Cloud Functions re-check UID, entitlement, job ownership, quota, and schema server-side on every privileged call — never trust a UID, entitlement, price, rate, or path submitted by the client.
- Route guards in `go_router` improve UX (redirect unauthenticated users) but are not a security control — treat them purely as navigation convenience.

## Browser/app storage

- No secrets or privileged tokens in local storage of any kind (`SharedPreferences`, on-disk caches).
- Use Firestore's built-in offline persistence deliberately, not by default-and-forget.
- Clear user-scoped local caches on logout.
- Warn the user visibly about unsynced local changes before they could be lost (e.g. logout while offline with pending writes).

## Offline baseline

- Cached confirmed shifts remain viewable offline.
- Manual shift creation/editing works fully offline.
- Pending writes show an explicit sync-state indicator in the UI (`docs/design/screens.md` — Schedule screen states).
- AI import clearly requires connectivity — communicate this in the Scan screen, don't let users queue a scan offline expecting silent background completion.
- Interrupted uploads (mid-scan) restart or resume without creating duplicate parse jobs.

## Conflict resolution — the highest-risk piece of this app

**Do not treat "Firestore has offline persistence" as solving this.** Firestore's offline cache handles read-while-offline well; it does not give you conflict resolution for free. Default behavior without explicit handling is last-write-wins, which silently loses data.

Required design before building sync-dependent UI:

- Every shift document carries `revision` (monotonic int) and `updatedAt` (server timestamp).
- Writes go through a transaction that reads current `revision` first; if the local write's base revision doesn't match, the write is rejected client-side and the user is shown a conflict resolution prompt — never silently overwritten.
- Test case: shift edited on Device A while offline, then edited differently on Device B while online, then Device A reconnects. Expected: Device A's write is flagged as stale, user chooses which version wins (or fields are merged if non-overlapping).
- Test case: same scenario but Device A's edit is a delete. Deletes need explicit conflict handling too — don't let a stale delete silently remove a shift someone else just edited.

**Full spec: `docs/architecture/offline-conflict-resolution.md`** — data model addition, write-path transaction logic, the two conflict cases this app actually needs to handle, UX rules, and required test cases. Read that doc before building any screen with edit-while-offline capability. Treat it as a Phase 2 deliverable, not a checkbox.

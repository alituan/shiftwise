# Offline Conflict Resolution — Design Spec

Referenced from `docs/architecture/sync-and-auth.md`. Phase 2 deliverable — build this before any screen ships edit-while-offline capability.

## Scope check first

This app has no employer/team accounts and no shift-swapping (see `docs/scope.md` — both explicitly deferred). That means conflicts are never "two different people edited the same shift." They're always one of two narrower cases:

1. **Same user, multiple devices** — phone and tablet, or old phone and new phone mid-migration, both holding a stale local copy.
2. **Manual edit vs. AI-import draft** — a user manually edits a shift while an AI-import job is independently proposing a change to a shift that overlaps or matches it.

Design for these two cases specifically. Don't build generic multi-party CRDT-style merge machinery for a conflict shape that can't occur — that's effort spent solving a harder problem than the one you have.

## Data model addition

Every shift document (see `docs/architecture/data-model.md`) already has `revision` and `updatedAt`. This spec defines exactly how they're used.

```
revision: int          # starts at 1 on creation, incremented on every accepted write
updatedAt: Timestamp    # server-set, never client-set
updatedBy: deviceId     # new field — see below
```

**Add `updatedBy: string`** — a locally-generated, persisted device identifier (UUID, generated once on first app install, stored in local device storage, never synced or shown to the user). This isn't for security or identity — it's so the UI can distinguish "this stale write came from a different device than the one I'm on right now" versus "I'm looking at my own recent edit that hasn't finished syncing yet." Without it, the conflict prompt can't tell those two cases apart, and they need different copy: one is "your other device changed this," the other is "still syncing."

## Write path

All shift writes — manual edit, manual delete, and AI-import confirmation writes — go through one function, not ad hoc `.set()` calls scattered across features:

```dart
Future<WriteResult> writeShift({
  required String shiftId,
  required ShiftData data,
  required int baseRevision,   // revision the app believes is current, read before editing began
})
```

Server-side (Cloud Function, since this is exactly the kind of transactional guard that shouldn't live client-side even though it's not a privileged-data write):

```
transaction:
  read current shift doc
  if current.revision != baseRevision:
    return CONFLICT(current)   # do not write, return the current server state
  else:
    write with revision = baseRevision + 1, updatedAt = server time, updatedBy = deviceId
    return SUCCESS
```

Doing this as a Cloud Function rather than a raw client-side Firestore transaction keeps it consistent with the rest of the app's authority model (`sync-and-auth.md`) and gives one place to add server-side validation (e.g. reject an edit that breaks the "end after start" invariant) without duplicating that logic into a client-side transaction too.

## Client behavior on `WriteResult`

- `SUCCESS` → local state updates normally, sync indicator clears.
- `CONFLICT(current)` → do **not** retry silently, do **not** overwrite. Surface the conflict prompt (see UX below) with both versions visible: what the user was about to save, and what's currently on the server.

## Case 1: same user, multiple devices

**Scenario:** User edits shift start time on Device A while offline. Later, still offline, edits the same shift's location on Device B (different device, synced earlier). Device B is online and syncs immediately (`revision` 3 → 4). Device A reconnects later and tries to push its own edit based on stale `revision` 3.

**Resolution:** Device A's write returns `CONFLICT`. Since the two edits touched *different fields* (start time vs. location), this is a safe case for field-level merge, not a forced choice:

- If the changed fields don't overlap between the local pending write and the current server version → auto-merge, write succeeds with the merged result, no user prompt needed. This keeps the common case invisible.
- If the changed fields *do* overlap (both edited start time, differently) → show the conflict prompt. Auto-merging conflicting values on the same field is exactly the "silently lose data" failure mode this spec exists to prevent.

**Deletes are never auto-merged.** If Device A's pending write is a delete and the server version has since been edited (different revision), always prompt — never silently apply a stale delete over an edit someone made in the meantime, and never silently discard a delete because an edit came in first. Show both: "You deleted this shift. It was also edited on [device] since then. Delete anyway / Keep the edit."

## Case 2: manual edit vs. AI-import draft

**Scenario:** AI import proposes a new shift (or an edit to an existing one, if the import pipeline supports that) that overlaps a shift the user is simultaneously editing manually in the Schedule screen.

This is narrower than Case 1 because AI-import drafts never write to confirmed shifts directly (`docs/architecture/ai-import.md`) — they only ever reach `review_required` state. So there's no silent-write risk here at all; the actual requirement is just **UI awareness**, not a data-layer conflict:

- If the user opens the Scan review screen and a draft shift overlaps an existing confirmed shift (by time range, same job), flag it visibly in the review UI before they confirm — "This overlaps your existing 2–10 PM shift on Tuesday." Let them accept, edit, or discard the draft with that context, rather than silently creating two overlapping confirmed shifts.
- This is a review-time UI check, not a transactional write-path check — implement it as a query against confirmed shifts in the draft's date range when rendering the Scan review screen.

## UX for the conflict prompt (ties to `docs/design/tokens.md` and `screens.md`)

Trigger only for genuine same-field conflicts (Case 1) or conflicting deletes — not for the auto-merged or review-time-flagged cases above, which stay invisible or advisory respectively.

- Plain language, no technical terms: never say "revision mismatch" or "sync conflict" to the user. Say what actually happened: "This shift was changed on your other device."
- Show both versions side by side with the differing field(s) highlighted — don't make the user hunt for what's different.
- Two clear actions, named for the outcome, not the mechanism: "Keep this device's version" / "Keep the other version" — never "Overwrite" / "Cancel," which don't communicate which data survives.
- No silent auto-resolution for same-field conflicts or delete conflicts, ever — full stop, this is the one absolute rule in this spec.

## Required test cases (add to `docs/testing.md` integration suite)

1. Two devices, non-overlapping field edits, both offline then both sync → auto-merge succeeds, no prompt shown, both field changes present in final document.
2. Two devices, same-field edit (e.g. both change `startUtc` to different values) → conflict prompt shown, user's choice is the value that persists, `revision` increments correctly, `updatedBy` reflects the winning device.
3. Device A deletes offline while Device B edits the same shift online first → conflict prompt shown, both explicit choices (delete-anyway / keep-edit) tested.
4. Interrupted write mid-transaction (simulate network drop after transaction starts, before it completes) → no partial write, no duplicate `revision` increment, retry is safe.
5. AI-import draft overlapping a confirmed shift → overlap warning renders in Scan review screen before confirmation, confirming with the warning still present creates the shift (user's explicit choice is respected, this is advisory not blocking).

## What this spec deliberately does not cover

Multi-user collaborative editing, real-time presence indicators ("someone else is editing this"), or CRDT-based automatic merging of arbitrary concurrent edits. None of these apply given the no-team-accounts scope constraint. If team accounts are ever added (currently deferred per `docs/scope.md`), this spec needs a full revisit — the "one user, multiple devices" assumption breaks and the conflict space gets meaningfully larger.

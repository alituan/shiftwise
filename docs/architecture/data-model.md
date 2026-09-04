# Firestore Data Model

Unchanged from the original web plan — this is backend, not frontend. Restated here so Flutter feature work can reference it without pulling in unrelated docs.

## Collections

```
/users/{uid}                              # validated profile
/users/{uid}/jobs/{jobId}
/users/{uid}/jobs/{jobId}/rateVersions/{rateId}
/users/{uid}/shifts/{shiftId}
/users/{uid}/parseJobs/{parseJobId}        # readable; server controls authority
/users/{uid}/calculationSnapshots/{id}     # server-owned
/entitlements/{uid}                        # server-owned
/usage/{uid_period}                        # server-owned
/rulePacks/{jurisdiction_ruleVersion}      # admin/server-owned
/webhookEvents/{provider_eventId}          # server-only
```

## Shift document

```
jobId
startUtc
endUtc
timeZone
localWorkDate
role
location
paidBreakMinutes
unpaidBreakMinutes
source: manual | scanned
sourceParseJobId
reviewStatus: confirmed
revision
createdAt
updatedAt
```

Constraints: end after start, valid IANA timezone, job must be owned by requesting user, overnight shifts supported, server-set audit timestamps, reject unknown fields/types. Derive "upcoming"/"completed" status at read time — never store it, it goes stale.

## Query rules

- Query the visible calendar range plus a small prefetch window only.
- Unsubscribe listeners on route/range change — don't accumulate listeners.
- Paginate history views.
- Add indexes only from real queries you're running, not speculatively.
- Never listen to a user's entire shift history at once.
- Large exports run as bounded server-side jobs, not client-side loops.

## Client-prohibited writes

The Flutter app must never write these directly — only Cloud Functions do:

- Entitlements
- Usage counters
- Billing/webhook records
- Authoritative parse-job transitions
- Calculation snapshots
- Published rule packs

**This list is the enforcement boundary in a client-only app — there's no server-rendered layer to add defense in depth like a traditional web app might have.** Every item here needs a Firestore emulator test proving direct-SDK writes are denied, not just proving the UI doesn't expose a button for it.

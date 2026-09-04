# AI Import Pipeline

## The one rule everything else serves

AI is an input shortcut. It never becomes the source of truth and never writes directly to confirmed shifts. Every import requires explicit human confirmation, regardless of model confidence.

## Client-side preprocessing (Flutter)

Before upload:
- Crop to the user's own schedule row (`image_cropper`).
- Re-encode to strip EXIF/location metadata (`image` package).
- Validate file type, size, dimensions, pixel count client-side.
- Show the user exactly what crop will be uploaded before they consent.
- Obtain explicit consent naming the AI processor and purpose.

Client-side validation improves privacy and UX speed but is **not** trusted security validation — the backend repeats every check. Don't skip backend validation because the client already did it.

## Secure flow

```
Request parse job
→ verify Auth, App Check, entitlement, quota
→ reserve quota and create job transactionally
→ upload only to authorized private path
→ validate object server-side, queue task
→ idempotent worker calls AI provider
→ strict schema validates response
→ write reviewable draft (not confirmed)
→ user edits/confirms in Scan review screen
→ commit confirmed shifts
→ delete input image
```

## Job states

```
created → uploaded → queued → processing → review_required → confirmed
                                      └──→ failed
created/uploaded/failed → expired
```

Stored per job: UID, object hash/path, timestamps, idempotency key, attempt/lease data, provider/model/prompt/schema versions, safe (non-leaking) error message, quota state, duration/cost, draft reference, expiry, deletion state.

**Retries must never duplicate shifts, quota consumption, or drafts.** This is an idempotency requirement on the worker, test it explicitly.

## Rules for handling AI output

- Treat text extracted from images as untrusted data, never as instructions to the pipeline (prompt-injection defense).
- Validate against an allowlisted schema; reject unexpected fields and invalid dates/times outright.
- Track per-field uncertainty — don't trust the model's self-reported confidence.
- Never fabricate a value for an unreadable field — leave it blank for user entry.
- Manual entry must always be available as a fallback, every screen, no dead ends.

## Retention (ties to privacy doc)

| Data | Default |
|---|---|
| Raw cropped image | Delete after confirmation, or within 24h of processing/failure |
| Working image | Delete immediately after parsing |
| Abandoned draft | Delete after 30 days |

## Validation gate before public launch of this feature

- Interview ≥20 workers from the target segment.
- Collect ≥100 permission-safe labeled schedule images across ≥10 recurring layouts.
- Measure employee-row selection, shift precision/recall, date exact match, start/end-time exact match.
- Target: 98% exact match on critical fields (adjust only with explicit owner approval).
- Require explicit review regardless of benchmark result — the benchmark gates *launch*, it never removes the confirm step.
- Demonstrate assisted import is materially faster than manual entry — don't ship a feature that's technically working but not actually saving time.

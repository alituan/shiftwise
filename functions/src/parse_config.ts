/// Server-side tunables for the AI-import pipeline (docs/architecture/
/// ai-import.md, docs/scope.md). Enforced by Cloud Functions only — the
/// client never sees or trusts these values.
///
/// Free tier is deliberately tight for launch (owner decision): a low
/// allowance forces validating that AI import is actually useful before
/// giving it away liberally, and raising a limit later is far easier than
/// lowering one users already expect.

/** Free-tier monthly AI-import allowance. */
export const FREE_TIER_MONTHLY_PARSE_LIMIT = 5;

/** Hours until an un-uploaded / failed job expires (ai-import.md retention). */
export const PARSE_JOB_TTL_HOURS = 24;

/** Job document id prefix; the idempotency key completes it. */
export const PARSE_JOB_ID_PREFIX = 'pj_';

/** Client-generated per-consent key: UUID-shaped, its own document id. */
export const IDEMPOTENCY_KEY_PATTERN = /^[A-Za-z0-9-]{8,64}$/;

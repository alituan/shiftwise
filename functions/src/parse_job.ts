/// createParseJob — the parse-job state machine's entry point and the
/// quota reservation authority (docs/architecture/ai-import.md,
/// docs/architecture/billing.md).
///
/// One Firestore transaction performs the idempotency check, the
/// entitlement/quota check, the usage increment, and the job creation.
/// Atomicity guarantees: quota is never consumed without a job existing,
/// and no job exists without quota consumed. Concurrent callers serialize
/// on the usage document, so parallel requests cannot race past the limit.
/// Every later transition (uploaded, queued, processing, …) is written by
/// server code only — Firestore rules already deny all client writes to
/// parseJobs, entitlements, and usage.
import { HttpsError } from 'firebase-functions/v2/https';
import {
  FieldValue,
  Timestamp,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';

import {
  FREE_TIER_MONTHLY_PARSE_LIMIT,
  IDEMPOTENCY_KEY_PATTERN,
  PARSE_JOB_ID_PREFIX,
  PARSE_JOB_TTL_HOURS,
} from './parse_config';

export interface CreateParseJobResult {
  jobId: string;
  /** Current job state — 'created', or the state of an idempotent replay. */
  state: string;
  /** The only Storage path a later step may upload to. */
  uploadPath: string;
  expiresAt: Timestamp;
  /** True when an existing job was returned without consuming quota. */
  idempotentReplay: boolean;
}

function bad(message: string): never {
  throw new HttpsError('invalid-argument', message);
}

/** The request carries exactly one field — nothing client-authoritative. */
function parseIdempotencyKey(raw: unknown): string {
  if (typeof raw !== 'object' || raw === null) bad('request must be an object');
  const req = raw as Record<string, unknown>;
  const keys = Object.keys(req);
  if (keys.length !== 1 || keys[0] !== 'idempotencyKey') {
    bad('request must contain only idempotencyKey');
  }
  const key = req.idempotencyKey;
  if (typeof key !== 'string' || !IDEMPOTENCY_KEY_PATTERN.test(key)) {
    bad('idempotencyKey must be [A-Za-z0-9-]{8,64}');
  }
  return key;
}

/** Monthly period key for the server-owned usage document. UTC-based. */
function periodKey(now: Date): string {
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(2, '0')}`;
}

/**
 * A missing entitlement is the free tier. A lapsed Pro subscription
 * (active: false) degrades to the free tier rather than denying outright —
 * scope.md keeps a limited AI-import allowance in the free tier, so an
 * expired subscription must not compare worse than never having subscribed.
 * An explicit integer allowance overrides the default when active.
 */
function effectiveMonthlyLimit(entitlement: DocumentSnapshot): number {
  if (!entitlement.exists) return FREE_TIER_MONTHLY_PARSE_LIMIT;
  const data = entitlement.data() ?? {};
  if (data.active === false) return FREE_TIER_MONTHLY_PARSE_LIMIT;
  const allowance = data.parseAllowancePerMonth;
  if (
    typeof allowance === 'number' &&
    Number.isInteger(allowance) &&
    allowance >= 0
  ) {
    return allowance;
  }
  return FREE_TIER_MONTHLY_PARSE_LIMIT;
}

/**
 * The guard itself, separated from the callable wrapper so tests drive it
 * directly against the Firestore emulator. `now` is injectable so the
 * month-rollover behavior can be tested across period boundaries.
 */
export async function applyCreateParseJob(
  db: Firestore,
  uid: string | null | undefined,
  rawRequest: unknown,
  now: Date = new Date(),
): Promise<CreateParseJobResult> {
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const idempotencyKey = parseIdempotencyKey(rawRequest);
  const jobId = `${PARSE_JOB_ID_PREFIX}${idempotencyKey}`;
  const jobRef = db.doc(`users/${uid}/parseJobs/${jobId}`);
  const entitlementRef = db.doc(`entitlements/${uid}`);
  const period = periodKey(now);
  const usageRef = db.doc(`usage/${uid}_${period}`);
  const expiresAt = Timestamp.fromDate(
    new Date(now.getTime() + PARSE_JOB_TTL_HOURS * 60 * 60 * 1000),
  );
  const uploadPath = `users/${uid}/parseJobs/${jobId}/input.jpg`;

  return db.runTransaction(async (tx) => {
    const [jobSnap, entitlementSnap, usageSnap] = await Promise.all([
      tx.get(jobRef),
      tx.get(entitlementRef),
      tx.get(usageRef),
    ]);

    // Idempotent replay: same consent, same job — never a second charge.
    if (jobSnap.exists) {
      const existing = jobSnap.data() as {
        state: string;
        uploadPath: string;
        expiresAt: Timestamp;
      };
      return {
        jobId,
        state: existing.state,
        uploadPath: existing.uploadPath,
        expiresAt: existing.expiresAt,
        idempotentReplay: true,
      } satisfies CreateParseJobResult;
    }

    const limit = effectiveMonthlyLimit(entitlementSnap);
    const created =
      typeof usageSnap.get('parseJobsCreated') === 'number'
        ? (usageSnap.get('parseJobsCreated') as number)
        : 0;
    const refunded =
      typeof usageSnap.get('parseJobsRefunded') === 'number'
        ? (usageSnap.get('parseJobsRefunded') as number)
        : 0;
    // Reserved = created minus refunded, so later failure refunds (the
    // worker step) can give allowance back without schema changes.
    if (Math.max(0, created - refunded) + 1 > limit) {
      throw new HttpsError(
        'resource-exhausted',
        'Monthly AI-import limit reached.',
      );
    }

    if (usageSnap.exists) {
      tx.update(usageRef, {
        parseJobsCreated: FieldValue.increment(1),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      tx.create(usageRef, {
        uid,
        period,
        parseJobsCreated: 1,
        parseJobsRefunded: 0,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    tx.create(jobRef, {
      uid,
      idempotencyKey,
      state: 'created',
      uploadPath,
      objectHash: null, // stamped at server-side upload validation
      quotaPeriod: period,
      deletionState: 'pending',
      createdAt: FieldValue.serverTimestamp(),
      expiresAt,
    });

    return {
      jobId,
      state: 'created',
      uploadPath,
      expiresAt,
      idempotentReplay: false,
    } satisfies CreateParseJobResult;
  });
}

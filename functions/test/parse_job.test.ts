/// createParseJob tests against the real Firestore emulator — quota
/// reservation, idempotency, and the job state machine's entry point
/// (docs/architecture/ai-import.md, docs/testing.md "Cloud Functions").
///
/// The concurrency tests fire genuinely parallel calls (Promise.allSettled,
/// never a sequential loop) because only real simultaneous transactions
/// prove the usage-document serialization the spec demands.
///
/// Run under the emulator (never against a real project):
///
///     firebase emulators:exec --only firestore -- "npm --prefix functions test"
import { beforeAll, beforeEach, afterAll, describe, expect, it } from 'vitest';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { applyCreateParseJob } from '../src/parse_job';
import { FREE_TIER_MONTHLY_PARSE_LIMIT } from '../src/parse_config';

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    'FIRESTORE_EMULATOR_HOST is not set — run under ' +
      '`firebase emulators:exec --only firestore -- "npm --prefix functions test"` ' +
      'so these tests never touch a real project.',
  );
}

let db: Firestore;

beforeAll(() => {
  if (getApps().length === 0) {
    initializeApp({ projectId: 'demo-shiftwise' });
  }
  db = getFirestore();
});

const ALICE = 'alice';
const NOW = new Date(Date.UTC(2026, 8, 5, 12, 0)); // 2026-09-05T12:00Z

async function clearAll(): Promise<void> {
  const jobs = await db.collection(`users/${ALICE}/parseJobs`).listDocuments();
  await Promise.all(jobs.map((doc) => doc.delete()));
  await db.doc(`entitlements/${ALICE}`).delete();
  const usage = await db.collection('usage').listDocuments();
  await Promise.all(usage.map((doc) => doc.delete()));
}

beforeEach(clearAll);
afterAll(clearAll);

function call(
  key: string | unknown,
  uid: string | null = ALICE,
  now: Date = NOW,
): ReturnType<typeof applyCreateParseJob> {
  return applyCreateParseJob(
    db,
    uid,
    typeof key === 'string' ? { idempotencyKey: key } : key,
    now,
  );
}

function key(n: number): string {
  return `parallel-key-${n}`;
}

async function jobCount(): Promise<number> {
  const snap = await db.collection(`users/${ALICE}/parseJobs`).get();
  return snap.size;
}

async function usageDoc(period: string) {
  return db.doc(`usage/${ALICE}_${period}`).get();
}

describe('entry point: job creation', () => {
  it('creates a job in the created state with expiry and upload path', async () => {
    const result = await call('aaaa-bbbb-cccc-0001');

    expect(result.jobId).toBe('pj_aaaa-bbbb-cccc-0001');
    expect(result.state).toBe('created');
    expect(result.idempotentReplay).toBe(false);
    expect(result.uploadPath).toBe(
      'users/alice/parseJobs/pj_aaaa-bbbb-cccc-0001/input.jpg',
    );
    // 24h TTL, stamped server-side from the injectable clock.
    expect(result.expiresAt.toMillis()).toBe(
      NOW.getTime() + 24 * 60 * 60 * 1000,
    );

    const job = (await db.doc(`users/${ALICE}/parseJobs/${result.jobId}`).get())
      .data();
    expect(job).toMatchObject({
      uid: ALICE,
      idempotencyKey: 'aaaa-bbbb-cccc-0001',
      state: 'created',
      uploadPath: result.uploadPath,
      objectHash: null,
      quotaPeriod: '2026-09',
      deletionState: 'pending',
    });

    const usage = await usageDoc('2026-09');
    expect(usage.exists).toBe(true);
    expect(usage.data()).toMatchObject({
      uid: ALICE,
      period: '2026-09',
      parseJobsCreated: 1,
      parseJobsRefunded: 0,
    });
  });

  it('rejects unauthenticated callers', async () => {
    await expect(call('aaaa-bbbb-cccc-0002', null)).rejects.toMatchObject({
      code: 'unauthenticated',
    });
    expect(await jobCount()).toBe(0);
  });

  it('rejects malformed keys and any client-authoritative field', async () => {
    await expect(call('short')).rejects.toMatchObject({
      code: 'invalid-argument',
    });
    await expect(call({ idempotencyKey: 'aaaa-bbbb-cccc-0003', state: 'confirmed' }))
      .rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(call({ quota: 999 })).rejects.toMatchObject({
      code: 'invalid-argument',
    });
    expect(await jobCount()).toBe(0);
  });
});

describe('idempotency', () => {
  it('replaying the same key returns the same job without a second charge', async () => {
    const first = await call('aaaa-bbbb-cccc-0010');
    const second = await call('aaaa-bbbb-cccc-0010');

    expect(second.jobId).toBe(first.jobId);
    expect(second.idempotentReplay).toBe(true);
    expect(second.state).toBe('created');
    expect(await jobCount()).toBe(1);
    expect((await usageDoc('2026-09')).data()?.parseJobsCreated).toBe(1);
  });

  it('parallel calls with the same key create one job and one charge', async () => {
    const results = await Promise.allSettled([
      call('aaaa-bbbb-cccc-0011'),
      call('aaaa-bbbb-cccc-0011'),
      call('aaaa-bbbb-cccc-0011'),
    ]);

    // Every caller succeeds — one creates, the others replay it.
    for (const r of results) expect(r.status).toBe('fulfilled');
    expect(await jobCount()).toBe(1);
    expect((await usageDoc('2026-09')).data()?.parseJobsCreated).toBe(1);
  });
});

describe('quota enforcement', () => {
  it('parallel calls at the limit boundary admit exactly the limit', async () => {
    const total = FREE_TIER_MONTHLY_PARSE_LIMIT + 3; // 8 contenders, 5 slots
    // Genuinely simultaneous transactions — a sequential loop would prove
    // nothing about serialization under real concurrency.
    const results = await Promise.allSettled(
      Array.from({ length: total }, (_, i) => call(key(i))),
    );

    const fulfilled = results.filter((r) => r.status === 'fulfilled');
    const rejected = results.filter((r) => r.status === 'rejected');
    expect(fulfilled.length).toBe(FREE_TIER_MONTHLY_PARSE_LIMIT);
    expect(rejected.length).toBe(3);
    for (const r of rejected) {
      expect((r as PromiseRejectedResult).reason).toMatchObject({
        code: 'resource-exhausted',
      });
    }
    expect(await jobCount()).toBe(FREE_TIER_MONTHLY_PARSE_LIMIT);
    expect((await usageDoc('2026-09')).data()?.parseJobsCreated).toBe(
      FREE_TIER_MONTHLY_PARSE_LIMIT,
    );
  });

  it('rejects the next job once the period is exhausted, creating nothing', async () => {
    await db.doc(`usage/${ALICE}_2026-09`).create({
      uid: ALICE,
      period: '2026-09',
      parseJobsCreated: FREE_TIER_MONTHLY_PARSE_LIMIT,
      parseJobsRefunded: 0,
    });

    await expect(call('aaaa-bbbb-cccc-0020')).rejects.toMatchObject({
      code: 'resource-exhausted',
    });
    expect(await jobCount()).toBe(0);
    // The rejected attempt must not have mutated the counter.
    expect((await usageDoc('2026-09')).data()?.parseJobsCreated).toBe(
      FREE_TIER_MONTHLY_PARSE_LIMIT,
    );
  });

  it('counts refunds against the allowance (worker-step forward compatibility)', async () => {
    await db.doc(`usage/${ALICE}_2026-09`).create({
      uid: ALICE,
      period: '2026-09',
      parseJobsCreated: FREE_TIER_MONTHLY_PARSE_LIMIT,
      parseJobsRefunded: 2,
    });
    // 5 created - 2 refunded = 3 reserved; two more slots exist.
    await expect(call('aaaa-bbbb-cccc-0030')).resolves.toMatchObject({
      idempotentReplay: false,
    });
    await expect(call('aaaa-bbbb-cccc-0031')).resolves.toMatchObject({
      idempotentReplay: false,
    });
    await expect(call('aaaa-bbbb-cccc-0032')).rejects.toMatchObject({
      code: 'resource-exhausted',
    });
  });

  it('a month rollover creates a separate usage document, not a reset counter', async () => {
    const august = new Date(Date.UTC(2026, 7, 31, 23, 30)); // 2026-08-31
    const september = new Date(Date.UTC(2026, 8, 1, 0, 30)); // 2026-09-01

    await call('aaaa-bbbb-cccc-0040', ALICE, august);
    await call('aaaa-bbbb-cccc-0041', ALICE, september);

    // Both period documents must exist independently, each with its own
    // count — uid_YYYY-MM is the key, so rollover produces a new document.
    const augDoc = await usageDoc('2026-08');
    const sepDoc = await usageDoc('2026-09');
    expect(augDoc.exists).toBe(true);
    expect(augDoc.data()?.parseJobsCreated).toBe(1);
    expect(augDoc.data()?.period).toBe('2026-08');
    expect(sepDoc.exists).toBe(true);
    expect(sepDoc.data()?.parseJobsCreated).toBe(1);
    expect(sepDoc.data()?.period).toBe('2026-09');

    // And the September job stamps its own quota period.
    const sepJob = (
      await db.doc(`users/${ALICE}/parseJobs/pj_aaaa-bbbb-cccc-0041`).get()
    ).data();
    expect(sepJob?.quotaPeriod).toBe('2026-09');
  });
});

describe('entitlements', () => {
  it('an active entitlement allowance overrides the free-tier default', async () => {
    await db.doc(`entitlements/${ALICE}`).create({
      active: true,
      parseAllowancePerMonth: 2,
    });
    await expect(call('aaaa-bbbb-cccc-0050')).resolves.toBeTruthy();
    await expect(call('aaaa-bbbb-cccc-0051')).resolves.toBeTruthy();
    await expect(call('aaaa-bbbb-cccc-0052')).rejects.toMatchObject({
      code: 'resource-exhausted',
    });
    expect(await jobCount()).toBe(2);
  });

  it('a lapsed subscription degrades to the free tier, not denial', async () => {
    await db.doc(`entitlements/${ALICE}`).create({
      active: false,
      parseAllowancePerMonth: 100,
    });
    // Free-tier limit (5), not the stale allowance of 100 — and never a
    // total denial, since the free tier includes limited AI imports.
    for (let i = 0; i < FREE_TIER_MONTHLY_PARSE_LIMIT; i++) {
      await expect(call(`lapsed-key-${i}`)).resolves.toBeTruthy();
    }
    await expect(call('lapsed-key-final')).rejects.toMatchObject({
      code: 'resource-exhausted',
    });
  });

  it('parallel calls honor an entitlement allowance without overselling it', async () => {
    await db.doc(`entitlements/${ALICE}`).create({
      active: true,
      parseAllowancePerMonth: 3,
    });
    const results = await Promise.allSettled(
      Array.from({ length: 6 }, (_, i) => call(`entitled-key-${i}`)),
    );
    expect(results.filter((r) => r.status === 'fulfilled').length).toBe(3);
    expect(results.filter((r) => r.status === 'rejected').length).toBe(3);
    expect(await jobCount()).toBe(3);
  });
});

describe('HttpsError surface', () => {
  it('quota failures are resource-exhausted HttpsErrors, not raw throws', async () => {
    await db.doc(`usage/${ALICE}_2026-09`).create({
      uid: ALICE,
      period: '2026-09',
      parseJobsCreated: FREE_TIER_MONTHLY_PARSE_LIMIT,
      parseJobsRefunded: 0,
    });
    try {
      await call('aaaa-bbbb-cccc-0060');
      expect.unreachable('should have thrown');
    } catch (error) {
      expect(error).toBeInstanceOf(HttpsError);
      expect((error as HttpsError).code).toBe('resource-exhausted');
    }
  });
});

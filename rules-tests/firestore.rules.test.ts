/// Hostile direct-SDK tests for the deny-by-default Firestore rules.
///
/// These attack the rules through the Firestore client SDK, bypassing any
/// app UI — the only honest way to test the security boundary
/// (docs/testing.md, docs/threat-model.md). Shift documents are read-only
/// here on purpose: every shift write goes through the writeShift callable
/// (functions/src/write_shift.ts), whose own suite covers schema,
/// revision monotonicity, and conflict detection. Closing direct client
/// writes in these rules is what makes that guard unbypassable.
///
/// Run with the Firestore emulator up:
///
///     firebase emulators:exec --only firestore,storage -- "npm --prefix rules-tests test"
import { beforeAll, afterAll, beforeEach, describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

const { FieldValue, Timestamp } = firebase.firestore;

// v5 of the harness takes rules SOURCE, not a file path — load it from
// beside the repo's firebase/ directory so any CWD works.
const rulesPath = fileURLToPath(
  new URL('../firebase/firestore.rules', import.meta.url),
);
const rulesSource = readFileSync(rulesPath, 'utf8');

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-shiftwise',
    firestore: { rules: rulesSource },
  });
});

afterAll(() => testEnv.cleanup());

beforeEach(() => testEnv.clearFirestore());

/** Full 16-key shift document (writeShift's stored shape). */
function shiftDoc(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    jobId: 'job-1',
    startUtc: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 14, 0)),
    endUtc: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 22, 0)),
    timeZone: 'Africa/Kigali',
    localWorkDate: '2026-09-04',
    role: null,
    location: null,
    paidBreakMinutes: 0,
    unpaidBreakMinutes: 30,
    source: 'manual',
    sourceParseJobId: null,
    reviewStatus: 'confirmed',
    revision: 1,
    createdAt: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 9, 0)),
    updatedAt: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 9, 0)),
    updatedBy: 'device-seed',
    ...overrides,
  };
}

async function seed(path: string, data: Record<string, unknown>): Promise<void> {
  await testEnv.withSecurityRulesDisabled((context) =>
    context.firestore().doc(path).set(data as never),
  );
}

describe('authentication boundary', () => {
  it('denies unauthenticated reads of a user tree', async () => {
    await seed('users/alice/shifts/s1', shiftDoc());
    await assertFails(
      testEnv.unauthenticatedContext().firestore().doc('users/alice/shifts/s1').get(),
    );
  });

  it('denies unauthenticated shift creation', async () => {
    await assertFails(
      testEnv
        .unauthenticatedContext()
        .firestore()
        .doc('users/alice/shifts/s1')
        .set(shiftDoc({ createdAt: FieldValue.serverTimestamp() }) as never),
    );
  });
});

describe('user isolation (cross-user attacks)', () => {
  it('denies reading another user shift', async () => {
    await seed('users/alice/shifts/s1', shiftDoc());
    await assertFails(
      testEnv.authenticatedContext('bob').firestore().doc('users/alice/shifts/s1').get(),
    );
  });

  it('denies listing another user shifts', async () => {
    await seed('users/alice/shifts/s1', shiftDoc());
    await assertFails(
      testEnv
        .authenticatedContext('bob')
        .firestore()
        .collection('users/alice/shifts')
        .get(),
    );
  });

  it('denies writing into another user tree', async () => {
    await assertFails(
      testEnv
        .authenticatedContext('bob')
        .firestore()
        .doc('users/alice/shifts/s1')
        .set(shiftDoc({ createdAt: FieldValue.serverTimestamp() }) as never),
    );
  });

  it('denies deleting another user shift', async () => {
    await seed('users/alice/shifts/s1', shiftDoc());
    await assertFails(
      testEnv
        .authenticatedContext('bob')
        .firestore()
        .doc('users/alice/shifts/s1')
        .delete(),
    );
  });

  it('denies reading another user profile', async () => {
    await seed('users/alice', {
      email: 'alice@shiftwise.test',
      createdAt: FieldValue.serverTimestamp(),
    });
    await assertFails(
      testEnv.authenticatedContext('bob').firestore().doc('users/alice').get(),
    );
  });
});

describe('shifts are writeShift-only', () => {
  it('allows the owner to read and list own shifts', async () => {
    await seed('users/alice/shifts/s1', shiftDoc());
    await assertSucceeds(
      testEnv.authenticatedContext('alice').firestore().doc('users/alice/shifts/s1').get(),
    );
    await assertSucceeds(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .collection('users/alice/shifts')
        .get(),
    );
  });

  it('denies direct owner creates — the callable is the only write path', async () => {
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .doc('users/alice/shifts/s1')
        .set(shiftDoc({ createdAt: FieldValue.serverTimestamp() }) as never),
    );
  });

  it('denies direct owner updates even with a correct revision bump', async () => {
    await seed('users/alice/shifts/s1', shiftDoc());
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .doc('users/alice/shifts/s1')
        .set(
          shiftDoc({
            revision: 2,
            updatedAt: FieldValue.serverTimestamp(),
          }) as never,
        ),
    );
  });

  it('denies direct owner deletes — stale deletes must hit the guard', async () => {
    await seed('users/alice/shifts/s1', shiftDoc());
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .doc('users/alice/shifts/s1')
        .delete(),
    );
  });
});

describe('profile document', () => {
  it('allows the owner to create a minimal profile', async () => {
    await assertSucceeds(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .doc('users/alice')
        .set({
          email: 'alice@shiftwise.test',
          createdAt: FieldValue.serverTimestamp(),
        } as never),
    );
  });

  it('rejects a profile with an unknown field', async () => {
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .doc('users/alice')
        .set({
          email: 'alice@shiftwise.test',
          createdAt: FieldValue.serverTimestamp(),
          quota: 999,
        } as never),
    );
  });

  it('rejects profile updates for now (they arrive with the sync step)', async () => {
    await seed('users/alice', {
      email: 'alice@shiftwise.test',
      createdAt: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 9, 0)),
    });
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .doc('users/alice')
        .set({
          email: 'alice@shiftwise.test',
          createdAt: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 9, 0)),
          displayName: 'Alice',
        } as never),
    );
  });
});

describe('server-owned collections (Cloud Functions territory)', () => {
  it('denies client reads and writes of entitlements even when signed in', async () => {
    const ctx = testEnv.authenticatedContext('alice').firestore();
    await assertFails(ctx.doc('entitlements/alice').get());
    await assertFails(ctx.doc('entitlements/alice').set({ pro: true } as never));
  });

  it('denies client writes to usage counters', async () => {
    await assertFails(
      testEnv
        .authenticatedContext('alice')
        .firestore()
        .doc('usage/alice_2026_09')
        .set({ imports: 99 } as never),
    );
  });

  it('denies client writes to rule packs and webhook events', async () => {
    const ctx = testEnv.authenticatedContext('alice').firestore();
    await assertFails(ctx.doc('rulePacks/rw-1').set({ rules: [] } as never));
    await assertFails(ctx.doc('webhookEvents/evt-1').set({ payload: {} } as never));
  });

  it('allows the owner to read but never write parse jobs', async () => {
    const ctx = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(ctx.doc('users/alice/parseJobs/p1').get());
    await assertFails(
      ctx.doc('users/alice/parseJobs/p1').set({ state: 'confirmed' } as never),
    );
  });

  it('allows the owner to read but never write calculation snapshots', async () => {
    const ctx = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(ctx.doc('users/alice/calculationSnapshots/c1').get());
    await assertFails(
      ctx.doc('users/alice/calculationSnapshots/c1').set({ hours: 8 } as never),
    );
  });

  it('allows the owner to read but never write jobs and rate versions', async () => {
    const ctx = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(ctx.doc('users/alice/jobs/job-1').get());
    await assertFails(
      ctx.doc('users/alice/jobs/job-1').set({ name: 'Cafe' } as never),
    );
    await assertFails(
      ctx
        .doc('users/alice/jobs/job-1/rateVersions/r1')
        .set({ rate: 16.5 } as never),
    );
  });
});

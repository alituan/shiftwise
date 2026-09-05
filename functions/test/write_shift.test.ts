/// writeShift guard tests against the real Firestore emulator — the spec's
/// required cases 1-4 plus the authority and schema boundary
/// (docs/architecture/offline-conflict-resolution.md,
/// docs/testing.md "Cloud Functions" layer).
///
/// Run under the emulator (never against a real project):
///
///     firebase emulators:exec --only firestore -- "npm --prefix functions test"
import { beforeAll, beforeEach, afterAll, describe, expect, it } from 'vitest';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { applyWriteShift } from '../src/write_shift';

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

afterAll(async () => {
  await clearShifts();
});

const ALICE = 'alice';
const CREATED_AT = Timestamp.fromMillis(Date.UTC(2026, 8, 4, 9, 0));
const UPDATED_AT = Timestamp.fromMillis(Date.UTC(2026, 8, 4, 9, 0));

async function clearShifts(): Promise<void> {
  const docs = await db.collection(`users/${ALICE}/shifts`).listDocuments();
  await Promise.all(docs.map((doc) => doc.delete()));
}

beforeEach(clearShifts);

/** The 12 client-supplied fields. */
function dataFixture(overrides: Record<string, unknown> = {}) {
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
    ...overrides,
  };
}

/** A full 16-key document as the server stores it. */
function docFixture(overrides: Record<string, unknown> = {}) {
  return {
    ...dataFixture(),
    revision: 1,
    createdAt: CREATED_AT,
    updatedAt: UPDATED_AT,
    updatedBy: 'device-seed',
    ...overrides,
  };
}

async function seed(
  overrides: Record<string, unknown> = {},
): Promise<ReturnType<typeof docFixture>> {
  const doc = docFixture(overrides);
  await db.doc(`users/${ALICE}/shifts/s1`).set(doc);
  return doc;
}

function request(
  overrides: Partial<{
    shiftId: string;
    operation: string;
    baseRevision: number;
    deviceId: string;
    data: unknown;
    baseData: unknown;
  }> = {},
) {
  return {
    shiftId: 's1',
    operation: 'update',
    baseRevision: 1,
    deviceId: 'device-a',
    ...overrides,
  };
}

describe('create', () => {
  it('writes revision 1 with server timestamps and updatedBy', async () => {
    const result = await applyWriteShift(
      db,
      ALICE,
      request({ operation: 'create', baseRevision: 0, data: dataFixture() }),
    );
    expect(result).toEqual({ status: 'success', revision: 1 });
    const stored = (await db.doc(`users/${ALICE}/shifts/s1`).get()).data()!;
    expect(stored.revision).toBe(1);
    expect(stored.updatedBy).toBe('device-a');
    expect(stored.createdAt).toBeInstanceOf(Timestamp);
    expect(stored.updatedAt).toBeInstanceOf(Timestamp);
  });

  it('rejects creating over an existing shift', async () => {
    await seed();
    await expect(
      applyWriteShift(
        db,
        ALICE,
        request({ operation: 'create', baseRevision: 0, data: dataFixture() }),
      ),
    ).rejects.toMatchObject({ code: 'already-exists' });
  });

  it('validates the schema (end after start, exact keys)', async () => {
    await expect(
      applyWriteShift(
        db,
        ALICE,
        request({
          operation: 'create',
          baseRevision: 0,
          data: dataFixture({ endUtc: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 14, 0)) }),
        }),
      ),
    ).rejects.toMatchObject({ code: 'invalid-argument' });

    const withExtra = { ...dataFixture(), updatedBy: 'device-a' };
    await expect(
      applyWriteShift(db, ALICE, request({ operation: 'create', baseRevision: 0, data: withExtra })),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

describe('update on a fresh base', () => {
  it('increments revision, preserves createdAt, records updatedBy', async () => {
    await seed();
    const result = await applyWriteShift(
      db,
      ALICE,
      request({
        baseData: dataFixture(),
        data: dataFixture({ unpaidBreakMinutes: 45 }),
        deviceId: 'device-b',
      }),
    );
    expect(result).toEqual({ status: 'success', revision: 2 });
    const stored = (await db.doc(`users/${ALICE}/shifts/s1`).get()).data()!;
    expect(stored.unpaidBreakMinutes).toBe(45);
    expect(stored.revision).toBe(2);
    expect(stored.updatedBy).toBe('device-b');
    expect((stored.createdAt as Timestamp).isEqual(CREATED_AT)).toBe(true);
  });
});

describe('spec case 1: disjoint field edits auto-merge', () => {
  it('merges without a prompt and bumps from the server revision', async () => {
    const base = await seed(); // revision 1, break 30, location null
    // Another device already moved revision to 2 with a location edit.
    await db.doc(`users/${ALICE}/shifts/s1`).set({
      ...base,
      revision: 2,
      location: 'Front counter',
      updatedBy: 'device-b',
    });

    // This device, still holding revision 1, edits only the break.
    const result = await applyWriteShift(
      db,
      ALICE,
      request({
        baseRevision: 1,
        baseData: dataFixture(),
        data: dataFixture({ unpaidBreakMinutes: 45 }),
        deviceId: 'device-a',
      }),
    );
    expect(result).toEqual({ status: 'success', revision: 3, merged: true });
    const stored = (await db.doc(`users/${ALICE}/shifts/s1`).get()).data()!;
    expect(stored.unpaidBreakMinutes).toBe(45);
    expect(stored.location).toBe('Front counter');
    expect(stored.revision).toBe(3);
    expect(stored.updatedBy).toBe('device-a');
  });
});

describe('spec case 2: same-field conflict', () => {
  it('returns CONFLICT with the current document and writes nothing', async () => {
    const base = await seed();
    await db.doc(`users/${ALICE}/shifts/s1`).set({
      ...base,
      revision: 2,
      location: 'Kitchen',
      updatedBy: 'device-b',
    });

    const result = await applyWriteShift(
      db,
      ALICE,
      request({
        baseRevision: 1,
        baseData: dataFixture(),
        data: dataFixture({ location: 'Bar' }),
        deviceId: 'device-a',
      }),
    );
    expect(result.status).toBe('conflict');
    if (result.status === 'conflict') {
      expect(result.current.revision).toBe(2);
      expect(result.current.location).toBe('Kitchen');
    }
    const stored = (await db.doc(`users/${ALICE}/shifts/s1`).get()).data()!;
    expect(stored.location).toBe('Kitchen');
    expect(stored.revision).toBe(2);
  });

  it("the user's choice persists when resent on the fresh base", async () => {
    const base = await seed();
    await db.doc(`users/${ALICE}/shifts/s1`).set({
      ...base,
      revision: 2,
      location: 'Kitchen',
      updatedBy: 'device-b',
    });
    const result = await applyWriteShift(
      db,
      ALICE,
      request({
        baseRevision: 2,
        baseData: dataFixture({ location: 'Kitchen' }),
        data: dataFixture({ location: 'Bar' }),
        deviceId: 'device-a',
      }),
    );
    expect(result).toEqual({ status: 'success', revision: 3 });
    const stored = (await db.doc(`users/${ALICE}/shifts/s1`).get()).data()!;
    expect(stored.location).toBe('Bar');
    expect(stored.updatedBy).toBe('device-a');
  });

  it('never writes a disjoint merge that breaks end-after-start', async () => {
    const base = await seed(); // 14:00-22:00
    await db.doc(`users/${ALICE}/shifts/s1`).set({
      ...base,
      revision: 2,
      endUtc: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 16, 0)),
      updatedBy: 'device-b',
    });
    // Disjoint fields (startUtc vs endUtc) but the merge would end <= start.
    const result = await applyWriteShift(
      db,
      ALICE,
      request({
        baseRevision: 1,
        baseData: dataFixture(),
        data: dataFixture({ startUtc: Timestamp.fromMillis(Date.UTC(2026, 8, 4, 18, 0)) }),
        deviceId: 'device-a',
      }),
    );
    expect(result.status).toBe('conflict');
    const stored = (await db.doc(`users/${ALICE}/shifts/s1`).get()).data()!;
    expect((stored.endUtc as Timestamp).toMillis()).toBe(
      Date.UTC(2026, 8, 4, 16, 0),
    );
    expect(stored.revision).toBe(2);
  });
});

describe('spec case 3: deletes never auto-merge', () => {
  it('conflicts a stale delete over a newer edit', async () => {
    const base = await seed();
    await db.doc(`users/${ALICE}/shifts/s1`).set({
      ...base,
      revision: 2,
      location: 'Kitchen',
      updatedBy: 'device-b',
    });
    const result = await applyWriteShift(
      db,
      ALICE,
      request({ operation: 'delete', baseRevision: 1 }),
    );
    expect(result.status).toBe('conflict');
    expect((await db.doc(`users/${ALICE}/shifts/s1`).get()).exists).toBe(true);
  });

  it('delete-anyway works once resubmitted on the fresh base', async () => {
    const base = await seed();
    await db.doc(`users/${ALICE}/shifts/s1`).set({ ...base, revision: 2 });
    const result = await applyWriteShift(
      db,
      ALICE,
      request({ operation: 'delete', baseRevision: 2 }),
    );
    expect(result).toEqual({ status: 'success' });
    expect((await db.doc(`users/${ALICE}/shifts/s1`).get()).exists).toBe(false);
  });

  it('keep-edit works: a normal update on the fresh base survives', async () => {
    const base = await seed();
    await db.doc(`users/${ALICE}/shifts/s1`).set({ ...base, revision: 2 });
    const result = await applyWriteShift(
      db,
      ALICE,
      request({
        baseRevision: 2,
        baseData: dataFixture(),
        data: dataFixture({ unpaidBreakMinutes: 15 }),
      }),
    );
    expect(result).toEqual({ status: 'success', revision: 3 });
  });

  it('deleting a missing shift is idempotent (retry after uncertainty)', async () => {
    const result = await applyWriteShift(
      db,
      ALICE,
      request({ operation: 'delete', baseRevision: 3 }),
    );
    expect(result).toEqual({ status: 'success' });
  });
});

describe('spec case 4: transaction integrity', () => {
  it('two writers on the same base produce one success, one conflict, +1 revision', async () => {
    await seed();
    const calls = [
      applyWriteShift(
        db,
        ALICE,
        request({
          baseData: dataFixture(),
          data: dataFixture({ unpaidBreakMinutes: 45 }),
          deviceId: 'device-a',
        }),
      ),
      applyWriteShift(
        db,
        ALICE,
        request({
          baseData: dataFixture(),
          data: dataFixture({ unpaidBreakMinutes: 60 }),
          deviceId: 'device-b',
        }),
      ),
    ];
    const results = await Promise.all(calls);
    const successes = results.filter((r) => r.status === 'success');
    const conflicts = results.filter((r) => r.status === 'conflict');
    expect(successes).toHaveLength(1);
    expect(conflicts).toHaveLength(1);
    const stored = (await db.doc(`users/${ALICE}/shifts/s1`).get()).data()!;
    expect(stored.revision).toBe(2);
    expect([45, 60]).toContain(stored.unpaidBreakMinutes);
  });
});

describe('authority boundary', () => {
  it('rejects unauthenticated calls', async () => {
    await expect(applyWriteShift(db, undefined, request())).rejects.toMatchObject({
      code: 'unauthenticated',
    });
  });

  it('rejects shiftId path traversal (cross-user escape)', async () => {
    await expect(
      applyWriteShift(db, ALICE, request({ shiftId: '../bob/shifts/s1' })),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('rejects malformed requests (bad revision, empty deviceId, bad operation)', async () => {
    await expect(
      applyWriteShift(db, ALICE, request({ baseRevision: 1.5 })),
    ).rejects.toBeInstanceOf(HttpsError);
    await expect(
      applyWriteShift(db, ALICE, request({ deviceId: '' })),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(
      applyWriteShift(db, ALICE, request({ operation: 'overwrite' })),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(
      applyWriteShift(db, ALICE, request({ data: dataFixture({ source: 'magic' }) })),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

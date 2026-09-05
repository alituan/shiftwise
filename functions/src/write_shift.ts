/// The writeShift transactional guard — the single write path for shift
/// documents (docs/architecture/offline-conflict-resolution.md).
///
/// All shift writes (create, edit, delete) pass through here so the client
/// never silently loses data: stale writes either auto-merge (disjoint
/// fields) or return CONFLICT with the current server document. The Admin
/// SDK bypasses Firestore rules, so this module is also the schema and
/// revision authority for shift documents.
import { HttpsError } from 'firebase-functions/v2/https';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import {
  SHIFT_DATA_KEYS,
  changedFields,
  validateShiftData,
  type ShiftData,
  type ShiftDocument,
} from './shift_schema';

export type WriteShiftOperation = 'create' | 'update' | 'delete';

export interface WriteShiftRequest {
  shiftId: string;
  operation: WriteShiftOperation;
  /** Revision the caller believes is current (0 for create). */
  baseRevision: number;
  /** Locally generated device id — recorded as updatedBy, never shown. */
  deviceId: string;
  /** The 12 client-supplied fields; required for create and update. */
  data?: unknown;
  /** The document as the caller last saw it; required for update so a
   * stale write can be auto-merged when the changed fields are disjoint. */
  baseData?: unknown;
}

export type WriteShiftResult =
  | { status: 'success'; revision?: number; merged?: boolean }
  | { status: 'conflict'; current: ShiftDocument };

const SHIFT_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
const DEVICE_ID_MAX = 128;

function bad(message: string): never {
  throw new HttpsError('invalid-argument', message);
}

function parseRequest(raw: unknown): WriteShiftRequest {
  if (typeof raw !== 'object' || raw === null) bad('request must be an object');
  const req = raw as Record<string, unknown>;
  if (typeof req.shiftId !== 'string' || !SHIFT_ID_PATTERN.test(req.shiftId)) {
    bad('shiftId must be [A-Za-z0-9_-]{1,128}');
  }
  if (req.operation !== 'create' && req.operation !== 'update' && req.operation !== 'delete') {
    bad("operation must be 'create', 'update', or 'delete'");
  }
  if (typeof req.baseRevision !== 'number' || !Number.isInteger(req.baseRevision) || req.baseRevision < 0) {
    bad('baseRevision must be an integer >= 0');
  }
  if (typeof req.deviceId !== 'string' || req.deviceId.length === 0 || req.deviceId.length > DEVICE_ID_MAX) {
    bad('deviceId must be a non-empty string');
  }
  return req as unknown as WriteShiftRequest;
}

/**
 * The guard itself, separated from the callable wrapper so tests drive it
 * directly against the Firestore emulator.
 */
export async function applyWriteShift(
  db: Firestore,
  uid: string | null | undefined,
  rawRequest: unknown,
): Promise<WriteShiftResult> {
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const request = parseRequest(rawRequest);
  if (request.operation !== 'delete' && request.data === undefined) {
    bad('data is required for create and update');
  }
  if (request.operation === 'update' && request.baseData === undefined) {
    bad('baseData is required for update');
  }
  const data =
    request.operation === 'delete' ? undefined : validateShiftData(request.data);
  const baseData =
    request.operation === 'update' ? validateShiftData(request.baseData) : undefined;

  const ref = db.doc(`users/${uid}/shifts/${request.shiftId}`);
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    if (!snapshot.exists) {
      if (request.operation === 'delete') {
        // Retry after an uncertain outcome: already gone, stay successful.
        return { status: 'success' } as const;
      }
      if (request.operation === 'update') {
        throw new HttpsError('not-found', 'Shift no longer exists.');
      }
      tx.set(ref, {
        ...data,
        revision: 1,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.deviceId,
      });
      return { status: 'success', revision: 1 } as const;
    }

    const current = snapshot.data() as ShiftDocument;

    if (request.operation === 'delete') {
      if (current.revision !== request.baseRevision) {
        return { status: 'conflict', current } as const;
      }
      tx.delete(ref);
      return { status: 'success' } as const;
    }

    if (request.operation === 'create') {
      throw new HttpsError('already-exists', 'Shift already exists.');
    }

    // update
    if (current.revision === request.baseRevision) {
      tx.set(ref, {
        ...data,
        revision: request.baseRevision + 1,
        createdAt: current.createdAt,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.deviceId,
      });
      return { status: 'success', revision: request.baseRevision + 1 } as const;
    }

    // Stale write: auto-merge only when the edited fields are disjoint
    // (spec Case 1). Overlapping edits and unsafe merges surface CONFLICT.
    const clientChanged = changedFields(baseData!, data!);
    const serverChanged = changedFields(baseData!, current);
    const overlap = clientChanged.some((key) => serverChanged.includes(key));
    if (!overlap) {
      const merged: Record<string, unknown> = {};
      for (const key of SHIFT_DATA_KEYS) {
        merged[key] = clientChanged.includes(key) ? data![key] : current[key];
      }
      try {
        validateShiftData(merged);
      } catch {
        // Disjoint fields can still break the end-after-start invariant —
        // merging would corrupt the document, so surface it instead.
        return { status: 'conflict', current } as const;
      }
      tx.set(ref, {
        ...merged,
        revision: (current.revision as number) + 1,
        createdAt: current.createdAt,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.deviceId,
      });
      return {
        status: 'success',
        revision: (current.revision as number) + 1,
        merged: true,
      } as const;
    }
    return { status: 'conflict', current } as const;
  });
}

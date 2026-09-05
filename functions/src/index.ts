/// Callable entry points. Admin is initialized at cold start; the Firestore
/// emulator is used only in dev/CI (FIRESTORE_EMULATOR_HOST), never as the
/// production backend. Named submodule imports — the same CJS/ESM interop
/// constraint the test harness hit first.
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { applyCreateParseJob } from './parse_job';
import { applyWriteShift } from './write_shift';

if (getApps().length === 0) {
  initializeApp();
}
const db = getFirestore();

export const writeShift = onCall((request) =>
  applyWriteShift(db, request.auth?.uid, request.data),
);

export const createParseJob = onCall((request) =>
  applyCreateParseJob(db, request.auth?.uid, request.data),
);

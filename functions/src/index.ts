/// Callable entry points. Admin is initialized at cold start; the Firestore
/// emulator is used only in dev/CI (FIRESTORE_EMULATOR_HOST), never as the
/// production backend.
import * as admin from 'firebase-admin';
import { onCall } from 'firebase-functions/v2/https';
import { applyWriteShift } from './write_shift';

admin.initializeApp();

export const writeShift = onCall((request) =>
  applyWriteShift(admin.firestore(), request.auth?.uid, request.data),
);

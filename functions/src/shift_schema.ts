/// Shift document schema shared by the writeShift guard. Mirrors
/// firebase/firestore.rules (pre-function era) and the Dart mapper
/// lib/features/schedule/data/shift_document.dart — the three are kept in
/// sync by their test suites.
///
/// The client supplies the 12 data fields; revision, createdAt, updatedAt,
/// and updatedBy are set by writeShift itself (docs/architecture/
/// offline-conflict-resolution.md).
import { HttpsError } from 'firebase-functions/v2/https';
import { Timestamp } from 'firebase-admin/firestore';

export const SHIFT_DATA_KEYS = [
  'jobId',
  'startUtc',
  'endUtc',
  'timeZone',
  'localWorkDate',
  'role',
  'location',
  'paidBreakMinutes',
  'unpaidBreakMinutes',
  'source',
  'sourceParseJobId',
  'reviewStatus',
] as const;

export type ShiftData = Record<(typeof SHIFT_DATA_KEYS)[number], unknown>;

export type ShiftDocument = ShiftData & {
  revision: number;
  createdAt: unknown;
  updatedAt: unknown;
  updatedBy: string;
};

const TIME_ZONE_PATTERN = /^[A-Za-z0-9_+/-]+$/;
const LOCAL_DATE_PATTERN = /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/;

function bad(message: string): never {
  throw new HttpsError('invalid-argument', message);
}

export function isNonEmptyString(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0;
}

function isStringOrNull(value: unknown): boolean {
  return value === null || typeof value === 'string';
}

/** Validates the 12 client-supplied data fields; throws on violation. */
export function validateShiftData(data: unknown): ShiftData {
  if (typeof data !== 'object' || data === null) {
    bad('data must be an object');
  }
  const keys = new Set(Object.keys(data));
  for (const key of SHIFT_DATA_KEYS) {
    if (!keys.has(key)) bad(`data is missing '${key}'`);
  }
  if (keys.size !== SHIFT_DATA_KEYS.length) {
    const unknown = [...keys].filter((k) => !(SHIFT_DATA_KEYS as readonly string[]).includes(k));
    bad(`data has unknown keys: ${unknown.join(', ')}`);
  }
  const doc = data as Record<string, unknown>;
  if (!isNonEmptyString(doc.jobId)) bad('jobId must be a non-empty string');
  if (!(doc.startUtc instanceof Timestamp)) bad('startUtc must be a timestamp');
  if (!(doc.endUtc instanceof Timestamp)) bad('endUtc must be a timestamp');
  if ((doc.endUtc as Timestamp).toMillis() <= (doc.startUtc as Timestamp).toMillis()) {
    bad('endUtc must be after startUtc');
  }
  if (typeof doc.timeZone !== 'string' || !TIME_ZONE_PATTERN.test(doc.timeZone)) {
    bad('timeZone must be an IANA-style zone id');
  }
  if (typeof doc.localWorkDate !== 'string' || !LOCAL_DATE_PATTERN.test(doc.localWorkDate)) {
    bad('localWorkDate must be YYYY-MM-DD');
  }
  if (!isStringOrNull(doc.role)) bad('role must be a string or null');
  if (!isStringOrNull(doc.location)) bad('location must be a string or null');
  if (typeof doc.paidBreakMinutes !== 'number' || !Number.isInteger(doc.paidBreakMinutes) || doc.paidBreakMinutes < 0) {
    bad('paidBreakMinutes must be an int >= 0');
  }
  if (typeof doc.unpaidBreakMinutes !== 'number' || !Number.isInteger(doc.unpaidBreakMinutes) || doc.unpaidBreakMinutes < 0) {
    bad('unpaidBreakMinutes must be an int >= 0');
  }
  if (doc.source !== 'manual' && doc.source !== 'scanned') {
    bad('source must be manual or scanned');
  }
  if (doc.source === 'manual' && doc.sourceParseJobId !== null) {
    bad('sourceParseJobId must be null for manual shifts');
  }
  if (doc.source === 'scanned' && !isNonEmptyString(doc.sourceParseJobId)) {
    bad('scanned shifts must reference their parse job');
  }
  if (doc.reviewStatus !== 'confirmed') {
    bad("shift documents are always 'confirmed'");
  }
  return data as ShiftData;
}

/** Values compare across Timestamps and primitives. */
export function valuesEqual(a: unknown, b: unknown): boolean {
  if (a instanceof Timestamp && b instanceof Timestamp) return a.isEqual(b);
  return a === b;
}

/** Which of the 12 data fields differ between two versions. */
export function changedFields(base: ShiftData, next: Record<string, unknown>): string[] {
  return SHIFT_DATA_KEYS.filter((key) => !valuesEqual(base[key], next[key]));
}

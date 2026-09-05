import { DateTime, Interval } from 'luxon';

/**
 * A shift's time boundaries, stored as UTC instants plus the IANA zone that
 * was in effect when the shift was scheduled (matches the shift document
 * shape in docs/architecture/data-model.md: startUtc, endUtc, timeZone).
 *
 * Durations are always computed from the UTC instants, never from wall-clock
 * subtraction -- that is what makes DST transitions correct for free: a
 * shift spanning "spring forward" is genuinely one hour shorter in wall-clock
 * terms, and one spanning "fall back" is genuinely one hour longer, because
 * the UTC instants already encode that.
 */
export interface ShiftInterval {
  startUtc: string; // ISO 8601 UTC instant, e.g. "2026-03-08T10:00:00.000Z"
  endUtc: string | null; // null = shift has no recorded end time yet
  timeZone: string; // IANA zone, e.g. "America/New_York"
}

export class InvalidShiftIntervalError extends Error {}

/** Throws InvalidShiftIntervalError for missing end, end<=start, or an unrecognized IANA zone. */
export function assertValidInterval(shift: ShiftInterval): void {
  if (!DateTime.local().setZone(shift.timeZone).isValid) {
    throw new InvalidShiftIntervalError(`Invalid IANA time zone: ${shift.timeZone}`);
  }
  if (shift.endUtc === null) {
    throw new InvalidShiftIntervalError('Shift has no end time');
  }
  const start = DateTime.fromISO(shift.startUtc, { zone: 'utc' });
  const end = DateTime.fromISO(shift.endUtc, { zone: 'utc' });
  if (!start.isValid || !end.isValid) {
    throw new InvalidShiftIntervalError('startUtc/endUtc must be valid ISO 8601 instants');
  }
  if (end <= start) {
    throw new InvalidShiftIntervalError('endUtc must be after startUtc');
  }
}

/**
 * Duration in minutes, computed from UTC instants. Correct across DST
 * transitions and timezone changes mid-shift by construction, since the
 * instants are already absolute -- no wall-clock arithmetic happens here.
 */
export function durationMinutes(shift: ShiftInterval): number {
  assertValidInterval(shift);
  const start = DateTime.fromISO(shift.startUtc, { zone: 'utc' });
  const end = DateTime.fromISO(shift.endUtc as string, { zone: 'utc' });
  return Interval.fromDateTimes(start, end).length('minutes');
}

/** True if the local wall-clock work date (per the shift's own time zone) falls on `dateISO` (YYYY-MM-DD). */
export function localWorkDate(shift: ShiftInterval): string {
  const start = DateTime.fromISO(shift.startUtc, { zone: 'utc' }).setZone(shift.timeZone);
  return start.toISODate() as string;
}

/** True if two shifts' UTC intervals overlap at all (used for the overlap schedule concern). */
export function intervalsOverlap(a: ShiftInterval, b: ShiftInterval): boolean {
  if (a.endUtc === null || b.endUtc === null) return false;
  const intervalA = Interval.fromDateTimes(
    DateTime.fromISO(a.startUtc, { zone: 'utc' }),
    DateTime.fromISO(a.endUtc, { zone: 'utc' }),
  );
  const intervalB = Interval.fromDateTimes(
    DateTime.fromISO(b.startUtc, { zone: 'utc' }),
    DateTime.fromISO(b.endUtc, { zone: 'utc' }),
  );
  return intervalA.overlaps(intervalB);
}

/** Rest interval in minutes between the end of `earlier` and the start of `later`. Negative if they overlap. */
export function restIntervalMinutes(earlier: ShiftInterval, later: ShiftInterval): number {
  if (earlier.endUtc === null) {
    throw new InvalidShiftIntervalError(
      'Cannot compute rest interval: earlier shift has no end time',
    );
  }
  const earlierEnd = DateTime.fromISO(earlier.endUtc, { zone: 'utc' });
  const laterStart = DateTime.fromISO(later.startUtc, { zone: 'utc' });
  return laterStart.diff(earlierEnd, 'minutes').minutes;
}

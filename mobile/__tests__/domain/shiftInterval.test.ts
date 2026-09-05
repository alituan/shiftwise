import {
  assertValidInterval,
  durationMinutes,
  InvalidShiftIntervalError,
  intervalsOverlap,
  localWorkDate,
  restIntervalMinutes,
  ShiftInterval,
} from '@/domain/time/ShiftInterval';

describe('ShiftInterval — required boundary cases (docs/architecture/pay-engine.md)', () => {
  it('computes a plain same-day shift duration correctly', () => {
    const shift: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
      timeZone: 'America/New_York',
    };
    expect(durationMinutes(shift)).toBe(8 * 60);
  });

  it('handles a shift crossing midnight (overnight shift)', () => {
    const shift: ShiftInterval = {
      startUtc: '2026-06-01T23:00:00.000Z',
      endUtc: '2026-06-02T07:00:00.000Z',
      timeZone: 'America/New_York',
    };
    expect(durationMinutes(shift)).toBe(8 * 60);
    // localWorkDate attributes the shift to the day it started, in its own zone
    expect(localWorkDate(shift)).toBe('2026-06-01');
  });

  it('handles a shift crossing a pay-week boundary (Sunday night into Monday)', () => {
    // 2026-06-07 is a Sunday
    const shift: ShiftInterval = {
      startUtc: '2026-06-08T02:00:00.000Z', // Sun 10pm EDT
      endUtc: '2026-06-08T10:00:00.000Z', // Mon 6am EDT
      timeZone: 'America/New_York',
    };
    expect(durationMinutes(shift)).toBe(8 * 60);
    expect(localWorkDate(shift)).toBe('2026-06-07');
  });

  it('DST spring-forward: a shift spanning the missing hour is genuinely one hour shorter', () => {
    // US spring-forward 2026: clocks jump 2:00am -> 3:00am on 2026-03-08 (America/New_York)
    const shift: ShiftInterval = {
      startUtc: '2026-03-08T05:00:00.000Z', // 12:00am EST
      endUtc: '2026-03-08T12:00:00.000Z', // 8:00am EDT
      timeZone: 'America/New_York',
    };
    // Wall-clock reads 12:00am-8:00am (8 hours) but only 7 real hours elapsed
    // because 2:00-3:00am never happened.
    expect(durationMinutes(shift)).toBe(7 * 60);
  });

  it('DST fall-back: a shift spanning the repeated hour is genuinely one hour longer', () => {
    // US fall-back 2026: clocks repeat 1:00am-2:00am on 2026-11-01 (America/New_York)
    const shift: ShiftInterval = {
      startUtc: '2026-11-01T04:00:00.000Z', // 12:00am EDT
      endUtc: '2026-11-01T12:00:00.000Z', // 7:00am EST
      timeZone: 'America/New_York',
    };
    // Wall-clock reads 12:00am-7:00am (7 hours) but 8 real hours elapsed
    // because 1:00-2:00am happened twice.
    expect(durationMinutes(shift)).toBe(8 * 60);
  });

  it('timezone change mid-shift: duration is still correct from UTC instants alone', () => {
    // The shift's own recorded zone can differ from a device's current zone;
    // duration never depends on wall-clock re-derivation, only on the UTC pair.
    const shift: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
      timeZone: 'Asia/Tokyo', // user travelled; zone recorded at shift creation
    };
    expect(durationMinutes(shift)).toBe(8 * 60);
  });

  it('detects overlapping shifts', () => {
    const a: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
      timeZone: 'UTC',
    };
    const b: ShiftInterval = {
      startUtc: '2026-06-01T20:00:00.000Z',
      endUtc: '2026-06-02T04:00:00.000Z',
      timeZone: 'UTC',
    };
    expect(intervalsOverlap(a, b)).toBe(true);
  });

  it('does not flag adjacent (split) shifts as overlapping', () => {
    const a: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T18:00:00.000Z',
      timeZone: 'UTC',
    };
    const b: ShiftInterval = {
      startUtc: '2026-06-01T18:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
      timeZone: 'UTC',
    };
    expect(intervalsOverlap(a, b)).toBe(false);
  });

  it('computes rest interval between two non-overlapping shifts', () => {
    const earlier: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
      timeZone: 'UTC',
    };
    const later: ShiftInterval = {
      startUtc: '2026-06-02T06:00:00.000Z',
      endUtc: '2026-06-02T14:00:00.000Z',
      timeZone: 'UTC',
    };
    expect(restIntervalMinutes(earlier, later)).toBe(8 * 60);
  });

  it('returns a negative rest interval for overlapping shifts (never throws)', () => {
    const earlier: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
      timeZone: 'UTC',
    };
    const later: ShiftInterval = {
      startUtc: '2026-06-01T20:00:00.000Z',
      endUtc: '2026-06-02T04:00:00.000Z',
      timeZone: 'UTC',
    };
    expect(restIntervalMinutes(earlier, later)).toBeLessThan(0);
  });

  it('rejects a missing end time', () => {
    const shift: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: null,
      timeZone: 'UTC',
    };
    expect(() => assertValidInterval(shift)).toThrow(InvalidShiftIntervalError);
    expect(() => durationMinutes(shift)).toThrow('no end time');
  });

  it('rejects end before or equal to start', () => {
    const equalShift: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T14:00:00.000Z',
      timeZone: 'UTC',
    };
    const reversedShift: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T10:00:00.000Z',
      timeZone: 'UTC',
    };
    expect(() => assertValidInterval(equalShift)).toThrow('after startUtc');
    expect(() => assertValidInterval(reversedShift)).toThrow('after startUtc');
  });

  it('rejects an invalid IANA time zone', () => {
    const shift: ShiftInterval = {
      startUtc: '2026-06-01T14:00:00.000Z',
      endUtc: '2026-06-01T22:00:00.000Z',
      timeZone: 'Not/A_Real_Zone',
    };
    expect(() => assertValidInterval(shift)).toThrow('Invalid IANA time zone');
  });

  it('is deterministic — running the same computation twice yields identical output', () => {
    const shift: ShiftInterval = {
      startUtc: '2026-03-08T05:00:00.000Z',
      endUtc: '2026-03-08T12:00:00.000Z',
      timeZone: 'America/New_York',
    };
    expect(durationMinutes(shift)).toBe(durationMinutes(shift));
  });
});

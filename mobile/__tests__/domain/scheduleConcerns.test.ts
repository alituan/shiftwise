import { detectConcerns } from '@/domain/concerns/scheduleConcerns';
import { ShiftInterval } from '@/domain/time/ShiftInterval';

describe('detectConcerns', () => {
  it('flags overlapping shifts', () => {
    const shifts: ShiftInterval[] = [
      { startUtc: '2026-06-01T14:00:00.000Z', endUtc: '2026-06-01T22:00:00.000Z', timeZone: 'UTC' },
      { startUtc: '2026-06-01T20:00:00.000Z', endUtc: '2026-06-02T04:00:00.000Z', timeZone: 'UTC' },
    ];
    const concerns = detectConcerns(shifts, {});
    expect(concerns.some((c) => c.kind === 'overlap')).toBe(true);
  });

  it('flags rest below the configured threshold, not above it', () => {
    const shifts: ShiftInterval[] = [
      { startUtc: '2026-06-01T14:00:00.000Z', endUtc: '2026-06-01T22:00:00.000Z', timeZone: 'UTC' },
      { startUtc: '2026-06-02T00:00:00.000Z', endUtc: '2026-06-02T08:00:00.000Z', timeZone: 'UTC' }, // 2h rest
    ];
    const flagged = detectConcerns(shifts, { minRestMinutes: 480 }); // 8h required
    expect(flagged.some((c) => c.kind === 'short_rest')).toBe(true);

    const notFlagged = detectConcerns(shifts, { minRestMinutes: 60 }); // 1h required
    expect(notFlagged.some((c) => c.kind === 'short_rest')).toBe(false);
  });

  it('flags total weekly hours above the configured threshold', () => {
    const shifts: ShiftInterval[] = [
      { startUtc: '2026-06-01T14:00:00.000Z', endUtc: '2026-06-01T22:00:00.000Z', timeZone: 'UTC' }, // 8h
      { startUtc: '2026-06-02T14:00:00.000Z', endUtc: '2026-06-02T22:00:00.000Z', timeZone: 'UTC' }, // 8h
    ];
    const flagged = detectConcerns(shifts, { maxWeeklyMinutes: 600 }); // 10h cap, 16h scheduled
    expect(flagged.some((c) => c.kind === 'long_week')).toBe(true);
  });

  it('flags an unusually long single shift', () => {
    const shifts: ShiftInterval[] = [
      { startUtc: '2026-06-01T08:00:00.000Z', endUtc: '2026-06-01T22:00:00.000Z', timeZone: 'UTC' }, // 14h
    ];
    const flagged = detectConcerns(shifts, { maxShiftMinutes: 600 }); // 10h cap
    expect(flagged.some((c) => c.kind === 'unusually_long_shift')).toBe(true);
  });

  it('flags no threshold-gated concerns when no thresholds are configured (overlap is unconditional, not threshold-gated)', () => {
    const nonOverlapping: ShiftInterval[] = [
      { startUtc: '2026-06-01T14:00:00.000Z', endUtc: '2026-06-01T22:00:00.000Z', timeZone: 'UTC' },
      { startUtc: '2026-06-02T14:00:00.000Z', endUtc: '2026-06-02T22:00:00.000Z', timeZone: 'UTC' },
    ];
    expect(detectConcerns(nonOverlapping, {})).toEqual([]);
  });

  it('does not crash on a shift with no end time -- just skips duration-dependent checks for it', () => {
    const shifts: ShiftInterval[] = [
      { startUtc: '2026-06-01T14:00:00.000Z', endUtc: null, timeZone: 'UTC' },
      { startUtc: '2026-06-02T14:00:00.000Z', endUtc: '2026-06-02T22:00:00.000Z', timeZone: 'UTC' },
    ];
    expect(() =>
      detectConcerns(shifts, { minRestMinutes: 480, maxWeeklyMinutes: 600 }),
    ).not.toThrow();
  });

  it('uses "possible schedule concern" phrasing, never "violation" (docs/scope.md hard rule)', () => {
    const shifts: ShiftInterval[] = [
      { startUtc: '2026-06-01T14:00:00.000Z', endUtc: '2026-06-01T22:00:00.000Z', timeZone: 'UTC' },
      { startUtc: '2026-06-01T20:00:00.000Z', endUtc: '2026-06-02T04:00:00.000Z', timeZone: 'UTC' },
    ];
    const concerns = detectConcerns(shifts, {});
    for (const concern of concerns) {
      expect(concern.message).toMatch(/possible schedule concern/i);
      expect(concern.message.toLowerCase()).not.toContain('violation');
    }
  });
});

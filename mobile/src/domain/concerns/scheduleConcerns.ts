import {
  durationMinutes,
  intervalsOverlap,
  restIntervalMinutes,
  ShiftInterval,
} from '@/domain/time/ShiftInterval';

/**
 * Schedule concerns are always user-configured thresholds, never an assumed
 * statutory rule -- see docs/architecture/pay-engine.md and docs/scope.md.
 * Surfaced in UI as "possible schedule concern", never "violation". Only a
 * legally reviewed, versioned jurisdiction rule pack (not built yet) may
 * ever describe an actual statutory rule.
 */

export interface ScheduleConcernThresholds {
  minRestMinutes?: number;
  maxWeeklyMinutes?: number;
  maxShiftMinutes?: number;
}

export type ScheduleConcernKind = 'short_rest' | 'overlap' | 'long_week' | 'unusually_long_shift';

export interface ScheduleConcern {
  kind: ScheduleConcernKind;
  message: string;
}

/** Shifts must be sorted by startUtc ascending before calling this. */
export function detectConcerns(
  shifts: ShiftInterval[],
  thresholds: ScheduleConcernThresholds,
): ScheduleConcern[] {
  const concerns: ScheduleConcern[] = [];

  for (let i = 0; i < shifts.length; i++) {
    const shift = shifts[i];

    if (shift.endUtc !== null && thresholds.maxShiftMinutes !== undefined) {
      const minutes = durationMinutes(shift);
      if (minutes > thresholds.maxShiftMinutes) {
        concerns.push({
          kind: 'unusually_long_shift',
          message: `Possible schedule concern: shift starting ${shift.startUtc} runs longer than usual.`,
        });
      }
    }

    if (i > 0) {
      const previous = shifts[i - 1];
      if (previous.endUtc !== null) {
        if (intervalsOverlap(previous, shift)) {
          concerns.push({
            kind: 'overlap',
            message: `Possible schedule concern: this shift overlaps the one before it.`,
          });
        } else if (thresholds.minRestMinutes !== undefined) {
          const rest = restIntervalMinutes(previous, shift);
          if (rest < thresholds.minRestMinutes) {
            concerns.push({
              kind: 'short_rest',
              message: `Possible schedule concern: less than ${thresholds.minRestMinutes} minutes of rest before this shift.`,
            });
          }
        }
      }
    }
  }

  if (thresholds.maxWeeklyMinutes !== undefined) {
    const totalMinutes = shifts.reduce(
      (sum, shift) => sum + (shift.endUtc !== null ? durationMinutes(shift) : 0),
      0,
    );
    if (totalMinutes > thresholds.maxWeeklyMinutes) {
      concerns.push({
        kind: 'long_week',
        message: `Possible schedule concern: total scheduled hours this week exceed your configured threshold.`,
      });
    }
  }

  return concerns;
}

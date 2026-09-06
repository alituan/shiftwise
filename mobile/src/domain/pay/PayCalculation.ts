import Decimal from 'decimal.js';
import { Money } from '@/domain/money/Money';
import { durationMinutes, ShiftInterval } from '@/domain/time/ShiftInterval';

/**
 * Estimated gross pay only -- never take-home pay, tax, or exact payroll
 * accuracy. See docs/architecture/pay-engine.md and docs/scope.md's hard
 * content rules. Pure and deterministic: no wall-clock reads, no hidden
 * state -- same inputs always produce the same output.
 */

export interface RateVersion {
  /** Identifies which rate/rule version produced a calculation snapshot -- see docs/architecture/data-model.md. */
  versionId: string;
  hourlyRate: string; // decimal string, e.g. "16.50"
  currency: string;
  /** The instant this rate became effective; a shift uses whichever version was effective at its startUtc. */
  effectiveFromUtc: string;
}

export interface Differential {
  label: string; // e.g. "Weekend premium"
  /** Additional amount per hour, added on top of the base rate for this shift's hours. */
  amountPerHour: string;
}

export interface PayCalculationInput {
  shift: ShiftInterval;
  paidBreakMinutes: number;
  unpaidBreakMinutes: number;
  rateVersions: RateVersion[]; // may contain multiple versions; the effective one is selected by shift.startUtc
  differentials?: Differential[];
  /** Round paid minutes to the nearest multiple of this value (e.g. 15). Omit for no rounding. */
  roundToNearestMinutes?: number;
}

export interface PayCalculationResult {
  paidMinutes: number;
  baseEstimate: Money;
  differentialsApplied: { label: string; amount: Money }[];
  totalEstimate: Money;
  rateVersionUsed: string;
  currency: string;
}

export class InvalidBreakConfigurationError extends Error {}
export class NoEffectiveRateVersionError extends Error {}

function selectEffectiveRateVersion(
  shift: ShiftInterval,
  rateVersions: RateVersion[],
): RateVersion {
  const shiftStart = shift.startUtc;
  const candidates = rateVersions
    .filter((version) => version.effectiveFromUtc <= shiftStart)
    .sort((a, b) => (a.effectiveFromUtc < b.effectiveFromUtc ? 1 : -1));
  if (candidates.length === 0) {
    throw new NoEffectiveRateVersionError(
      `No rate version is effective at or before ${shiftStart} (mid-period rate change must still resolve to exactly one version per shift)`,
    );
  }
  return candidates[0];
}

function roundMinutes(minutes: number, roundToNearestMinutes: number | undefined): number {
  if (roundToNearestMinutes === undefined || roundToNearestMinutes <= 0) return minutes;
  return Math.round(minutes / roundToNearestMinutes) * roundToNearestMinutes;
}

export function calculatePay(input: PayCalculationInput): PayCalculationResult {
  const { shift, paidBreakMinutes, unpaidBreakMinutes, rateVersions, differentials = [] } = input;

  if (paidBreakMinutes < 0 || unpaidBreakMinutes < 0) {
    throw new InvalidBreakConfigurationError('Break minutes cannot be negative');
  }

  const totalShiftMinutes = durationMinutes(shift);
  if (paidBreakMinutes + unpaidBreakMinutes > totalShiftMinutes) {
    throw new InvalidBreakConfigurationError(
      `Break duration (${paidBreakMinutes + unpaidBreakMinutes}min) cannot exceed shift duration (${totalShiftMinutes}min)`,
    );
  }

  const rawPaidMinutes = totalShiftMinutes - unpaidBreakMinutes;
  const paidMinutes = roundMinutes(rawPaidMinutes, input.roundToNearestMinutes);

  const rateVersion = selectEffectiveRateVersion(shift, rateVersions);
  const paidHours = new Decimal(paidMinutes).dividedBy(60);

  const baseEstimate = Money.fromDecimalString(
    rateVersion.hourlyRate,
    rateVersion.currency,
  ).multiply(paidHours);

  const differentialsApplied = differentials.map((differential) => ({
    label: differential.label,
    amount: Money.fromDecimalString(differential.amountPerHour, rateVersion.currency).multiply(
      paidHours,
    ),
  }));

  const totalEstimate = differentialsApplied.reduce(
    (total, applied) => total.add(applied.amount),
    baseEstimate,
  );

  return {
    paidMinutes,
    baseEstimate,
    differentialsApplied,
    totalEstimate,
    rateVersionUsed: rateVersion.versionId,
    currency: rateVersion.currency,
  };
}

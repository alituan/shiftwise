import {
  calculatePay,
  InvalidBreakConfigurationError,
  NoEffectiveRateVersionError,
  PayCalculationInput,
} from '@/domain/pay/PayCalculation';

const baseShift = {
  startUtc: '2026-06-01T14:00:00.000Z',
  endUtc: '2026-06-01T22:00:00.000Z', // 8 hours
  timeZone: 'America/New_York',
};

const baseRateVersion = {
  versionId: 'v1',
  hourlyRate: '16.50',
  currency: 'USD',
  effectiveFromUtc: '2026-01-01T00:00:00.000Z',
};

describe('calculatePay — required boundary cases (docs/architecture/pay-engine.md)', () => {
  it('calculates a plain 8-hour shift with no breaks', () => {
    const input: PayCalculationInput = {
      shift: baseShift,
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 0,
      rateVersions: [baseRateVersion],
    };
    const result = calculatePay(input);
    expect(result.paidMinutes).toBe(8 * 60);
    expect(result.baseEstimate.toFixed(2)).toBe('132.00');
    expect(result.totalEstimate.toFixed(2)).toBe('132.00');
    expect(result.rateVersionUsed).toBe('v1');
  });

  it('subtracts unpaid break minutes from paid time, but not paid break minutes', () => {
    const input: PayCalculationInput = {
      shift: baseShift,
      paidBreakMinutes: 15,
      unpaidBreakMinutes: 30,
      rateVersions: [baseRateVersion],
    };
    const result = calculatePay(input);
    // 8h = 480min; only the 30 unpaid minutes come off
    expect(result.paidMinutes).toBe(480 - 30);
  });

  it('rejects negative break minutes', () => {
    const input: PayCalculationInput = {
      shift: baseShift,
      paidBreakMinutes: -5,
      unpaidBreakMinutes: 0,
      rateVersions: [baseRateVersion],
    };
    expect(() => calculatePay(input)).toThrow(InvalidBreakConfigurationError);
  });

  it('rejects a break configuration longer than the shift itself', () => {
    const input: PayCalculationInput = {
      shift: baseShift, // 480 minutes
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 500,
      rateVersions: [baseRateVersion],
    };
    expect(() => calculatePay(input)).toThrow(InvalidBreakConfigurationError);
  });

  it('selects the correct rate version for a mid-period rate change', () => {
    const oldRate = {
      ...baseRateVersion,
      versionId: 'v1',
      hourlyRate: '15.00',
      effectiveFromUtc: '2026-01-01T00:00:00.000Z',
    };
    const newRate = {
      ...baseRateVersion,
      versionId: 'v2',
      hourlyRate: '17.00',
      effectiveFromUtc: '2026-06-01T00:00:00.000Z',
    };

    // Shift starts after the rate change takes effect -> new rate applies
    const afterChange = calculatePay({
      shift: baseShift, // starts 2026-06-01T14:00Z
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 0,
      rateVersions: [oldRate, newRate],
    });
    expect(afterChange.rateVersionUsed).toBe('v2');
    expect(afterChange.baseEstimate.toFixed(2)).toBe('136.00');

    // A shift the day before the change still uses the old rate
    const beforeChange = calculatePay({
      shift: {
        ...baseShift,
        startUtc: '2026-05-31T14:00:00.000Z',
        endUtc: '2026-05-31T22:00:00.000Z',
      },
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 0,
      rateVersions: [oldRate, newRate],
    });
    expect(beforeChange.rateVersionUsed).toBe('v1');
    expect(beforeChange.baseEstimate.toFixed(2)).toBe('120.00');
  });

  it('throws when no rate version is effective at the shift start', () => {
    const futureRate = { ...baseRateVersion, effectiveFromUtc: '2099-01-01T00:00:00.000Z' };
    const input: PayCalculationInput = {
      shift: baseShift,
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 0,
      rateVersions: [futureRate],
    };
    expect(() => calculatePay(input)).toThrow(NoEffectiveRateVersionError);
  });

  it('applies differentials on top of the base rate, each traceable by label', () => {
    const input: PayCalculationInput = {
      shift: baseShift,
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 0,
      rateVersions: [baseRateVersion],
      differentials: [{ label: 'Weekend premium', amountPerHour: '2.00' }],
    };
    const result = calculatePay(input);
    expect(result.differentialsApplied).toHaveLength(1);
    expect(result.differentialsApplied[0].label).toBe('Weekend premium');
    expect(result.differentialsApplied[0].amount.toFixed(2)).toBe('16.00'); // 8h * $2.00
    expect(result.totalEstimate.toFixed(2)).toBe('148.00'); // 132.00 base + 16.00
  });

  it('rounds paid minutes to the requested increment', () => {
    const shift = { ...baseShift, endUtc: '2026-06-01T21:52:00.000Z' }; // 7h52m = 472min
    const input: PayCalculationInput = {
      shift,
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 0,
      rateVersions: [baseRateVersion],
      roundToNearestMinutes: 15,
    };
    const result = calculatePay(input);
    expect(result.paidMinutes).toBe(465); // 472 rounds to nearest 15 -> 465
  });

  it('is deterministic — recomputing the same snapshot inputs twice yields identical output', () => {
    const input: PayCalculationInput = {
      shift: baseShift,
      paidBreakMinutes: 15,
      unpaidBreakMinutes: 30,
      rateVersions: [baseRateVersion],
      differentials: [{ label: 'Weekend premium', amountPerHour: '2.00' }],
    };
    const first = calculatePay(input);
    const second = calculatePay(input);
    expect(first.totalEstimate.equals(second.totalEstimate)).toBe(true);
    expect(first.paidMinutes).toBe(second.paidMinutes);
    expect(first.rateVersionUsed).toBe(second.rateVersionUsed);
  });

  it('propagates a missing-end-time error from the underlying interval check', () => {
    const input: PayCalculationInput = {
      shift: { ...baseShift, endUtc: null },
      paidBreakMinutes: 0,
      unpaidBreakMinutes: 0,
      rateVersions: [baseRateVersion],
    };
    expect(() => calculatePay(input)).toThrow('no end time');
  });
});

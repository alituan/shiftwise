import { Money } from '@/domain/money/Money';

describe('Money', () => {
  it('avoids binary-float rounding artifacts on multiply', () => {
    // hours * rate that would produce 47.999999999996 as raw JS numbers
    const rate = Money.fromDecimalString('16.55', 'USD');
    const result = rate.multiply('2.9');
    expect(result.toFixed(2)).toBe('48.00');
  });

  it('adds and subtracts within the same currency', () => {
    const a = Money.fromDecimalString('10.00', 'USD');
    const b = Money.fromDecimalString('2.50', 'USD');
    expect(a.add(b).toFixed(2)).toBe('12.50');
    expect(a.subtract(b).toFixed(2)).toBe('7.50');
  });

  it('throws on cross-currency arithmetic', () => {
    const usd = Money.fromDecimalString('10.00', 'USD');
    const eur = Money.fromDecimalString('10.00', 'EUR');
    expect(() => usd.add(eur)).toThrow('Currency mismatch');
    expect(() => usd.compare(eur)).toThrow('Currency mismatch');
  });

  it('round-trips minor units exactly', () => {
    const money = Money.fromMinorUnits(1250, 'USD');
    expect(money.toFixed(2)).toBe('12.50');
    expect(money.toMinorUnits()).toBe(1250);
  });

  it('rejects non-integer minor units', () => {
    expect(() => Money.fromMinorUnits(12.5, 'USD')).toThrow();
  });

  it('compares correctly', () => {
    const a = Money.fromDecimalString('5.00', 'USD');
    const b = Money.fromDecimalString('10.00', 'USD');
    expect(a.compare(b)).toBe(-1);
    expect(b.compare(a)).toBe(1);
    expect(a.compare(a)).toBe(0);
  });

  it('detects zero and negative amounts', () => {
    expect(Money.zero('USD').isZero()).toBe(true);
    const negative = Money.fromDecimalString('-5.00', 'USD');
    expect(negative.isNegative()).toBe(true);
  });

  it('equals compares value and currency', () => {
    const a = Money.fromDecimalString('10.00', 'USD');
    const b = Money.fromMinorUnits(1000, 'USD');
    const c = Money.fromDecimalString('10.00', 'EUR');
    expect(a.equals(b)).toBe(true);
    expect(a.equals(c)).toBe(false);
  });
});

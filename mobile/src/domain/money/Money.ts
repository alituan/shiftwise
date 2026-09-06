import Decimal from 'decimal.js';

/**
 * Every currency value in this app must be a Money instance. Never a raw JS
 * `number` — see docs/architecture/pay-engine.md. Money wraps decimal.js so
 * `hours * rate` can never produce a binary-float artifact like
 * $47.999999999996.
 */
export class Money {
  private readonly amount: Decimal;
  readonly currency: string;

  private constructor(amount: Decimal, currency: string) {
    this.amount = amount;
    this.currency = currency;
  }

  /** `amount` must be a string (e.g. "12.50"), never a JS number literal. */
  static fromDecimalString(amount: string, currency: string): Money {
    return new Money(new Decimal(amount), currency);
  }

  static zero(currency: string): Money {
    return new Money(new Decimal(0), currency);
  }

  /** Minor units (e.g. cents) as an integer — the one safe number boundary. */
  static fromMinorUnits(minorUnits: number, currency: string): Money {
    if (!Number.isInteger(minorUnits)) {
      throw new Error('fromMinorUnits requires an integer number of minor units');
    }
    return new Money(new Decimal(minorUnits).dividedBy(100), currency);
  }

  private assertSameCurrency(other: Money): void {
    if (this.currency !== other.currency) {
      throw new Error(`Currency mismatch: ${this.currency} vs ${other.currency}`);
    }
  }

  add(other: Money): Money {
    this.assertSameCurrency(other);
    return new Money(this.amount.plus(other.amount), this.currency);
  }

  subtract(other: Money): Money {
    this.assertSameCurrency(other);
    return new Money(this.amount.minus(other.amount), this.currency);
  }

  /** factor must be a Decimal or a numeric string — never a raw JS number. */
  multiply(factor: Decimal | string): Money {
    const decimalFactor = factor instanceof Decimal ? factor : new Decimal(factor);
    return new Money(this.amount.times(decimalFactor), this.currency);
  }

  isNegative(): boolean {
    return this.amount.isNegative();
  }

  isZero(): boolean {
    return this.amount.isZero();
  }

  /** -1 if this < other, 0 if equal, 1 if this > other. Throws on currency mismatch. */
  compare(other: Money): -1 | 0 | 1 {
    this.assertSameCurrency(other);
    return this.amount.comparedTo(other.amount) as -1 | 0 | 1;
  }

  equals(other: Money): boolean {
    return this.currency === other.currency && this.amount.equals(other.amount);
  }

  /** Fixed-point string for display, e.g. "127.88". Never parse this back with parseFloat. */
  toFixed(decimalPlaces = 2): string {
    return this.amount.toFixed(decimalPlaces);
  }

  toMinorUnits(): number {
    const minorUnits = this.amount.times(100);
    if (!minorUnits.isInteger()) {
      throw new Error(
        `Cannot represent ${this.amount.toString()} as an exact integer of minor units`,
      );
    }
    return minorUnits.toNumber();
  }
}

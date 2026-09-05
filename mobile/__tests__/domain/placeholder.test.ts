// Placeholder — replaced by the Money/time domain suite in the next phase.
// Confirms the Jest + jest-expo pipeline runs pure-TypeScript tests with no
// React Native runtime needed, matching the "domain stays framework-free"
// discipline rule in docs/architecture/stack.md.
import Decimal from 'decimal.js';

describe('decimal.js sanity check', () => {
  it('avoids the classic binary-float rounding error', () => {
    const hours = new Decimal('7.75');
    const rate = new Decimal('16.5');
    expect(hours.times(rate).toFixed(2)).toBe('127.88');
  });
});
